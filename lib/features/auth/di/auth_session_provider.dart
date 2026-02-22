import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/core/models/user_model.dart';

/// アプリ全体で参照するログイン済みユーザー状態。
final authSessionProvider = StateProvider<UserModel?>((_) => null);
// StateProviderとProviderの違いは、StateProviderは状態を持つことができるのに対し、Providerは単純な値やオブジェクトを提供するためのものです。StateProviderは、状態を更新するためのnotifierを提供し、その状態を監視することができます。
// 記事→https://www.notion.so/StateProvider-Provider-30f8b8225642807f9f53d78fa9d4d7eb?showMoveTo=true&saveParent=true