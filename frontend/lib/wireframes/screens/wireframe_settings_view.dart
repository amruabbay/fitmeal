import 'package:flutter/material.dart';
import 'package:fit_meal/wireframes/widgets/wireframe_components.dart';

class WireframeSettingsView extends StatefulWidget {
  const WireframeSettingsView({super.key});

  @override
  State<WireframeSettingsView> createState() => _WireframeSettingsViewState();
}

class _WireframeSettingsViewState extends State<WireframeSettingsView> {
  // Initial baseline data
  final String _initialName = 'Budi Santoso';
  final String _initialWeight = '70';
  final String _initialHeight = '175';
  final String _initialAge = '28';
  final String _initialActivity = 'Sedang (3-5x/minggu)';

  // Text Controllers
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;
  late String _selectedActivity;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _initialName);
    _weightController = TextEditingController(text: _initialWeight);
    _heightController = TextEditingController(text: _initialHeight);
    _ageController = TextEditingController(text: _initialAge);
    _selectedActivity = _initialActivity;

    _nameController.addListener(_checkFormChanged);
    _weightController.addListener(_checkFormChanged);
    _heightController.addListener(_checkFormChanged);
    _ageController.addListener(_checkFormChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _checkFormChanged() {
    setState(() {});
  }

  bool get _hasChanges {
    return _nameController.text != _initialName ||
        _weightController.text != _initialWeight ||
        _heightController.text != _initialHeight ||
        _ageController.text != _initialAge ||
        _selectedActivity != _initialActivity;
  }

  void _onSavePressed() async {
    if (!_hasChanges || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Perubahan profil berhasil disimpan!'),
          ],
        ),
        backgroundColor: WireframeTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onResetPressed() {
    setState(() {
      _nameController.text = _initialName;
      _weightController.text = _initialWeight;
      _heightController.text = _initialHeight;
      _ageController.text = _initialAge;
      _selectedActivity = _initialActivity;
    });
  }

  @override
  Widget build(BuildContext context) {
    final WireframeButtonState buttonState = _isSaving
        ? WireframeButtonState.loading
        : (_hasChanges ? WireframeButtonState.normal : WireframeButtonState.disabled);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Guidelines Wireframe
          const Text(
            'Wireframe: Pengaturan Profil & State Form',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: WireframeTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '💡 Tombol "Simpan Perubahan" mati (disabled) secara default dan baru aktif HANYA JIKA data diubah.',
            style: TextStyle(fontSize: 12, color: WireframeTheme.textSecondary),
          ),

          const SizedBox(height: 16),

          // Avatar Wireframe Card
          Center(
            child: Column(
              children: [
                Stack(
                  children: const [
                    WireframeBox(
                      width: 80,
                      height: 80,
                      label: '',
                      icon: Icons.person_outline,
                      padding: EdgeInsets.zero,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: WireframeTheme.textPrimary,
                        child: Icon(Icons.camera_alt, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ubah Foto Profil',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WireframeTheme.activeHighlight),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Form Fields Section
          _buildTextField('Nama Lengkap', _nameController, Icons.person),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField('Berat (kg)', _weightController, Icons.monitor_weight_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Tinggi (cm)', _heightController, Icons.height)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Usia (th)', _ageController, Icons.cake_outlined)),
            ],
          ),

          const SizedBox(height: 16),

          // Activity Selector Wireframe
          const Text(
            'Tingkat Aktivitas Harian',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WireframeTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          _buildActivityOption('Ringan (1-2x/minggu)'),
          const SizedBox(height: 6),
          _buildActivityOption('Sedang (3-5x/minggu)'),
          const SizedBox(height: 6),
          _buildActivityOption('Berat (6-7x/minggu)'),

          const SizedBox(height: 24),

          // Save & Reset Wireframe Buttons
          Row(
            children: [
              if (_hasChanges) ...[
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _onResetPressed,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.vertical(14),
                      side: const BorderSide(color: WireframeTheme.border),
                    ),
                    child: const Text('Reset', style: TextStyle(color: WireframeTheme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: WireframeButton(
                  label: _hasChanges ? 'Simpan Perubahan' : 'Belum Ada Perubahan',
                  state: buttonState,
                  onPressed: _onSavePressed,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status Badge Indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _hasChanges ? WireframeTheme.activeHighlight.withOpacity(0.1) : WireframeTheme.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hasChanges ? WireframeTheme.activeHighlight : WireframeTheme.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _hasChanges ? Icons.edit_note : Icons.check_circle_outline,
                  color: _hasChanges ? WireframeTheme.activeHighlight : WireframeTheme.textDisabled,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _hasChanges ? 'Status: Ada perubahan belum disimpan' : 'Status: Data sesuai (Tombol Disabled)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _hasChanges ? WireframeTheme.activeHighlight : WireframeTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WireframeTheme.textSecondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: WireframeTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: WireframeTheme.border, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: WireframeTheme.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityOption(String title) {
    final bool isSelected = _selectedActivity == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedActivity = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? WireframeTheme.accentActive : WireframeTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? WireframeTheme.accentActive : WireframeTheme.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : WireframeTheme.textPrimary,
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: isSelected ? Colors.white : WireframeTheme.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}
