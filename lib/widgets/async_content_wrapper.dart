import 'package:flutter/material.dart';

/// 通用异步内容包装组件，统一处理 loading / empty / error / content 四态。
class AsyncContentWrapper extends StatelessWidget {
  final bool isLoading;
  final bool isEmpty;
  final String? errorMessage;
  final VoidCallback? onRetry;

  final String emptyIconText;
  final String emptyTitle;
  final String emptySubtitle;

  final Widget Function(BuildContext) contentBuilder;

  const AsyncContentWrapper({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    this.errorMessage,
    this.onRetry,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.emptyIconText = '📦',
    required this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
              const SizedBox(height: 12),
              if (onRetry != null)
                OutlinedButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emptyIconText, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(emptyTitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            const SizedBox(height: 4),
            Text(emptySubtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    return contentBuilder(context);
  }
}
