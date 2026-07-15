import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CaptureCameraPartagee extends StatefulWidget {
  const CaptureCameraPartagee({
    super.key,
    required this.onCapturesTerminees,
    this.titre = 'Capture faciale',
  });

  final Future<void> Function(List<XFile> images) onCapturesTerminees;
  final String titre;

  @override
  State<CaptureCameraPartagee> createState() => _CaptureCameraPartageeState();
}

class _CaptureCameraPartageeState extends State<CaptureCameraPartagee>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  List<XFile> _captures = [];
  String? _erreur;
  bool _initialisation = true;
  bool _captureEnCours = false;
  bool _traitement = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialiser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initialiser();
    }
  }

  Future<void> _initialiser() async {
    if (!mounted) return;
    setState(() {
      _initialisation = true;
      _erreur = null;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('no_camera', 'Aucune camera disponible');
      }
      final camera = _cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      final controller =
          CameraController(camera, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await _controller?.dispose();
      setState(() {
        _controller = controller;
        _initialisation = false;
      });
    } on CameraException catch (exception) {
      if (!mounted) return;
      setState(() {
        _initialisation = false;
        _erreur = _messageCamera(exception);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initialisation = false;
        _erreur = 'La camera est indisponible ou la permission a ete refusee.';
      });
    }
  }

  Future<void> _basculerCamera() async {
    if (_cameras.length < 2 || _controller == null) return;
    final index = _cameras.indexOf(_controller!.description);
    final suivante = _cameras[(index + 1) % _cameras.length];
    final controller =
        CameraController(suivante, ResolutionPreset.medium, enableAudio: false);
    await controller.initialize();
    await _controller?.dispose();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  Future<void> _capturer() async {
    final controller = _controller;
    if (_captureEnCours ||
        _traitement ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    setState(() => _captureEnCours = true);
    try {
      final image = await controller.takePicture();
      final captures = [..._captures, image];
      if (captures.length == 3) {
        setState(() {
          _captures = captures;
          _traitement = true;
        });
        await widget.onCapturesTerminees(captures);
        if (mounted) setState(() => _traitement = false);
      } else if (mounted) {
        setState(() => _captures = captures);
      }
    } on CameraException catch (exception) {
      if (mounted) setState(() => _erreur = _messageCamera(exception));
    } finally {
      if (mounted) setState(() => _captureEnCours = false);
    }
  }

  void _recommencer() {
    setState(() {
      _captures = [];
      _erreur = null;
      _traitement = false;
    });
  }

  String _messageCamera(CameraException exception) {
    if (exception.code == 'CameraAccessDenied' ||
        exception.code == 'cameraPermission') {
      return 'La permission camera a ete refusee.';
    }
    return exception.description ?? 'La camera est indisponible.';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.titre, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text('Verification de vivacite renforcee non encore activee.'),
        const SizedBox(height: 12),
        if (_initialisation)
          const Center(child: CircularProgressIndicator())
        else if (_erreur != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_erreur!),
              TextButton.icon(
                  onPressed: _initialiser,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reessayer')),
            ],
          )
        else if (controller != null && controller.value.isInitialized)
          Column(
            children: [
              AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(controller),
                    Center(
                        child: Container(
                            width: 190,
                            height: 240,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white, width: 2)))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Capture ${_captures.length + 1} sur 3'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      onPressed: _cameras.length > 1 ? _basculerCamera : null,
                      tooltip: 'Changer de camera',
                      icon: const Icon(Icons.flip_camera_android)),
                  FilledButton.icon(
                      onPressed:
                          _captureEnCours || _traitement ? null : _capturer,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_traitement ? 'Traitement...' : 'Capturer')),
                  IconButton(
                      onPressed: _captures.isEmpty ? null : _recommencer,
                      tooltip: 'Recommencer',
                      icon: const Icon(Icons.restart_alt)),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
