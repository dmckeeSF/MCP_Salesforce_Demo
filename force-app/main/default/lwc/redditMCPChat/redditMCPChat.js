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

    messageIdCounter = 0;
    redditLogoUrl = RedditLogo;

    connectedCallback() {
        this.loadAvailableTools();
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

            this.addSystemMessage('Reddit MCP tools loaded successfully. ' + tools.length + ' tools available.');
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

        this.addUserMessage(this.selectedTool, parameters);

        try {
            this.isLoading = true;

            const result = await invokeGenAIFunction({
                functionName: this.selectedTool,
                parameters: parameters
            });

            if (result.success) {
                this.addAssistantMessage(JSON.stringify(result.data, null, 2));
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
        this.addSystemMessage('Chat cleared. Ready for new conversation.');
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

        if (!isError) {
            formattedContent = '<pre>' + content + '</pre>';
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
            errorDetails: errorDetails
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
}
