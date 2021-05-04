# Dell Warranty	
Used part of [cyberdrain's](https://www.cyberdrain.com/automating-with-powershell-automating-warranty-information-reporting/) warranty script to grab Dell assets from Syncro and query the warranty status. Then used the asset API to push that status into Custom Fields.

### Use this at your own risk.

You will need the API Token to have permissions for:

Customer: 
-
- Customers - View Detail
- Customers - List/Search
- Assets - Edit
- Assets - List/Search
- Assets - View Details


Need the following custom fields:
-
- Warranty Product Name (Text area)
- Warranty Start (Date Field)
- Warranty End (Date Field)
- Warranty Status (Text Field)

## Dell:

Go to the [Dell TechDirect](https://tdm.dell.com/portal/) website and register if you do not yet have an account. Complete the enrollment.

After registration, browse to the Dell TechDirect API enrollment page and wait for approval. This is a manual procedure so can take a day or two.

When the approval has been given, request a new API key and save this in a secure location.