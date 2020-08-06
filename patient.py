from pymodm import EmbeddedMongoModel, MongoModel, fields, connect

connect('mongodb://localhost:27017/test')

class SeizurePrediction(EmbeddedMongoModel):
    prediction = fields.IntegerField()
    time = fields.DateTimeField()
    confidence = fields.FloatField()

class Patient(EmbeddedMongoModel):
    pid=fields.CharField()
    name=fields.CharField()
    predictions = fields.EmbeddedDocumentListField(SeizurePrediction, default=[])
    lastread=fields.DateTimeField()
    start=fields.DateTimeField()

class Bed(MongoModel):
    bed_id=fields.CharField()
    patients=fields.EmbeddedDocumentListField(Patient,default=[])
    active=fields.BooleanField()
    room=fields.IntegerField()