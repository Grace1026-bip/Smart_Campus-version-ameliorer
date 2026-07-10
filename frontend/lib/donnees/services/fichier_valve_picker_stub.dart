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

bool get supportsValveFilePicker => false;

Future<ValveAttachmentFile?> choisirFichierValve() async => null;
