#!/bin/bash

# Prompt for org alias
echo "Enter your Salesforce org alias or username:"
read TARGET_ORG

if [ -z "$TARGET_ORG" ]; then
    echo "Error: No org alias provided. Exiting."
    exit 1
fi

echo ""
echo "Deploying Reddit MCP Demo App, Components, and Metadata to $TARGET_ORG..."
echo ""

# Deploy in correct order: LWC Components -> Tab -> Page -> App -> Permission Set

echo "Step 1/5: Deploying Lightning Web Components..."
sf project deploy start --source-dir force-app/main/default/lwc --target-org $TARGET_ORG
if [ $? -ne 0 ]; then
    echo "❌ LWC deployment failed. Exiting."
    exit 1
fi

echo ""
echo "Step 2/5: Deploying Tab..."
sf project deploy start --source-dir force-app/main/default/tabs --target-org $TARGET_ORG
if [ $? -ne 0 ]; then
    echo "❌ Tab deployment failed. Exiting."
    exit 1
fi

echo ""
echo "Step 3/5: Deploying App Page..."
sf project deploy start --source-dir force-app/main/default/flexipages --target-org $TARGET_ORG
if [ $? -ne 0 ]; then
    echo "❌ App Page deployment failed. Exiting."
    exit 1
fi

echo ""
echo "Step 4/5: Deploying Lightning App..."
sf project deploy start --source-dir force-app/main/default/applications --target-org $TARGET_ORG
if [ $? -ne 0 ]; then
    echo "❌ Lightning App deployment failed. Exiting."
    exit 1
fi

echo ""
echo "Step 5/5: Deploying Permission Set..."
sf project deploy start --source-dir force-app/main/default/permissionsets --target-org $TARGET_ORG
if [ $? -ne 0 ]; then
    echo "❌ Permission Set deployment failed. Exiting."
    exit 1
fi

echo ""
echo "Assigning RedditMCP_UX_Perm_Set to user..."
echo "Enter the username to assign the permission set to (or press Enter to skip):"
read USERNAME

if [ ! -z "$USERNAME" ]; then
    sf org assign permset --name RedditMCP_UX_Perm_Set --on-behalf-of $USERNAME --target-org $TARGET_ORG
    if [ $? -ne 0 ]; then
        echo "⚠️  Warning: Permission set assignment failed. You may need to assign it manually."
    fi
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Navigate to App Launcher → RedditMCP Demo App"
echo "2. The Reddit MCP Demo page should be visible"
echo "3. The redditMCPChat component is embedded on the page"
echo ""
echo "Note: If you need to assign the permission set manually:"
echo "  sf org assign permset --name RedditMCP_UX_Perm_Set --on-behalf-of <username> --target-org $TARGET_ORG"
