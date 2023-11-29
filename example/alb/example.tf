provider "aws" {
  region = "us-east-1"
}

locals {
  name        = "albb"
  environment = "test"
}

module "vpc" {
  source      = "git::https://github.com/cypik/terraform-aws-vpc.git?ref=v1.0.0"
  name        = local.name
  environment = local.environment
  cidr_block  = "172.16.0.0/16"
}


module "subnet" {
  source = "git::https://github.com/cypik/terraform-aws-subnet.git?ref=v1.0.0"

  name               = local.name
  environment        = local.environment
  availability_zones = ["us-east-1b", "us-east-1c"]
  type               = "public"
  vpc_id             = module.vpc.id
  cidr_block         = module.vpc.vpc_cidr_block
  igw_id             = module.vpc.igw_id
  ipv6_cidr_block    = module.vpc.ipv6_cidr_block
}

module "iam-role" {
  source             = "git::https://github.com/cypik/terraform-aws-iam-role.git?ref=v1.0.0"
  name               = local.name
  environment        = local.environment
  assume_role_policy = data.aws_iam_policy_document.default.json
  policy_enabled     = true
  policy             = data.aws_iam_policy_document.iam-policy.json
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
  source                      = "git::https://github.com/cypik/terraform-aws-ec2.git?ref=v1.0.0"
  name                        = "alb"
  environment                 = local.environment
  vpc_id                      = module.vpc.id
  ssh_allowed_ip              = ["0.0.0.0/0"]
  ssh_allowed_ports           = [22]
  public_key                  = "AZjA6mtjK/BTXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXcoU0ElzHYU= satish@satish"
  instance_count              = 1
  ami                         = "ami-0fc5d935ebf8bc3bc"
  instance_type               = "t2.nano"
  monitoring                  = true
  tenancy                     = "default"
  subnet_ids                  = tolist(module.subnet.public_subnet_id)
  iam_instance_profile        = module.iam-role.name
  assign_eip_address          = false
  associate_public_ip_address = true
  instance_profile_enabled    = true
  ebs_optimized               = false
  ebs_volume_enabled          = true
  ebs_volume_type             = "gp2"
  ebs_volume_size             = 30
}



module "alb" {
  source = "./../../"

  name                       = local.name
  enable                     = true
  internal                   = true
  load_balancer_type         = "application"
  instance_count             = 1
  subnets                    = module.subnet.public_subnet_id
  target_id                  = module.ec2.instance_id
  vpc_id                     = module.vpc.id
  allowed_ip                 = [module.vpc.vpc_cidr_block]
  allowed_ports              = [3306]
  enable_deletion_protection = false
  with_target_group          = true
  https_enabled              = false
  http_enabled               = true
  https_port                 = 443
  listener_type              = "forward"
  target_group_port          = 80

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    },
  ]
  https_listeners = [
    {
      port               = 443
      protocol           = "TLS"
      target_group_index = 0
      certificate_arn    = ""
    },
    {
      port               = 84
      protocol           = "TLS"
      target_group_index = 0
      certificate_arn    = ""
    },
  ]

  target_groups = [
    {
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 300
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 10
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]

}
