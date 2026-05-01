public with sharing class RedditMCPController {

    @AuraEnabled
    public static Map<String, Object> invokeMCPTool(String toolName, Map<String, Object> parameters) {
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

                // Check if response is SSE format (Server-Sent Events)
                if (responseBody.startsWith('event:') || responseBody.startsWith('data:')) {
                    // Extract JSON from SSE format
                    // SSE format: "event: message\ndata: {...json...}\n\n"
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
                    'error' => 'HTTP ' + res.getStatusCode() + ': ' + res.getStatus(),
                    'body' => res.getBody()
                };
            }
        } catch (Exception e) {
            return new Map<String, Object>{
                'success' => false,
                'error' => e.getMessage(),
                'stackTrace' => e.getStackTraceString()
            };
        }
    }

    @AuraEnabled
    public static List<Map<String, Object>> getAvailableTools() {
        try {
            String endpoint = 'callout:RedditMCP';

            Map<String, Object> requestBody = new Map<String, Object>{
                'jsonrpc' => '2.0',
                'id' => 2,
                'method' => 'tools/list',
                'params' => new Map<String, Object>()
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

                // Check if response is SSE format (Server-Sent Events)
                if (responseBody.startsWith('event:') || responseBody.startsWith('data:')) {
                    // Extract JSON from SSE format
                    responseBody = extractJsonFromSSE(responseBody);
                }

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

                // Check if we have a result field (MCP protocol)
                Object toolsObj = null;
                if (responseData.containsKey('result')) {
                    Map<String, Object> result = (Map<String, Object>) responseData.get('result');
                    toolsObj = result.get('tools');
                } else {
                    toolsObj = responseData.get('tools');
                }

                if (toolsObj != null) {
                    List<Object> toolsList = (List<Object>) toolsObj;
                    List<Map<String, Object>> tools = new List<Map<String, Object>>();

                    for (Object toolObj : toolsList) {
                        tools.add((Map<String, Object>) toolObj);
                    }

                    return tools;
                } else {
                    return getDefaultRedditTools();
                }
            } else {
                return getDefaultRedditTools();
            }
        } catch (Exception e) {
            System.debug('Error fetching tools: ' + e.getMessage());
            return getDefaultRedditTools();
        }
    }

    private static String extractJsonFromSSE(String sseResponse) {
        // SSE format: "event: message\ndata: {...json...}\n\n"
        // We need to extract just the JSON part after "data: "

        String jsonData = '';
        List<String> lines = sseResponse.split('\n');

        for (String line : lines) {
            line = line.trim();
            if (line.startsWith('data:')) {
                // Extract everything after "data: "
                jsonData += line.substring(5).trim();
            }
        }

        return jsonData;
    }

    private static List<Map<String, Object>> getDefaultRedditTools() {
        return new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'get_subreddit_posts',
                'description' => 'Get posts from a specific subreddit',
                'inputSchema' => new Map<String, Object>{
                    'type' => 'object',
                    'properties' => new Map<String, Object>{
                        'subreddit' => new Map<String, Object>{'type' => 'string', 'description' => 'Subreddit name'},
                        'limit' => new Map<String, Object>{'type' => 'number', 'description' => 'Number of posts to return'},
                        'sort' => new Map<String, Object>{'type' => 'string', 'description' => 'Sort order (hot, new, top)'}
                    },
                    'required' => new List<String>{'subreddit'}
                }
            },
            new Map<String, Object>{
                'name' => 'get_post',
                'description' => 'Get a specific post by ID',
                'inputSchema' => new Map<String, Object>{
                    'type' => 'object',
                    'properties' => new Map<String, Object>{
                        'postId' => new Map<String, Object>{'type' => 'string', 'description' => 'Post ID'}
                    },
                    'required' => new List<String>{'postId'}
                }
            },
            new Map<String, Object>{
                'name' => 'create_post',
                'description' => 'Create a new post in a subreddit',
                'inputSchema' => new Map<String, Object>{
                    'type' => 'object',
                    'properties' => new Map<String, Object>{
                        'title' => new Map<String, Object>{'type' => 'string', 'description' => 'Post title'},
                        'content' => new Map<String, Object>{'type' => 'string', 'description' => 'Post content/text'},
                        'subreddit' => new Map<String, Object>{'type' => 'string', 'description' => 'Subreddit name'},
                        'author' => new Map<String, Object>{'type' => 'string', 'description' => 'Author username'},
                        'url' => new Map<String, Object>{'type' => 'string', 'description' => 'Optional URL for link posts'}
                    },
                    'required' => new List<String>{'title', 'subreddit', 'author'}
                }
            },
            new Map<String, Object>{
                'name' => 'get_comments',
                'description' => 'Get comments for a specific post',
                'inputSchema' => new Map<String, Object>{
                    'type' => 'object',
                    'properties' => new Map<String, Object>{
                        'postId' => new Map<String, Object>{'type' => 'string', 'description' => 'Post ID'},
                        'limit' => new Map<String, Object>{'type' => 'number', 'description' => 'Number of comments to return'}
                    },
                    'required' => new List<String>{'postId'}
                }
            },
            new Map<String, Object>{
                'name' => 'create_comment',
                'description' => 'Create a comment on a post or reply to another comment',
                'inputSchema' => new Map<String, Object>{
                    'type' => 'object',
                    'properties' => new Map<String, Object>{
                        'postId' => new Map<String, Object>{'type' => 'string', 'description' => 'Post ID'},
                        'parentId' => new Map<String, Object>{'type' => 'string', 'description' => 'Parent comment ID (for replies)'},
                        'author' => new Map<String, Object>{'type' => 'string', 'description' => 'Author username'},
                        'content' => new Map<String, Object>{'type' => 'string', 'description' => 'Comment text'}
                    },
                    'required' => new List<String>{'postId', 'author', 'content'}
                }
            },
            new Map<String, Object>{
                'name' => 'search_posts',
                'description' => 'Search for posts by query',
                'inputSchema' => new Map<String, Object>{
                    'type' => 'object',
                    'properties' => new Map<String, Object>{
                        'query' => new Map<String, Object>{'type' => 'string', 'description' => 'Search query'},
                        'subreddit' => new Map<String, Object>{'type' => 'string', 'description' => 'Optional: limit search to subreddit'},
                        'limit' => new Map<String, Object>{'type' => 'number', 'description' => 'Number of results to return'}
                    },
                    'required' => new List<String>{'query'}
                }
            },
            new Map<String, Object>{
                'name' => 'get_user_posts',
                'description' => 'Get posts by a specific user',
                'inputSchema' => new Map<String, Object>{
                    'type' => 'object',
                    'properties' => new Map<String, Object>{
                        'username' => new Map<String, Object>{'type' => 'string', 'description' => 'Reddit username'},
                        'limit' => new Map<String, Object>{'type' => 'number', 'description' => 'Number of posts to return'}
                    },
                    'required' => new List<String>{'username'}
                }
            }
        };
    }
}