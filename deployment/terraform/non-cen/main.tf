# Provider for #1 region on Alibaba Cloud, here we use Singapore region
# For all the region code information, please refer to https://www.alibabacloud.com/help/doc-detail/40654.htm
provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  alias  = "region1"
  region = "ap-southeast-1"
}

# Provider for #1 region on Alibaba Cloud, here we use Jarkata region
# For all the region code information, please refer to https://www.alibabacloud.com/help/doc-detail/40654.htm
provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  alias  = "region2"
  region = "ap-southeast-5"
}

# Data source for Alibaba Cloud zones
# here we filter zone by MongoDB
data "alicloud_zones" "region1" {
  provider                    = alicloud.region1
  available_resource_creation = "MongoDB"
}

# Data source for Alibaba Cloud zones
# here we filter zone by MongoDB
data "alicloud_zones" "region2" {
  provider                    = alicloud.region2
  available_resource_creation = "MongoDB"
}

# Resource: VPC at region #1
resource "alicloud_vpc" "vpc_region1" {
  provider   = alicloud.region1
  name       = "vpc-test"
  cidr_block = "172.16.0.0/16"
}

# Resource: VSW at region #1
resource "alicloud_vswitch" "vsw_region1" {
  provider          = alicloud.region1
  vpc_id            = alicloud_vpc.vpc_region1.id
  cidr_block        = "172.16.0.0/24"
  availability_zone = data.alicloud_zones.region1.zones[0].id
  name              = "vsw-test"
}

# Resource: VPC at region #2
resource "alicloud_vpc" "vpc_region2" {
  provider   = alicloud.region2
  name       = "vpc-test"
  cidr_block = "172.16.0.0/16"
}

# Resource: VSW at region #2
resource "alicloud_vswitch" "vsw_region2" {
  provider          = alicloud.region2
  vpc_id            = alicloud_vpc.vpc_region2.id
  cidr_block        = "172.16.0.0/24"
  availability_zone = data.alicloud_zones.region2.zones[0].id
  name              = "vsw-test"
}

# Security group at region #1
resource "alicloud_security_group" "sg_region1" {
  provider    = alicloud.region1
  name        = "sg_1"
  description = "sg_solution_multiregion_mongodb_sync"
  vpc_id      = alicloud_vpc.vpc_region1.id
}

# Security group at region #2
resource "alicloud_security_group" "sg_region2" {
  provider    = alicloud.region2
  name        = "sg_2"
  description = "sg_solution_multiregion_mongodb_sync"
  vpc_id      = alicloud_vpc.vpc_region2.id
}

# ECS at region #1
resource "alicloud_instance" "ecs_region1" {
  provider        = alicloud.region1
  security_groups = alicloud_security_group.sg_region1.*.id

  # series III
  instance_type              = "ecs.t5-lc1m1.small"
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "test_foo_system_disk_name"
  system_disk_description    = "test_foo_system_disk_description"
  image_id                   = "ubuntu_18_04_64_20G_alibase_20190624.vhd"
  instance_name              = "test_foo"
  vswitch_id                 = alicloud_vswitch.vsw_region1.id
  internet_max_bandwidth_out = 10
  data_disks {
    name        = "disk2"
    size        = 20
    category    = "cloud_efficiency"
    description = "disk2"
    # encrypted   = true
    # kms_key_id  = alicloud_kms_key.key.id
  }
}

# ECS at region #2
resource "alicloud_instance" "ecs_region2" {
  provider        = alicloud.region2
  security_groups = alicloud_security_group.sg_region2.*.id

  # series III
  instance_type              = "ecs.t5-lc1m1.small"
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "test_foo_system_disk_name"
  system_disk_description    = "test_foo_system_disk_description"
  image_id                   = "ubuntu_18_04_64_20G_alibase_20190624.vhd"
  instance_name              = "test_foo"
  vswitch_id                 = alicloud_vswitch.vsw_region2.id
  internet_max_bandwidth_out = 10
  data_disks {
    name        = "disk2"
    size        = 20
    category    = "cloud_efficiency"
    description = "disk2"
    # encrypted   = true
    # kms_key_id  = alicloud_kms_key.key.id
  }
}

# Resource: MongoDB (Replica Set) at region #1
resource "alicloud_mongodb_instance" "mongodb_region1" {
  provider            = alicloud.region1
  engine_version      = "4.2"
  db_instance_class   = "dds.mongo.mid"
  db_instance_storage = 10
  vswitch_id          = alicloud_vswitch.vsw_region1.id
  security_ip_list    = ["127.0.0.1"]
}

# Resource: MongoDB (Replica Set) at region #2
resource "alicloud_mongodb_instance" "mongodb_region2" {
  provider            = alicloud.region2
  engine_version      = "4.2"
  db_instance_class   = "dds.mongo.mid"
  db_instance_storage = 10
  vswitch_id          = alicloud_vswitch.vsw_region2.id
  security_ip_list    = ["127.0.0.1"]
}
