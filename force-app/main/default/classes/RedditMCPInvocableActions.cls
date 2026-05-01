public with sharing class RedditMCPInvocableActions {

    // Input/Output wrapper classes
    public class InvocableRequest {
        @InvocableVariable(required=true label='Tool Name')
        public String toolName;

        @InvocableVariable(required=true label='Parameters (JSON)')
        public String parametersJson;
    }

    public class InvocableResponse {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Response Data (JSON)')
        public String responseJson;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(label='Invoke Reddit MCP Tool' description='Invokes a Reddit MCP tool via GenAI Function' category='Reddit MCP')
    public static List<InvocableResponse> invokeRedditTool(List<InvocableRequest> requests) {
        List<InvocableResponse> responses = new List<InvocableResponse>();

        for (InvocableRequest request : requests) {
            InvocableResponse response = new InvocableResponse();

            try {
                // Map tool name to GenAI Function developer name
                String functionName = getGenAiFunctionName(request.toolName);

                if (String.isBlank(functionName)) {
                    response.success = false;
                    response.errorMessage = 'Unknown tool: ' + request.toolName;
                    responses.add(response);
                    continue;
                }

                // Parse parameters
                Map<String, Object> parameters = (Map<String, Object>) JSON.deserializeUntyped(request.parametersJson);

                // Use direct HTTP callout (ConnectApi not available for GenAI functions in this API version)
                Map<String, Object> httpResult = invokeViaHttp(request.toolName, parameters);

                response.success = (Boolean) httpResult.get('success');
                if (response.success) {
                    response.responseJson = JSON.serialize(httpResult.get('data'));
                } else {
                    response.errorMessage = (String) httpResult.get('error');
                }

            } catch (Exception e) {
                response.success = false;
                response.errorMessage = e.getMessage() + '\n' + e.getStackTraceString();
            }

            responses.add(response);
        }

        return responses;
    }

    private static String getGenAiFunctionName(String toolName) {
        Map<String, String> toolToFunctionMap = new Map<String, String>{
            'get_subreddit_posts' => 'McpTool_get_subreddit_postsRedditMC',
            'get_post' => 'McpTool_get_postRedditMCP',
            'get_comments' => 'McpTool_get_commentsRedditMCP',
            'get_user_posts' => 'McpTool_get_user_postsRedditMCP',
            'create_post' => 'McpTool_create_postRedditMCP',
            'create_comment' => 'McpTool_create_commentRedditMCP',
            'search_posts' => 'McpTool_search_postsRedditMCP'
        };

        return toolToFunctionMap.get(toolName);
    }

    // Fallback HTTP callout method (same as V1)
    private static Map<String, Object> invokeViaHttp(String toolName, Map<String, Object> parameters) {
        try {
            String endpoint = 'callout:RedditMCP';

            Map<String, Object> requestBody = new Map<String, Object>{
                'jsonrpc' => '2.0',
                'id' => 1,
                'method' => 'tools/call',
                'params' => new Map<String, Object>{
                    'name' => toolName,
                    'arguments' => parameters
                }
            };

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json, text/event-stream');
            req.setBody(JSON.serialize(requestBody));
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                String responseBody = res.getBody();

                // Handle SSE format if present
                if (responseBody.startsWith('event:') || responseBody.startsWith('data:')) {
                    responseBody = extractJsonFromSSE(responseBody);
                }

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                return new Map<String, Object>{
                    'success' => true,
                    'data' => responseData
                };
            } else {
                return new Map<String, Object>{
                    'success' => false,
                    'error' => 'HTTP ' + res.getStatusCode() + ': ' + res.getStatus()
                };
            }
        } catch (Exception e) {
            return new Map<String, Object>{
                'success' => false,
                'error' => e.getMessage()
            };
        }
    }

    private static String extractJsonFromSSE(String sseResponse) {
        String jsonData = '';
        List<String> lines = sseResponse.split('\n');

        for (String line : lines) {
            line = line.trim();
            if (line.startsWith('data:')) {
                jsonData += line.substring(5).trim();
            }
        }

        return jsonData;
    }
}
