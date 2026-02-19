// abstract class（抽象クラス）: 「この設計図を使ってね」という緩いルール。誰がどこで継承してもOK。

// sealed class（封印されたクラス）: 「サブクラスはこのファイル内に書かれたものだけ！」という強い制限。

sealed class MessageContent{} // ドメイン定義

final class TextContent extends MessageContent {
  final String text;// ドメイン定義
  TextContent(this.text);
}

final class ImageContent extends MessageContent {
  final String fileName;      // ドメイン定義
  final int sizeInBytes;      // ドメイン定義
  final int width;            // ドメイン定義
  final int height;           // ドメイン定義

  ImageContent({
    required this.fileName,
    required this.sizeInBytes,
    required this.width,
    required this.height,
  });
}