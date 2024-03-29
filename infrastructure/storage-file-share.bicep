param storageAccountName string
param fileshareName string

resource fileshare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-09-01' = {
  name: '${storageAccountName}/default/${fileshareName}'
}
