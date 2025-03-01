import 'package:flutter/material.dart';

void showCustomAlertDialog(BuildContext context, String title, String message,
    {VoidCallback? onConfirm}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text(message),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      actions: [
        if (onConfirm != null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (onConfirm != null) onConfirm();
          },
          child: Text(onConfirm != null ? "OK" : "Close",
              style: const TextStyle(color: Colors.green)),
        ),
      ],
    ),
  );
}

void showSuccessAlert(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Success",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          )),
      content: Text(message),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK", style: TextStyle(color: Colors.green)),
        ),
      ],
    ),
  );
}
