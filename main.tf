terraform {
    required_version = ">= 0.12"
}

variable "service_bus_topics" {
  type = set(string)
}

variable "core_resource_group_name" {
}

variable "environment" {
    description = "The environment that this deployment will apply to. Such as DEV, QA, PROD."
}

variable "resource_group_name" {
  description = "The name of the resource group for the microservice"
}

provider "azurerm" {
    version         = "1.36.0"
}

resource "azurerm_resource_group" "rg" {
    name     = "${var.environment}.${var.resource_group_name}"
    location = "northeurope"
    
    tags = {
        environment = var.environment
    }
}

resource "azurerm_storage_account" "sa" {
    name                     = "${var.environment}${replace(var.resource_group_name, ".", "")}sa"
    resource_group_name      = azurerm_resource_group.rg.name
    location                 = azurerm_resource_group.rg.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    
    tags = {
        environment = var.environment
    }
}

resource "azurerm_app_service_plan" "asp" {
    name                = "${var.environment}-${replace(var.resource_group_name, ".", "-")}sa"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    kind                = "FunctionApp"

    sku {
        tier = "Dynamic"
        size = "Y1"
    }
    
    tags = {
        environment = var.environment
    }
}

resource "azurerm_function_app" "fa" {
    name                      = "${var.environment}-${replace(var.resource_group_name, ".", "-")}app"
    location                  = azurerm_resource_group.rg.location
    resource_group_name       = azurerm_resource_group.rg.name
    app_service_plan_id       = azurerm_app_service_plan.asp.id
    storage_connection_string = azurerm_storage_account.sa.primary_connection_string
    
    tags = {
        environment = var.environment
    }
}

resource "azurerm_servicebus_topic" "topic" {
    for_each = var.service_bus_topics
  name                = each.value
  resource_group_name = var.core_resource_group_name
  namespace_name      = "${var.core_resource_group_name}sbn"

  enable_partitioning = true
}