#!/usr/bin/env python3
from datetime import datetime, timedelta
from subprocess import call
import json
import os

from celery import Celery
import celeryconfig
from flask import Flask, render_template, make_response, request, url_for, jsonify
from flask_assets import Environment, Bundle
import ieeg
from ieeg.auth import Session
import numpy as np
import pandas as pd

from patient import Bed, Patient, SeizurePrediction
import setup_db
from stream import get_data, BEDS, CHANNELS, ROOMS
from scipy import signal as sig

# setup flask app
app = Flask(__name__)

#setup Celery
app.config['CELERY_BROKER_URL'] = 'redis://localhost:6379/0'
app.config['CELERY_RESULT_BACKEND'] = 'redis://localhost:6379/0'

#https://flask.palletsprojects.com/en/1.1.x/patterns/celery/
def make_celery(app):
    """
    wraps celery task in the flask app context
    """

    celery = Celery(
        app.import_name,
        backend=app.config['CELERY_RESULT_BACKEND'],
        broker=app.config['CELERY_BROKER_URL']
    )
    celery.conf.update(app.config)
    celery.config_from_object(celeryconfig)

    class ContextTask(celery.Task):
        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery.Task = ContextTask
    return celery

celery = make_celery(app)
#bundle static files
assets=Environment(app)

js_reqs_bundle=Bundle(
    'src/js/chartjs-plugin-downsample.js',
    'src/js/jquery.fittext.js',
    filters='jsmin',
    output='dist/js/reqs.min.js')

js_main=Bundle(
    'src/js/display.js',
    filters='jsmin',
    output='dist/js/main.min.js')

css_bundle=Bundle(
    'src/css/style.css',
    filters='cssutils',
    output='dist/css/style.min.css')

assets.register('main_css', css_bundle)
assets.register('reqs_js', js_reqs_bundle)
assets.register('main_js', js_main)

css_bundle.build()
js_reqs_bundle.build()
js_main.build()

def to_usec(seconds):
    return int(seconds * 1e6)

def get_last(l, item):
    """
    find the most recent occurence of an item in an ordered list
    """
    for i, x in enumerate(reversed(l)):
        if x == item:
            return len(l) - i - 1
    raise ValueError('item not found')

def get_stats(predictions,ts):
    """
    given the predictions and timestamps in given window 
    for a patient on a given active bed
    compute summary statistics for the home page
    """

    #determine the worst prediction
    try:
        worst=max(filter(lambda x:x<3,predictions))
    except ValueError:
        worst=max(predictions)

    #compute the percentage of data in the window that is concerning
    total_length = (ts[-1] - ts[0]).total_seconds()
    lengths=[(t-ts[i]).total_seconds() for i,t in enumerate(ts[1:len(ts)]) if (predictions[i]==1 or predictions[i]==2)]
    pct=round(100*sum(lengths)/total_length,2)

    #determine when the last seizure was and how many seizures occured in the window
    try:
        idx = get_last(predictions, 2)
    except ValueError:
        sztimes=0
        sznums=0
    else:
        since = datetime.now() - ts[idx]
        sztimes=round(since.total_seconds()/60,2)   
        ds=pd.Series(predictions)  
        sznums=len(ds[ds==2])
    return sztimes, sznums, worst, pct

@app.route('/')
def home():
    """
    Use get_stats to compute summary statistics for patients on all active beds
    over all selectable time windows and render the html accordingly
    """

    windows=['h2','h4','h8','h12','h24']
    sztimes= {win:[] for win in windows}
    sznums={win:[] for win in windows}
    worst={win:[] for win in windows}
    pct={win:[] for win in windows}
    preds={win:[] for win in windows}
    times={win:[] for win in windows}
    orders={}

    active=[]
    active_names=[]
    rooms=[]

    for bd in BEDS: #loop through all beds

        if Bed.objects.raw({'bed_id': bd}).first().active: #check if the bed is active
            pt=Bed.objects.raw({'bed_id': bd}).first().patients[-1]
            predictions= pt.predictions
            valid=list(filter(lambda x:x<3,[x.prediction for x in predictions]))

            if len(valid)>0: #check if any predictions have been made with the classifier yet
                active.append(bd)
                active_names.append(Bed.objects.raw({'bed_id': bd}).first().patients[-1].name)
                rooms.append(Bed.objects.raw({'bed_id': bd}).first().room)
                
                for win in windows: #loop through all windows and compute the summary stats over each 
                    now=datetime.now()
                    hours=int(win[1:len(win)])
                    wind_start=now-timedelta(hours=hours)
                    ts = [max(wind_start,pt.start)] + [x.time for x in predictions if x.time>wind_start]
                    ps = [x.prediction for x in predictions if x.time>wind_start]

                    sztimes_tmp, sznums_tmp, worst_tmp, pct_tmp=get_stats(ps,ts)
                    sztimes[win].append(sztimes_tmp)
                    sznums[win].append(sznums_tmp)
                    worst[win].append(worst_tmp)
                    pct[win].append(pct_tmp)
                    preds[win].append(ps)
                    times[win].append([t.strftime('%Y-%m-%d %H:%M:%S.%f') for t in ts])
 


    for win in windows:
        # for each window size we have a different set of orderings       
        orders[win]={
            'recent': np.argsort(np.array(sztimes[win])).tolist(),
            'density': np.argsort(-np.array(pct[win])).tolist(),
            'room': np.argsort(-np.array(rooms)).tolist(),
        }



    return render_template(
        'index.html', 
        list=json.dumps(active),
        list2=json.dumps(active_names),
        sznums=json.dumps(sznums), 
        sztimes=json.dumps(sztimes),
        worst=json.dumps(worst),
        orders=json.dumps(orders),
        pct=json.dumps(pct),
        preds=json.dumps(preds),
        times=json.dumps(times),
        )

@app.route('/dashboard')
def dashboard():
    """
    Pull the selected patient's data from the database and prepare
    the data and statistics to render the display
    """

    #get patient data from request and from database
    bed = request.args.get('name')
    if not Bed.objects.raw({ 'bed_id': bed }).first().active:
        return render_template('inactive.html')

    patient_db = Bed.objects.raw({ 'bed_id': bed }).first().patients[-1]

    active=[b for b in BEDS if Bed.objects.raw({ 'bed_id': b }).first().active]
    bIndex = active.index(bed)
    prevb = active[bIndex-1] if bIndex > 0 else active[-1]
    nextb = active[bIndex+1] if bIndex < len(active)-1 else active[0]

    if len(patient_db.predictions) == 1:
        return render_template('loading.html')

    # extract the predictions, confidence values and associated time intervals
    preds_list = [p.prediction for p in patient_db.predictions]
    preds_list.pop(0)
    conf_list = [p.confidence for p in patient_db.predictions]
    conf_list.pop(0)
    vals = ['Good', 'Maybe seizure', 'Seizure','Artifact']
    pred = vals[preds_list[-1]]
    times_list = [p.time for p in patient_db.predictions]

    # compute seizure statistics
    total_length = times_list[-1] - times_list[0]
    lengths=[(t-times_list[i]).total_seconds() for i,t in enumerate(times_list[1:len(times_list)]) if (preds_list[i]==1 or preds_list[i]==2)]
    median=str(np.median(lengths))+' seconds'
    pct=str(round(100*sum(lengths)/total_length.total_seconds(),2))+'%'

    try:
        idx = get_last(preds_list, 2)
    except ValueError:
        last_sz = timedelta(0)
    else:
        last_sz = times_list[-1] - times_list[idx]
        last_sz = str(last_sz - timedelta(microseconds=last_sz.microseconds))

    total_length = str(total_length - timedelta(microseconds=total_length.microseconds))
    times_list= [datetime.strftime(t,'%Y-%m-%d %H:%M:%S.%f') for t in times_list]
    print(times_list)
    return render_template(
        'patient_view.html',
        prevp=prevb,
        nextp=nextb,
        Patient=patient_db.name,
        bed=bed,
        current_state=pred,
        pct=pct,
        median=median,
        predictions=json.dumps(preds_list),
        confidence=json.dumps(conf_list),
        times=json.dumps(times_list),
        last_sz=last_sz,
        total_length=total_length,
    )


@app.route('/pull-data', methods=['GET'])
def pull_data():
    """
    pull raw EEG from ieeg for plotting purposes
    """

    #get pulling parameters from the request
    bed=request.args['bed']
    start = datetime.strptime(request.args['start'],'%Y-%m-%d %H:%M:%S.%f')
    end = datetime.strptime(request.args['end'],'%Y-%m-%d %H:%M:%S.%f')
    length = (end - start).total_seconds()
    rec_start=Bed.objects.raw({'bed_id': bed}).first().patients[-1].start


    #round to the nearest data point 
    begin_pull=to_usec(round((start-rec_start).total_seconds()))

    print('start time:',start)
    print('recording start', rec_start)
    print('since start', (start-rec_start).total_seconds())
    print('end time:',datetime.strptime(request.args['end'],'%Y-%m-%d %H:%M:%S.%f'))
    print('first argument to get_data',begin_pull)
    print('time difference:',length)

    #pull from ieeg and downsample the data
    data = get_data(bed, begin_pull, to_usec(length)).transpose()
    print('downsampling')
    data = sig.resample(data,round((1000/12)*length),axis=1)

    #reformat downsampled data and create a list of associated time points
    data={CHANNELS[i]:d.tolist() for i,d in enumerate(data)}
    times = pd.date_range(start=start, end=end, periods=len(data[CHANNELS[0]])).to_pydatetime().tolist()
    times = [t.strftime('%Y-%m-%d %H:%M:%S.%f') for t in times]
    return jsonify(
        times= times,
        data=data
    )

@app.route('/add-patient',methods=['POST'])
def add():
    """
    Add a patient to a bed based on user input
    """
    try:
        bed_id='RID00'+str(int(request.form['bed'])+59)
        setup_db.add_patient(bed_id,request.form['name'])
        return render_template('success.html')
    except (setup_db.InvalidBed,ValueError):
        return render_template('failed.html')


@app.route('/deactivate-bed',methods=['POST'])
def deactivate():
    """
    Render a user specified bed inactive 
    """
    try:
        bed_id='RID00'+str(int(request.form['bed']))
        setup_db.deactivate_bed(bed_id)
        return render_template('success.html')
    except (setup_db.InvalidBed,ValueError):
        return render_template('failed.html')

@app.route('/about')
def about():
    return render_template('about.html')

@app.route('/contact')
def contact():
    return render_template('contact.html')

@app.route('/options')
def options():
    return render_template('options.html')

@app.before_first_request
def reset_db():
    """
    Reset the databse when the app is started
    """
    print('resetting db')
    setup_db.clear_db()
    for i,b in enumerate(BEDS):
        setup_db.add_bed(b,ROOMS[i])

#https://stackoverflow.com/questions/34066804/disabling-caching-in-flask
@app.after_request
def add_header(r):
    """
    Add headers to both force latest IE rendering engine or Chrome Frame,
    and also to cache the rendered page for 10 minutes.
    """
    r.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    r.headers["Pragma"] = "no-cache"
    r.headers["Expires"] = "0"
    r.headers['Cache-Control'] = 'public, max-age=0'
    return r

if __name__=='__main__':
    app.run(debug=True)
