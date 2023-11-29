# Terraform-aws-lb

# AWS Infrastructure Provisioning with Terraform

## Table of Contents
- [Introduction](#introduction)
- [Usage](#usage)
- [Module Inputs](#module-inputs)
- [Module Outputs](#module-outputs)
- [License](#license)

## Introduction
This module is basically combination of Terraform open source and includes automatation tests and examples. It also helps to create and improve your infrastructure with minimalistic code instead of maintaining the whole infrastructure code yourself.
## Usage
To use this module, you can include it in your Terraform configuration. Here's an example of how to use it:

## Example: alb

```hcl
module "alb" {
  source                     = "git::https://github.com/cypik/terraform-aws-lb.git?ref=v1.0.0"
  name                       = local.name
  enable                     = true
  internal                   = true
  load_balancer_type         = "application"
  instance_count             = 1
  subnets                    = module.subnet.public_subnet_id
  target_id                  = module.ec2.instance_id
  vpc_id                     = module.vpc.vpc_id
  allowed_ip                 = [module.vpc.vpc_cidr_block]
  allowed_ports              = [3306]
  enable_deletion_protection = false
  with_target_group          = true
  https_enabled              = true
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
```

## example: clb

```hcl
module "clb" {
  source             = "git::https://github.com/cypik/terraform-aws-lb.git?ref=v1.0.0"
  name               = "app"
  load_balancer_type = "classic"
  clb_enable         = true
  internal           = true
  vpc_id             = module.vpc.vpc_id
  target_id          = module.ec2.instance_id
  subnets            = module.public_subnets.public_subnet_id
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
```
## example: nlb

```hcl
module "nlb" {
  source                     = "git::https://github.com/cypik/terraform-aws-lb.git?ref=v1.0.0"
  name                       = "app"
  enable                     = true
  internal                   = false
  load_balancer_type         = "network"
  instance_count             = 1
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
```

## Module Inputs
- `name`:  The name of the LB. This name must be unique within your AWS account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen.
- `environment`: Name of the cluster.
- `load_balancer_type`: The type of load balancer to create.
- `subnets`:  A list of subnet IDs to attach to the LB.
- `internal`:  If true, the LB will be internal.
For security group settings, you can configure the ingress and egress rules using variables like:

## Module Outputs
- `id` : The ARN of the load balancer (matches arn).
- `arn`: The ARN of the load balancer
- `dns_name`: The DNS name of the load balancer.
- `zone_id`: The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record).
- Other relevant security group outputs (modify as needed).

## Example
For detailed examples on how to use this module, please refer to the '[example](https://github.com/cypik/terraform-aws-lb/tree/master/example)' directory within this repository.

## Author
Your Name Replace '[License Name]' and '[Your Name]' with the appropriate license and your information. Feel free to expand this README with additional details or usage instructions as needed for your specific use case.

## License
This project is licensed under the MIT License - see the [LICENSE](https://github.com/cypik/terraform-aws-lb/blob/master/LICENSE) file for details.
