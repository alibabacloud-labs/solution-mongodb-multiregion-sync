import pymongo
import time

cl = pymongo.MongoClient(
    'mongodb://root:xxxx@<replace with the source MongoDB VPC URL>')

db = cl.test_mongodb

id = 0
while id < 1000000:
    db.col.insert_one({'id': id, 'name': 'aa', 'age': 25})
    id += 1
    print('Insert document with id: ' + str(id))
    time.sleep(5)
