provider "aws" {
  region = "us-east-1"
}

locals {
  name        = "clb"
  environment = "test"
}

module "vpc" {
  source      = "cypik/vpc/aws"
  version     = "1.0.2"
  name        = local.name
  environment = local.environment
  cidr_block  = "172.16.0.0/16"
}

module "subnet" {
  source             = "cypik/subnet/aws"
  version            = "1.0.3"
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
  source             = "cypik/iam-role/aws"
  version            = "1.0.1"
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
  source                      = "cypik/ec2/aws"
  version                     = "1.0.4"
  name                        = local.name
  environment                 = local.environment
  vpc_id                      = module.vpc.vpc_id
  ssh_allowed_ip              = ["0.0.0.0/0"]
  ssh_allowed_ports           = [22]
  instance_count              = 1
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "t2.nano"
  monitoring                  = false
  tenancy                     = "default"
  public_key                  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDXtnrTCvN0ThcuIARFyEyQUSP9W7JUKs92R7ccjf9D4ccOYV6DMAtezwp48DplX+4Thap3v8tiFvwbtkT1Bld7WHLxD9lKsEkuuJBuCc9vpseClV9O+bN1Gx0SKiV+1AkmvsTckhyO55ldnkeGh7L+LNsaAsC5BbmhwLqlLnSHj8RdRu8z0GNIRmqRit0tNXXfux0VP0hdXAh+IblsQzqbEWr7viG2oWcntQlSZgVf+kS8SisbnsrM0b56rOVG5MZBH98cVjuazt0NHxDodrCYdZVc6dS4pHc+WxunaILSXyAJJHOEaSwU2rwCD03HPjLZD6WcU5Jlo+vz5ofIc3Vz06MgYRkFJHB1cRgqpdF5ckTPSa7KjjiK9yDJmxwiw7ZNRrs525oqk5uJfXkHmOcIvfeRhnLBg84Eqvqdu5jjsIJRSiOCZdUpB82KZ5DaPhQH0Ev6ua9JoMQCkUCUiQlNvHqjhz+Iy4fn3lsvengN7ennSRjPdvhhDRRDRjH+gVk= satish@satish"
  subnet_ids                  = tolist(module.subnet.public_subnet_id)
  iam_instance_profile        = module.iam-role.name
  assign_eip_address          = true
  associate_public_ip_address = true
  instance_profile_enabled    = true

  ebs_optimized      = false
  ebs_volume_enabled = true
  ebs_volume_type    = "gp2"
  ebs_volume_size    = 30
}

module "clb" {
  source             = "./../../"
  name               = "app"
  load_balancer_type = "classic"
  clb_enable         = true
  internal           = true
  vpc_id             = module.vpc.vpc_id
  target_id          = module.ec2.instance_id
  subnets            = module.subnet.public_subnet_id
  with_target_group  = true
  listeners = [
    {
      lb_port            = 22000
      lb_protocol        = "TCP"
      instance_port      = 22000
      instance_protocol  = "TCP"
      ssl_certificate_id = null
    },
    {
      lb_port            = 4444
      lb_protocol        = "TCP"
      instance_port      = 4444
      instance_protocol  = "TCP"
      ssl_certificate_id = null
    }
  ]
  health_check_target              = "TCP:4444"
  health_check_timeout             = 10
  health_check_interval            = 30
  health_check_unhealthy_threshold = 5
  health_check_healthy_threshold   = 5
}
