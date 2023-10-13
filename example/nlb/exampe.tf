provider "aws" {
  region = "us-east-1"
}

locals {
  name        = "nlb"
  environment = "test"
}

module "vpc" {
  source      = "git::git@github.com:opz0/terraform-aws-vpc.git?ref=master"
  name        = local.name
  environment = local.environment
  cidr_block  = "172.16.0.0/16"
}

module "public_subnets" {
  source             = "git::git@github.com:opz0/terraform-aws-subnet.git"
  name               = local.name
  environment        = local.environment
  availability_zones = ["us-east-1b", "us-east-1c"]
  type               = "public"
  vpc_id             = module.vpc.vpc_id
  cidr_block         = module.vpc.vpc_cidr_block
  igw_id             = module.vpc.igw_id
  ipv6_cidr_block    = module.vpc.ipv6_cidr_block
}


module "iam-role" {
  source             = "git::git@github.com:opz0/terraform-aws-iam-role.git"
  name               = local.name
  environment        = local.environment
  assume_role_policy = data.aws_iam_policy_document.default.json

  policy_enabled = true
  policy         = data.aws_iam_policy_document.iam-policy.json
}

data "aws_iam_policy_document" "default" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "iam-policy" {
  statement {
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
    "ssmmessages:OpenDataChannel"]
    effect    = "Allow"
    resources = ["*"]
  }
}

module "ec2" {
  source                      = "git::git@github.com:opz0/terraform-aws-ec2.git?ref=master"
  name                        = local.name
  environment                 = local.environment
  instance_count              = 1
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "t2.nano"
  monitoring                  = false
  vpc_id                      = module.vpc.vpc_id
  ssh_allowed_ip              = ["0.0.0.0/0"]
  ssh_allowed_ports           = [22]
  tenancy                     = "default"
  public_key                  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzJVDK2umFR7a47ebFhIapr00fh6KZVpMFxOp9CRn7AQQdwN7mjm+NWT7LsyKo0i5bLeHpo5Iqu4QoN1Ld1abG4wq7kMhJVC8E6+dPej5SlqyXaXIZOOfdu9zOaDAH2urEodKa+m8H4qf7vYZqhhWdCrS9gW8IAvN08jvw+BKweUIvgAJvx/t6JLyhEV1gqbcRq2Fz3S3OVLTmLclWn+bwugjYSOcHGc2qVrVd4Tar8RjvQl32aNkscutdbVgaE1mnFMQz0kTZ2a78lfI7od10UMnCj1Fjf5wdYzT60CXJ6wLFto/nko5TpZwIzjsMXen1Tp0Futr4efz8fPjdtM568sV0ZL4ltJPypComy3/PiyGRz7BdJ1VCco1g/pH+vteQ4CjOTfmL+8Z7/DLJ04soUVrSqTHl/l/FcG4cO3x2rNJxNTQGqLCvXBXEDfQKpQR/zpS0wotoF1FN3eKkgifzcM1T1zLwKyaOnukbnzTZTAZjA6mtjK/BTcoU0ElzHYU= satish@satish"
  subnet_ids                  = tolist(module.public_subnets.public_subnet_id)
  iam_instance_profile        = module.iam-role.name
  assign_eip_address          = true
  associate_public_ip_address = true
  instance_profile_enabled    = true
  ebs_optimized               = false
  ebs_volume_enabled          = true
  ebs_volume_type             = "gp2"
  ebs_volume_size             = 30
}




module "nlb" {
  source = "./../../"

  name                       = "app"
  enable                     = true
  internal                   = false
  load_balancer_type         = "network"
  instance_count             = module.ec2.instance_count
  subnets                    = module.public_subnets.public_subnet_id
  target_id                  = module.ec2.instance_id
  vpc_id                     = module.vpc.vpc_id
  enable_deletion_protection = false
  with_target_group          = true
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    },
    {
      port               = 81
      protocol           = "TCP"
      target_group_index = 0
    },
  ]
  target_groups = [
    {
      backend_protocol = "TCP"
      backend_port     = 80
      target_type      = "instance"
    },
    {
      backend_protocol = "TCP"
      backend_port     = 81
      target_type      = "instance"
    },
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "TLS"
      target_group_index = 1
      certificate_arn    = ""
    },
    {
      port               = 84
      protocol           = "TLS"
      target_group_index = 1
      certificate_arn    = ""
    },
  ]
}
