@isTest
private class RedditMCPInvocableActionsTest {

    @isTest
    static void testInvokeRedditToolSuccess() {
        Test.setMock(HttpCalloutMock.class, new RedditMCPHttpMock());

        RedditMCPInvocableActions.InvocableRequest request = new RedditMCPInvocableActions.InvocableRequest();
        request.toolName = 'get_subreddit_posts';
        request.parametersJson = '{"subreddit":"salesforce","limit":10}';

        Test.startTest();
        List<RedditMCPInvocableActions.InvocableResponse> responses =
            RedditMCPInvocableActions.invokeRedditTool(new List<RedditMCPInvocableActions.InvocableRequest>{ request });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return one response');
        RedditMCPInvocableActions.InvocableResponse response = responses[0];
        System.assertEquals(true, response.success, 'Should be successful');
        System.assertNotEquals(null, response.responseJson, 'Should have response JSON');
    }

    @isTest
    static void testInvokeRedditToolUnknownTool() {
        RedditMCPInvocableActions.InvocableRequest request = new RedditMCPInvocableActions.InvocableRequest();
        request.toolName = 'unknown_tool';
        request.parametersJson = '{}';

        Test.startTest();
        List<RedditMCPInvocableActions.InvocableResponse> responses =
            RedditMCPInvocableActions.invokeRedditTool(new List<RedditMCPInvocableActions.InvocableRequest>{ request });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return one response');
        RedditMCPInvocableActions.InvocableResponse response = responses[0];
        System.assertEquals(false, response.success, 'Should fail for unknown tool');
        System.assert(response.errorMessage.contains('Unknown tool'), 'Should have error message');
    }

    @isTest
    static void testInvokeRedditToolHttpFallback() {
        Test.setMock(HttpCalloutMock.class, new RedditMCPHttpMock());

        RedditMCPInvocableActions.InvocableRequest request = new RedditMCPInvocableActions.InvocableRequest();
        request.toolName = 'search_posts';
        request.parametersJson = '{"query":"salesforce"}';

        Test.startTest();
        List<RedditMCPInvocableActions.InvocableResponse> responses =
            RedditMCPInvocableActions.invokeRedditTool(new List<RedditMCPInvocableActions.InvocableRequest>{ request });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return one response');
        // Should use HTTP fallback since ConnectApi will fail in test context
        System.assertNotEquals(null, responses[0], 'Should have a response');
    }

    @isTest
    static void testMultipleRequests() {
        Test.setMock(HttpCalloutMock.class, new RedditMCPHttpMock());

        List<RedditMCPInvocableActions.InvocableRequest> requests = new List<RedditMCPInvocableActions.InvocableRequest>();

        RedditMCPInvocableActions.InvocableRequest request1 = new RedditMCPInvocableActions.InvocableRequest();
        request1.toolName = 'get_subreddit_posts';
        request1.parametersJson = '{"subreddit":"salesforce"}';
        requests.add(request1);

        RedditMCPInvocableActions.InvocableRequest request2 = new RedditMCPInvocableActions.InvocableRequest();
        request2.toolName = 'get_user_posts';
        request2.parametersJson = '{"username":"testuser"}';
        requests.add(request2);

        Test.startTest();
        List<RedditMCPInvocableActions.InvocableResponse> responses =
            RedditMCPInvocableActions.invokeRedditTool(requests);
        Test.stopTest();

        System.assertEquals(2, responses.size(), 'Should return two responses');
    }

    private class RedditMCPHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            Map<String, Object> responseBody = new Map<String, Object>{
                'jsonrpc' => '2.0',
                'id' => 1,
                'result' => new Map<String, Object>{
                    'content' => new List<Object>{
                        new Map<String, Object>{
                            'type' => 'text',
                            'text' => 'Test response data'
                        }
                    }
                }
            };

            res.setBody(JSON.serialize(responseBody));
            return res;
        }
    }
}
