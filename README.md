# Salesforce MCP Integration Demo

A production-ready demonstration of integrating Model Context Protocol (MCP) servers with Salesforce using Lightning Web Components and Apex.

## Overview

This demo showcases how to call MCP servers from Salesforce using standard Apex HTTP callouts with Named Credentials for secure authentication management.

## What This Demo Includes

- **Lightning Web Component (LWC)** - Interactive UI for selecting and executing MCP tools
- **Apex Controller** - HTTP callout logic for communicating with MCP servers
- **Named Credential Setup** - Secure credential management
- **JSON-RPC 2.0 Implementation** - Standard MCP protocol support
- **SSE Response Handling** - Parses Server-Sent Events format

## Architecture

```
User Click → LWC → Apex Controller → Named Credential → HTTP Callout → MCP Server
```

## Key Features

- ✅ Production-ready integration pattern
- ✅ Secure credential management via Named Credentials
- ✅ Standard Apex HTTP callouts
- ✅ Flexible configuration (headers, timeout, error handling)
- ✅ Uses standard Salesforce platform capabilities
- ✅ Easy to test and debug

## Documentation

See [HOW_IT_WORKS.md](./HOW_IT_WORKS.md) for detailed technical documentation including:
- Complete request/response flow
- Code examples for each component
- Authentication setup
- Network diagrams
- File structure

## Getting Started

### Prerequisites

- Salesforce org with API access
- MCP server endpoint
- Authentication credentials for your MCP server

### Setup Steps

1. **Deploy Apex Classes**
   - `RedditMCPController.cls` - Main controller
   - `RedditMCPControllerTest.cls` - Test coverage

2. **Deploy LWC Component**
   - `redditMCPChat` - UI component

3. **Configure Named Credential**
   - Create External Credential with your MCP server auth
   - Create Named Credential pointing to your MCP server URL
   - Link External Credential to Named Credential

4. **Assign Permission Set**
   - Grant users access to Apex class and Named Credential

5. **Add LWC to Page**
   - Add component to Lightning page
   - Test MCP tool execution

## Example Use Case

This demo uses Reddit MCP server integration as an example:

```javascript
// User executes tool from UI
{
  "toolName": "get_subreddit_posts",
  "parameters": {
    "subreddit": "salesforce",
    "limit": 10
  }
}
```

The flow:
1. LWC captures user input
2. Apex builds JSON-RPC request
3. Standard Apex HTTP callout with Named Credential
4. Named Credential adds authentication
5. MCP server processes request
6. Response displayed in LWC UI

## Benefits

**For Developers:**
- Standard Salesforce development patterns
- Easy to customize and extend
- Full control over request/response handling
- Simple debugging with standard HTTP tools

**For Organizations:**
- Secure credential management
- Production-ready architecture
- Leverages existing Salesforce security model
- No additional platform dependencies

## Testing

Test coverage included:
- Mock HTTP callouts
- Success and error scenarios
- SSE format parsing
- JSON response handling

Run tests in your Salesforce org to verify deployment.

## Support

This is a demonstration project showing how to integrate MCP servers with Salesforce using standard platform capabilities.

## License

This demo is provided as-is for educational and development purposes.
