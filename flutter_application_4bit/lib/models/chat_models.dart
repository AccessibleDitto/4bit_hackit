import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUserMessage;

  const ChatMessage({
    super.key,
    required this.text,
    this.isUserMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CrossAxisAlignment crossAxisAlignment =
        isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: isUserMessage
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.tertiaryContainer,
            borderRadius: isUserMessage
                ? const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(0.0),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(0.0),
                    topRight: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                  ),
          ),
          child: Text(
            text,
            style: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class ErrorMessage extends ChatMessage {
  const ErrorMessage({super.key, required super.text});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0.0),
              topRight: Radius.circular(8.0),
              bottomLeft: Radius.circular(8.0),
              bottomRight: Radius.circular(8.0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}