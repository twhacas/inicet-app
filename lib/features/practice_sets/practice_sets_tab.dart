import 'package:flutter/material.dart';

import '../../data/question_repository.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/test_config.dart';
import '../test/mcq_session_screen.dart';
import 'practice_set_custom_modal.dart';

class PracticeSetsTab extends StatefulWidget {
  const PracticeSetsTab({
    required this.repository,
    super.key,
  });

  final QuestionRepository repository;

  @override
  State<PracticeSetsTab> createState() => _PracticeSetsTabState();
}

class _PracticeSetsTabState extends State<PracticeSetsTab> {
  TestMode _selectedMode = TestMode.practice;
  bool _isLoading = false;

  final List<_PracticeSetInfo> _sets = const [
    _PracticeSetInfo(
      subject: 'Anatomy',
      title: 'Anatomy — 150 Core PYQ Practice MCQs',
      topics: 'Head & Neck, Neuroanatomy, Thorax, Abdomen, Upper & Lower Limb, Embryology',
      icon: Icons.accessibility_new_rounded,
      color: Color(0xFF1E88E5),
    ),
    _PracticeSetInfo(
      subject: 'Physiology',
      title: 'Physiology — 150 Core PYQ Practice MCQs',
      topics: 'General, Nerve-Muscle, CVS, Respiratory, Renal, Neurophysiology, Endocrine',
      icon: Icons.monitor_heart_rounded,
      color: Color(0xFFE53935),
    ),
    _PracticeSetInfo(
      subject: 'Biochemistry',
      title: 'Biochemistry — 150 Core PYQ Practice MCQs',
      topics: 'Enzymes, Carbohydrate & Lipid Metabolism, Molecular Biology, Genetics, Nutrition',
      icon: Icons.biotech_rounded,
      color: Color(0xFF8E24AA),
    ),
    _PracticeSetInfo(
      subject: 'Pathology',
      title: 'Pathology — 150 Core PYQ Practice MCQs',
      topics: 'Hematology, Cell Injury, Inflammation, Neoplasia, Systemic & General Pathology',
      icon: Icons.coronavirus_rounded,
      color: Color(0xFFD81B60),
    ),
    _PracticeSetInfo(
      subject: 'Microbiology',
      title: 'Microbiology — 150 Core PYQ Practice MCQs',
      topics: 'Bacteriology, Virology, Parasitology, Mycology, Immunology, Lab Diagnosis',
      icon: Icons.science_rounded,
      color: Color(0xFF43A047),
    ),
    _PracticeSetInfo(
      subject: 'Pharmacology',
      title: 'Pharmacology — 150 Core PYQ Practice MCQs',
      topics: 'General Principles, ANS, CVS, CNS, Antimicrobials, Anticancer & Toxicology',
      icon: Icons.medication_rounded,
      color: Color(0xFFFB8C00),
    ),
    _PracticeSetInfo(
      subject: 'Forensic Medicine',
      title: 'FMT — 150 Core PYQ Practice MCQs',
      topics: 'Toxicology, Thanatology, Asphyxia, Mechanical Injuries, Firearms, Legal Procedure',
      icon: Icons.gavel_rounded,
      color: Color(0xFF5D4037),
    ),
    _PracticeSetInfo(
      subject: 'ENT',
      title: 'ENT — 150 Core PYQ Practice MCQs',
      topics: 'Ear & Audiology, Vestibular, Nose & Sinuses, Larynx, Pharynx & Adenoids, Neck',
      icon: Icons.hearing_rounded,
      color: Color(0xFF00897B),
    ),
    _PracticeSetInfo(
      subject: 'PSM',
      title: 'PSM (Community Medicine) — 150 Core PYQ Practice MCQs',
      topics: 'Biostatistics, Epidemiology, Screening, Infectious Disease, Health Programmes, Vaccines',
      icon: Icons.groups_rounded,
      color: Color(0xFF00ACC1),
    ),
    _PracticeSetInfo(
      subject: 'Ophthalmology',
      title: 'Ophthalmology — 150 Core PYQ Practice MCQs',
      topics: 'Retina & Vitreous, Glaucoma, Cornea, Neuro-ophthalmology, Optics, Cataract',
      icon: Icons.visibility_rounded,
      color: Color(0xFF3949AB),
    ),
    _PracticeSetInfo(
      subject: 'General Medicine',
      title: 'General Medicine — 150 Core PYQ Practice MCQs',
      topics: 'Neurology, Cardiology, Respiratory & Critical Care, GI & Liver, Endocrine, Nephrology',
      icon: Icons.medical_services_rounded,
      color: Color(0xFF0288D1),
    ),
    _PracticeSetInfo(
      subject: 'General Surgery',
      title: 'General Surgery — 150 Core PYQ Practice MCQs',
      topics: 'Trauma & Burns, Breast, Biliary Tract & Pancreas, GI Surgery, Hernia, Thyroid, Urology',
      icon: Icons.healing_rounded,
      color: Color(0xFFC2185B),
    ),
    _PracticeSetInfo(
      subject: 'Obstetrics',
      title: 'Obstetrics — 167 Core PYQ Practice MCQs',
      topics: 'Teratology, Placenta, Antenatal Care, Labour Mechanics, Pre-eclampsia, PPH, Fetal Monitoring',
      icon: Icons.pregnant_woman_rounded,
      color: Color(0xFF7B1FA2),
      count: 167,
    ),
    _PracticeSetInfo(
      subject: 'Gynaecology',
      title: 'Gynaecology — 160 Core PYQ Practice MCQs',
      topics: 'Amenorrhoea, DSD, Contraception, Infertility, PCOS, Cervical & Ovarian Tumours, Prolapse',
      icon: Icons.female_rounded,
      color: Color(0xFFE91E63),
      count: 160,
    ),
    _PracticeSetInfo(
      subject: 'Pediatrics',
      title: 'Pediatrics — 206 Core PYQ Practice MCQs',
      topics: 'Neonatology, Growth & Development, Nutrition, Infections & Immunisation, Inborn Errors, CNS, CVS',
      icon: Icons.child_care_rounded,
      color: Color(0xFF26A69A),
      count: 206,
    ),
    _PracticeSetInfo(
      subject: 'Anesthesia',
      title: 'Anesthesia — 148 Core PYQ Practice MCQs',
      topics: 'Airway & Intubation, Inhaled & IV Agents, Neuromuscular Blockers, Local & Regional, Critical Care',
      icon: Icons.masks_rounded,
      color: Color(0xFF546E7A),
      count: 148,
    ),
    _PracticeSetInfo(
      subject: 'Dermatology',
      title: 'Dermatology — 172 Core PYQ Practice MCQs',
      topics: 'Fungal, STDs, Leprosy, Viral & Bacterial, Papulosquamous, Vesiculobullous, Eczema, Hair & Pigmentary',
      icon: Icons.spa_rounded,
      color: Color(0xFFFF7043),
      count: 172,
    ),
    _PracticeSetInfo(
      subject: 'Orthopedics',
      title: 'Orthopedics — 171 Core PYQ Practice MCQs',
      topics: 'Upper & Lower Limb Fractures, Nerve Lesions, Spine & Pelvis, Pediatric Ortho, Bone Tumors, Clinical Tests',
      icon: Icons.personal_injury_rounded,
      color: Color(0xFF8D6E63),
      count: 171,
    ),
    _PracticeSetInfo(
      subject: 'Psychiatry',
      title: 'Psychiatry — 209 Core PYQ Practice MCQs',
      topics: 'Substance Use, Psychosis & Schizophrenia, Mood Disorders, Anxiety & OCD, Sleep & Eating, Psychopharmacology',
      icon: Icons.psychology_rounded,
      color: Color(0xFF5E35B1),
      count: 209,
    ),
    _PracticeSetInfo(
      subject: 'Radiology',
      title: 'Radiology — 225 Core PYQ Practice MCQs',
      topics: 'Radiophysics & Radiation Protection, Named Signs, Chest Imaging, Neuroimaging, MSK, Nuclear Medicine',
      icon: Icons.document_scanner_rounded,
      color: Color(0xFF00838F),
      count: 225,
    ),
  ];

  Future<void> _launchPracticeSet(String subject, {int? limit}) async {
    setState(() => _isLoading = true);
    final questions = await widget.repository.loadPracticeSet(subject);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No questions found for $subject.')),
      );
      return;
    }

    final selectedList = limit != null && limit < questions.length
        ? questions.take(limit).toList()
        : questions;

    final config = TestConfig(
      title: '$subject — ${selectedList.length} Practice MCQs',
      selectedSubjects: {subject},
      selectedSubTopics: {},
      questionCount: selectedList.length,
      mode: _selectedMode,
      timerEnabled: true,
      timerType: TimerType.perQuestion,
      timePerQuestionSeconds: 50,
      shuffleQuestions: false,
      shuffleOptions: false,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => McqSessionScreen(
          questions: selectedList,
          config: config,
          repository: widget.repository,
        ),
      ),
    );
  }

  void _openCustomModal(_PracticeSetInfo setInfo) {
    PracticeSetCustomModal.show(
      context,
      subject: setInfo.subject,
      subjectColor: setInfo.color,
      subjectIcon: setInfo.icon,
      repository: widget.repository,
      initialMode: _selectedMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Practice Sets'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppDimensions.contentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mode Switcher Banner
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.auto_stories_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'Curated Core Sets (3,258 Authored Questions across 20 Subjects)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Complete INI-CET pattern practice sets extracted from 2014–2024 PYQ clusters with full rationales.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SegmentedButton<TestMode>(
                                segments: const [
                                  ButtonSegment(
                                    value: TestMode.practice,
                                    icon: Icon(Icons.school_rounded),
                                    label: Text('Practice Mode'),
                                  ),
                                  ButtonSegment(
                                    value: TestMode.exam,
                                    icon: Icon(Icons.timer_rounded),
                                    label: Text('Exam Mode'),
                                  ),
                                ],
                                selected: {_selectedMode},
                                onSelectionChanged: (set) {
                                  setState(() => _selectedMode = set.first);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // List of 6 Subject Cards
                        for (final s in _sets) ...[
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: s.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.md,
                                        ),
                                      ),
                                      child: Icon(s.icon, color: s.color, size: 28),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.subject,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          AppBadge(
                                            label: '${s.count} QUESTIONS',
                                            color: AppColors.success,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  s.topics,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                                const Divider(height: AppSpacing.lg),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    AppButton(
                                      label: 'Start All ${s.count} Qs',
                                      icon: Icons.play_arrow_rounded,
                                      variant: AppButtonVariant.primary,
                                      onPressed: () =>
                                          _launchPracticeSet(s.subject),
                                    ),
                                    AppButton(
                                      label: 'Quick 50 Qs',
                                      variant: AppButtonVariant.outline,
                                      onPressed: () => _launchPracticeSet(
                                        s.subject,
                                        limit: 50,
                                      ),
                                    ),
                                    AppButton(
                                      label: 'Sprint 25 Qs',
                                      variant: AppButtonVariant.outline,
                                      onPressed: () => _launchPracticeSet(
                                        s.subject,
                                        limit: 25,
                                      ),
                                    ),
                                    AppButton(
                                      label: 'Custom',
                                      icon: Icons.tune_rounded,
                                      variant: AppButtonVariant.secondary,
                                      onPressed: () => _openCustomModal(s),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _PracticeSetInfo {
  const _PracticeSetInfo({
    required this.subject,
    required this.title,
    required this.topics,
    required this.icon,
    required this.color,
    this.count = 150,
  });

  final String subject;
  final String title;
  final String topics;
  final IconData icon;
  final Color color;
  final int count;
}
