public with sharing class RedditMCPAgentController {

    @AuraEnabled
    public static Map<String, Object> invokeGenAIFunction(String functionName, Map<String, Object> parameters) {
        try {
            // Use the InvocableMethod approach
            RedditMCPInvocableActions.InvocableRequest request = new RedditMCPInvocableActions.InvocableRequest();
            request.toolName = functionName;
            request.parametersJson = JSON.serialize(parameters);

            List<RedditMCPInvocableActions.InvocableRequest> requests = new List<RedditMCPInvocableActions.InvocableRequest>{ request };
            List<RedditMCPInvocableActions.InvocableResponse> responses = RedditMCPInvocableActions.invokeRedditTool(requests);

            if (!responses.isEmpty()) {
                RedditMCPInvocableActions.InvocableResponse response = responses[0];

                if (response.success) {
                    return new Map<String, Object>{
                        'success' => true,
                        'data' => JSON.deserializeUntyped(response.responseJson),
                        'response' => response.responseJson
                    };
                } else {
                    return new Map<String, Object>{
                        'success' => false,
                        'error' => response.errorMessage
                    };
                }
            } else {
                return new Map<String, Object>{
                    'success' => false,
                    'error' => 'No response from invocable method'
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
        // Return the list of available tools
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
            }
        };
    }
}
