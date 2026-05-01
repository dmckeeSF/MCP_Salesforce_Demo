# Deployment Guide

## What Gets Deployed

This deployment includes:

### 1. **Lightning App**
- **Name**: RedditMCP Demo App
- **Type**: Lightning Application
- **Navigation**: Standard
- **Description**: Demo application for Reddit MCP integration

### 2. **Lightning App Page**
- **Name**: Reddit MCP Demo
- **Type**: App Page
- **Component**: Embeds the `redditMCPChat` LWC component
- **Template**: Default App Home Template

### 3. **Custom Tab**
- **Name**: Reddit MCP Demo
- **Type**: Flexipage Tab
- **Icon**: Custom8: Wrench
- **Links to**: Reddit_MCP_Demo flexipage

### 4. **Permission Set**
- **Name**: RedditMCP_UX_Perm_Set
- **Label**: RedditMCP UX Perm Set
- **Grants**:
  - Visibility to RedditMCP Demo App (set as default)
  - Access to Reddit MCP Demo tab
- **Auto-assigned to**: dmckee@salesforce.com.mcpdemo032526v2

## Deployment Steps

### Option 1: Quick Deploy (Automated)

Run the deployment script:

```bash
./deploy-demo-app.sh
```

### Option 2: Manual Deploy

1. **Deploy the App**
   ```bash
   sf project deploy start --source-dir force-app/main/default/applications
   ```

2. **Deploy the Page**
   ```bash
   sf project deploy start --source-dir force-app/main/default/flexipages
   ```

3. **Deploy the Tab**
   ```bash
   sf project deploy start --source-dir force-app/main/default/tabs
   ```

4. **Deploy the Permission Set**
   ```bash
   sf project deploy start --source-dir force-app/main/default/permissionsets
   ```

5. **Assign Permission Set**
   ```bash
   sf org assign permset --name RedditMCP_UX_Perm_Set --target-org dmckee@salesforce.com.mcpdemo032526v2
   ```

## Making the App Available to All Profiles

To make the app available as default for all profiles:

1. **Via Setup UI**:
   - Go to Setup → Apps → App Manager
   - Find "RedditMCP Demo App"
   - Click dropdown → Edit
   - Under "User Profiles", add all profiles that should see this app
   - Check "Visible" and optionally "Default" for each profile

2. **Via Profile Metadata** (add to each profile XML):
   ```xml
   <applicationVisibilities>
       <application>RedditMCP_Demo_App</application>
       <default>true</default>
       <visible>true</visible>
   </applicationVisibilities>
   ```

## Accessing the App

After deployment:

1. Click the App Launcher (waffle icon)
2. Search for "RedditMCP Demo App"
3. Click to open
4. The Reddit MCP Demo page will be displayed with the embedded chat component

## Files Created

```
force-app/main/default/
├── applications/
│   └── RedditMCP_Demo_App.app-meta.xml
├── flexipages/
│   └── Reddit_MCP_Demo.flexipage-meta.xml
├── tabs/
│   └── Reddit_MCP_Demo.tab-meta.xml
└── permissionsets/
    └── RedditMCP_UX_Perm_Set.permissionset-meta.xml
```

## Troubleshooting

**App not showing in App Launcher?**
- Check that RedditMCP_UX_Perm_Set is assigned to your user
- Refresh the page or log out/in

**Component not rendering?**
- Verify the LWC component `redditMCPChat` is deployed
- Check browser console for errors

**Permission errors?**
- Ensure both permission sets are assigned:
  - RedditMCP_Perm_Set (for Apex/credentials)
  - RedditMCP_UX_Perm_Set (for app/page access)
