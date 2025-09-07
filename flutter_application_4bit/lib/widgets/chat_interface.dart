import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';

class ChatInterface extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;
  
  const ChatInterface({
    Key? key,
    required this.isVisible,
    required this.onClose,
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
      _chatService.addUserMessage(text);
      final response = await _chatService.sendMessage();
      
      if (response.isNotEmpty) {
        _chatService.addAssistantMessage(response);

        ChatMessage responseMessage = ChatMessage(
          text: response,
          isUserMessage: false,
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

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
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
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _clearChat,
                      icon: Icon(Icons.delete, color: Colors.blue.shade800),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: Icon(Icons.close, color: Colors.blue.shade800),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                          'AI is thinking...',
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
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your calendar or anything else...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _handleChatSubmitted,
                    enabled: !_isLoading,
                  ),
                ),
                IconButton(
                  icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.send),
                  onPressed: _isLoading ? null : () => _handleChatSubmitted(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}