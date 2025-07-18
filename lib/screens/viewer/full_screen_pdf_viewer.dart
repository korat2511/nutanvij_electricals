import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/material.dart';
import 'package:nutanvij_electricals/core/theme/app_colors.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;


class FullScreenPdfViewer extends StatefulWidget {
  final String url;
  final String fileName;
  const FullScreenPdfViewer({required this.url, required this.fileName, Key? key}) : super(key: key);

  @override
  State<FullScreenPdfViewer> createState() => _FullScreenPdfViewerState();
}

class _FullScreenPdfViewerState extends State<FullScreenPdfViewer> {
  String? localPath;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadPdf();
  }

  Future<void> loadPdf() async {
    try {
      final url = widget.url.startsWith('http') ? widget.url : 'https://nutanvij.com/public/${widget.url}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.fileName}');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          localPath = file.path;
          loading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load PDF (${response.statusCode})';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load PDF: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(widget.fileName, style: const TextStyle(color: AppColors.primary)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : localPath != null
                  ? PDFView(
                      filePath: localPath!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: true,
                      pageFling: true,
                    )
                  : const Center(child: Text('PDF not available')),
    );
  }
}