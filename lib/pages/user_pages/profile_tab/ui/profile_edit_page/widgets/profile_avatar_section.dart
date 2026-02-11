// 自己紹介バナーのUIです。
import 'package:flutter/material.dart';

class ProfileAvatarSection extends StatelessWidget {
  final String editingPhotoUrl;
  final bool isSaving;
  final VoidCallback? onTap; // 💡 タップされた時の処理を外部から受け取る

  const ProfileAvatarSection({
    super.key,
    required this.editingPhotoUrl,
    required this.isSaving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 元のデコレーションをそのまま移植
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.fromARGB(210, 0, 6, 117),
            Color.fromARGB(120, 102, 126, 234),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isSaving ? null : onTap, // 💡 保存中はタップ不可=null
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: editingPhotoUrl.startsWith('http')
                    ? NetworkImage(editingPhotoUrl) as ImageProvider
                    : const AssetImage('assets/image/treatGemini.png'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'プロフィール画像',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isSaving ? 'アップロード中...' : 'タップして画像を変更',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.camera_alt, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}