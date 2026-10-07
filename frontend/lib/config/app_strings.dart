/// Centralized bilingual string dictionary for the entire app.
/// Usage: AppStrings.get('key', lang) where lang is 'id' or 'en'.
class AppStrings {
  AppStrings._();

  static final Map<String, Map<String, String>> _strings = {
    // ================================
    // COMMON / SHARED
    // ================================
    'app_name': {'id': 'FitMeal', 'en': 'FitMeal'},
    'save': {'id': 'Simpan', 'en': 'Save'},
    'cancel': {'id': 'Batal', 'en': 'Cancel'},
    'close': {'id': 'Tutup', 'en': 'Close'},
    'retry': {'id': 'Coba Lagi', 'en': 'Retry'},
    'add': {'id': 'Tambah', 'en': 'Add'},
    'delete': {'id': 'Hapus', 'en': 'Delete'},
    'reset': {'id': 'Reset', 'en': 'Reset'},
    'loading': {'id': 'Memuat...', 'en': 'Loading...'},
    'kkal': {'id': 'kkal', 'en': 'kcal'},
    'target': {'id': 'target', 'en': 'target'},
    'today': {'id': 'Hari Ini', 'en': 'Today'},
    'guest': {'id': 'Guest', 'en': 'Guest'},

    // ================================
    // MEAL TYPES
    // ================================
    'breakfast': {'id': 'Sarapan', 'en': 'Breakfast'},
    'lunch': {'id': 'Makan Siang', 'en': 'Lunch'},
    'dinner': {'id': 'Makan Malam', 'en': 'Dinner'},
    'snacks': {'id': 'Cemilan', 'en': 'Snacks'},

    // ================================
    // NAVIGATION (main_screen)
    // ================================
    'nav_home': {'id': 'Beranda', 'en': 'Home'},
    'nav_stats': {'id': 'Stats', 'en': 'Stats'},
    'nav_recommendation': {'id': 'Rekomendasi', 'en': 'Recommend'},
    'nav_search': {'id': 'Cari', 'en': 'Search'},

    // Greetings
    'greeting_morning': {'id': 'Selamat Pagi', 'en': 'Good Morning'},
    'greeting_afternoon': {'id': 'Selamat Siang', 'en': 'Good Afternoon'},
    'greeting_evening': {'id': 'Selamat Sore', 'en': 'Good Evening'},
    'greeting_night': {'id': 'Selamat Malam', 'en': 'Good Night'},

    // ================================
    // DASHBOARD
    // ================================
    'calorie_summary': {'id': 'Rangkuman Kalori', 'en': 'Calorie Summary'},
    'macronutrients': {'id': 'Makronutrisi', 'en': 'Macronutrients'},
    'protein': {'id': 'Protein', 'en': 'Protein'},
    'carbs': {'id': 'Karbohidrat', 'en': 'Carbs'},
    'fat': {'id': 'Lemak', 'en': 'Fat'},
    'food_log': {'id': 'Catatan Makan', 'en': 'Food Log'},
    'consumed': {'id': 'Dikonsumsi', 'en': 'Consumed'},
    'remaining': {'id': 'Tersisa', 'en': 'Remaining'},
    'exceeded': {'id': 'Melebihi', 'en': 'Exceeded'},
    'progress': {'id': 'Progress', 'en': 'Progress'},
    'day_streak': {'id': 'Hari Streak', 'en': 'Day Streak'},

    // ================================
    // SETTINGS
    // ================================
    'settings': {'id': 'Pengaturan', 'en': 'Settings'},
    'appearance': {'id': 'TAMPILAN', 'en': 'APPEARANCE'},
    'dark_mode': {'id': 'Mode Gelap', 'en': 'Dark Mode'},
    'language_section': {'id': 'BAHASA', 'en': 'LANGUAGE'},
    'language': {'id': 'Bahasa', 'en': 'Language'},
    'indonesian': {'id': 'Indonesia', 'en': 'Indonesia'},
    'english': {'id': 'English', 'en': 'English'},
    'recommendation_section': {'id': 'REKOMENDASI', 'en': 'RECOMMENDATION'},
    'food_preferences': {'id': 'Preferensi Makanan', 'en': 'Food Preferences'},
    'food_customized': {
      'id': 'makanan dikustomisasi',
      'en': 'foods customized'
    },
    'no_preferences': {
      'id': 'Belum ada preferensi',
      'en': 'No preferences set'
    },
    'others': {'id': 'LAINNYA', 'en': 'OTHERS'},
    'app_version': {'id': 'Versi Aplikasi', 'en': 'App Version'},
    'reset_all_data': {'id': 'Reset Semua Data', 'en': 'Reset All Data'},
    'reset_dialog_title': {'id': 'Reset Semua Data?', 'en': 'Reset All Data?'},
    'reset_dialog_content': {
      'id':
          'Semua data profil, catatan makan, dan riwayat pencarian akan dihapus. Kamu akan kembali ke layar onboarding.',
      'en':
          'All profile data, food logs, and search history will be deleted. You will return to the onboarding screen.',
    },

    // Profile
    'weight': {'id': 'Berat', 'en': 'Weight'},
    'height': {'id': 'Tinggi', 'en': 'Height'},
    'age': {'id': 'Umur', 'en': 'Age'},
    'gender': {'id': 'Gender', 'en': 'Gender'},
    'male': {'id': 'Pria', 'en': 'Male'},
    'female': {'id': 'Wanita', 'en': 'Female'},
    'activity': {'id': 'Aktivitas', 'en': 'Activity'},
    'daily_activity': {'id': 'Aktivitas Harian', 'en': 'Daily Activity'},
    'bmi': {'id': 'BMI (IMT)', 'en': 'BMI'},
    'sedentary': {'id': 'Jarang Gerak', 'en': 'Sedentary'},
    'moderate': {'id': 'Cukup Aktif', 'en': 'Moderately Active'},
    'active': {'id': 'Sangat Aktif', 'en': 'Very Active'},
    'save_changes': {'id': 'Simpan Perubahan', 'en': 'Save Changes'},
    'no_changes': {'id': 'Belum Ada Perubahan', 'en': 'No Changes'},
    'profile_updated': {
      'id': 'Profil berhasil diperbarui! ✅',
      'en': 'Profile updated successfully! ✅'
    },
    'change_photo': {'id': 'Ganti Foto Profil', 'en': 'Change Profile Photo'},
    'take_photo': {'id': 'Ambil Foto', 'en': 'Take Photo'},
    'choose_from_gallery': {
      'id': 'Pilih dari Galeri',
      'en': 'Choose from Gallery'
    },
    'remove_photo': {'id': 'Hapus Foto', 'en': 'Remove Photo'},
    'crop_title': {'id': 'Sesuaikan Foto', 'en': 'Adjust Photo'},
    'rotate': {'id': 'Putar', 'en': 'Rotate'},
    'zoom': {'id': 'Perbesar', 'en': 'Zoom'},
    'done': {'id': 'Selesai', 'en': 'Done'},
    'weight_unit': {'id': 'kg', 'en': 'kg'},
    'height_unit': {'id': 'cm', 'en': 'cm'},
    'age_unit': {'id': 'tahun', 'en': 'years'},

    // ================================
    // RECOMMENDATION SCREEN
    // ================================
    'tab_auto': {'id': 'Otomatis', 'en': 'Auto'},
    'tab_manual': {'id': 'Pilih Sendiri', 'en': 'Choose Yourself'},
    'auto_recommendation': {
      'id': 'Rekomendasi Otomatis',
      'en': 'Auto Recommendation'
    },
    'get_recommendation': {
      'id': 'Dapatkan Rekomendasi',
      'en': 'Get Recommendation'
    },
    'manage_preferences': {
      'id': 'Kelola Preferensi Makanan',
      'en': 'Manage Food Preferences'
    },
    'manage_preferences_count': {
      'id': 'Kelola Preferensi',
      'en': 'Manage Preferences'
    },
    'meal_plan': {'id': 'Rencana Makan', 'en': 'Meal Plan'},
    'long_press_hint': {
      'id': 'Tekan lama makanan untuk mengatur preferensi',
      'en': 'Long press food to manage preferences'
    },
    'algorithm_label': {
      'id': 'Diformulasikan berdasarkan algoritma Constraint-Based Filtering',
      'en': 'Formulated using Constraint-Based Filtering algorithm'
    },
    'daily_nutrition_target': {
      'id': 'TARGET NUTRISI HARIAN',
      'en': 'DAILY NUTRITION TARGET'
    },
    'meals_count': {'id': 'Makan', 'en': 'Meals'},
    'add_all_to_log': {
      'id': 'Tambahkan Semua ke Catatan Hari Ini',
      'en': 'Add All to Today\'s Log'
    },
    'added': {'id': 'Ditambahkan', 'en': 'Added'},
    'log_button': {'id': 'Catat', 'en': 'Log'},
    'added_to_log': {
      'id': 'ditambahkan ke catatan! ✅',
      'en': 'added to log! ✅'
    },
    'failed_to_load': {'id': 'Gagal Memuat', 'en': 'Failed to Load'},
    'loading_recommendation': {
      'id': 'Menghitung rekomendasi...',
      'en': 'Calculating recommendations...'
    },
    'no_food_found': {
      'id': 'Tidak ada makanan ditemukan',
      'en': 'No food found'
    },
    'remaining_calories_today': {
      'id': 'Sisa Kalori Hari Ini',
      'en': 'Remaining Calories Today'
    },
    'category_protein': {'id': 'Protein', 'en': 'Protein'},
    'category_carbs': {'id': 'Karbohidrat', 'en': 'Carbs'},
    'category_veggies': {'id': 'Sayuran', 'en': 'Vegetables'},
    'category_fruits': {'id': 'Buah', 'en': 'Fruits'},
    'constraint_filter_active': {
      'id': 'Constraint-Based Filtering Aktif',
      'en': 'Constraint-Based Filtering Active'
    },
    'constraint_filter_success': {
      'id':
          'Kandidat menu telah disaring berdasarkan batasan nutrisi dan kategori makanan.',
      'en':
          'Menu candidates have been filtered by nutrition and food-category constraints.',
    },
    'filtering_stats': {
      'id': 'Rincian Penyaringan Menu',
      'en': 'Menu Filtering Details'
    },
    'filtered_instantly': {
      'id': 'Diproses menggunakan aturan batasan yang eksplisit',
      'en': 'Processed using explicit constraint rules'
    },
    'main_algorithm': {'id': 'Algoritma', 'en': 'Algorithm'},
    'candidate_count': {
      'id': 'Kandidat Tersaring',
      'en': 'Filtered Candidates'
    },
    'rules_applied': {'id': 'Aturan Diterapkan', 'en': 'Rules Applied'},
    'items': {'id': 'Item', 'en': 'Items'},
    'rules': {'id': 'Aturan', 'en': 'Rules'},
    'macro_accuracy': {
      'id': 'Akurasi Target Nutrisi',
      'en': 'Nutrition Target Accuracy'
    },
    'calories_label': {'id': 'Kalori', 'en': 'Calories'},
    'carbs_label': {'id': 'Karbohidrat', 'en': 'Carbs'},
    'fat_label': {'id': 'Lemak', 'en': 'Fat'},
    'algorithm_edu': {
      'id':
          'Constraint-Based Filtering menyaring kandidat menggunakan aturan eksplisit: hanya Real Food, UPF dikecualikan, preferensi pengguna dihormati, dan total energi dibatasi oleh target efektif.',
      'en':
          'Constraint-Based Filtering applies explicit rules: Real Food only, UPF excluded, user preferences respected, and total energy capped by the effective target.',
    },
    'show_more_often': {
      'id': 'Tampilkan Lebih Sering',
      'en': 'Show More Often'
    },
    'algorithm_will_prioritize': {
      'id': 'Algoritma akan memprioritaskan makanan ini',
      'en': 'Algorithm will prioritize this food'
    },
    'dont_show_again': {
      'id': 'Jangan Tampilkan Lagi',
      'en': 'Don\'t Show Again'
    },
    'food_wont_appear': {
      'id': 'Makanan ini tidak akan muncul di rekomendasi',
      'en': 'This food won\'t appear in recommendations'
    },
    'set_preference_hint': {
      'id': 'Atur preferensi untuk rekomendasi berikutnya',
      'en': 'Set preference for next recommendations'
    },
    'active_label': {'id': 'Aktif', 'en': 'Active'},
    'removed_from_priority': {
      'id': 'dihapus dari prioritas',
      'en': 'removed from priority'
    },
    'prioritized': {'id': 'diprioritaskan ✅', 'en': 'prioritized ✅'},
    'removed_from_avoid': {
      'id': 'dihapus dari daftar hindari',
      'en': 'removed from avoid list'
    },
    'wont_be_shown': {
      'id': 'tidak akan ditampilkan 🚫',
      'en': 'won\'t be shown 🚫'
    },
    'favorite': {'id': 'Favoritmu', 'en': 'Favorite'},

    // Smart badges
    'badge_balanced': {'id': 'Seimbang', 'en': 'Balanced'},
    'badge_high_protein_good': {
      'id': 'Tinggi Protein Baik',
      'en': 'High Quality Protein'
    },
    'badge_high_protein': {'id': 'Tinggi Protein', 'en': 'High Protein'},
    'badge_fits_remaining': {
      'id': 'Pas Untuk Sisa Kalori',
      'en': 'Fits Remaining Calories'
    },
    'badge_low_fat_light': {
      'id': 'Rendah Lemak & Ringan',
      'en': 'Low Fat & Light'
    },

    // Goal descriptions
    'goal_cutting_desc': {
      'id': 'target Cutting kamu!',
      'en': 'your Cutting target!',
    },
    'goal_maintain_desc': {
      'id': 'target Maintain kamu!',
      'en': 'your Maintain target!',
    },
    'goal_bulking_desc': {
      'id': 'target Bulking kamu!',
      'en': 'your Bulking target!',
    },
    'auto_desc_prefix': {
      'id':
          'Dapatkan rencana makan harian lengkap yang sesuai dengan profil dan target ',
      'en': 'Get a complete daily meal plan tailored to your profile and ',
    },

    // Error messages
    'server_error': {'id': 'Server error', 'en': 'Server error'},
    'pref_too_strict': {
      'id':
          'Batasan preferensi makanan Anda mungkin terlalu ketat sehingga algoritma tidak menemukan kombinasi yang pas. Coba kurangi makanan yang dihindari.',
      'en':
          'Your food preference restrictions may be too strict for the algorithm to find a suitable combination. Try reducing avoided foods.',
    },
    'failed_generate_menu': {
      'id':
          'Gagal menyusun menu.\n\nBatasan preferensi makanan Anda mungkin terlalu ketat (terlalu banyak makanan dihindari) sehingga algoritma tidak menemukan kombinasi yang pas.\n\nCoba kurangi makanan yang dihindari di tab pengaturan.',
      'en':
          'Failed to generate menu.\n\nYour food preferences may be too strict (too many avoided foods) for the algorithm to find a suitable combination.\n\nTry reducing avoided foods in the settings tab.',
    },
    'failed_connect': {
      'id': 'Gagal terhubung ke server.\nPastikan backend & Ngrok aktif.',
      'en':
          'Failed to connect to server.\nMake sure backend & Ngrok are running.',
    },

    // ================================
    // SEARCH SCREEN
    // ================================
    'search_hint': {
      'id': 'Cari makanan (misal: Dada Ayam)',
      'en': 'Search food (e.g.: Chicken Breast)'
    },
    'no_search_history': {
      'id': 'Belum ada riwayat pencarian',
      'en': 'No search history yet'
    },
    'food_not_found': {'id': 'Makanan tidak ditemukan', 'en': 'No food found'},
    'add_food_title': {'id': 'Tambah', 'en': 'Add'},
    'added_to_meal': {'id': 'ditambahkan ke', 'en': 'added to'},
    'add_failed': {
      'id': 'Gagal menambahkan makanan. Silakan coba lagi.',
      'en': 'Failed to add food. Please try again.'
    },

    // ================================
    // STATISTICS SCREEN
    // ================================
    'weekly_stats': {'id': 'Weekly Stats', 'en': 'Weekly Stats'},
    'your_performance': {
      'id': 'Performa kamu minggu ini',
      'en': 'Your performance this week'
    },
    'from_to': {'id': 'Dari', 'en': 'From'},
    'until': {'id': 'sampai', 'en': 'to'},
    'avg_calories': {'id': 'AVG KALORI', 'en': 'AVG CALORIES'},
    'avg_protein': {'id': 'AVG PROTEIN', 'en': 'AVG PROTEIN'},
    'active_days': {'id': 'HARI AKTIF', 'en': 'ACTIVE DAYS'},
    'best_day': {'id': 'HARI TERBAIK', 'en': 'BEST DAY'},
    'kkal_per_day': {'id': 'kkal/hari', 'en': 'kcal/day'},
    'g_per_day': {'id': 'g/hari', 'en': 'g/day'},
    'of_7_days': {'id': 'dari 7 hari', 'en': 'of 7 days'},
    'not_yet': {'id': 'Belum ada', 'en': 'Not yet'},
    'daily_calories': {'id': 'Kalori Harian', 'en': 'Daily Calories'},
    'weekly_energy': {
      'id': 'Weekly energy\nconsumption breakdown',
      'en': 'Weekly energy\nconsumption breakdown'
    },
    'goal_baseline': {'id': 'GOAL BASELINE', 'en': 'GOAL BASELINE'},
    'weekly_insight': {'id': 'Weekly Insight', 'en': 'Weekly Insight'},
    'health_tip': {'id': 'Health Tip', 'en': 'Health Tip'},
    'read_guide': {'id': 'BACA PANDUAN', 'en': 'READ GUIDE'},

    // Insights
    'insight_no_data': {
      'id':
          'Belum ada data yang tercatat minggu ini. Mulai catat makananmu hari ini untuk mendapatkan insight yang lebih akurat!',
      'en':
          'No data recorded this week. Start logging your food today for more accurate insights!',
    },
    'insight_far_below': {
      'id': 'Asupan kalori kamu masih jauh di bawah target minggu ini. ',
      'en': 'Your calorie intake is still far below target this week. ',
    },
    'insight_close': {
      'id':
          'Asupan kalori kamu cukup mendekati target, tapi masih bisa ditingkatkan. ',
      'en':
          'Your calorie intake is close to target, but can still be improved. ',
    },
    'insight_great': {
      'id': 'Luar biasa! Asupan kalori kamu sangat konsisten dengan target. ',
      'en':
          'Amazing! Your calorie intake is very consistent with your target. ',
    },
    'insight_over': {
      'id':
          'Asupan kalori kamu melebihi target minggu ini. Pertimbangkan untuk mengurangi porsi. ',
      'en':
          'Your calorie intake exceeded target this week. Consider reducing portions. ',
    },
    'insight_best_day': {
      'id': ' adalah hari terbaikmu untuk memenuhi target nutrisi. ',
      'en': ' was your best day for meeting nutrition targets. ',
    },
    'insight_improve': {
      'id':
          'Tingkatkan konsistensi pencatatan harian untuk hasil yang lebih akurat.',
      'en': 'Improve daily logging consistency for more accurate results.',
    },
    'insight_keep_up': {
      'id': 'Pertahankan konsistensi pencatatanmu yang sudah bagus!',
      'en': 'Keep up your great logging consistency!',
    },

    // Health tips
    'health_tip_low': {
      'id':
          'Fokus pada karbohidrat kompleks di hari-hari yang kurang aktif untuk menjaga energi tetap stabil sepanjang hari.',
      'en':
          'Focus on complex carbohydrates on less active days to keep energy stable throughout the day.',
    },
    'health_tip_mid': {
      'id':
          'Tingkatkan asupan protein setelah aktivitas fisik untuk mendukung pemulihan otot dan menjaga metabolisme tetap optimal.',
      'en':
          'Increase protein intake after physical activity to support muscle recovery and keep metabolism optimal.',
    },
    'health_tip_high': {
      'id':
          'Pola makan kamu sudah sangat konsisten! Pastikan untuk tetap terhidrasi dan mengonsumsi cukup serat dari sayuran dan buah.',
      'en':
          'Your diet is very consistent! Make sure to stay hydrated and consume enough fiber from vegetables and fruits.',
    },

    // ================================
    // FOOD PREFERENCES SCREEN
    // ================================
    'food_preferences_title': {
      'id': 'Preferensi Makanan',
      'en': 'Food Preferences'
    },
    'food_pref_subtitle': {
      'id': 'Kelola makanan favorit dan yang dihindari',
      'en': 'Manage favorite and avoided foods',
    },
    'favorites_tab': {'id': 'Favorit', 'en': 'Favorites'},
    'avoided_tab': {'id': 'Dihindari', 'en': 'Avoided'},
    'no_favorites': {
      'id': 'Belum ada makanan favorit',
      'en': 'No favorite foods yet'
    },
    'no_avoided': {
      'id': 'Belum ada makanan dihindari',
      'en': 'No avoided foods yet'
    },

    // ================================
    // WATER TRACKER
    // ================================
    'water_intake': {'id': 'Asupan Air', 'en': 'Water Intake'},
    'glasses': {'id': 'gelas', 'en': 'glasses'},

    // ================================
    // ONBOARDING
    // ================================
    'welcome_title': {
      'id': 'Selamat Datang di FitMeal',
      'en': 'Welcome to FitMeal'
    },
    'next': {'id': 'Lanjut', 'en': 'Next'},
    'back': {'id': 'Kembali', 'en': 'Back'},
    'finish': {'id': 'Mulai', 'en': 'Start'},
    'your_name': {'id': 'Nama kamu', 'en': 'Your name'},
    'enter_name': {'id': 'Masukkan nama kamu', 'en': 'Enter your name'},
    'your_weight': {'id': 'Berat badan (kg)', 'en': 'Weight (kg)'},
    'your_height': {'id': 'Tinggi badan (cm)', 'en': 'Height (cm)'},
    'your_age': {'id': 'Umur', 'en': 'Age'},
    'your_gender': {'id': 'Jenis Kelamin', 'en': 'Gender'},
    'your_goal': {'id': 'Target Fitness', 'en': 'Fitness Goal'},
    'your_activity': {'id': 'Level Aktivitas', 'en': 'Activity Level'},

    // ================================
    // CALCULATOR SCREEN
    // ================================
    'bmi_calculator': {'id': 'Kalkulator BMI', 'en': 'BMI Calculator'},
    'calorie_calculator': {
      'id': 'Kalkulator Kalori',
      'en': 'Calorie Calculator'
    },
    'calculate': {'id': 'Hitung', 'en': 'Calculate'},
    'result': {'id': 'Hasil', 'en': 'Result'},

    // ================================
    // FOOD CARD BADGES
    // ================================
    'badge_balanced_label': {'id': 'Seimbang', 'en': 'Balanced'},
    'badge_high_protein_good_label': {
      'id': 'Protein Tinggi',
      'en': 'High Protein'
    },
    'badge_rich_protein_label': {'id': 'Kaya Protein', 'en': 'Rich in Protein'},
    'badge_fits_remaining_label': {
      'id': 'Pas Sisa Kalori',
      'en': 'Fits Remaining'
    },
    'badge_low_fat_label': {'id': 'Rendah Lemak', 'en': 'Low Fat'},

    // ================================
    // FOOD PREFERENCES SCREEN (extra)
    // ================================
    'add_food_preference': {
      'id': 'Tambah Preferensi Makanan',
      'en': 'Add Food Preference'
    },
    'add_food_pref_desc': {
      'id': 'Masukkan nama makanan yang ingin diprioritaskan atau dihindari',
      'en': 'Enter the food name you want to prioritize or avoid',
    },
    'food_name_hint': {
      'id': 'Contoh: Dada Ayam Rebus',
      'en': 'e.g.: Grilled Chicken Breast'
    },
    'prioritize': {'id': 'Prioritaskan', 'en': 'Prioritize'},
    'avoid': {'id': 'Hindari', 'en': 'Avoid'},
    'add_button': {'id': 'Tambahkan', 'en': 'Add'},
    'added_to_priority': {
      'id': 'ditambahkan ke prioritas ✅',
      'en': 'added to priority ✅'
    },
    'added_to_avoid': {
      'id': 'ditambahkan ke daftar hindari 🚫',
      'en': 'added to avoid list 🚫'
    },
    'reset_all_preferences': {
      'id': 'Reset Semua Preferensi?',
      'en': 'Reset All Preferences?'
    },
    'reset_pref_content': {
      'id':
          'Semua daftar makanan prioritas dan yang dihindari akan dihapus. Rekomendasi berikutnya akan menggunakan algoritma default.',
      'en':
          'All prioritized and avoided food lists will be cleared. Future recommendations will use the default algorithm.',
    },
    'all_preferences_reset': {
      'id': 'Semua preferensi direset ✅',
      'en': 'All preferences reset ✅'
    },
    'customize_recommendation': {
      'id': 'Kustomisasi Rekomendasi',
      'en': 'Customize Recommendations'
    },
    'customize_rec_desc': {
      'id':
          'Algoritma akan memprioritaskan makanan favoritmu dan menghindari yang tidak disukai.',
      'en':
          'The algorithm will prioritize your favorite foods and avoid the ones you dislike.',
    },
    'prioritize_section': {'id': 'PRIORITASKAN', 'en': 'PRIORITIZE'},
    'prioritize_desc': {
      'id': 'Algoritma akan lebih sering memasukkan makanan ini',
      'en': 'Algorithm will include this food more often'
    },
    'avoid_section': {'id': 'HINDARI', 'en': 'AVOID'},
    'avoid_desc': {
      'id': 'Makanan ini tidak akan muncul di rekomendasi',
      'en': 'This food won\'t appear in recommendations'
    },
    'no_prioritized_yet': {
      'id': 'Belum ada makanan yang diprioritaskan',
      'en': 'No prioritized foods yet'
    },
    'no_avoided_yet': {
      'id': 'Belum ada makanan yang dihindari',
      'en': 'No avoided foods yet'
    },
    'tap_to_add': {'id': 'Ketuk + untuk menambahkan', 'en': 'Tap + to add'},
    'reset_all_pref_btn': {
      'id': 'Reset Semua Preferensi',
      'en': 'Reset All Preferences'
    },
    'toggle_avoid': {'id': 'Hindari', 'en': 'Avoid'},
    'toggle_priority': {'id': 'Prioritas', 'en': 'Priority'},
    'item_removed': {'id': 'dihapus', 'en': 'removed'},

    // ================================
    // RECOMMENDATION SCREEN (extra)
    // ================================
    'reload': {'id': 'Muat ulang', 'en': 'Reload'},
    'added_to_meal_snack': {'id': 'ditambahkan ke', 'en': 'added to'},
    'accuracy_label': {'id': 'Akurasi', 'en': 'Accuracy'},
    'remaining_over': {'id': 'TERSISA', 'en': 'REMAINING'},
    'exceeded_over': {'id': 'MELEBIHI', 'en': 'EXCEEDED'},
    'added_label': {'id': 'Ditambahkan', 'en': 'Added'},
    'log_btn': {'id': 'Catat', 'en': 'Log'},
    // Result sheet and extra meal translations
    'your_meal_plan': {'id': 'Rencana Makan Anda', 'en': 'Your Meal Plan'},
    'based_on_body_data': {
      'id': 'Berdasarkan data tubuh & target Anda',
      'en': 'Based on your body data & targets'
    },
    'daily_needs_title': {'id': 'KEBUTUHAN HARIAN', 'en': 'DAILY NEEDS'},
    'bmi_status_title': {'id': 'Status BMI', 'en': 'BMI Status'},
    'underweight': {'id': 'Kurus', 'en': 'Underweight'},
    'normal': {'id': 'Ideal', 'en': 'Normal'},
    'overweight': {'id': 'Gemuk', 'en': 'Overweight'},
    'obese': {'id': 'Obesitas', 'en': 'Obese'},
  };

  /// Get a translated string by key and language code.
  static String get(String key, String lang) {
    return _strings[key]?[lang] ?? _strings[key]?['id'] ?? key;
  }
}
