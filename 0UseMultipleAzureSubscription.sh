#!/bin/bash
## Use multiple Azure subscriptions
## https://docs.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli?view=azure-cli-latest
## Azure CLI - az account
## https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest
## Sign in to Azure with the Azure CLI 
## https://docs.microsoft.com/zh-tw/cli/azure/install-azure-cli-linux?pivots=apt#sign-in-to-azure-with-the-azure-cli

# Run the login command to sign in.
az login

## Change the active subscription
# Get a list of your subscriptions with the az account list command:
az account list --output table

# Use az account set with the subscription ID or name you want to switch to.
#az account set --subscription "My Demos"
#az account set --subscription "Microsoft Azure Internal Consumption"
az account set --subscription "hslin - Microsoft Azure Internal Consumption"

# Get the details of a subscription current.
az account show

# Log out to remove access to Azure subscriptions.
az logout
