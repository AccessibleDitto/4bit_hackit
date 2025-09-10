import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../services/chat_tool_service.dart';

class ChatInterface extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;
  final ChatToolCallingService? toolService;
  
  const ChatInterface({
    Key? key,
    required this.isVisible,
    required this.onClose,
    this.toolService,
  }) : super(key: key);

  @override
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  bool _isLoading = false;
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  void _handleChatSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    
    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      isUserMessage: true,
    );
    setState(() {
      _messages.add(message);
    });

    _scrollToBottomWithDelay(const Duration(milliseconds: 200));
    await _sendMessage(text);
  }

  Future<void> _sendMessage(String text) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String response = '';
      Widget? responseWidget;
      
      // Try tool calling first if service is available
      if (widget.toolService != null) {
        final toolResponse = await widget.toolService!.processNaturalLanguage(text);
        
        if (toolResponse.success) {
          response = toolResponse.text;
          responseWidget = _buildResponseWidget(toolResponse);
        } else {
          // Fallback to regular chat if tool calling fails
          _chatService.addUserMessage(text);
          response = await _chatService.sendMessage();
        }
      } else {
        // Regular chat service
        _chatService.addUserMessage(text);
        response = await _chatService.sendMessage();
      }
      
      if (response.isNotEmpty) {
        _chatService.addAssistantMessage(response);

        ChatMessage responseMessage = EnhancedChatMessage(
          text: response,
          isUserMessage: false,
          widget: responseWidget,
        );

        setState(() {
          _messages.add(responseMessage);
        });
      }
    } catch (error) {
      ErrorMessage errorMessage = ErrorMessage(
        text: 'Failed to get response: ${error.toString()}',
      );

      setState(() {
        _messages.add(errorMessage);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottomWithDelay(const Duration(milliseconds: 300));
    }
  }

  Widget? _buildResponseWidget(ChatResponse toolResponse) {
    if (toolResponse.taskWidget != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: toolResponse.taskWidget,
      );
    } else if (toolResponse.eventWidget != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: toolResponse.eventWidget,
      );
    } else if (toolResponse.taskListWidget != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: toolResponse.taskListWidget,
      );
    } else if (toolResponse.eventListWidget != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: toolResponse.eventListWidget,
      );
    } else if (toolResponse.schedulingResultWidget != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: toolResponse.schedulingResultWidget,
      );
    } else if (toolResponse.summaryWidget != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: toolResponse.summaryWidget,
      );
    }
    return null;
  }

  _scrollToBottomWithDelay(Duration delay) async {
    await Future.delayed(delay);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _chatService.clearHistory();
    });
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          _buildQuickActionChip(
            "Schedule tasks",
            Icons.schedule,
            () => _handleChatSubmitted("Schedule my unscheduled tasks"),
          ),
          _buildQuickActionChip(
            "Show tasks",
            Icons.task,
            () => _handleChatSubmitted("Show me all my tasks"),
          ),
          _buildQuickActionChip(
            "Calendar summary",
            Icons.calendar_today,
            () => _handleChatSubmitted("Give me a calendar summary"),
          ),
          _buildQuickActionChip(
            "Create task",
            Icons.add_task,
            () => _handleChatSubmitted("Create a new task"),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: _isLoading ? null : onTap,
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: Colors.blue.shade200),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Container(
      height: MediaQuery.of(context).size.height * 0.6, // Increased height
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Calendar Assistant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    if (widget.toolService != null)
                      Text(
                        'Enhanced with tool calling',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _clearChat,
                      icon: Icon(Icons.delete, color: Colors.blue.shade800),
                      tooltip: 'Clear chat',
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: Icon(Icons.close, color: Colors.blue.shade800),
                      tooltip: 'Close chat',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Quick actions
          if (widget.toolService != null && _messages.isEmpty)
            _buildQuickActions(),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, int index) {
                if (index == _messages.length && _isLoading) {
                  // Loading indicator
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.toolService != null 
                            ? 'AI is processing your request...'
                            : 'AI is thinking...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return _messages[index];
              },
            ),
          ),
          
          // Chat input
          const Divider(height: 1.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: widget.toolService != null 
                        ? 'Ask me to create tasks, schedule events, or manage your calendar...'
                        : 'Ask about your calendar or anything else...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.blue.shade400),
                      ),
                    ),
                    onSubmitted: _handleChatSubmitted,
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey.shade300 : Colors.blue.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isLoading ? Icons.hourglass_empty : Icons.send,
                      color: Colors.white,
                    ),
                    onPressed: _isLoading ? null : () => _handleChatSubmitted(_textController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced chat message that can contain widgets
class EnhancedChatMessage extends ChatMessage {
  final Widget? widget;

  EnhancedChatMessage({
    required String text,
    required bool isUserMessage,
    this.widget,
  }) : super(text: text, isUserMessage: isUserMessage);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) ...[
            Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.blue.shade600,
                radius: 16,
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: isUserMessage ? Colors.blue.shade600 : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUserMessage ? 12 : 4),
                  bottomRight: Radius.circular(isUserMessage ? 4 : 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    text,
                    style: TextStyle(
                      color: isUserMessage ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  if (widget != null) ...[
                    const SizedBox(height: 8),
                    widget!,
                  ],
                ],
              ),
            ),
          ),
          if (isUserMessage) ...[
            Container(
              margin: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade600,
                radius: 16,
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}