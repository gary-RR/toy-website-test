#Install "jq" on Git Bash. You must start Git Bash as an admin:
    # curl -L -o /usr/bin/jq.exe https://github.com/stedolan/jq/releases/latest/download/jq-win64.exe
    # chmod +x /usr/bin/jq.exe

# Open a Git Bash in VS and run the rest of these commands

githubOrganizationName='gary-RR'
githubRepositoryName='toy-website-test'

applicationRegistrationDetails=$(az ad app create --display-name 'toy-website-test')
applicationRegistrationObjectId=$(echo $applicationRegistrationDetails | jq -r '.id')
applicationRegistrationAppId=$(echo $applicationRegistrationDetails | jq -r '.appId')

az ad app federated-credential create \
   --id $applicationRegistrationObjectId \
   --parameters "{\"name\":\"toy-website-test\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:${githubOrganizationName}/${githubRepositoryName}:environment:Website\",\"audiences\":[\"api://AzureADTokenExchange\"]}"

az ad app federated-credential create \
   --id $applicationRegistrationObjectId \
   --parameters "{\"name\":\"toy-website-test-branch\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:${githubOrganizationName}/${githubRepositoryName}:ref:refs/heads/main\",\"audiences\":[\"api://AzureADTokenExchange\"]}"


resourceGroupResourceId=$(az group create --name ToyWebsiteTest --location westus3 --query id --output tsv)
# There is a bug in git bash and Azure CLI where we must remove the starting "/" from "/subscriptions"
resourceGroupResourceId=${resourceGroupResourceId:1}

az ad sp create --id $applicationRegistrationObjectId
az role assignment create \
  --assignee $applicationRegistrationAppId \
  --role Contributor \
  --scope $resourceGroupResourceId

echo "AZURE_CLIENT_ID: $applicationRegistrationAppId"
echo "AZURE_TENANT_ID: $(az account show --query tenantId --output tsv)"
echo "AZURE_SUBSCRIPTION_ID: $(az account show --query id --output tsv)"

#Clean up
az group delete --name ToyWebsiteTest --y
