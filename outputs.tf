output "name" {
  value       = join("", aws_lb.main[*].name)
  description = "The ARN suffix of the ALB."
}

output "arn" {
  value       = join("", concat(aws_lb.main[*].arn))
  description = "The ARN of the ALB."
}

output "clb_arn" {
  value       = join("", concat(aws_elb.main[*].arn))
  description = "The ARN of the CLB."
}

output "arn_suffix" {
  value       = join("", aws_lb.main[*].arn_suffix)
  description = "The ARN suffix of the ALB."
}

output "dns_name" {
  value       = join("", aws_lb.main[*].dns_name)
  description = "DNS name of ALB."
}

output "clb_name" {
  value       = join("", aws_elb.main[*].dns_name)
  description = "DNS name of CLB."
}

output "zone_id" {
  value       = join("", aws_lb.main[*].zone_id)
  description = "The ID of the zone which ALB is provisioned."
}

output "clb_zone_id" {
  value       = join("", aws_elb.main[*].zone_id)
  description = "The ID of the zone which ALB is provisioned."
}

output "main_target_group_arn" {
  value       = join("", aws_lb_target_group.main[*].arn)
  description = "The main target group ARN."
}

output "http_listener_arn" {
  value       = join("", aws_lb_listener.http[*].arn)
  description = "The ARN of the HTTP listener."
}

output "https_listener_arn" {
  value       = join("", aws_lb_listener.https[*].arn)
  description = "The ARN of the HTTPS listener."
}

output "listener_arns" {
  value       = compact(concat(aws_lb_listener.http[*].arn, aws_lb_listener.https[*].arn))
  description = "A list of all the listener ARNs."
}

output "tags" {
  value       = module.labels.tags
  description = "A mapping of tags to assign to the resource."
}

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = try(aws_security_group.default[0].arn, null)
}

output "security_group_id" {
  description = "ID of the security group"
  value       = try(aws_security_group.default[0].id, null)
}

#output "lb_arn" {
#  value       = aws_lb.main[0].arn
#  description = "The ARN of the load balancer"
#}
#
#output "lb_dns_name" {
#  value       = aws_lb.main[0].dns_name
#  description = "The DNS name of the load balancer"
#}

#output "lb_id" {
#  value       = aws_lb.main[0].id
#  description = "The ID of the load balancer"
#}

#output "lb_zone_id" {
#  value       = aws_lb.main.zone_id
#  description = "The canonical hosted zone ID of the load balancer"
#}

output "target_group_arns" {
  value       = aws_lb_target_group.main[*].arn
  description = "ARNs of the created target groups."
}

output "target_group_names" {
  value       = aws_lb_target_group.main[*].name
  description = "Names of the created target groups."
}

output "target_group_ids" {
  value       = aws_lb_target_group.main[*].id
  description = "IDs of the created target groups."
}

output "target_group_tags" {
  value       = aws_lb_target_group.main[*].tags_all
  description = "Tags associated with the target groups."
}

#output "elb_id" {
#  description = "The name of the ELB"
#  value       = aws_elb.main[0].id
#  condition   = length(aws_elb.main) > 0
#}

#output "elb_arn" {
#  description = "The ARN of the ELB"
#  value       = aws_elb.main[0].arn
#  condition   = length(aws_elb.main) > 0
#}

#output "elb_dns_name" {
#  description = "The DNS name of the ELB"
#  value       = aws_elb.main[0].dns_name
#  condition   = length(aws_elb.main) > 0
#}

#output "elb_zone_id" {
#  description = "The canonical hosted zone ID of the ELB"
#  value       = aws_elb.main[0].zone_id
#  condition   = length(aws_elb.main) > 0
#}

#output "elb_source_security_group" {
#  description = "The name of the security group for back-end instances"
#  value       = aws_elb.main[0].source_security_group
#  condition   = length(aws_elb.main) > 0
#}

#output "elb_tags_all" {
#  description = "All tags assigned to the ELB"
#  value       = aws_elb.main[0].tags_all
#  condition   = length(aws_elb.main) > 0
#}
output "http_tcp_listener_rules" {
  description = "List of listener rules created"
  value       = aws_lb_listener_rule.http_tcp_listener_rule[*].id
}
