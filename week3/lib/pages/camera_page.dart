import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamera'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt), text: 'Live Camera'),
            Tab(icon: Icon(Icons.photo_library), text: 'Image Picker'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _LiveCameraTab(),
          _ImagePickerTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FITUR 1: Live Camera (package: camera)
// ─────────────────────────────────────────────────────────────────────────────
class _LiveCameraTab extends StatefulWidget {
  const _LiveCameraTab();

  @override
  State<_LiveCameraTab> createState() => _LiveCameraTabState();
}

class _LiveCameraTabState extends State<_LiveCameraTab>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  XFile? _capturedPhoto;
  String? _error;
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera({int index = 0}) async {
    setState(() {
      _isInitialized = false;
      _error = null;
    });

    if (!kIsWeb && (!Platform.isAndroid && !Platform.isIOS)) {
      setState(() {
        _error =
            'Live preview kamera belum didukung pada platform Desktop macOS/Windows.\n\nSilakan gunakan tab Image Picker atau jalankan di browser Web / HP (iOS/Android).';
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'Tidak ada perangkat kamera / webcam yang terdeteksi.');
        return;
      }
      await _controller?.dispose();
      _controller = CameraController(
        _cameras[index],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _cameraIndex = index;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Gagal memuat kamera: $e\nPastikan izin kamera browser telah diizinkan.');
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final photo = await _controller!.takePicture();
      setState(() => _capturedPhoto = photo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    _initCamera(index: (_cameraIndex + 1) % _cameras.length);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) _controller?.dispose();
    if (state == AppLifecycleState.resumed) _initCamera(index: _cameraIndex);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_capturedPhoto != null) {
      return Column(
        children: [
          Expanded(
            child: kIsWeb
                ? Image.network(_capturedPhoto!.path, fit: BoxFit.contain)
                : Image.file(File(_capturedPhoto!.path), fit: BoxFit.contain),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _capturedPhoto = null),
                    child: const Text('Ulangi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Foto disimpan!')),
                    ),
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: CameraPreview(_controller!)),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _switchCamera,
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 32),
              ),
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.8),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FITUR 2: Image Picker (package: image_picker)
// ─────────────────────────────────────────────────────────────────────────────
class _ImagePickerTab extends StatefulWidget {
  const _ImagePickerTab();

  @override
  State<_ImagePickerTab> createState() => _ImagePickerTabState();
}

class _ImagePickerTabState extends State<_ImagePickerTab> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file != null && mounted) {
        setState(() => _image = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_image != null) ...[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb
                    ? Image.network(_image!.path, fit: BoxFit.cover, width: double.infinity)
                    : Image.file(File(_image!.path), fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Belum ada gambar',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                ),
              ),
            ],
          ),
          if (_image != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => setState(() => _image = null),
                child: const Text('Hapus Gambar',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
