# coding: utf-8
'''
This file pulls seizure and nonseizure clips
for each patient from IEEG and saves them.
'''
import math
import os

import h5py
import ieeg
from ieeg.auth import Session
from ieeg.dataset import Annotation
import numpy as np
from scipy.io import loadmat, savemat

N_INTERICTALS = 360
WINDOW_SIZE = int(10e6)
HDF5_NAME = 'training_data.hdf5'
BATCH_SIZE = 100

os.chdir('matlab')

### load seizure timestamps
all_annots = loadmat('other/all_annots_32')['all_annots']
A = {row[0].item(): [(int(a*1e6), int(b*1e6)) for a,b in zip(row[1][0], row[2][0])]
    for row in all_annots[0] if row[0].item().startswith('RID00')}
pt_names = sorted(A.keys())

### Connect to IEEG
with open('ieeg_login', 'r') as f:
    LOGIN = f.readline().strip().split()
with Session(*LOGIN) as s:
    datasets = {p: s.open_dataset(p) for p in pt_names}

def create_file(fname):
    'create hdf5 file with ictal/interictal groups, truncate if exists'
    with h5py.File(fname, 'w') as f:
        for category in ('ictal', 'interictal'):
            g = f.create_group(category)

def append_dataset(fname, category, data_dict):
    '''
    fname: hdf5 file name
    category: 'ictal' or 'interictal'
    data_dict: {pt_name: [3d array of clips]}
    '''
    with h5py.File(fname, 'a') as f:
        group = f[category]
        for pt, data in data_dict.items():
            if data.size == 0:
                continue
            if pt in group:
                # append to existing dataset
                ds = group[pt]
                n_clips = data.shape[0]
                ds.resize(ds.shape[0] + n_clips, axis=0)
                ds[-n_clips:, ...] = data
            else:
                # dimensions: (# clips, # samples, # channels)
                group.create_dataset(pt, data=data,
                    chunks=(1, data.shape[1], data.shape[2]), # 1 chunk per clip
                    maxshape=(None, data.shape[1], data.shape[2]))

def getclip(ds, window, ictal, sz_number=None):
    '''
    get a random clip of length `window`, can be ictal or not
    if ictal, specify which seizure to sample from
    '''
    # get dataset start/end and channel indices
    ch_names = ['C3', 'C4', 'Cz', 'F3', 'F4', 'F7', 'F8', 'Fp1', 'Fp2', 'Fz', 'O1', 'O2', 'P3', 'P4', 'T3', 'T4', 'T5', 'T6']
    channels = [i for i,x in enumerate(ds.ts_details.keys()) if x in ch_names]
    ts_start = max(ds.ts_details[ch].start_time for ch in ch_names) #ds.ts_details['O1'].start_time
    ts_end = min(ds.ts_details[ch].start_time + ds.ts_details[ch].duration for ch in ch_names) #ts_start + ds.ts_details['O1'].duration

    if ictal:
        sz_start, sz_stop = annots[sz_number]
        sz_len = sz_stop - sz_start
        if sz_len > window:
            # pick clip in somewhere inside the seizure
            a = sz_start
            b = sz_len - window
            start = int(np.random.sample() * b + a)
            end = start + window
        else:
            # pick clip that encompasss the entire sz
            a = sz_stop - window
            b = sz_start
            start = int(np.random.sample() * (b - a) + a)
            end = start + window
    else:
        # pick a window between end of 1st sz and start of last sz
        a = annots[0][1]
        b = annots[-1][0]

        # make sure this window doesnt contain a sz
        while True:
            start = int(np.random.random_sample() * (b - a) + a)
            end = start + window
            if not(any(start < a[1] and end > a[0] for a in annots)):
                break
    
    try:
        return ds.get_data(start, window, channels)
    except ieeg.ieeg_api.IeegConnectionError:
        return np.array(np.nan)

### Create hdf5 file (overwrites existing file!)
create_file(HDF5_NAME)

### Get ictal clips - use all seizure data
print('Finding ictal clips...')
for pt_name in pt_names:
    annots = A[pt_name]
    ds = datasets[pt_name]
    for i, (start,stop) in enumerate(annots):
        n_ictals = math.ceil((stop - start) / WINDOW_SIZE)
        total = 0
        errors = 0
        while total < n_ictals and errors < 5:
            # get batch of clips
            ictals = {x: [] for x in pt_names}
            clip = getclip(ds, WINDOW_SIZE, ictal=True, sz_number=i)
            if np.isnan(clip).any():
                errors += 1
                continue
            ictals[pt_name].append(clip)
            total += 1

        if errors < 5:
            # save batch
            ictals = {k: np.array(v) for k,v in ictals.items()}
            append_dataset(HDF5_NAME, 'ictal', ictals)
            print('%s: seiure %d: batch saved.' % (pt_name, i+1))

### Get interictal clips
print('Finding interictal clips...')
total = 0
batch_no = 1
while total < N_INTERICTALS:
    interictals = {x: [] for x in pt_names}
    for _ in range(min(BATCH_SIZE, N_INTERICTALS - total)):
        for pt_name in pt_names:
            # get the dataset
            annots = A[pt_name]
            ds = datasets[pt_name]

            # find a non-empty clip
            while True:
                clip = getclip(ds, WINDOW_SIZE, ictal=False)
                if not(np.isnan(clip).any()):
                    break
            interictals[pt_name].append(clip)
        total += 1

    interictals = {k: np.array(v) for k,v in interictals.items()}
    append_dataset(HDF5_NAME, 'interictal', interictals)
    print('Batch %d saved.' % batch_no)
    batch_no += 1
