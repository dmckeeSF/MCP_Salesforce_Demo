import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import invokeMCPTool from '@salesforce/apex/RedditMCPController.invokeMCPTool';

export default class McpSetup extends LightningElement {
    @track isLoadingPosts = false;
    @track isLoadingComments = false;
    @track postResults = [];
    @track createdPostIds = {};

    samplePosts = [
        {
            subreddit: 'salesforce',
            author: 'Trailblazer_Tech',
            title: 'Agentforce is a Game Changer!',
            content: 'Just watched the latest demo on Agentforce and the autonomous capabilities are incredible. This is going to revolutionize how we handle customer service workflows!',
            key: 'agentforce_post'
        },
        {
            subreddit: 'MarketingCloud',
            author: 'DigitalMarketer_99',
            title: 'Loving the new MCP updates!',
            content: 'The latest Marketing Cloud Personalization releases make real-time orchestration so much smoother. Excited to see how everyone is implementing these new features!',
            key: 'mcp_post'
        },
        {
            subreddit: 'Slack',
            author: 'Collab_Queen',
            title: 'Slack + Agentforce = Productivity Powerhouse',
            content: 'The deep integration between Slack and Salesforce\'s new AI agents is officially here! It\'s amazing to see how much work we can get done without even leaving our channels.',
            key: 'slack_post'
        },
        {
            subreddit: 'Tableau',
            author: 'DataViz_Pro',
            title: 'Tableau Next is looking sharp!',
            content: 'The new visualization enhancements in Tableau Next are exactly what we needed. Data storytelling just got a whole lot more intuitive and powerful!',
            key: 'tableau_post'
        },
        {
            subreddit: 'technology',
            author: 'Innovation_Hunter',
            title: 'Salesforce\'s Latest Release Cycle is Massive',
            content: 'From Agentforce to Tableau Next, the sheer scale of the new Salesforce releases is impressive. It\'s a great time to be in the ecosystem!',
            key: 'technology_post'
        },
        {
            subreddit: 'salesforce',
            author: 'Cloud_Architect_Sam',
            title: 'The Power of the Unified Platform',
            content: 'Seeing Agentforce, Slack, and MCP working together so seamlessly is a dream come true for architects. The synergy in this latest release is top-tier!',
            key: 'platform_post'
        }
    ];

    sampleComments = [
        {
            postKey: 'agentforce_post',
            author: 'AI_Enthusiast_Jen',
            content: 'The autonomy factor is really what sets this apart. I can\'t wait to see how the reasoning engine handles complex multi-step cases in production!'
        },
        {
            postKey: 'mcp_post',
            author: 'Strategy_Steve',
            content: 'Totally agree! The real-time orchestration in MCP is a huge leap forward. It\'s finally making 1-to-1 personalization feel manageable at scale.'
        },
        {
            postKey: 'slack_post',
            author: 'Remote_Work_Rick',
            content: 'Having Agentforce built directly into the Slack UI is going to save my team hours of context switching every week. Slack really is becoming the OS for the enterprise.'
        },
        {
            postKey: 'tableau_post',
            author: 'Insight_Ivy',
            content: 'Those viz enhancements are gorgeous! Tableau Next seems much more focused on the end-user experience, which should help with internal adoption.'
        }
    ];

    demoUtterances = [
        'I\'m doing some research on the latest ecosystem trends. Can you show me the newest posts from r/salesforce? I want to see what people are saying about the new platform releases.',
        'That post about the \'Unified Platform\' by Cloud_Architect_Sam looks interesting. Can you pull up the full details and show me any comments on it?',
        'What\'s the latest buzz in the r/Slack community regarding Salesforce? Give me a quick summary of the top post.'
    ];

    async handleSendPosts() {
        this.isLoadingPosts = true;
        this.postResults = [];
        this.createdPostIds = {};

        try {
            for (const post of this.samplePosts) {
                const result = await invokeMCPTool({
                    toolName: 'create_post',
                    parameters: {
                        subreddit: post.subreddit,
                        title: post.title,
                        content: post.content,
                        author: post.author
                    }
                });

                if (result.success) {
                    // Store the post ID for later comment creation
                    const postData = result.data?.result?.content?.[0]?.text;
                    if (postData) {
                        try {
                            const parsed = JSON.parse(postData);
                            this.createdPostIds[post.key] = parsed.id;
                        } catch (e) {
                            console.error('Error parsing post result:', e);
                        }
                    }
                    this.postResults.push(`✓ Created: "${post.title}" in r/${post.subreddit}`);
                } else {
                    this.postResults.push(`✗ Failed: "${post.title}" - ${result.error}`);
                }
            }

            this.showToast('Success', `Created ${this.samplePosts.length} sample posts!`, 'success');
        } catch (error) {
            this.showToast('Error', 'Error creating posts: ' + this.getErrorMessage(error), 'error');
        } finally {
            this.isLoadingPosts = false;
        }
    }

    async handleSendComments() {
        this.isLoadingComments = true;

        if (Object.keys(this.createdPostIds).length === 0) {
            this.showToast('Warning', 'Please create posts first before adding comments!', 'warning');
            this.isLoadingComments = false;
            return;
        }

        try {
            let successCount = 0;
            for (const comment of this.sampleComments) {
                const postId = this.createdPostIds[comment.postKey];
                if (!postId) {
                    console.warn(`No post ID found for key: ${comment.postKey}`);
                    continue;
                }

                const result = await invokeMCPTool({
                    toolName: 'create_comment',
                    parameters: {
                        post_id: postId,
                        content: comment.content,
                        author: comment.author
                    }
                });

                if (result.success) {
                    successCount++;
                }
            }

            this.showToast('Success', `Created ${successCount} comments!`, 'success');
        } catch (error) {
            this.showToast('Error', 'Error creating comments: ' + this.getErrorMessage(error), 'error');
        } finally {
            this.isLoadingComments = false;
        }
    }

    handleCopyUtterance(event) {
        const index = event.target.dataset.index;
        const utterance = this.demoUtterances[index];

        navigator.clipboard.writeText(utterance).then(() => {
            this.showToast('Copied!', 'Demo utterance copied to clipboard', 'success');
        }).catch(() => {
            this.showToast('Error', 'Failed to copy to clipboard', 'error');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    getErrorMessage(error) {
        if (error.body?.message) return error.body.message;
        if (error.message) return error.message;
        return String(error);
    }

    get hasPostResults() {
        return this.postResults.length > 0;
    }
}
