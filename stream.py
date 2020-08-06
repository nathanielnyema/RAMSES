#!/usr/bin/env python3
'''
This file mock-streams data from each of the ICU patients on the IEEG portal,
and runs the Litt Lab classifier on each EEG clip.
'''
import sys
from datetime import datetime, timedelta

import ieeg
from ieeg.auth import Session
import matlab.engine
import numpy as np
from math import floor
import celery

from patient import Bed, Patient, SeizurePrediction
import setup_db
from time import sleep

def to_usec(seconds):
    return int(seconds * 1e6)

# parameters for data pulling
DURATION = to_usec(7200) # 2 hours
SAMPLERATE = 256
WINDOWSIZE = to_usec(10)
CHANNELS = ['C3', 'C4', 'Cz', 'F3', 'F4', 'F7', 'F8', 'Fp1', 'Fp2', 'Fz',
            'O1', 'O2', 'P3', 'P4', 'T3', 'T4', 'T5', 'T6'] # 18 total
BEDS = ['RID%04d' % i for i in range(60,76)] # RID0060 to RID0075
ROOMS=[floor(4*i/len(BEDS)) for i in range(len(BEDS))]
# initialize matlab classifier
if len(matlab.engine.find_matlab()) > 0:
    print('connecting to existing matlab engine')
    eng=matlab.engine.connect_matlab()
    eng.addpath('matlab')
    eng.addpath('matlab/IEEGToolbox')
else:
    print('starting matlab engine')
    eng = matlab.engine.start_matlab('-r "matlab.engine.shareEngine"')
    eng.addpath('matlab')
    eng.addpath('matlab/IEEGToolbox')
    eng.init_classifier(nargout=0)

# get all the datasets
print('connecting to IEEG')
with open('matlab/ieeg_login', 'r') as f:
    login = f.readline().strip().split()
with Session(*login) as s:
    datasets = {bd: s.open_dataset(bd) for bd in BEDS}

def get_data(bd, start_usec, length_usec):
    'Pull raw data for bed from IEEG'
    ds = datasets[bd]
    ch_indices = [ds.ch_labels.index(ch) for ch in CHANNELS]
    return ds.get_data(start_usec, length_usec, ch_indices)

# pull data from each dataset for specified beds
# TODO: apply smoothing of predictions by:
#   1) removing isolated seizure predictions
#   2) combining seizure predictions which are close together
# TODO: detect poor performance and retroactively change predictions to unsure (1)
def classify_save(bd, start, duration, timestamp, data):
    '''
    Classifies and saves MEF EEG data
    '''

    # get prediction
    try:
        pred, conf = eng.predict(matlab.double(data.tolist()), SAMPLERATE, nargout=2)
        pred = int(pred)
    except matlab.engine.MatlabExecutionError:
        pred=3
        conf=1.0
    print('%s: %d (%.3f)' % (bd, pred, conf))

    # save prediction and timestamp
    bd_entry=Bed.objects.raw({"bed_id": bd}).first()
    last_read = bd_entry.patients[-1].predictions[-1].prediction
    if last_read != pred:
        #if new prediction add it
        bd_entry.patients[-1].predictions.append(SeizurePrediction(prediction=pred, time=timestamp, confidence=conf))
    else:
        #otherwise don't and change the end time of the last prediction
        # TODO: update the confidence score as well
        bd_entry.patients[-1].predictions[-1].time=timestamp
    bd_entry.patients[-1].lastread = timestamp
    bd_entry.save()

def pull_classify_save(bd, start, duration, timestamp):
    'pull from IEEG -> classify as 0/1/2/3 -> save to db'
    try:
        data = get_data(bd, start, duration) 
    except matlab.engine.MatlabExecutionError:
        data = np.nan
    classify_save(bd, start, duration, timestamp, data)

@celery.task()
def async_stream():
    beds=setup_db.check_available()
    if len(beds)>0:
        beds=[Bed.objects.raw({'bed_id':b}).first() for b in beds]
        for i,b in enumerate(beds):
            dur=to_usec((datetime.now()-b.patients[-1].lastread).total_seconds())
            start=to_usec((b.patients[-1].lastread-b.patients[-1].start).total_seconds())
            pull_classify_save(b.bed_id,start,dur,datetime.now())
    else:
        print('all beds empty')


#old function for streaming without celery beat scheduler
def independent_stream(bed=None, start=0):
    'mock-stream one or all IEEG patients, save predictions to db'
    running_total = 0
    timestamp = datetime.now()
    while True: #running_total < DURATION:
        print(timestamp.strftime('%Y-%m-%d %H:%M:%S.%f'))
        if bed is None: # stream all patients
            for b in BEDS:
                if Bed.objects.raw({"bed_id": b}).first().active:
                    pull_classify_save(b, start, WINDOWSIZE,timestamp)
                else:
                    print(b,' is inactive')
                    sleep(0.5)
        else: # stream only the selected bed
            pull_classify_save(bed, start, WINDOWSIZE,timestamp)

        # move the window forward
        start += WINDOWSIZE
        running_total += WINDOWSIZE
        timestamp += timedelta(microseconds=WINDOWSIZE)

if __name__ == '__main__':
    if len(sys.argv) >= 2:
        bed = sys.argv[1]
        print('stream.py: Streaming bed:', bed)
        if len(sys.argv) >= 3:
            independent_stream(bed, sys.argv[2])
        else:
            independent_stream(bed)
    else:
        # stream all IEEG patients
        print('stream.py: streaming all beds')
        print('resetting db')
        setup_db.clear_db()
        for i,b in enumerate(BEDS):
            setup_db.add_bed(b,ROOMS[i])
        print('pulling data')
        independent_stream()
