import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/core/models/user_model.dart';

/// アプリ全体で参照するログイン済みユーザー状態。
final authSessionProvider = StateProvider<UserModel?>((_) => null);
