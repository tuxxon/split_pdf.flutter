import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef ProgressCallbackNative = Void Function(
    Int32 currentPage, Int32 totalPages);

typedef SplitPdfNative = Void Function(
    Pointer<Utf8> inputFilename,
    Pointer<Utf8> outputDirectory,
    Pointer<Utf8> outputPrefix,
    Pointer<NativeFunction<ProgressCallbackNative>> progressCallback);
typedef SplitPdfDart = void Function(
    Pointer<Utf8> inputFilename,
    Pointer<Utf8> outputDirectory,
    Pointer<Utf8> outputPrefix,
    Pointer<NativeFunction<ProgressCallbackNative>> progressCallback);

typedef GetPageCountNative = Int32 Function();
typedef GetPageCountDart = int Function();

class SplitPdf {
  late DynamicLibrary _lib;
  late SplitPdfDart _splitPdf;
  late GetPageCountDart _getPageCount;
  static late Pointer<NativeFunction<ProgressCallbackNative>> nativeCallback;
  static Function(int, int)? progressCallback;

  SplitPdf() {
    if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libsplit_pdf.so');
    } else if (Platform.isIOS) {
      _lib = DynamicLibrary.process(); // iOS에서는 process() 사용
    }

    _splitPdf = _lib
        .lookup<NativeFunction<SplitPdfNative>>('split_pdf')
        .asFunction<SplitPdfDart>();
    _getPageCount = _lib
        .lookup<NativeFunction<GetPageCountNative>>('get_page_count')
        .asFunction<GetPageCountDart>();

    // 콜백 함수 설정
    nativeCallback =
        Pointer.fromFunction<ProgressCallbackNative>(nativeProgressCallback);
  }

  static void nativeProgressCallback(int currentPage, int totalPages) {
    if (progressCallback != null) {
      progressCallback!(currentPage, totalPages);
    }
  }

  void splitPdf(String inputFilename, String outputDirectory,
      String outputPrefix, Function(int, int) progressCallback) {
    final inputPtr = inputFilename.toNativeUtf8();
    final outputDirPtr = outputDirectory.toNativeUtf8();
    final outputPrefixPtr = outputPrefix.toNativeUtf8();

    // 콜백 함수 설정
    SplitPdf.progressCallback = progressCallback;

    _splitPdf(inputPtr, outputDirPtr, outputPrefixPtr, nativeCallback);

    calloc.free(inputPtr);
    calloc.free(outputDirPtr);
    calloc.free(outputPrefixPtr);
  }

  int getPageCount() {
    return _getPageCount();
  }
}
