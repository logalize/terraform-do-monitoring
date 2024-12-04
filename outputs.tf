# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------
output "uptime_check_id" {
  value       = element(concat(digitalocean_uptime_check.main[*].id[*], [""]), 0) ##digitalocean_uptime_check.main[*].id[*]
  description = " The id of the check."
}
output "uptime_alert_id" {
  value = join(",", [for alert in digitalocean_uptime_alert.main : alert.id])
}

output "uuid" {
  value       = digitalocean_monitor_alert.cpu_alert
  description = "The uuid of the alert."
}
