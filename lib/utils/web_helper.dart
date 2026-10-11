import 'dart:html' as html;
import 'dart:typed_data';

/// Opens a file in a new browser tab using a blob URL.
void viewFileBytes(Uint8List? bytes, String name) {
  if (bytes == null) return;
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}

/// Triggers a browser download of PDF bytes.
void downloadPdf(String fileName, List<int> bytes) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
