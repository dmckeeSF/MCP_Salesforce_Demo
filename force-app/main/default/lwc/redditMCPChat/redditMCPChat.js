import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAvailableTools from '@salesforce/apex/RedditMCPAgentController.getAvailableTools';
import invokeGenAIFunction from '@salesforce/apex/RedditMCPAgentController.invokeGenAIFunction';
import RedditLogo from '@salesforce/resourceUrl/RedditLogo';

export default class RedditMCPChat extends LightningElement {
    @track messages = [];
    @track toolOptions = [];
    @track selectedTool = '';
    @track currentToolInputs = [];
    @track isLoading = false;
    @track toolsMetadata = [];
    @track toolSelectorCollapsed = false;
    @track expandedPostComments = {};

    messageIdCounter = 0;
    redditLogoUrl = RedditLogo;

    connectedCallback() {
        this.loadAvailableTools();
    }

    handleToggleToolSelector() {
        this.toolSelectorCollapsed = !this.toolSelectorCollapsed;
    }

    async handleViewComments(event) {
        console.log('handleViewComments called');
        const postId = event.currentTarget.dataset.postid;
        const messageId = event.currentTarget.dataset.messageid;

        console.log('Post ID:', postId);
        console.log('Message ID:', messageId);
        console.log('Current target:', event.currentTarget);

        // Toggle comments visibility
        if (this.expandedPostComments[postId]) {
            // Already showing, so hide
            console.log('Hiding comments for post:', postId);
            this.expandedPostComments = { ...this.expandedPostComments, [postId]: null };
            this.updateMessageComments(messageId, postId);
            return;
        }

        // Fetch comments
        try {
            this.isLoading = true;
            console.log('Fetching comments for post:', postId);

            const result = await invokeGenAIFunction({
                functionName: 'get_comments',
                parameters: { postId: postId, limit: 10 }
            });

            console.log('Comment fetch result:', result);

            if (result.success) {
                const parsed = JSON.parse(JSON.stringify(result.data));
                console.log('Full parsed result.data:', JSON.stringify(parsed, null, 2));
                console.log('result.structuredContent:', parsed.result?.structuredContent);
                console.log('result.result:', parsed.result);

                // Check if MCP returned an error
                if (parsed.result?.isError === true) {
                    const errorText = parsed.result?.content?.[0]?.text || 'Unknown MCP error';
                    console.error('MCP error:', errorText);
                    this.showToast('Error', 'Comments are temporarily unavailable due to a server validation issue.', 'error');
                    return;
                }

                const comments = parsed.result?.structuredContent?.comments || parsed.comments || [];

                console.log('Parsed comments:', comments);
                console.log('Comments array length:', comments.length);

                if (comments.length === 0) {
                    this.showToast('Info', 'No comments found for this post.', 'info');
                    return;
                }

                this.expandedPostComments = { ...this.expandedPostComments, [postId]: comments };
                this.updateMessageComments(messageId, postId);
            } else {
                this.showToast('Error', 'Failed to load comments: ' + result.error, 'error');
            }
        } catch (error) {
            console.error('Error in handleViewComments:', error);
            this.showToast('Error', 'Error loading comments: ' + this.getErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    updateMessageComments(messageId, postId) {
        console.log('updateMessageComments called with messageId:', messageId, 'postId:', postId);
        console.log('expandedPostComments:', this.expandedPostComments);

        // Find the message and update its posts with comment data
        this.messages = this.messages.map(msg => {
            console.log('Checking message:', msg.id, 'against', parseInt(messageId));
            if (msg.id === parseInt(messageId) && msg.redditData && msg.redditData.data) {
                console.log('Found matching message, updating posts');
                const updatedPosts = msg.redditData.data.map(post => {
                    console.log('Checking post:', post.id, 'against', postId);
                    if (post.id === postId) {
                        const updatedPost = {
                            ...post,
                            comments: this.expandedPostComments[postId] || null,
                            hasComments: !!(this.expandedPostComments[postId] && this.expandedPostComments[postId].length > 0)
                        };
                        console.log('Updated post:', updatedPost);
                        return updatedPost;
                    }
                    return post;
                });
                return {
                    ...msg,
                    redditData: {
                        ...msg.redditData,
                        data: updatedPosts
                    }
                };
            }
            return msg;
        });
        console.log('Messages after update:', this.messages);
    }

    async loadAvailableTools() {
        try {
            this.isLoading = true;
            const tools = await getAvailableTools();
            this.toolsMetadata = tools;

            this.toolOptions = tools.map(tool => ({
                label: this.formatToolName(tool.name),
                value: tool.name,
                description: tool.description
            }));

            // Tools loaded successfully - no message needed
        } catch (error) {
            this.addSystemMessage('Error loading tools: ' + this.getErrorMessage(error), true);
        } finally {
            this.isLoading = false;
        }
    }

    formatToolName(name) {
        return name
            .split('_')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');
    }

    handleToolChange(event) {
        this.selectedTool = event.detail.value;
        this.buildInputFields();
        // Clear chat when switching tools
        this.messages = [];
    }

    buildInputFields() {
        const tool = this.toolsMetadata.find(t => t.name === this.selectedTool);
        if (!tool || !tool.inputSchema) {
            this.currentToolInputs = [];
            return;
        }

        const properties = tool.inputSchema.properties || {};
        const required = tool.inputSchema.required || [];

        this.currentToolInputs = Object.keys(properties).map(key => {
            const prop = properties[key];

            // Determine input type and options
            let inputType = 'text';
            let options = null;
            let defaultValue = '';

            if (prop.type === 'number') {
                inputType = 'number';
                if (key === 'limit') {
                    defaultValue = '3';
                }
            } else if (key === 'sort') {
                inputType = 'combobox';
                options = [
                    { label: 'Hot', value: 'hot' },
                    { label: 'New', value: 'new' },
                    { label: 'Top', value: 'top' },
                    { label: 'Rising', value: 'rising' }
                ];
                defaultValue = 'new';
            } else if (key === 'subreddit') {
                defaultValue = 'salesforce';
            }

            return {
                name: key,
                label: this.formatToolName(key),
                type: inputType,
                placeholder: prop.description || '',
                required: required.includes(key),
                value: defaultValue,
                options: options
            };
        });
    }

    handleInputChange(event) {
        const name = event.target.name;
        const value = event.target.value;

        this.currentToolInputs = this.currentToolInputs.map(input => {
            if (input.name === name) {
                return { ...input, value: value };
            }
            return input;
        });
    }

    async handleExecute() {
        if (!this.selectedTool) {
            this.showToast('Error', 'Please select a tool', 'error');
            return;
        }

        const parameters = {};
        let hasRequiredFieldsError = false;

        this.currentToolInputs.forEach(input => {
            if (input.required && !input.value) {
                hasRequiredFieldsError = true;
            }
            if (input.value) {
                parameters[input.name] = input.type === 'number' ?
                    parseInt(input.value, 10) : input.value;
            }
        });

        if (hasRequiredFieldsError) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }

        // Clear previous results before executing
        this.messages = [];

        try {
            this.isLoading = true;

            const result = await invokeGenAIFunction({
                functionName: this.selectedTool,
                parameters: parameters
            });

            if (result.success) {
                this.addAssistantMessage(JSON.stringify(result.data, null, 2));
                // Collapse tool selector after successful query
                this.toolSelectorCollapsed = true;
            } else {
                this.addAssistantMessage('Error: ' + result.error, true, result.body);
            }
        } catch (error) {
            this.addAssistantMessage('Exception: ' + this.getErrorMessage(error), true);
        } finally {
            this.isLoading = false;
        }
    }

    handleClearChat() {
        this.messages = [];
        this.selectedTool = '';
        this.currentToolInputs = [];
    }

    addUserMessage(toolName, parameters) {
        const content = '<strong>Tool:</strong> ' + this.formatToolName(toolName) +
                       '<br/><strong>Parameters:</strong><br/><pre>' +
                       JSON.stringify(parameters, null, 2) + '</pre>';

        this.messages.push({
            id: this.messageIdCounter++,
            role: 'User',
            content: content,
            timestamp: this.getCurrentTimestamp(),
            icon: 'utility:user',
            cssClass: 'message user-message',
            isError: false
        });
        this.scrollToBottom();
    }

    addAssistantMessage(content, isError = false, errorDetails = null) {
        let formattedContent = content;
        let redditData = null;
        let isPostsList = false;
        let isSinglePost = false;
        let isCommentsList = false;

        if (!isError) {
            // Try to parse as JSON and detect Reddit data structures
            try {
                const parsed = JSON.parse(content);
                console.log('Parsed response in addAssistantMessage:', JSON.stringify(parsed, null, 2));

                // MCP responses have result.structuredContent, so check there first
                const structuredData = parsed.result?.structuredContent;
                console.log('structuredData:', structuredData);

                // Also check if there's additional data in content[0].text
                if (parsed.result?.content?.[0]?.text) {
                    try {
                        const contentText = JSON.parse(parsed.result.content[0].text);
                        console.log('Parsed content[0].text:', contentText);
                        console.log('Posts from content[0].text:', contentText.posts);
                        if (contentText.posts && contentText.posts.length > 0) {
                            console.log('First post from content[0].text:', JSON.stringify(contentText.posts[0], null, 2));
                        }
                    } catch (e) {
                        console.log('Could not parse content[0].text');
                    }
                }

                // Check if it's a list of posts (get_subreddit_posts, search_posts, etc.)
                if (structuredData?.posts && Array.isArray(structuredData.posts)) {
                    if (structuredData.posts.length === 0) {
                        formattedContent = '<div class="no-results">Request returned 0 results</div>';
                    } else {
                        redditData = { type: 'posts', data: structuredData.posts };
                        isPostsList = true;
                        console.log('Detected posts list, count:', structuredData.posts.length);
                    }
                }
                // Check if it's a single post (get_post)
                else if (structuredData?.post) {
                    redditData = { type: 'post', data: structuredData.post };
                    isSinglePost = true;
                    console.log('Detected single post');
                }
                // Check if it's comments
                else if (structuredData?.comments && Array.isArray(structuredData.comments)) {
                    if (structuredData.comments.length === 0) {
                        formattedContent = '<div class="no-results">Request returned 0 results</div>';
                    } else {
                        redditData = { type: 'comments', data: structuredData.comments, post: structuredData.post };
                        isCommentsList = true;
                        console.log('Detected comments list, count:', structuredData.comments.length);
                    }
                }
                // Fallback: check top-level for direct data
                else if (parsed.posts && Array.isArray(parsed.posts)) {
                    redditData = { type: 'posts', data: parsed.posts };
                    isPostsList = true;
                    console.log('Detected posts list at top level, count:', parsed.posts.length);
                }
                else if (parsed.post) {
                    redditData = { type: 'post', data: parsed.post };
                    isSinglePost = true;
                    console.log('Detected single post at top level');
                }
                else if (parsed.comments && Array.isArray(parsed.comments)) {
                    redditData = { type: 'comments', data: parsed.comments, post: parsed.post };
                    isCommentsList = true;
                    console.log('Detected comments at top level, count:', parsed.comments.length);
                }
                // Default: show as formatted JSON
                else {
                    console.log('No Reddit data structure detected, showing raw JSON');
                    formattedContent = '<pre>' + JSON.stringify(parsed, null, 2) + '</pre>';
                }
            } catch (e) {
                console.error('Error parsing response:', e);
                formattedContent = '<pre>' + content + '</pre>';
            }
        } else {
            formattedContent = '<strong style="color: #c23934;">' + content + '</strong>';
        }

        this.messages.push({
            id: this.messageIdCounter++,
            role: 'Assistant',
            content: formattedContent,
            timestamp: this.getCurrentTimestamp(),
            icon: 'utility:bot',
            cssClass: 'message assistant-message' + (isError ? ' error-message' : ''),
            isError: isError,
            errorDetails: errorDetails,
            redditData: redditData,
            isPostsList: isPostsList,
            isSinglePost: isSinglePost,
            isCommentsList: isCommentsList
        });
        this.scrollToBottom();
    }

    addSystemMessage(content, isError = false) {
        this.messages.push({
            id: this.messageIdCounter++,
            role: 'System',
            content: content,
            timestamp: this.getCurrentTimestamp(),
            icon: 'utility:info',
            cssClass: 'message system-message' + (isError ? ' error-message' : ''),
            isError: isError
        });
        this.scrollToBottom();
    }

    scrollToBottom() {
        setTimeout(() => {
            const container = this.template.querySelector('.messages-container');
            if (container) {
                container.scrollTop = container.scrollHeight;
            }
        }, 100);
    }

    getCurrentTimestamp() {
        const now = new Date();
        return now.toLocaleTimeString();
    }

    getErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        }
        return error.message || JSON.stringify(error);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }

    get hasMessages() {
        return this.messages.length > 0;
    }

    get showToolInputs() {
        return this.currentToolInputs.length > 0;
    }

    get executeDisabled() {
        return !this.selectedTool || this.isLoading;
    }

    get collapseIconName() {
        return this.toolSelectorCollapsed ? 'utility:chevronright' : 'utility:chevrondown';
    }
}
