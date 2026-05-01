@isTest
private class RedditMCPControllerTest {

    @isTest
    static void testGetAvailableTools() {
        Test.startTest();
        List<Map<String, Object>> tools = RedditMCPController.getAvailableTools();
        Test.stopTest();

        System.assertNotEquals(null, tools, 'Tools list should not be null');
        System.assertEquals(7, tools.size(), 'Should return 7 default Reddit tools');

        Boolean hasSubredditPosts = false;
        for (Map<String, Object> tool : tools) {
            if (tool.get('name') == 'get_subreddit_posts') {
                hasSubredditPosts = true;
                System.assert(tool.containsKey('description'), 'Tool should have description');
                System.assert(tool.containsKey('inputSchema'), 'Tool should have input schema');
            }
        }
        System.assert(hasSubredditPosts, 'Should include get_subreddit_posts tool');
    }

    @isTest
    static void testInvokeMCPToolWithMock() {
        Test.setMock(HttpCalloutMock.class, new RedditMCPHttpMock());

        Map<String, Object> parameters = new Map<String, Object>{
            'subreddit' => 'salesforce',
            'limit' => 10
        };

        Test.startTest();
        Map<String, Object> result = RedditMCPController.invokeMCPTool('get_subreddit_posts', parameters);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('success'), 'Result should have success flag');
    }

    @isTest
    static void testInvokeMCPToolError() {
        Test.setMock(HttpCalloutMock.class, new RedditMCPHttpErrorMock());

        Map<String, Object> parameters = new Map<String, Object>{
            'subreddit' => 'salesforce'
        };

        Test.startTest();
        Map<String, Object> result = RedditMCPController.invokeMCPTool('get_subreddit_posts', parameters);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.get('success'), 'Should indicate failure');
        System.assert(result.containsKey('error'), 'Should contain error message');
    }

    private class RedditMCPHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            Map<String, Object> responseBody = new Map<String, Object>{
                'success' => true,
                'data' => new Map<String, Object>{
                    'posts' => new List<Object>{
                        new Map<String, Object>{
                            'title' => 'Test Post',
                            'author' => 'testuser',
                            'score' => 100
                        }
                    }
                }
            };

            res.setBody(JSON.serialize(responseBody));
            return res;
        }
    }

    private class RedditMCPHttpErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setBody('{"error": "Server error"}');
            return res;
        }
    }
}