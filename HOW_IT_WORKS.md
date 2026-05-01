# How to Call MCP Servers from Salesforce

## Complete Request Flow

```
User Click → LWC → Apex Controller → Named Credential → HTTP Callout → MCP Server
```

## Step-by-Step Breakdown

### 1. User Interaction (LWC UI)

**File:** `force-app/main/default/lwc/redditMCPChat/redditMCPChat.js`

```javascript
// User selects tool and fills parameters, clicks Execute
async handleExecute() {
    const result = await invokeMCPTool({
        toolName: this.selectedTool,      // e.g., "get_subreddit_posts"
        parameters: parameters             // e.g., {"subreddit": "salesforce", "limit": 10}
    });
}
```

**Import:**
```javascript
import invokeMCPTool from '@salesforce/apex/RedditMCPController.invokeMCPTool';
```

---

### 2. Apex Controller Receives Request

**File:** `force-app/main/default/classes/RedditMCPController.cls`

```apex
@AuraEnabled
public static Map<String, Object> invokeMCPTool(String toolName, Map<String, Object> parameters) {
```

**Receives:**
- `toolName`: `"get_subreddit_posts"`
- `parameters`: `{"subreddit": "salesforce", "limit": 10}`

---

### 3. Build JSON-RPC 2.0 Request

```apex
String endpoint = 'callout:RedditMCP';  // Named Credential

Map<String, Object> requestBody = new Map<String, Object>{
    'jsonrpc' => '2.0',
    'id' => 1,
    'method' => 'tools/call',
    'params' => new Map<String, Object>{
        'name' => toolName,
        'arguments' => parameters
    }
};
```

**JSON payload sent:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "get_subreddit_posts",
    "arguments": {
      "subreddit": "salesforce",
      "limit": 10
    }
  }
}
```

---

### 4. Create HTTP Request

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint(endpoint);                                    // callout:RedditMCP
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Accept', 'application/json, text/event-stream');
req.setBody(JSON.serialize(requestBody));
req.setTimeout(120000);                                       // 120 seconds
```

---

### 5. Named Credential Resolution

**Named Credential:** `callout:RedditMCP`

The platform automatically:
1. Looks up Named Credential: `RedditMCP`
2. Resolves the target URL (e.g., `https://your-mcp-server.com`)
3. Adds authentication headers (from External Credential)
4. Replaces `callout:RedditMCP` with actual endpoint

**Result:** Request goes to actual MCP server URL with auth

---

### 6. Send HTTP Request

```apex
Http http = new Http();
HttpResponse res = http.send(req);
```

**Standard Apex HTTP callout:**
- Uses standard Apex HTTP classes
- Secure communication via Named Credential
- Supports standard authentication patterns

---

### 7. MCP Server Processing

**MCP Server receives:**
```http
POST /
Host: your-mcp-server.com
Content-Type: application/json
Authorization: Bearer [from Named Credential]

{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "get_subreddit_posts",
    "arguments": {"subreddit": "salesforce", "limit": 10}
  }
}
```

**MCP Server:**
1. Parses JSON-RPC request
2. Routes to `get_subreddit_posts` tool
3. Calls Reddit API
4. Returns response

---

### 8. MCP Server Response (SSE Format)

**Response format:**
```
event: message
data: {"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":"[{\"title\":\"Post 1\",\"author\":\"user1\"}]"}]}}
```

Or plain JSON:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "[{\"title\":\"Post 1\",\"author\":\"user1\"}]"
      }
    ]
  }
}
```

---

### 9. Parse Response in Apex

```apex
if (res.getStatusCode() == 200) {
    String responseBody = res.getBody();

    // Check if SSE format
    if (responseBody.startsWith('event:') || responseBody.startsWith('data:')) {
        // Extract JSON from SSE format
        responseBody = extractJsonFromSSE(responseBody);
    }

    Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
    
    return new Map<String, Object>{
        'success' => true,
        'data' => responseData
    };
}
```

**SSE Parsing:**
```apex
private static String extractJsonFromSSE(String sseResponse) {
    String jsonData = '';
    List<String> lines = sseResponse.split('\n');
    
    for (String line : lines) {
        line = line.trim();
        if (line.startsWith('data:')) {
            jsonData += line.substring(5).trim();  // Remove "data: " prefix
        }
    }
    
    return jsonData;
}
```

---

### 10. Return to LWC

**Apex returns:**
```json
{
  "success": true,
  "data": {
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
      "content": [...]
    }
  }
}
```

**LWC receives:**
```javascript
if (result.success) {
    this.addAssistantMessage(JSON.stringify(result.data, null, 2));
} else {
    this.addAssistantMessage('Error: ' + result.error, true);
}
```

---

## Key Components

### Named Credential: `RedditMCP`

**Purpose:** Stores MCP server URL and authentication

**Configuration:**
- URL: `https://your-mcp-server.com`
- Authentication: Bearer token, OAuth, or Basic Auth
- Referenced as: `callout:RedditMCP`

**Benefits:** 
- Centralizes endpoint configuration
- Manages authentication securely
- No hardcoded URLs in code
- Easy to update credentials without code changes

---

### External Credential

**Purpose:** Stores actual credentials (API keys, tokens)

**Links to Named Credential:**
- Named Credential → External Credential → Principal
- Principal has actual authentication values
- Credentials stored securely by Salesforce platform

---

### Permission Set: `RedditMCP_Perm_Set`

**Grants:**
- Access to `RedditMCPController` Apex class
- Access to Named Credential
- Access to External Credential
- Remote Site Settings (if needed)

---

## Network Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Salesforce Org                                              │
│                                                             │
│  ┌──────────┐         ┌───────────────┐                   │
│  │   LWC    │────────→│ Apex          │                   │
│  │ Component│         │ Controller    │                   │
│  └──────────┘         └───────┬───────┘                   │
│                               │                            │
│                               ↓                            │
│                       ┌───────────────┐                    │
│                       │ HttpRequest   │                    │
│                       └───────┬───────┘                    │
│                               │                            │
│                               ↓                            │
│                       ┌───────────────┐                    │
│                       │ Named         │                    │
│                       │ Credential    │                    │
│                       └───────┬───────┘                    │
│                               │                            │
└───────────────────────────────┼────────────────────────────┘
                                │
                                │ HTTPS
                                ↓
┌───────────────────────────────────────────────────────────┐
│ Internet                                                  │
└───────────────────────────────────────────────────────────┘
                                │
                                ↓
┌───────────────────────────────────────────────────────────┐
│ Your MCP Server                                           │
│                                                           │
│  ┌─────────────┐         ┌──────────────┐               │
│  │ JSON-RPC    │────────→│ MCP Tool     │               │
│  │ Handler     │         │ Handler      │               │
│  └─────────────┘         └──────┬───────┘               │
│                                 │                        │
│                                 ↓                        │
│                          ┌──────────────┐               │
│                          │ Reddit API   │               │
│                          │ Client       │               │
│                          └──────────────┘               │
└───────────────────────────────────────────────────────────┘
```

---

## Authentication Flow

### How Named Credential Adds Auth

1. **External Credential stores:**
   - Authentication type (Bearer, OAuth, Basic)
   - API keys, tokens, or credentials

2. **Named Credential references:**
   - External Credential
   - Specific Principal (identity)

3. **At runtime, Salesforce:**
   - Retrieves credentials from secure storage
   - Adds authentication headers
   - Makes authenticated request

**Example headers added:**
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Key Benefits

1. **Production Ready** - Proven integration pattern
2. **Full Control** - Direct HTTP access with flexible configuration
3. **Secure** - Credentials managed by Salesforce platform
4. **Flexible** - Customize headers, timeout, error handling
5. **Testable** - Easy to test with Postman/curl during development
6. **Standard** - Uses established Salesforce integration patterns

---

## Files Involved

```
force-app/main/default/
├── classes/
│   ├── RedditMCPController.cls              ← HTTP callout logic
│   ├── RedditMCPController.cls-meta.xml
│   ├── RedditMCPControllerTest.cls          ← Test coverage
│   └── RedditMCPControllerTest.cls-meta.xml
│
├── lwc/
│   └── redditMCPChat/
│       ├── redditMCPChat.html               ← UI
│       ├── redditMCPChat.js                 ← Calls Apex
│       ├── redditMCPChat.css                ← Styling
│       └── redditMCPChat.js-meta.xml
│
└── [Metadata deployed separately]
    ├── Named Credential: RedditMCP
    ├── External Credential: RedditMCP
    ├── Permission Set: RedditMCP_Perm_Set
    └── Remote Site Settings (if needed)
```

---

## Summary

**This integration uses standard Apex HTTP callouts:**

1. LWC calls `@AuraEnabled` Apex method
2. Apex builds JSON-RPC 2.0 request
3. Apex uses standard `Http` and `HttpRequest` classes with Named Credential
4. Named Credential resolves to MCP server URL + auth
5. Standard HTTP callout sent to MCP server
6. MCP server processes and returns response
7. Apex parses response (handles SSE format)
8. Response returned to LWC
9. LWC displays results in chat UI

**This uses standard Apex HTTP callout capabilities** with Named Credentials for secure authentication management.

The pattern is flexible, testable, and production-ready for integrating MCP servers with Salesforce applications.
