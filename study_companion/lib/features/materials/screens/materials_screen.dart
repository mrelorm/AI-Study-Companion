import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../../shared/theme/app_theme.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final _api = ApiClient();
  List<StudyMaterial> _materials = [];
  bool _loading = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/materials');
      setState(() {
        _materials = (res.data as List)
            .map((e) => StudyMaterial.fromJson(e))
            .toList();
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    setState(() => _uploading = true);
    try {
      final MultipartFile multipartFile;
      if (file.bytes != null) {
        // Web — no file path available, use bytes directly
        multipartFile = MultipartFile.fromBytes(file.bytes!, filename: file.name);
      } else {
        // Native (Android/iOS/desktop)
        multipartFile = await MultipartFile.fromFile(file.path!, filename: file.name);
      }
      final formData = FormData.fromMap({'file': multipartFile});
      await _api.postFormData('/materials/upload', formData);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('File uploaded successfully'),
            ]),
            backgroundColor: AppTheme.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _delete(StudyMaterial material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete material',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Remove "${material.filename}"?\nThis cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.delete('/materials/${material.id}');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('My Materials'),
        actions: [
          if (_uploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.primary),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.upload_rounded,
                      color: Colors.white, size: 18),
                ),
                onPressed: _upload,
                tooltip: 'Upload file',
              ),
            ),
        ],
      ),
      body: _loading
          ? _ShimmerList()
          : _materials.isEmpty
              ? _EmptyState(onUpload: _upload)
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _materials.length,
                    itemBuilder: (_, i) => _MaterialCard(
                      material: _materials[i],
                      onDelete: () => _delete(_materials[i]),
                      formatSize: _formatSize,
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _upload,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Upload',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final StudyMaterial material;
  final VoidCallback onDelete;
  final String Function(int) formatSize;

  const _MaterialCard({
    required this.material,
    required this.onDelete,
    required this.formatSize,
  });

  bool get _isPdf => material.contentType.contains('pdf');
  Color get _accentColor => _isPdf ? AppTheme.error : AppTheme.primary;
  LinearGradient get _iconGradient => _isPdf
      ? const LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFFF1744)])
      : AppTheme.primaryGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Row(
        children: [
          // Colored left accent bar
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              gradient: _iconGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // File icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: _iconGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isPdf
                  ? Icons.picture_as_pdf_rounded
                  : Icons.description_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.filename,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _isPdf ? 'PDF' : 'TXT',
                          style: TextStyle(
                              color: _accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatSize(material.sizeBytes),
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      const Text('•',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(width: 8),
                      Text(
                        material.uploadedAt
                            .toLocal()
                            .toString()
                            .split(' ')
                            .first,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.error, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surface,
      highlightColor: AppTheme.surfaceHigh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyState({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.primaryShadow,
              ),
              child: const Icon(Icons.folder_open_rounded,
                  size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'No materials yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            const Text(
              'Upload your PDFs, lecture slides, or text files\nand let AI do the heavy lifting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Upload your first file'),
            ),
          ],
        ),
      ),
    );
  }
}
