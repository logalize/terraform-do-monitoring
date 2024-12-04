##Description : This Script is used to create VPC.
#Module      : LABEL
#Description : Terraform label module variables.
module "labels" {
  source      = "terraform-do-modules/labels/digitalocean"
  version     = "0.0.1"
  name        = var.name
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
}

#################################################################################################
##Description : Uptime Checks provide the ability to monitor your endpoints from around the world
#################################################################################################
resource "digitalocean_uptime_check" "main" {
  count   = var.enable ? length(var.target_url) : 0
  name    = format("%s-uptime-check-%s", module.labels.id, count.index)
  target  = element(var.target_url, count.index)
  type    = element(var.type, count.index)
  regions = var.regions
  enabled = var.enabled
}

locals {
  alert_combinations = flatten([
    for url_idx, url in var.target_url : [
      for alert_idx, alert in var.alert_type : {
        key         = "${url_idx}-${alert_idx}"
        url_idx     = url_idx
        alert_idx   = alert_idx
        check_id    = digitalocean_uptime_check.main[url_idx].id
        alert_type  = alert
      }
    ]
  ])
}

resource "digitalocean_uptime_alert" "main" {
  for_each = { for combination in local.alert_combinations : combination.key => combination }

  name       = format("%s-alert-%s", each.value.check_id, each.value.alert_type)
  check_id   = each.value.check_id
  type       = each.value.alert_type
  threshold  = var.threshold
  comparison = var.comparison
  period     = var.period

  dynamic "notifications" {
    for_each = try(jsondecode(var.notifications), var.notifications)
    content {
      email = lookup(notifications.value, "email", null)

      dynamic "slack" {
        for_each = lookup(notifications.value, "slack", [])
        content {
          channel = lookup(slack.value, "channel", null)
          url     = lookup(slack.value, "url", null)
        }
      }
    }
  }
}

###########################################################
##Description :Monitor alerts can be configured to alert
###########################################################
resource "digitalocean_monitor_alert" "cpu_alert" {
  for_each = var.resource_alerts
  dynamic "alerts" {
    for_each = each.value.alerts
    content {
      email = lookup(alerts.value, "email", null)
      dynamic "slack" {
        for_each = lookup(alerts.value, "slack", null)
        content {
          channel = lookup(slack.value, "channel", null)
          url     = lookup(slack.value, "url", null)
        }
      }
    }
  }
  description = lookup(each.value, "description", null)
  compare     = lookup(each.value, "compare", null)
  type        = lookup(each.value, "type", null)
  enabled     = lookup(each.value, "enabled", true)
  entities    = lookup(each.value, "entities", null)
  value       = lookup(each.value, "value", 95)
  window      = lookup(each.value, "window", "5m")
  tags        = lookup(each.value, "tags", null)
}
