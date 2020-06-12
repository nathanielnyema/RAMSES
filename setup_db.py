'''
This file contains functions for managing the database.
'''
from datetime import datetime as dt

from patient import Bed, Patient, SeizurePrediction


class InvalidBed(Exception):
    "This bed does not exist"
    pass

def add_bed(bed_id,room,active=False, name=None, start_time=None):
    if Bed.objects.raw({'bed_id': bed_id}).count() > 0:
        return
    bed=Bed(bed_id=bed_id, room=room, active=active)
    bed.save()
    if active:
        add_patient(bed_id,name,start_time)

def add_patient(bed_id, name, start_time=None):
    if Bed.objects.raw({'bed_id': bed_id}).count()==0:
        raise InvalidBed('Tried to add to a nonexistent bed')
    now = dt.now()
    if start_time is None or start_time > now:
        start_time = now
    init_pred = SeizurePrediction(prediction=4, time=now)
    patient = Patient(name=name, start=start_time, lastread=now)
    patient.predictions.append(init_pred)
    bed=Bed.objects.raw({'bed_id': bed_id}).first()
    if not bed.active:
        bed.active=True
    bed.patients.append(patient)
    bed.save()
    print("bed_id: {}, lastread: {}, start: {}".format(bed_id, now, now))

def deactivate_bed(bed_id):
    if Bed.objects.raw({'bed_id': bed_id}).count()==0:
        raise InvalidBed('Tried to deactivate a nonexistent bed')
    bed=Bed.objects.raw({'bed_id': bed_id}).first()
    bed.active=False
    bed.save()

def check_available():
    active=[]
    if Bed.objects.count()>0:
        for bed in Bed.objects.all():
            if bed.active:
                active.append(bed.bed_id)
    return active


def clear_db():
    if Bed.objects.count()>0:
        for bed in Bed.objects.all():
            bed.delete()
