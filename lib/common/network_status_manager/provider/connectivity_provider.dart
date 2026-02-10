// lib/core/network/connectivity_provider.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

enum NetworkStatus { online, offline }

@riverpod
Stream<NetworkStatus> networkStatus(NetworkStatusRef ref) {
  // 💡 最初の状態を取得するためにStreamの先頭に現在の状態を流す工夫だ
  return Connectivity().onConnectivityChanged.map((results) {
    // 💡 ConnectivityResult.none しか含まれていない場合はオフライン
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    // 💡 Wi-Fi, Mobile, Ethernetなどのいずれかがあればオンライン
    return NetworkStatus.online;
  });
}

// 💡 便利に使うための拡張（Extension）
extension NetworkStatusX on NetworkStatus {
  bool get isOnline => this == NetworkStatus.online;
}