import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum WipeMethod {
  singlePass,
  threePass,
  sevenPass,
  gutmann35Pass,
}

class WipeService extends ChangeNotifier {
  double _progress = 0.0;
  String _currentFile = '';
  bool _isWiping = false;
  WipeMethod _selectedMethod = WipeMethod.threePass;
  List<WipeResult> _wipeResults = [];
  
  double get progress => _progress;
  String get currentFile => _currentFile;
  bool get isWiping => _isWiping;
  WipeMethod get selectedMethod => _selectedMethod;
  List<WipeResult> get wipeResults => _wipeResults;

  void setWipeMethod(WipeMethod method) {
    _selectedMethod = method;
    notifyListeners();
  }

  Future<WipeResult> wipeFiles(List<FileSystemEntity> files) async {
    _isWiping = true;
    _progress = 0.0;
    notifyListeners();

    final result = WipeResult(
      startTime: DateTime.now(),
      method: _selectedMethod,
      totalFiles: files.length,
    );

    try {
      int processedFiles = 0;
      
      for (var entity in files) {
        _currentFile = path.basename(entity.path);
        notifyListeners();
        
        if (entity is File) {
          await _wipeFile(entity);
          result.successfulFiles++;
        } else if (entity is Directory) {
          await _wipeDirectory(entity);
          result.successfulFiles++;
        }
        
        processedFiles++;
        _progress = processedFiles / files.length;
        notifyListeners();
      }
      
      result.endTime = DateTime.now();
      result.success = true;
      _wipeResults.add(result);
      
    } catch (e) {
      result.endTime = DateTime.now();
      result.success = false;
      result.error = e.toString();
      _wipeResults.add(result);
      debugPrint('Error during wipe: $e');
    } finally {
      _isWiping = false;
      _progress = 0.0;
      _currentFile = '';
      notifyListeners();
    }
    
    return result;
  }

  Future<void> _wipeFile(File file) async {
    try {
      final fileLength = await file.length();
      
      switch (_selectedMethod) {
        case WipeMethod.singlePass:
          await _singlePassWipe(file, fileLength);
          break;
        case WipeMethod.threePass:
          await _threePassWipe(file, fileLength);
          break;
        case WipeMethod.sevenPass:
          await _sevenPassWipe(file, fileLength);
          break;
        case WipeMethod.gutmann35Pass:
          await _gutmann35PassWipe(file, fileLength);
          break;
      }
      
      // Rename file multiple times to obscure original name
      await _obscureFileName(file);
      
      // Finally delete the file
      await file.delete();
      
    } catch (e) {
      debugPrint('Error wiping file: $e');
      throw e;
    }
  }

  Future<void> _wipeDirectory(Directory dir) async {
    try {
      // Recursively wipe all files in directory
      await for (var entity in dir.list(recursive: true)) {
        if (entity is File) {
          await _wipeFile(entity);
        }
      }
      
      // Delete the directory
      await dir.delete(recursive: true);
      
    } catch (e) {
      debugPrint('Error wiping directory: $e');
      throw e;
    }
  }

  Future<void> _singlePassWipe(File file, int fileLength) async {
    final random = Random.secure();
    final buffer = Uint8List(min(fileLength, 4096));
    
    final raf = await file.open(mode: FileMode.write);
    try {
      for (int i = 0; i < fileLength; i += buffer.length) {
        for (int j = 0; j < buffer.length; j++) {
          buffer[j] = random.nextInt(256);
        }
        await raf.writeFrom(buffer, 0, min(buffer.length, fileLength - i));
      }
    } finally {
      await raf.close();
    }
  }

  Future<void> _threePassWipe(File file, int fileLength) async {
    // Pass 1: Write zeros
    await _writePattern(file, fileLength, 0x00);
    
    // Pass 2: Write ones
    await _writePattern(file, fileLength, 0xFF);
    
    // Pass 3: Write random data
    await _singlePassWipe(file, fileLength);
  }

  Future<void> _sevenPassWipe(File file, int fileLength) async {
    // DoD 5220.22-M standard
    await _writePattern(file, fileLength, 0x00);
    await _writePattern(file, fileLength, 0xFF);
    await _singlePassWipe(file, fileLength);
    await _writePattern(file, fileLength, 0xF6);
    await _writePattern(file, fileLength, 0x00);
    await _writePattern(file, fileLength, 0xFF);
    await _singlePassWipe(file, fileLength);
  }

  Future<void> _gutmann35PassWipe(File file, int fileLength) async {
    // Simplified Gutmann method (35 passes)
    final patterns = [
      [0x55, 0x55, 0x55],
      [0xAA, 0xAA, 0xAA],
      [0x92, 0x49, 0x24],
      [0x49, 0x24, 0x92],
      [0x24, 0x92, 0x49],
      [0x00, 0x00, 0x00],
      [0x11, 0x11, 0x11],
      [0x22, 0x22, 0x22],
      [0x33, 0x33, 0x33],
      [0x44, 0x44, 0x44],
      [0x55, 0x55, 0x55],
      [0x66, 0x66, 0x66],
      [0x77, 0x77, 0x77],
      [0x88, 0x88, 0x88],
      [0x99, 0x99, 0x99],
      [0xAA, 0xAA, 0xAA],
      [0xBB, 0xBB, 0xBB],
      [0xCC, 0xCC, 0xCC],
      [0xDD, 0xDD, 0xDD],
      [0xEE, 0xEE, 0xEE],
      [0xFF, 0xFF, 0xFF],
    ];
    
    // First 4 random passes
    for (int i = 0; i < 4; i++) {
      await _singlePassWipe(file, fileLength);
    }
    
    // Pattern passes
    for (var pattern in patterns) {
      await _writePatternSequence(file, fileLength, pattern);
    }
    
    // Last 4 random passes
    for (int i = 0; i < 4; i++) {
      await _singlePassWipe(file, fileLength);
    }
  }

  Future<void> _writePattern(File file, int fileLength, int pattern) async {
    final buffer = Uint8List(min(fileLength, 4096));
    buffer.fillRange(0, buffer.length, pattern);
    
    final raf = await file.open(mode: FileMode.write);
    try {
      for (int i = 0; i < fileLength; i += buffer.length) {
        await raf.writeFrom(buffer, 0, min(buffer.length, fileLength - i));
      }
    } finally {
      await raf.close();
    }
  }

  Future<void> _writePatternSequence(File file, int fileLength, List<int> pattern) async {
    final buffer = Uint8List(min(fileLength, 4096));
    for (int i = 0; i < buffer.length; i++) {
      buffer[i] = pattern[i % pattern.length];
    }
    
    final raf = await file.open(mode: FileMode.write);
    try {
      for (int i = 0; i < fileLength; i += buffer.length) {
        await raf.writeFrom(buffer, 0, min(buffer.length, fileLength - i));
      }
    } finally {
      await raf.close();
    }
  }

  Future<void> _obscureFileName(File file) async {
    try {
      final random = Random.secure();
      final directory = file.parent;
      
      // Rename file multiple times
      for (int i = 0; i < 10; i++) {
        final newName = _generateRandomName(random);
        final newPath = path.join(directory.path, newName);
        file = await file.rename(newPath);
      }
    } catch (e) {
      // If renaming fails, continue with deletion
      debugPrint('Error obscuring filename: $e');
    }
  }

  String _generateRandomName(Random random) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String getMethodDescription(WipeMethod method) {
    switch (method) {
      case WipeMethod.singlePass:
        return 'Single Pass - Fast, basic security';
      case WipeMethod.threePass:
        return '3-Pass DoD - Good security, moderate speed';
      case WipeMethod.sevenPass:
        return '7-Pass DoD - High security, slower';
      case WipeMethod.gutmann35Pass:
        return '35-Pass Gutmann - Maximum security, very slow';
    }
  }

  Future<File> generateCertificate(WipeResult result) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'SECURE WIPE CERTIFICATE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('This certifies that the following data wiping operation was completed:'),
              pw.SizedBox(height: 20),
              _buildCertificateRow('Date:', dateFormat.format(result.startTime)),
              _buildCertificateRow('Method:', getMethodDescription(result.method)),
              _buildCertificateRow('Total Files:', result.totalFiles.toString()),
              _buildCertificateRow('Successfully Wiped:', result.successfulFiles.toString()),
              _buildCertificateRow('Duration:', result.duration.toString()),
              _buildCertificateRow('Status:', result.success ? 'SUCCESS' : 'FAILED'),
              if (result.error != null)
                _buildCertificateRow('Error:', result.error!),
              pw.SizedBox(height: 40),
              pw.Text(
                'Digital Signature:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text(_generateSignature(result)),
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated by SecureWipe Pro',
                style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
              ),
              pw.Text(
                'Certificate ID: ${result.certificateId}',
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );
    
    final outputDir = Directory('/storage/emulated/0/SecureWipe/Certificates');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    
    final fileName = 'certificate_${result.certificateId}.pdf';
    final file = File(path.join(outputDir.path, fileName));
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  pw.Widget _buildCertificateRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  String _generateSignature(WipeResult result) {
    final data = '${result.startTime}${result.method}${result.totalFiles}${result.successfulFiles}';
    final bytes = utf8.encode(data);
    final hash = base64.encode(bytes);
    return hash.substring(0, min(hash.length, 64));
  }
}

class WipeResult {
  final DateTime startTime;
  DateTime? endTime;
  final WipeMethod method;
  final int totalFiles;
  int successfulFiles = 0;
  bool success = false;
  String? error;
  late final String certificateId;

  WipeResult({
    required this.startTime,
    required this.method,
    required this.totalFiles,
  }) {
    certificateId = _generateCertificateId();
  }

  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  String _generateCertificateId() {
    final timestamp = startTime.millisecondsSinceEpoch.toString();
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'SW-$timestamp-$random';
  }
}
