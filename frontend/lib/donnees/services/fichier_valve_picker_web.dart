import 'dart:async';
import 'dart:html' as html;

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
  input.style.display = 'none';
  html.document.body?.append(input);

  input.onChange.first.then((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      input.remove();
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files.first;
    final reader = html.FileReader();

    reader.onError.first.then((_) {
      input.remove();
      if (!completer.isCompleted) completer.complete(null);
    });

    reader.onLoad.first.then((_) {
      final result = reader.result;
      if (result is! String || result.trim().isEmpty) {
        input.remove();
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      input.remove();
      if (!completer.isCompleted) {
        completer.complete(
          ValveAttachmentFile(
            fileName: file.name,
            base64Content: result,
            size: file.size,
          ),
        );
      }
    });

    reader.readAsDataUrl(file);
  });

  input.click();

  return completer.future.timeout(
    const Duration(minutes: 2),
    onTimeout: () {
      input.remove();
      return null;
    },
  );
}
