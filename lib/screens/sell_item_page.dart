import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/gemini_vision_service.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  File? _selectedImage;
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _geminiVisionService = GeminiVisionService();
  _AnalysisStatus _analysisStatus = _AnalysisStatus.idle;
  String? _analysisMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _geminiVisionService.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _selectedImage = File(image.path);
      _analysisStatus = _AnalysisStatus.idle;
      _analysisMessage = null;
    });
  }

  Future<void> _generateSuggestions() async {
    final image = _selectedImage;
    if (image == null) {
      _setAnalysisError('กรุณาเลือกรูปภาพสินค้าก่อนให้ AI ช่วยแนะนำ');
      return;
    }

    setState(() {
      _analysisStatus = _AnalysisStatus.loading;
      _analysisMessage = null;
    });

    try {
      final suggestion = await _geminiVisionService.analyzeProductImage(image);
      if (!mounted) return;
      setState(() {
        _nameController.text = suggestion.title;
        _categoryController.text = suggestion.category;
        _descriptionController.text = suggestion.description;
        _analysisStatus = _AnalysisStatus.success;
        _analysisMessage = 'วิเคราะห์ภาพสำเร็จ';
      });
    } on SocketException {
      _setAnalysisError('เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาลองอีกครั้ง');
    } on GeminiVisionException catch (error) {
      _setAnalysisError('วิเคราะห์ภาพไม่สำเร็จ: ${error.message}');
    } on TimeoutException {
      _setAnalysisError('Gemini API ใช้เวลานานเกินไป กรุณาลองอีกครั้ง');
    } on FormatException {
      _setAnalysisError('ได้รับข้อมูลจาก Gemini API ในรูปแบบที่ไม่ถูกต้อง');
    } on FileSystemException {
      _setAnalysisError('อ่านรูปภาพไม่สำเร็จ กรุณาเลือกรูปใหม่');
    } on Exception catch (error) {
      _setAnalysisError('เกิดข้อผิดพลาดในการวิเคราะห์ภาพ: $error');
    }
  }

  void _setAnalysisError(String message) {
    if (!mounted) return;
    setState(() {
      _analysisStatus = _AnalysisStatus.error;
      _analysisMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลงประกาศขายสินค้า')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _selectedImage == null
                    ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                      )
                    : Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('เลือกรูปภาพสินค้า'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อสินค้า',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'หมวดหมู่สินค้า',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'รายละเอียดสินค้า',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _analysisStatus == _AnalysisStatus.loading
                    ? null
                    : _generateSuggestions,
                child: _analysisStatus == _AnalysisStatus.loading
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('AI กำลังวิเคราะห์ภาพสินค้า...'),
                        ],
                      )
                    : const Text('ให้ AI ช่วยแนะนำ'),
              ),
              if (_analysisMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _analysisMessage!,
                  style: TextStyle(
                    color: _analysisStatus == _AnalysisStatus.error
                        ? Theme.of(context).colorScheme.error
                        : Colors.green.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _AnalysisStatus { idle, loading, success, error }
