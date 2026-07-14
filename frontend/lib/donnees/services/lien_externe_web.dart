import 'dart:html' as html;

bool ouvrirLienExterne(String url) {
  html.window.open(url, '_blank');
  return true;
}

Future<bool> telechargerOctets({
  required List<int> octets,
  required String nomFichier,
}) async {
  final blob = html.Blob([octets], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final ancre = html.AnchorElement(href: url)
    ..download = nomFichier
    ..style.display = 'none';
  html.document.body?.children.add(ancre);
  ancre.click();
  ancre.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}
