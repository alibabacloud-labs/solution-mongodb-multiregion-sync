import pymongo
import time

cl = pymongo.MongoClient(
    'mongodb://root:xxxx@<replace with the target MongoDB VPC URL>')

db = cl.test_mongodb

# Clean all the data before testing
db.col.remove()

loop_count = 1
while loop_count < 1000000:
    print('Document count: ' + str(db.col.find().count()))
    time.sleep(5)
