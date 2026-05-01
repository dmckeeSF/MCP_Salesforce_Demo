#!/bin/bash

# Deploy Reddit MCP Demo App and Components
echo "Deploying Reddit MCP Demo App, Page, and Permission Set..."

# Deploy the components
sf project deploy start --source-dir force-app/main/default/applications
sf project deploy start --source-dir force-app/main/default/flexipages
sf project deploy start --source-dir force-app/main/default/tabs
sf project deploy start --source-dir force-app/main/default/permissionsets

echo ""
echo "Assigning RedditMCP_UX_Perm_Set to dmckee@salesforce.com.mcpdemo032526v2..."
sf org assign permset --name RedditMCP_UX_Perm_Set --target-org dmckee@salesforce.com.mcpdemo032526v2

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Navigate to App Launcher → RedditMCP Demo App"
echo "2. The Reddit MCP Demo page should be visible"
echo "3. The redditMCPChat component is embedded on the page"
