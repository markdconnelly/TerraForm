resource "azurerm_monitor_diagnostic_setting" "sentinel-diag" {
  name               = "sentinel-diag"
  target_resource_id = azurerm_key_vault.example.id
  log_analytics_workspace_id = law-sentinel-cus-01.id
  log_analytics_destination_type = AzureDiagnostics

  enabled_log {
    category = "AllEvents"
  }
  metric {
    category = "AllMetrics"
    }
}

resource "azurerm_monitor_diagnostic_setting" "itops-diag" {
  name               = "itops-diag"
  target_resource_id = azurerm_key_vault.example.id
  log_analytics_workspace_id = law-itops-cus-01.id
  log_analytics_destination_type = AzureDiagnostics

  enabled_log {
    category = "AllEvents"
  }
  metric {
    category = "AllMetrics"
    }
}

resource "azurerm_monitor_diagnostic_setting" "devops-diag" {
  name               = "devops-diag"
  target_resource_id = azurerm_key_vault.example.id
  log_analytics_workspace_id = law-devops-cus-01.id
  log_analytics_destination_type = AzureDiagnostics

  enabled_log {
    category = "AllEvents"
  }
  metric {
    category = "AllMetrics"
    }
}