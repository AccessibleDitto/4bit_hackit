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

// Updated ChatInterface with history integration
class _ChatInterfaceState extends State<ChatInterface> {
  bool _isLoading = false;
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    // Load any existing chat history from the tool service
    if (widget.toolService != null) {
      _loadHistoryFromToolService();
    }
  }

  void _loadHistoryFromToolService() {
    if (widget.toolService == null) return;
    
    final history = widget.toolService!.getChatHistory();
    for (final entry in history) {
      _messages.add(ChatMessage(
        text: entry.userMessage,
        isUserMessage: true,
      ));
      
      _messages.add(ChatMessage(
        text: entry.assistantResponse,
        isUserMessage: false,
      ));
    }
    
    if (mounted && _messages.isNotEmpty) {
      setState(() {});
      _scrollToBottomWithDelay(const Duration(milliseconds: 100));
    }
  }

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

  Widget _buildResponseWidget(ChatResponse response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Caption (if any)
        if (response.caption != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              response.caption!,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],

        // Main text
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            response.text,
            style: const TextStyle(fontSize: 16),
          ),
        ),

        // Optional widgets
        if (response.taskWidget != null) response.taskWidget!,
        if (response.eventWidget != null) response.eventWidget!,
        if (response.taskListWidget != null) response.taskListWidget!,
        if (response.eventListWidget != null) response.eventListWidget!,
        if (response.schedulingResultWidget != null) response.schedulingResultWidget!,
        if (response.summaryWidget != null) response.summaryWidget!,
      ],
    );
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
      // Also clear tool service history
      if (widget.toolService != null) {
        widget.toolService!.clearChatHistory();
      }
    });
  }

  // Enhanced quick actions with contextual suggestions
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Standard actions
          Wrap(
            spacing: 8,
            runSpacing: 4,
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
              _buildQuickActionChip(
                "Create event",
                Icons.event,
                () => _handleChatSubmitted("Create a new calendar event"),
              ),
              _buildQuickActionChip(
                "Update task",
                Icons.edit_note,
                () => _handleChatSubmitted("Find a task to update"),
              ),
              _buildQuickActionChip(
                "Update event",
                Icons.edit_calendar,
                () => _handleChatSubmitted("Find an event to update"),
              ),
            ],
          ),
          
          // Contextual suggestions based on recent history
          if (widget.toolService != null) _buildContextualSuggestions(),
        ],
      ),
    );
  }

  Widget _buildContextualSuggestions() {
    final history = widget.toolService!.getChatHistory();
    if (history.isEmpty) return const SizedBox.shrink();

    // Get the last successful action
    final lastSuccessful = history.reversed.firstWhere(
      (entry) => entry.success,
      orElse: () => history.last,
    );

    if (!lastSuccessful.success) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          "Quick follow-ups:",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 2,
          children: _getContextualChips(lastSuccessful),
        ),
      ],
    );
  }

  List<Widget> _getContextualChips(ChatHistoryEntry lastAction) {
    final chips = <Widget>[];

    switch (lastAction.toolUsed) {
      case 'create_task':
        chips.addAll([
          _buildSmallActionChip(
            "Update it",
            Icons.edit,
            () => _handleChatSubmitted("Update that task"),
          ),
          _buildSmallActionChip(
            "Schedule it",
            Icons.schedule,
            () => _handleChatSubmitted("Schedule that task"),
          ),
        ]);
        break;
      case 'create_event':
        chips.addAll([
          _buildSmallActionChip(
            "Update it",
            Icons.edit,
            () => _handleChatSubmitted("Update that event"),
          ),
          _buildSmallActionChip(
            "Reschedule it",
            Icons.access_time,
            () => _handleChatSubmitted("Reschedule that event"),
          ),
        ]);
        break;
      case 'get_tasks':
        chips.addAll([
          _buildSmallActionChip(
            "Schedule them",
            Icons.schedule,
            () => _handleChatSubmitted("Schedule those unscheduled tasks"),
          ),
          _buildSmallActionChip(
            "Update one",
            Icons.edit,
            () => _handleChatSubmitted("Update a task from that list"),
          ),
        ]);
        break;
      case 'schedule_tasks':
        chips.addAll([
          _buildSmallActionChip(
            "Show result",
            Icons.visibility,
            () => _handleChatSubmitted("Show me the scheduled tasks"),
          ),
          _buildSmallActionChip(
            "Reschedule",
            Icons.refresh,
            () => _handleChatSubmitted("Reschedule some tasks"),
          ),
        ]);
        break;
    }

    return chips;
  }

  Widget _buildQuickActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: _isLoading ? null : onTap,
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: Colors.blue.shade200),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildSmallActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: _isLoading ? null : onTap,
      backgroundColor: Colors.orange.shade50,
      side: BorderSide(color: Colors.orange.shade200),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Container(
      height: MediaQuery.of(context).size.height,
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
          // Enhanced chat header with history info
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.toolService != null)
                          Text(
                            'Enhanced with tool calling',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        if (widget.toolService != null && _messages.isNotEmpty) ...[
                          // Text(" • ", style: TextStyle(color: Colors.blue.shade600)),
                          Text(
                            '${(_messages.length / 2).ceil()} exchanges',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Quick Actions Dropdown
                    if (widget.toolService != null && _messages.length < 6)
                      PopupMenuButton<String>(
                        onSelected: (String action) {
                          _handleQuickAction(action);
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'create_task',
                            child: Row(
                              children: [
                                Icon(Icons.add_task, size: 18),
                                SizedBox(width: 8),
                                Text('Create a task'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'schedule_meeting',
                            child: Row(
                              children: [
                                Icon(Icons.event, size: 18),
                                SizedBox(width: 8),
                                Text('Schedule meeting'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'view_today',
                            child: Row(
                              children: [
                                Icon(Icons.today, size: 18),
                                SizedBox(width: 8),
                                Text('View today\'s agenda'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'set_reminder',
                            child: Row(
                              children: [
                                Icon(Icons.alarm, size: 18),
                                SizedBox(width: 8),
                                Text('Set reminder'),
                              ],
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.flash_on,
                          color: Colors.blue.shade800,
                        ),
                        tooltip: 'Quick actions',
                      ),
                    if (_messages.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          if (widget.toolService != null) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Recent Actions'),
                                content: Text(widget.toolService!.getRecentActionsSummary()),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.history, color: Colors.blue.shade800),
                        tooltip: 'View recent actions',
                      ),
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
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, int index) {
                if (index == _messages.length && _isLoading) {
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
                        ? (_messages.isEmpty 
                            ? 'Ask me to create tasks, schedule events, or manage your calendar...'
                            : 'Continue our conversation...')
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

  // Add this method to handle quick action selections
  void _handleQuickAction(String action) {
    String message = '';
    switch (action) {
      case 'create_task':
        message = 'Help me create a new task';
        break;
      case 'schedule_meeting':
        message = 'Help me schedule a meeting';
        break;
      case 'view_today':
        message = 'Show me today\'s agenda';
        break;
      case 'set_reminder':
        message = 'Help me set a reminder';
        break;
    }
    
    if (message.isNotEmpty) {
      _textController.text = message;
      _handleChatSubmitted(message);
    }
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