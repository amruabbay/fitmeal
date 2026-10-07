import 'package:flutter/material.dart';
import 'package:fit_meal/wireframes/widgets/wireframe_components.dart';

class WireframeSearchView extends StatefulWidget {
  const WireframeSearchView({super.key});

  @override
  State<WireframeSearchView> createState() => _WireframeSearchViewState();
}

class _WireframeSearchViewState extends State<WireframeSearchView> {
  final TextEditingController _searchController = TextEditingController(text: 'Dada Ayam');
  
  // Track button states for food items (item_id -> button state)
  final Map<String, WireframeButtonState> _buttonStates = {
    'item_1': WireframeButtonState.normal,
    'item_2': WireframeButtonState.normal,
    'item_3': WireframeButtonState.normal,
  };

  bool _simulateApiError = false;

  void _onAddPressed(String itemId, String foodName) async {
    // 1. Check double tap / loading protection
    if (_buttonStates[itemId] == WireframeButtonState.loading) return;

    // 2. Set state to loading
    setState(() {
      _buttonStates[itemId] = WireframeButtonState.loading;
    });

    // Simulate Network API Call (1.5 seconds delay)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    if (_simulateApiError) {
      // 3. Handle API Failure
      setState(() {
        _buttonStates[itemId] = WireframeButtonState.error;
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gagal menambahkan makanan. Koneksi timeout.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: WireframeTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Reset back to normal after 2 seconds
      await Future.delayed(const Duration(seconds: 2000));
      if (mounted) {
        setState(() {
          _buttonStates[itemId] = WireframeButtonState.normal;
        });
      }
    } else {
      // 4. Success -> Show Meal Time Bottom Sheet
      setState(() {
        _buttonStates[itemId] = WireframeButtonState.normal;
      });

      _showMealTimeBottomSheet(foodName);
    }
  }

  void _showMealTimeBottomSheet(String foodName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Waktu Makan: $foodName',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: WireframeTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildBottomSheetOption(ctx, Icons.wb_sunny_outlined, 'Makan Pagi (Breakfast)'),
              _buildBottomSheetOption(ctx, Icons.wb_sunny, 'Makan Siang (Lunch)'),
              _buildBottomSheetOption(ctx, Icons.nights_stay_outlined, 'Makan Malam (Dinner)'),
              _buildBottomSheetOption(ctx, Icons.cookie_outlined, 'Cemilan (Snack)'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption(BuildContext ctx, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: WireframeTheme.accentActive),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil ditambahkan ke $title!'),
            backgroundColor: WireframeTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wireframe Search Header & Controls
          const Text(
            'Wireframe: Pencarian & Logger Makanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: WireframeTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Menguji Penanganan Loading, Timeout API, & Bottom Sheet.',
            style: TextStyle(fontSize: 12, color: WireframeTheme.textSecondary),
          ),

          const SizedBox(height: 16),

          // API Error Toggle Simulator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _simulateApiError
                  ? WireframeTheme.error.withOpacity(0.1)
                  : WireframeTheme.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _simulateApiError ? WireframeTheme.error : WireframeTheme.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _simulateApiError ? Icons.warning_amber : Icons.bug_report_outlined,
                      size: 20,
                      color: _simulateApiError ? WireframeTheme.error : WireframeTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _simulateApiError ? 'Simulasi: API Error / Timeout' : 'Simulasi: Sukses Normal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _simulateApiError ? WireframeTheme.error : WireframeTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _simulateApiError,
                  activeColor: WireframeTheme.error,
                  onChanged: (val) {
                    setState(() {
                      _simulateApiError = val;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search Bar Skeleton
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: WireframeTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: WireframeTheme.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: WireframeTheme.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Cari makanan (misal: Dada Ayam)...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const WireframeBox(
                width: 44,
                height: 44,
                label: '',
                icon: Icons.tune,
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Search Results Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Hasil Pencarian (3 item)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: WireframeTheme.textPrimary,
                ),
              ),
              WireframePillTag(label: 'Tinggi Protein', highContrast: true),
            ],
          ),

          const SizedBox(height: 12),

          // Item 1: Dada Ayam Rebus
          _buildFoodCardWireframe(
            id: 'item_1',
            name: 'Dada Ayam Rebus (100g)',
            details: '165 kcal • P: 31g • K: 0g • L: 3.6g',
            tags: ['Protein Tinggi', 'Rendah Lemak'],
          ),

          const SizedBox(height: 12),

          // Item 2: Dada Ayam Grill dengan Olive Oil
          _buildFoodCardWireframe(
            id: 'item_2',
            name: 'Dada Ayam Grill (150g)',
            details: '240 kcal • P: 42g • K: 2g • L: 7g',
            tags: ['Keto Friendly', 'High Protein'],
          ),

          const SizedBox(height: 12),

          // Item 3: Sup Dada Ayam Sayur
          _buildFoodCardWireframe(
            id: 'item_3',
            name: 'Sup Dada Ayam & Sayuran',
            details: '180 kcal • P: 22g • K: 14g • L: 4g',
            tags: ['Serat Tinggi', 'Rendah Kalori'],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCardWireframe({
    required String id,
    required String name,
    required String details,
    required List<String> tags,
  }) {
    final WireframeButtonState btnState = _buttonStates[id] ?? WireframeButtonState.normal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WireframeTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WireframeTheme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const WireframeBox(
                width: 48,
                height: 48,
                label: '',
                icon: Icons.fastfood_outlined,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: WireframeTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: const TextStyle(
                        fontSize: 11,
                        color: WireframeTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: WireframeButton(
                  label: '+ Tambah',
                  state: btnState,
                  isFullWidth: false,
                  onPressed: () => _onAddPressed(id, name),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: tags
                .map((t) => WireframePillTag(label: t, highContrast: true))
                .toList(),
          ),
        ],
      ),
    );
  }
}
