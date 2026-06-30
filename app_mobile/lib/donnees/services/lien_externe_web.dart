import 'dart:html' as html;

bool ouvrirLienExterne(String url) {
  html.window.open(url, '_blank');
  return true;
}
