resource "terraform_data" "purge_microsoft_foundry_account" {
  input = {
    account_name        = local.microsoft_foundry_name
    location            = var.location
    resource_group_name = module.resource_group.name
    subscription_id     = split("/", module.resource_group.id)[2]
  }

  provisioner "local-exec" {
    when = destroy

    command = "az cognitiveservices account purge --name \"$ACCOUNT_NAME\" --resource-group \"$RESOURCE_GROUP_NAME\" --location \"$LOCATION\" --subscription \"$SUBSCRIPTION_ID\" --only-show-errors --output none"
    environment = {
      ACCOUNT_NAME        = self.input.account_name
      LOCATION            = self.input.location
      RESOURCE_GROUP_NAME = self.input.resource_group_name
      SUBSCRIPTION_ID     = self.input.subscription_id
    }
  }
}
