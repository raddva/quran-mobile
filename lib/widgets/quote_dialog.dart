import 'package:flutter/material.dart';

class QuoteDialog extends StatefulWidget {
  final String? initialQuote;
  final String? initialSubtitle;
  final void Function(String quote, String subtitle) onSubmit;

  const QuoteDialog({
    super.key,
    this.initialQuote,
    this.initialSubtitle,
    required this.onSubmit,
  });

  @override
  State<QuoteDialog> createState() => _QuoteDialogState();
}

class _QuoteDialogState extends State<QuoteDialog> {
  late TextEditingController _quoteController;
  late TextEditingController _subtitleController;

  @override
  void initState() {
    super.initState();
    _quoteController = TextEditingController(text: widget.initialQuote ?? '');
    _subtitleController =
        TextEditingController(text: widget.initialSubtitle ?? '');
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialQuote == null ? 'Add Quote' : 'Edit Quote'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _quoteController,
            decoration: const InputDecoration(labelText: 'Quote'),
          ),
          TextField(
            controller: _subtitleController,
            decoration: const InputDecoration(labelText: 'Subtitle'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(
              _quoteController.text,
              _subtitleController.text,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
