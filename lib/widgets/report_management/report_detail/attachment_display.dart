import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class AttachmentDisplay extends StatelessWidget {  //widget to display attachment in report detail card,can be image or other file type
  final String attachmentUrl;
  final String attachmentFileName;

  const AttachmentDisplay({
    super.key,
    required this.attachmentUrl,
    required this.attachmentFileName,
  });

  @override
  Widget build(BuildContext context) {
    final String extension = path.extension(attachmentFileName).toLowerCase();
    final bool isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);

    if (isImage) {
      return Image.network(
        attachmentUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, size: 50, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              attachmentFileName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
  }
}