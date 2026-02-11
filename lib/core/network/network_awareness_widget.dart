import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/core/network/connectivity_provider.dart';


class NetworkAwarenessWrapper extends ConsumerWidget {
  final Widget child;
  const NetworkAwarenessWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 ネットワーク状態を監視
    final status = ref.watch(networkStatusProvider).valueOrNull ?? NetworkStatus.online;

    return Column(
      children: [
        // 💡 オフラインの時だけニョキッと出るバー
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: status == NetworkStatus.offline ? 30 : 0,
          color: Colors.redAccent,
          child: const Center(
            child: Text(
              'オフラインモード：接続を確認してください',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}