import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF1E40AF); // Deep Medical Blue
  static const primaryDark = Color(0xFF93C5FD);
  static const secondary = Color(0xFF0D9488); // Clinical Teal
  static const secondaryDark = Color(0xFF5EEAD4);
  static const tertiary = Color(0xFF6D28D9); // High-Yield Purple
  static const tertiaryDark = Color(0xFFC4B5FD);

  static const backgroundLight = Color(0xFFF8FAFC);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceVariantLight = Color(0xFFF1F5F9);
  static const textLight = Color(0xFF0F172A);
  static const textMutedLight = Color(0xFF64748B);
  static const outlineLight = Color(0xFF94A3B8);
  static const outlineVariantLight = Color(0xFFE2E8F0);

  static const backgroundDark = Color(0xFF0B0F19);
  static const surfaceDark = Color(0xFF131B2E);
  static const surfaceVariantDark = Color(0xFF1E293B);
  static const textDark = Color(0xFFF8FAFC);
  static const textMutedDark = Color(0xFF94A3B8);
  static const outlineDark = Color(0xFF475569);
  static const outlineVariantDark = Color(0xFF334155);

  static const success = Color(0xFF16A34A);
  static const successDark = Color(0xFF4ADE80);
  static const warning = Color(0xFFD97706);
  static const warningDark = Color(0xFFFBBF24);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF0284C7);
  static const infoDark = Color(0xFF38BDF8);

  // INICET Tag Colors
  static const iniTag = Color(0xFF0284C7);
  static const neetTag = Color(0xFF16A34A);
  static const repeatTag = Color(0xFFDC2626);
  static const bothTag = Color(0xFFEA580C);
}

enum InicetCategory {
  preClinical('Pre-Clinical'),
  paraClinical('Para-Clinical'),
  clinical('Clinical & Allied'),
  surgical('Surgical Specialties');

  const InicetCategory(this.label);
  final String label;
}

enum InicetSubject {
  anatomy(
    '1. Anatomy',
    'Anatomy',
    Color(0xFF2563EB),
    Color(0xFFEFF6FF),
    Icons.accessibility_new_rounded,
    InicetCategory.preClinical,
    362,
    21.6,
  ),
  physiology(
    '2. Physiology',
    'Physiology',
    Color(0xFF0D9488),
    Color(0xFFCCFBF1),
    Icons.monitor_heart_rounded,
    InicetCategory.preClinical,
    307,
    22.8,
  ),
  biochemistry(
    '3. Biochemistry',
    'Biochemistry',
    Color(0xFFD97706),
    Color(0xFFFEF3C7),
    Icons.science_rounded,
    InicetCategory.preClinical,
    346,
    25.0,
  ),
  pathology(
    '4. Pathology',
    'Pathology',
    Color(0xFFDC2626),
    Color(0xFFFEE2E2),
    Icons.biotech_rounded,
    InicetCategory.paraClinical,
    619,
    17.4,
  ),
  microbiology(
    '5. Microbiology',
    'Microbiology',
    Color(0xFF7C3AED),
    Color(0xFFEDE9FE),
    Icons.coronavirus_rounded,
    InicetCategory.paraClinical,
    406,
    16.0,
  ),
  pharmacology(
    '6. Pharmacology',
    'Pharmacology',
    Color(0xFF059669),
    Color(0xFFD1FAE5),
    Icons.medication_rounded,
    InicetCategory.paraClinical,
    622,
    18.8,
  ),
  fmt(
    '7. FMT',
    'Forensic Medicine (FMT)',
    Color(0xFF475569),
    Color(0xFFF1F5F9),
    Icons.gavel_rounded,
    InicetCategory.paraClinical,
    322,
    21.8,
  ),
  ent(
    '8. ENT',
    'ENT (Otorhinolaryngology)',
    Color(0xFF4338CA),
    Color(0xFFE0E7FF),
    Icons.hearing_rounded,
    InicetCategory.clinical,
    194,
    26.8,
  ),
  psm(
    '9. PSM',
    'Community Medicine (PSM)',
    Color(0xFF15803D),
    Color(0xFFDCFCE7),
    Icons.groups_rounded,
    InicetCategory.paraClinical,
    504,
    19.4,
  ),
  ophthalmology(
    '10. Ophthalmology',
    'Ophthalmology',
    Color(0xFF0284C7),
    Color(0xFFE0F2FE),
    Icons.visibility_rounded,
    InicetCategory.clinical,
    288,
    25.0,
  ),
  medicine(
    '11. General Medicine',
    'General Medicine',
    Color(0xFF1D4ED8),
    Color(0xFFDBEAFE),
    Icons.local_hospital_rounded,
    InicetCategory.clinical,
    384,
    18.0,
  ),
  surgery(
    '12. General Surgery',
    'General Surgery',
    Color(0xFFC2410C),
    Color(0xFFFFEDD5),
    Icons.healing_rounded,
    InicetCategory.surgical,
    417,
    19.4,
  ),
  obstetrics(
    '13.1 Obstetrics',
    'Obstetrics',
    Color(0xFFDB2777),
    Color(0xFFFCE7F3),
    Icons.pregnant_woman_rounded,
    InicetCategory.surgical,
    455,
    22.6,
  ),
  gynaecology(
    '13.2 Gynaecology',
    'Gynaecology',
    Color(0xFFBE185D),
    Color(0xFFFDF2F8),
    Icons.female_rounded,
    InicetCategory.surgical,
    346,
    21.1,
  ),
  pediatrics(
    '14. Pediatrics',
    'Pediatrics',
    Color(0xFF0284C7),
    Color(0xFFBAE6FD),
    Icons.child_care_rounded,
    InicetCategory.clinical,
    420,
    20.2,
  ),
  anesthesia(
    '15. Anesthesia',
    'Anesthesia',
    Color(0xFF6366F1),
    Color(0xFFEEF2FF),
    Icons.air_rounded,
    InicetCategory.surgical,
    243,
    23.5,
  ),
  dermatology(
    '16. Dermatology',
    'Dermatology',
    Color(0xFFB45309),
    Color(0xFFFEF3C7),
    Icons.face_retouching_natural_rounded,
    InicetCategory.clinical,
    284,
    22.9,
  ),
  orthopedics(
    '17. Orthopedics',
    'Orthopedics',
    Color(0xFF78350F),
    Color(0xFFF5EBE6),
    Icons.elderly_rounded,
    InicetCategory.surgical,
    308,
    19.8,
  ),
  psychiatry(
    '18. Psychiatry',
    'Psychiatry',
    Color(0xFF86198F),
    Color(0xFFFAE8FF),
    Icons.psychology_rounded,
    InicetCategory.clinical,
    312,
    22.4,
  ),
  radiology(
    '19. Radiology',
    'Radiology',
    Color(0xFF0F766E),
    Color(0xFFCCFBF1),
    Icons.camera_alt_rounded,
    InicetCategory.clinical,
    323,
    24.1,
  );

  const InicetSubject(
    this.key,
    this.label,
    this.color,
    this.softColor,
    this.icon,
    this.category,
    this.questionCount,
    this.repeatPercent,
  );

  final String key;
  final String label;
  final Color color;
  final Color softColor;
  final IconData icon;
  final InicetCategory category;
  final int questionCount;
  final double repeatPercent;
}
