import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

class ValveAttachmentFile {
  const ValveAttachmentFile({
    required this.fileName,
    required this.base64Content,
    required this.size,
  });

  final String fileName;
  final String base64Content;
  final int size;
}

bool get supportsValveFilePicker => true;

Future<ValveAttachmentFile?> choisirFichierValve() {
  final completer = Completer<ValveAttachmentFile?>();
  final input = html.FileUploadInputElement()
    ..accept = '.pdf,.doc,.docx,.ppt,.pptx,.xls,.xlsx,.png,.jpg,.jpeg,.txt,.zip'
    ..multiple = false;

  input.onChange.first.then((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files.first;
    final reader = html.FileReader();

    reader.onError.first.then((_) {
      if (!completer.isCompleted) completer.complete(null);
    });

    reader.onLoad.first.then((_) {
      final result = reader.result;
      if (result is! ByteBuffer) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      final bytes = Uint8List.view(result);
      if (!completer.isCompleted) {
        completer.complete(
          ValveAttachmentFile(
            fileName: file.name,
            base64Content: base64Encode(bytes),
            size: file.size,
          ),
        );
      }
    });

    reader.readAsArrayBuffer(file);
  });

  input.click();

  return completer.future.timeout(
    const Duration(minutes: 2),
    onTimeout: () => null,
  );
}
