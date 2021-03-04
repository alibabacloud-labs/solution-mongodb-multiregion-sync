variable "profile" {
  default = "default"
}

# Provider for #1 region on Alibaba Cloud, here we use Singapore region
# For all the region code information, please refer to https://www.alibabacloud.com/help/doc-detail/40654.htm
provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  alias  = "region1"
  region = var.region1
}

variable "region1" {
  default = "ap-southeast-1"
}

# Provider for #1 region on Alibaba Cloud, here we use Jarkata region
# For all the region code information, please refer to https://www.alibabacloud.com/help/doc-detail/40654.htm
provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  alias  = "region2"
  region = var.region2
}

variable "region2" {
  default = "ap-southeast-5"
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
  cidr_block = "192.168.0.0/16"
}

# Resource: VSW at region #2
resource "alicloud_vswitch" "vsw_region2" {
  provider          = alicloud.region2
  vpc_id            = alicloud_vpc.vpc_region2.id
  cidr_block        = "192.168.0.0/24"
  availability_zone = data.alicloud_zones.region2.zones[0].id
  name              = "vsw-test"
}

# Security group at region #1
resource "alicloud_security_group" "sg_region1" {
  provider    = alicloud.region1
  name        = "sg_solution_multiregion_mongodb_sync"
  description = "sg_solution_multiregion_mongodb_sync"
  vpc_id      = alicloud_vpc.vpc_region1.id
}

# Security group at region #2
resource "alicloud_security_group" "sg_region2" {
  provider    = alicloud.region2
  name        = "sg_solution_multiregion_mongodb_sync"
  description = "sg_solution_multiregion_mongodb_sync"
  vpc_id      = alicloud_vpc.vpc_region2.id
}

# CEN to connect VPC at region #1 and VPC at region #2 --------------------------------------
# - Bandwidth package is needed for production, and the charge_type needs to be PrePaid 
#   when purchasing bandwidth package. For bandwidth package resource in terraform, please
#   refer to https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/cen_bandwidth_package
# - For testing, no need to purchase bandwidth package, but the bandwidth is limited to 1Kbps.
resource "alicloud_cen_instance" "this" {
  cen_instance_name = "test_cen"
  description       = "CEN example to connect 2 VPC"
}

resource "alicloud_cen_instance_attachment" "vpc_attach_1" {
  instance_id              = alicloud_cen_instance.this.id
  child_instance_id        = alicloud_vpc.vpc_region1.id
  child_instance_type      = "VPC"
  child_instance_region_id = var.region1
}

resource "alicloud_cen_instance_attachment" "vpc_attach_2" {
  instance_id              = alicloud_cen_instance.this.id
  child_instance_id        = alicloud_vpc.vpc_region2.id
  child_instance_type      = "VPC"
  child_instance_region_id = var.region2
}

# ECS ----------------------------------------------------------------------------
# ECS at region #1
resource "alicloud_instance" "ecs_region1" {
  provider        = alicloud.region1
  security_groups = alicloud_security_group.sg_region1.*.id

  # series III
  instance_type           = "ecs.t5-lc1m1.small"
  system_disk_category    = "cloud_efficiency"
  system_disk_name        = "test_foo_system_disk_name"
  system_disk_description = "test_foo_system_disk_description"
  image_id                = "ubuntu_18_04_64_20G_alibase_20190624.vhd"
  instance_name           = "test_foo"
  vswitch_id              = alicloud_vswitch.vsw_region1.id
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
  instance_type           = "ecs.t5-lc1m1.small"
  system_disk_category    = "cloud_efficiency"
  system_disk_name        = "test_foo_system_disk_name"
  system_disk_description = "test_foo_system_disk_description"
  image_id                = "ubuntu_18_04_64_20G_alibase_20190624.vhd"
  instance_name           = "test_foo"
  vswitch_id              = alicloud_vswitch.vsw_region2.id
  data_disks {
    name        = "disk2"
    size        = 20
    category    = "cloud_efficiency"
    description = "disk2"
    # encrypted   = true
    # kms_key_id  = alicloud_kms_key.key.id
  }
}

# MongoDB ----------------------------------------------------------------------------
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
