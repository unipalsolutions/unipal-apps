import 'package:flutter/material.dart';
import 'package:unipal_api/unipal_api.dart';

/// Loads data with [load] and shows a spinner, an error with retry, or [builder]'s result.
/// Pull to refresh reloads. Call [AsyncViewState.reload] after a write.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future = widget.load();

  Future<void> reload() async {
    final next = widget.load();
    setState(() => _future = next);
    await next.catchError((_) => null as T);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is ApiException && error.status == 403
                        ? 'ليست لديك صلاحية على هذا القسم.'
                        : 'تعذّر تحميل البيانات.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: reload, child: const Text('إعادة المحاولة')),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return RefreshIndicator(onRefresh: reload, child: widget.builder(context, snapshot.data as T, reload));
      },
    );
  }
}
