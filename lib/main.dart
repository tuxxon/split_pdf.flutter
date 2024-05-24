import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'split_pdf.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PdfSplitter(),
    );
  }
}

class PdfSplitter extends StatefulWidget {
  const PdfSplitter({super.key});

  @override
  _PdfSplitterState createState() => _PdfSplitterState();
}

class _PdfSplitterState extends State<PdfSplitter> {
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  String? _fileName;
  String? _elapsedTime;
  int? _totalPages;
  List<File> _splitFiles = [];

  @override
  void dispose() {
    _progressNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Splitter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: requestPermissionAndPickPdf,
              child: const Text('Pick PDF'),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 20),
              Text('Selected File: $_fileName'),
            ],
            if (_totalPages != null) ...[
              const SizedBox(height: 20),
              Text('Total Pages: $_totalPages'),
            ],
            if (_elapsedTime != null) ...[
              const SizedBox(height: 20),
              Text('Elapsed Time: $_elapsedTime'),
            ],
            const SizedBox(height: 20),
            ValueListenableBuilder<double>(
              valueListenable: _progressNotifier,
              builder: (context, value, child) {
                return Column(
                  children: [
                    Text('Progress: ${(value * 100).toStringAsFixed(2)}%'),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: value),
                  ],
                );
              },
            ),
            if (_splitFiles.isNotEmpty) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(files: _splitFiles),
                    ),
                  );
                },
                child: const Text('View Split PDFs'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> requestPermissionAndPickPdf() async {
    if (await _requestPermissions()) {
      await pickPdf();
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid && await _isAtLeastAndroid13()) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      return status.isGranted;
    } else {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
  }

  Future<bool> _isAtLeastAndroid13() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getSdkInt();
      return sdkInt != null && sdkInt >= 33;
    }
    return false;
  }

  Future<int?> _getSdkInt() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      print('Failed to get SDK int: $e');
      return null;
    }
  }

  Future<void> pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      setState(() {
        _fileName = file.path.split('/').last;
        _totalPages = null;
        _elapsedTime = null;
        _splitFiles = [];
      });
      await splitPdf(file);
    } else {
      // User canceled the picker
    }
  }

  Future<void> splitPdf(File file) async {
    // 시작 시간 기록
    final startTime = DateTime.now();

    // SplitPdf 인스턴스 생성
    final splitter = SplitPdf();

    // PDF 파일 경로
    final inputPath = file.path;

    // 출력 디렉토리 설정
    final directory = await getApplicationDocumentsDirectory();
    final outputDirectory = directory.path;

    // 출력 파일 접두사 설정
    const outputPrefix = 'page';

    // 진행 상황 콜백
    void progressCallback(int currentPage, int totalPages) {
      if (mounted) {
        _progressNotifier.value = currentPage / totalPages;
      }
    }

    // PDF 분할
    splitter.splitPdf(
        inputPath, outputDirectory, outputPrefix, progressCallback);

    // 페이지 수 가져오기
    final totalPages = splitter.getPageCount();

    if (totalPages > 0) {
      // 출력된 파일 목록 업데이트
      final splitFiles = List<File>.generate(
        totalPages,
        (index) => File('$outputDirectory/${outputPrefix}_${index + 1}.pdf'),
      );

      if (mounted) {
        setState(() {
          _splitFiles = splitFiles;
          _totalPages = totalPages;
        });
      }
    }

    // 경과 시간 계산
    final endTime = DateTime.now();
    final elapsed = endTime.difference(startTime);
    if (mounted) {
      setState(() {
        _elapsedTime = '${elapsed.inSeconds} seconds';
      });
    }
  }
}

class PdfViewerScreen extends StatelessWidget {
  final List<File> files;

  const PdfViewerScreen({required this.files, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split PDFs'),
      ),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Page ${index + 1}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfViewer(file: files[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PdfViewer extends StatelessWidget {
  final File file;

  const PdfViewer({required this.file, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.path.split('/').last),
      ),
      body: SfPdfViewer.file(file),
    );
  }
}
