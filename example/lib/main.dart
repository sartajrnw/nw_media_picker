import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nw_media_picker/nw_media_picker.dart';

void main() {
  // Optional: plug in analytics callbacks / a custom logger app-wide.
  NWMediaPicker.configure(
    callbacks: MediaPickerCallbacks(
      onCameraOpened: () => debugPrint('[demo] camera opened'),
      onCaptureCompleted: (r) => debugPrint('[demo] captured ${r.path}'),
      onGallerySelected: (r) => debugPrint('[demo] selected ${r.length}'),
    ),
  );
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NW Media Picker',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFD4212A),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MediaResult? _result;
  List<MediaResult> _multiResults = const [];
  String? _status;
  bool _busy = false;

  Future<void> _run(
    Future<MediaResult?> Function() action, {
    String? label,
  }) async {
    setState(() {
      _busy = true;
      _status = label;
    });
    try {
      final result = await action();
      if (!mounted) return;
      setState(() {
        _multiResults = const [];
        _result = result;
        _status = result == null ? 'Cancelled' : null;
      });
    } on MediaPickerException catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Error [${e.code.name}]: ${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickImage() => _run(
    () => NWMediaPicker.pickImage(
      context,
      config: const MediaPickerConfig(
        processing: ImageProcessingConfig(
          quality: 85,
          maxWidth: 1600,
          maxHeight: 1600,
        ),
      ),
    ),
    label: 'Pick Image…',
  );

  Future<void> _cropImage() => _run(
    () => NWMediaPicker.pickImage(
      context,
      config: const MediaPickerConfig(
        crop: InteractiveCropConfig(
          toolbarTitle: 'Adjust photo',
        ),
        processing: ImageProcessingConfig(
          quality: 85,
          maxWidth: 1600,
          maxHeight: 1600,
        ),
      ),
    ),
    label: 'Pick & crop…',
  );

  Future<void> _camera() =>
      _run(() => NWMediaPicker.camera(context), label: 'Opening camera…');

  Future<void> _gallery() =>
      _run(() => NWMediaPicker.gallery(), label: 'Opening gallery…');

  Future<void> _profile() => _run(
    () => NWMediaPicker.pickImage(
      context,
      config: MediaPickerPresets.profilePhoto,
    ),
    label: 'Profile preset…',
  );

  Future<void> _product() => _run(
    () => NWMediaPicker.pickImage(
      context,
      config: MediaPickerPresets.productPhoto,
    ),
    label: 'Product preset…',
  );

  Future<void> _customTheme() => _run(
    () => NWMediaPicker.camera(
      context,
      config: const MediaPickerConfig(
        sources: [MediaSource.camera],
        theme: MediaPickerTheme(
          primaryColor: Color(0xFF00E5A0),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          captureButtonSize: 84,
        ),
      ),
    ),
    label: 'Custom theme camera…',
  );

  Future<void> _multiGallery() async {
    setState(() {
      _busy = true;
      _status = 'Multi gallery…';
    });
    try {
      final results = await NWMediaPicker.galleryMultiple(
        config: const MediaPickerConfig(
          gallery: GalleryPickerConfig(allowMultiple: true, maxSelection: 5),
        ),
      );
      if (!mounted) return;
      setState(() {
        _result = null;
        _multiResults = results;
        _status = results.isEmpty ? 'Cancelled' : null;
      });
    } on MediaPickerException catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Error [${e.code.name}]: ${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _capabilities() async {
    final caps = await NWMediaPicker.capabilities();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Capabilities'),
        content: Text(
          'camera: ${caps.camera}\n'
          'gallery: ${caps.gallery}\n'
          'multipleGallerySelection: ${caps.multipleGallerySelection}\n'
          'frontCamera: ${caps.frontCamera}\n'
          'backCamera: ${caps.backCamera}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    final before = await NWMediaPicker.getTemporaryCacheSize();
    await NWMediaPicker.clearTemporaryFiles();
    final after = await NWMediaPicker.getTemporaryCacheSize();
    if (!mounted) return;
    setState(() {
      _status =
          'Cache cleared: '
          '${(before / 1024).toStringAsFixed(1)} KB → '
          '${(after / 1024).toStringAsFixed(1)} KB';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NW Media Picker')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ActionButton('Pick Image', Icons.add_a_photo, _pickImage),
            _ActionButton('Pick & Crop Image', Icons.crop, _cropImage),
            _ActionButton('Take Photo', Icons.photo_camera, _camera),
            _ActionButton(
              'Choose Gallery Image',
              Icons.photo_library,
              _gallery,
            ),
            _ActionButton(
              'Multi Gallery (max 5)',
              Icons.collections,
              _multiGallery,
            ),
            _ActionButton('Profile Example', Icons.person, _profile),
            _ActionButton('Product Example', Icons.shopping_bag, _product),
            _ActionButton('Custom Theme Camera', Icons.palette, _customTheme),
            _ActionButton('Capability Test', Icons.info_outline, _capabilities),
            _ActionButton('Clear Cache', Icons.delete_outline, _clearCache),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _status!,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            if (_result != null) _ResultCard(result: _result!),
            for (final r in _multiResults) _ResultCard(result: r),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton(this.label, this.icon, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Align(alignment: Alignment.centerLeft, child: Text(label)),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final MediaResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result.exists)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: Image.file(File(result.path), fit: BoxFit.contain),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Source', result.source.name),
                _row('Dimensions', '${result.width} × ${result.height}'),
                _row(
                  'Size',
                  result.sizeBytes == null
                      ? 'unknown'
                      : '${(result.sizeBytes! / 1024).toStringAsFixed(1)} KB',
                ),
                _row('MIME', result.mimeType ?? 'unknown'),
                _row('Path', result.path),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(k, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
