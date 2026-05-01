#!/bin/bash

# Set target org
TARGET_ORG="dmckee@salesforce.com.mcpdemo032526v2"

# Deploy Reddit MCP Demo App and Components
echo "Deploying Reddit MCP Demo App, Page, and Permission Set to $TARGET_ORG..."

# Deploy the components
echo ""
echo "Deploying Lightning App..."
sf project deploy start --source-dir force-app/main/default/applications --target-org $TARGET_ORG

echo ""
echo "Deploying App Page..."
sf project deploy start --source-dir force-app/main/default/flexipages --target-org $TARGET_ORG

echo ""
echo "Deploying Tab..."
sf project deploy start --source-dir force-app/main/default/tabs --target-org $TARGET_ORG

echo ""
echo "Deploying Permission Set..."
sf project deploy start --source-dir force-app/main/default/permissionsets --target-org $TARGET_ORG

echo ""
echo "Assigning RedditMCP_UX_Perm_Set to $TARGET_ORG..."
sf org assign permset --name RedditMCP_UX_Perm_Set --target-org $TARGET_ORG

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Navigate to App Launcher → RedditMCP Demo App"
echo "2. The Reddit MCP Demo page should be visible"
echo "3. The redditMCPChat component is embedded on the page"
