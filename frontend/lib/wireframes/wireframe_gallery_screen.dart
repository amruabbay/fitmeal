import 'package:flutter/material.dart';
import 'package:fit_meal/wireframes/widgets/wireframe_components.dart';
import 'package:fit_meal/wireframes/screens/wireframe_dashboard_view.dart';
import 'package:fit_meal/wireframes/screens/wireframe_search_view.dart';
import 'package:fit_meal/wireframes/screens/wireframe_settings_view.dart';

class FitMealWireframeGalleryScreen extends StatefulWidget {
  const FitMealWireframeGalleryScreen({super.key});

  @override
  State<FitMealWireframeGalleryScreen> createState() => _FitMealWireframeGalleryScreenState();
}

class _FitMealWireframeGalleryScreenState extends State<FitMealWireframeGalleryScreen> {
  int _currentTab = 0;

  final List<Widget> _views = const [
    WireframeDashboardView(),
    WireframeSearchView(),
    WireframeSettingsView(),
    _WireframeComponentsGuideView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WireframeTheme.background,
      appBar: AppBar(
        backgroundColor: WireframeTheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'FitMeal Wireframe Suite',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: WireframeTheme.textPrimary,
              ),
            ),
            Text(
              'Interactive Greyscale Layout Shells',
              style: TextStyle(fontSize: 11, color: WireframeTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: WireframeTheme.textPrimary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'WIREFRAME MODE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: _views,
      ),

      // Bottom Navigation Bar with Dual-Coding Accessibility Demonstration
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: WireframeTheme.surface,
          border: Border(
            top: BorderSide(color: WireframeTheme.border, width: 1.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (idx) {
            setState(() {
              _currentTab = idx;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: WireframeTheme.surface,
          selectedItemColor: WireframeTheme.textPrimary,
          unselectedItemColor: WireframeTheme.textDisabled,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          items: const [
            // Tab 0: Dashboard (Dual-Coding: Solid vs Outline)
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            // Tab 1: Search (Dual-Coding: Solid vs Outline)
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Pencarian',
            ),
            // Tab 2: Settings (Dual-Coding: Solid vs Outline)
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Pengaturan',
            ),
            // Tab 3: Component Guide
            BottomNavigationBarItem(
              icon: Icon(Icons.widgets_outlined),
              activeIcon: Icon(Icons.widgets),
              label: 'Komponen',
            ),
          ],
        ),
      ),
    );
  }
}

class _WireframeComponentsGuideView extends StatelessWidget {
  const _WireframeComponentsGuideView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Katalog Komponen Wireframe UI/UX',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: WireframeTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Panduan standar komponen UI untuk menjaga konsistensi desain FitMeal.',
            style: TextStyle(fontSize: 12, color: WireframeTheme.textSecondary),
          ),

          const SizedBox(height: 20),

          // 1. State Tombol
          _buildGuideSection(
            title: '1. State Tombol (Normal, Loading, Disabled, Error)',
            child: Column(
              children: const [
                WireframeButton(label: 'Button State: Normal', state: WireframeButtonState.normal),
                SizedBox(height: 8),
                WireframeButton(label: 'Button State: Loading', state: WireframeButtonState.loading),
                SizedBox(height: 8),
                WireframeButton(label: 'Button State: Disabled', state: WireframeButtonState.disabled),
                SizedBox(height: 8),
                WireframeButton(label: 'Button State: Error Retry', state: WireframeButtonState.error),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Dual Coding Bottom Nav Explanation
          _buildGuideSection(
            title: '2. Dual-Coding Aksesibilitas Navigation Bar',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Prinsip WCAG: Jangan hanya mengandalkan warna untuk menandai tab aktif. Kombinasikan varian ikon Solid + Label Tebal untuk tab aktif, dan Outline + Label Muted untuk tab non-aktif.',
                  style: TextStyle(fontSize: 12, color: WireframeTheme.textSecondary),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.home, color: WireframeTheme.textPrimary, size: 28),
                        SizedBox(height: 4),
                        Text('Aktif (Solid)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.home_outlined, color: WireframeTheme.textDisabled, size: 28),
                        SizedBox(height: 4),
                        Text('Non-Aktif (Outline)', style: TextStyle(fontSize: 11, color: WireframeTheme.textDisabled)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. High Contrast Pill Tags
          _buildGuideSection(
            title: '3. Aksesibilitas Kontras Warna Pill Tags',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bandingkan tingkat keterbacaan tag kontras tinggi (WCAG AAA) vs pudar:',
                  style: TextStyle(fontSize: 12, color: WireframeTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    WireframePillTag(label: 'Protein Tinggi (AAA)', highContrast: true),
                    SizedBox(width: 8),
                    WireframePillTag(label: 'Pudar (Rendah)', highContrast: false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WireframeTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WireframeTheme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: WireframeTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
