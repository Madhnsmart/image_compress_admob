
// Added AdMob initialization
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:toggle_switch/toggle_switch.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Compressor',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFAFCBD5),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData.dark(),
      home: HomeScreen(
          onThemeChanged: _changeTheme, currentThemeMode: _themeMode),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final void Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;
  const HomeScreen(
      {super.key,
      required this.onThemeChanged,
      required this.currentThemeMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? _pickedFile;
  File? _compressedFile;
  bool _isCompressing = false;
  bool _isFileSizeMode = false;
  double _targetSize = 100.0;
  int _quality = 85;
  String _sizeUnit = 'KB';
  String? _error;

  Future<void> _pickImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
        _compressedFile = null;
        _error = null;
      });
    }
  }

  Future<File?> _compressImageByQuality({
    required File file,
    required int quality,
  }) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: quality,
    );

    if (compressed == null) return null;

    final outputFile = File(
        '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}');
    return await outputFile.writeAsBytes(compressed);
  }

  Future<File?> _compressToTargetSize({
    required File file,
    required int targetSizeInBytes,
    int minQuality = 10,
    int maxQuality = 95,
  }) async {
    int quality = maxQuality;
    File? resultFile;

    while (quality >= minQuality) {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: quality,
      );

      if (compressedBytes == null) return null;

      if (compressedBytes.lengthInBytes <= targetSizeInBytes) {
        final outputFile = File(
            '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}');
        return await outputFile.writeAsBytes(compressedBytes);
      }

      resultFile = File(
          '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}');
      await resultFile.writeAsBytes(compressedBytes);

      quality -= 5;
    }

    return resultFile;
  }

  Future<void> _compressImage() async {
    if (_pickedFile == null) return;
    setState(() => _isCompressing = true);

    final inputFile = File(_pickedFile!.path);
    final inputFileSize = inputFile.lengthSync();
    final targetBytes = (_targetSize * (_sizeUnit == 'MB' ? 1024 * 1024 : 1024)).toInt();

    if (_isFileSizeMode && targetBytes >= inputFileSize) {
      setState(() {
        _error = "Target size must be less than original file size.";
        _isCompressing = false;
        _compressedFile = null;
      });
      return;
    }

    File? file;
    if (_isFileSizeMode) {
      file = await _compressToTargetSize(
          file: inputFile, targetSizeInBytes: targetBytes);
    } else {
      file = await _compressImageByQuality(file: inputFile, quality: _quality);
    }

    setState(() {
      _compressedFile = file;
      _isCompressing = false;
      _error = null;
    });
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Choose Theme"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text("System Default"),
                value: ThemeMode.system,
                groupValue: widget.currentThemeMode,
                onChanged: (value) {
                  if (value != null) {
                    widget.onThemeChanged(value);
                    setState(() {});
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text("Light"),
                value: ThemeMode.light,
                groupValue: widget.currentThemeMode,
                onChanged: (value) {
                  if (value != null) {
                    widget.onThemeChanged(value);
                    setState(() {});
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text("Dark"),
                value: ThemeMode.dark,
                groupValue: widget.currentThemeMode,
                onChanged: (value) {
                  if (value != null) {
                    widget.onThemeChanged(value);
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Image Compressor'),
          content: const Text(
            'This app lets you compress images by quality or target file size, and share them. You can choose theme and upload images via gallery or camera.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                const url =
                    'https://play.google.com/store/apps/details?id=com.example.image_compressor';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  throw 'Could not launch $url';
                }
              },
              child: const Text('Rate this app'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showFullImage(File file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.file(file),
        ),
      ),
    );
  }

  String formatFileSize(int bytes) {
    final kb = bytes / 1024;
    final mb = kb / 1024;
    return '${kb.toStringAsFixed(2)} KB / ${mb.toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Compressor'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'theme') _showThemeDialog();
              if (value == 'about') _showAboutDialog();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'theme', child: Text('Change Theme')),
              const PopupMenuItem(value: 'about', child: Text('About')),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_pickedFile == null) ...[
              ElevatedButton.icon(
                onPressed: () => _pickImage(fromCamera: false),
                icon: const Icon(Icons.image),
                label: const Text("Upload Image"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _pickImage(fromCamera: true),
                icon: const Icon(Icons.camera_alt),
                label: const Text("Capture Image"),
              ),
            ],
            if (_pickedFile != null) ...[
              GestureDetector(
                onTap: () => _showFullImage(File(_pickedFile!.path)),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueGrey, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.file(
                    File(_pickedFile!.path),
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                  "Original File Size: ${formatFileSize(File(_pickedFile!.path).lengthSync())}"),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 10),
              Center(
                child: ToggleSwitch(
                  key: const Key('compressionToggle'),
                  minWidth: 90.0,
                  cornerRadius: 20.0,
                  activeBgColors: const [
                    [Colors.green],
                    [Colors.red]
                  ],
                  activeFgColor: Colors.white,
                  inactiveBgColor: Colors.grey,
                  inactiveFgColor: Colors.white,
                  initialLabelIndex: _isFileSizeMode ? 0 : 1,
                  totalSwitches: 2,
                  labels: const ['File Size', 'Quality'],
                  radiusStyle: true,
                  onToggle: (index) {
                    setState(() {
                      _isFileSizeMode = index == 0;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              _isFileSizeMode
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Size',
                              hintText: 'Enter size',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _targetSize = double.tryParse(value) ?? 100;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: _sizeUnit,
                          items: ['KB', 'MB'].map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sizeUnit = value;
                              });
                            }
                          },
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Slider(
                          value: _quality.toDouble(),
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: _quality.toString(),
                          onChanged: (value) {
                            setState(() {
                              _quality = value.round();
                            });
                          },
                        ),
                        const Text(
                          'Use the slider to control image quality from 1 to 100.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
              const SizedBox(height: 10),
              if (_compressedFile != null) ...[
                GestureDetector(
                  onTap: () => _showFullImage(_compressedFile!),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.file(
                      _compressedFile!,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                    "Compressed File Size: ${formatFileSize(_compressedFile!.lengthSync())}"),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: () =>
                      Share.shareXFiles([XFile(_compressedFile!.path)]),
                  icon: const Icon(Icons.share),
                  label: const Text("Share Compressed Image"),
                ),
              ],
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _isCompressing ? null : _compressImage,
                icon: const Icon(Icons.compress),
                label:
                    Text(_isCompressing ? "Compressing..." : "Compress Again"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _pickedFile = null;
                  _compressedFile = null;
                  _error = null;
                }),
                icon: const Icon(Icons.restart_alt),
                label: const Text("Start Over with New Image"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
