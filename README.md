### Project URL
[https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync)


### Architecture Overview

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/archi-nocen.png)

### Deployment
#### Terraform

Use this terraform script ([https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/blob/main/deployment/terraform/main.tf](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/blob/main/deployment/terraform/non-cen/main.tf)) to provision the resource including VPC, ECS, MongoDB on 2 regions. Later public IP endpoint will be used for MongoShake on ECS to connect the MongoDB on another region.


If you do not specify the provider parameters in the environment, please set your Alibaba Cloud access key, secret key here.
```bash
provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  alias  = "region1"
  region = var.region1
}

provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  alias  = "region2"
  region = var.region2
}
```


### Run Demo
#### Step 1: set source and target MongoDB access password
This new password will be used by MongoShake, reader and writer sample program running on ECS.

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step1.png)

#### Step 2: set the security group for source and target MongoDB
Set the MongoDB in the same security group with the ECS in the same region, which allows ECS accessing the MongoDB for read and write.

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step2_1.png)

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step2_2.png)


#### Step 3: apply target MongoDB public IP endpoint

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step3.png)

Copy the connection URL for later MongoShake setting, such as

```bash
mongodb://root:****@dds-d9jd0011be9071441896-pub.mongodb.ap-southeast-5.rds.aliyuncs.com:3717,dds-d9jd0011be9071442287-pub.mongodb.ap-southeast-5.rds.aliyuncs.com:3717/admin?replicaSet=mgset-1100731245
```

#### Step 4: add ECS (in region 1 for MongoShake) public IP to whitelist of target MongoDB

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step4_1.png)

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step4_2.png)


#### Step 5: install and start MongoShake on ECS (in the region where source MongoDB locates)

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step5_1.png)

Reset the ECS password here and restart the instance to apply the change.


![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step5_2.png)

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step5_3.png)

Click “Connect” button to log on ECS via VNC.

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step5_4.png)

You need to modify VNC password for the 1st time for logging on the ECS.

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step5_5.png)

Click "Enter Copy Commands" to execute the following commands.

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step5_6.png)

```bash
wget https://github.com/alibaba/MongoShake/releases/download/release-v2.4.19-20210115/mongo-shake-v2.4.19.tar.gz
tar zxvf mongo-shake-v2.4.19.tar.gz && mv mongo-shake-v2.4.19 /root/mongoshake && cd /root/mongoshake 
```
Run the `vi collector.conf` command to modify the collector.conf configuration file of MongoShake. The following table describes the parameters that you must configure to synchronize data between ApsaraDB for MongoDB instances.

| Parameter | Description | Example |
| :--- | :--- | :--- |
| mongo_urls | The connection string URI of the source ApsaraDB for MongoDB instance.
**Note**
- We recommend that you use a VPC endpoint to minimize network latency.
- For more information about the format of a connection string URI, see [Overview of replica set instance connections](https://www.alibabacloud.com/help/doc-detail/44623.htm#concept-44623-zh).
 | `mongo_urls = mongodb://root:Ftxxxxxx@dds-bpxxxxxxxx.mongodb.rds.aliyuncs.com:3717,dds-bpxxxxxxxx.mongodb.rds.aliyuncs.com:3717`
**Note** The password cannot contain at signs (@). Otherwise, the connection may fail. |
| tunnel.address | The connection string URI of the destination ApsaraDB for MongoDB instance.
**Note**
- We recommend that you use a VPC endpoint to minimize network latency.
- For more information about the format of a connection string URI, see [Overview of replica set instance connections](https://www.alibabacloud.com/help/doc-detail/44623.htm#concept-44623-zh).
 | `tunnel.address = mongodb://root:Ftxxxxxx@dds-bpxxxxxxxx.mongodb.rds.aliyuncs.com:3717,dds-bpxxxxxxxx.mongodb.rds.aliyuncs.com:3717`
**Note** The password cannot contain at signs (@). Otherwise, the connection may fail. |
| sync_mode | The data synchronization method. Valid values:
- all: performs both full data synchronization and incremental data synchronization.
- full: performs only full data synchronization.
- incr: performs only incremental data synchronization.


**Note** The default value is incr. | `sync_mode = all` |



Note For more information about all parameters in the collector.conf file, see the [https://www.alibabacloud.com/help/doc-detail/122621.htm?spm=a2c63.p38356.b99.149.83c95d51SHnDEP#section-zkn-lqg-z79](https://www.alibabacloud.com/help/doc-detail/122621.htm?spm=a2c63.p38356.b99.149.83c95d51SHnDEP#section-zkn-lqg-z79) of this topic.


Then run the following command at MongoShake ECS to start MongoShake service.
```bash
sh start.sh collector.conf
```
When the incremental data synchronization starts, you can open a command line window to monitor MongoShake.
```bash
cd /root/mongoshake && ./mongoshake-stat --port=9100
```
#### Step 6: run read and write application on ECS
Now you can run the sample python program to check with the MongoDB one-way synchronization behavior.

| Source code | Description | Source code file URL |
| --- | --- | --- |
| mongodb_insert_source.py | MongoDB writer run on ECS in region 1. It will continuously insert document data into source MongoDB. | [https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/source/mongodb_insert_source.py](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/source/mongodb_insert_source.py) |
| mongodb_read_source.py | MongoDB reader run on ECS in region 1. It will continuously read document data from source MongoDB. | [https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/source/mongodb_read_source.py](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/source/mongodb_read_source.py) |
| mongodb_read_target.py | MongoDB reader run on ECS in region 2. It will continuously read document data from target MongoDB. | [https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/source/mongodb_read_target.py](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/source/mongodb_read_target.py) |



First, log on both ECS in region 1 and region 2, run the following command to install pymongo python module.
```bash
pip install pymongo
```


On the ECS in region 2, log on via VNC, and use vi to create a source code file and copy the code described above:

- mongodb_read_target.py

Within the source code, modify the MongoDB URL to replace with the target MongoDB VPC URL accordingly:
```python
cl = pymongo.MongoClient(
    'mongodb://root:xxxx@<replace with the target MongoDB VPC URL>')
```
Then run the script:
```python
python mongodb_read_target.py
```


On the ECS in region 1, log on via VNC, and use vi to create source code file and copy the code described above:

- mongodb_insert_source.py

Within the source code, modify the MongoDB URL accordingly:
```python
cl = pymongo.MongoClient(
    'mongodb://root:xxxx@<replace with the source MongoDB VPC URL>')
```
Then run the script:
```python
python mongodb_insert_source.py
```


Then on ECS in region 1, you will see the MongoDB writer writes the document data into the source MongoDB.

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step6_1.png)

On ECS in region 2, you will see the MongoDB reader reads the newly synchronized data on the target MongoDB.

![image.png](https://github.com/alibabacloud-labs/solution-mongodb-multiregion-sync/raw/main/images/step6_2.png)
