# INICET MCQ Hub

A local-first, cross-platform Flutter application built specifically for medical postgraduates preparing for **INI-CET**, **NEET-PG**, and **AIIMS** entrance examinations. Supports **Android**, **iOS**, **iPad / Android Tablets**, **Windows**, and **macOS** from a single shared Dart codebase.

Unlike general learning apps, **INICET MCQ Hub is a pure, distraction-free MCQ testing and practice platform** featuring 4,300+ medical questions across all 20 subjects with detailed explanations, repeat-trend analytics, configurable timers, and local JSON question management.

---

## Key Features

### 1. Unified Adaptive Navigation Shell
- Responsive layout supporting mobile, tablet, and desktop:
  - **Custom Test**: Tailor your test session with full granularity.
  - **Subject Practice Sets**: Curated high-yield practice modules across all 20 subjects (3,258 authored questions).
  - **Mock Tests**: Full-length papers weighted to the real INI-CET subject blueprint, assembled at random on every run.
  - **History & Analytics**: Comprehensive attempt log, cumulative accuracy trends, weak-subject alerts (<60%), and full review reloads.
  - **Bookmarks Hub**: Dedicated screen to practice and revise bookmarked questions.

### 2. High-Yield Practice & Exam Simulation
- **Persistent Top Timer Bar**:
  - Visible in **both Practice and Exam modes**.
  - Displays remaining countdown or elapsed stopwatch alongside per-question pace (e.g. *50s/Q pace*).
  - Includes **Pause/Resume** controls.
- **Anti-Distraction Blackout Pause Overlay**:
  - Hides question stems and options behind a centered blackout card while paused to prevent reading ahead with time frozen.
- **Live Question Status Tracker Ribbon**:
  - Real-time badges for **Solved** (green), **Unsolved** (grey), and **Skipped** (amber).
  - Automatically marks skipped questions when navigating past them without answering.
  - **"Next Unsolved" Jump Button**: Cycles directly to the next unattempted question without clicking through the entire question palette.
- **Option Elimination (Strike-Through)**:
  - Dedicated `(✕)` button on each option card to eliminate/dim distractors with strike-through styling without selecting the option.
  - Re-tap to restore eliminated options.
- **Text Sizing Control (A- / A+)**:
  - Dedicated font-size adjustment controls in the session header for comfortable reading of long clinical vignettes.
- **Personal Question Notes**:
  - Note icon on each question to write custom high-yield pearls, mnemonics, or takeaways.
  - Persisted locally across sessions to `user_notes.json`.
- **High-Yield "Key Takeaway" Pearl Callout**:
  - Prominent gold callout box highlighting the core exam pearl in each explanation.

### 3. Curated Subject Practice Sets (3,258 Questions across 20 Subjects)
- 20 standalone practice modules bundled directly into the app:
  - **Anatomy**: Head & Neck, Neuroanatomy, Thorax, Abdomen, Upper & Lower Limb, Embryology (150 MCQs).
  - **Physiology**: General, Nerve-Muscle, CVS, Respiratory, Renal, Neuro, Endocrine (150 MCQs).
  - **Biochemistry**: Enzymes, Metabolism, Molecular Biology, Genetics, Nutrition (150 MCQs).
  - **Pathology**: Hematology, Cell Injury, Inflammation, Neoplasia, Systemic Pathology (150 MCQs).
  - **Microbiology**: Bacteriology, Virology, Parasitology, Mycology, Immunology, Lab Diagnosis (150 MCQs).
  - **Pharmacology**: General Principles, ANS, CVS, CNS, Antimicrobials, Chemotherapy (150 MCQs).
  - **Forensic Medicine & Toxicology (FMT)**: Thanatology, Asphyxia, Mechanical Injuries, Firearms, Toxicology, Legal Procedure (150 MCQs).
  - **ENT (Otorhinolaryngology)**: Ear & Audiology, Vestibular, Nose & Sinuses, Larynx, Pharynx & Adenoids, Neck (150 MCQs).
  - **PSM (Community Medicine)**: Biostatistics, Epidemiology, Screening, Infectious Disease, Health Programmes, Vaccines (150 MCQs).
  - **Ophthalmology**: Retina & Vitreous, Glaucoma, Cornea, Neuro-ophthalmology, Optics, Cataract (150 MCQs).
  - **General Medicine**: Neurology, Cardiology, Respiratory & Critical Care, GI & Liver, Endocrine, Nephrology (150 MCQs).
  - **General Surgery**: Trauma & Burns, Breast, Biliary Tract & Pancreas, GI Surgery, Hernia, Thyroid, Urology (150 MCQs).
  - **Obstetrics**: Teratology, Placenta, Antenatal Care, Labour Mechanics, Pre-eclampsia, PPH, Fetal Monitoring (167 MCQs).
  - **Gynaecology**: Amenorrhoea, DSD, Contraception, Infertility, PCOS, Cervical & Ovarian Tumours, Prolapse (160 MCQs).
  - **Pediatrics**: Neonatology, Growth & Development, Nutrition, Infections & Immunisation, Inborn Errors, CNS, CVS (206 MCQs).
  - **Anesthesia**: Airway & Intubation, Inhaled & IV Agents, Neuromuscular Blockers, Local & Regional, Critical Care (148 MCQs).
  - **Dermatology**: Fungal, STDs, Leprosy, Viral & Bacterial, Papulosquamous, Vesiculobullous, Eczema, Hair & Pigmentary (172 MCQs).
  - **Orthopedics**: Upper & Lower Limb Fractures, Nerve Lesions, Spine & Pelvis, Pediatric Ortho, Bone Tumors, Clinical Tests (171 MCQs).
  - **Psychiatry**: Substance Use, Psychosis & Schizophrenia, Mood Disorders, Anxiety & OCD, Sleep & Eating, Psychopharmacology (209 MCQs).
  - **Radiology**: Radiophysics & Radiation Protection, Named Signs, Chest Imaging, Neuroimaging, MSK, Nuclear Medicine (225 MCQs).
- One-click launch with **"Start All Qs"**, **"Quick 50 Qs"**, or **"Sprint 25 Qs"**.
- **Interactive "Custom" Filters**:
  - Dedicated **"Custom"** button on each subject card opening a comprehensive filter modal.
  - **Sub-Topic Multi-Select**: Select/unselect specific topics with live item counts (e.g. *Head & Neck (24)*, *Neuroanatomy (28)*), with "Select All" and "Clear All" controls.
  - **Exam Source Filter**: Filter set by *All Exams*, *INI-CET Only*, *NEET-PG Only*, or *AIIMS Only*.
  - **2X+ High-Yield Repeats Filter**: Focus only on questions repeatedly tested in previous exam cycles.
  - **Study Mode**: Choose between Practice Mode (instant rationales & pearls) and Exam Mode (quiet simulation).
  - **Timer Options**: Toggle timer on/off, select 50s/Q pace or custom total exam duration.
  - **Question Count Selector**: Live matching counter with presets (10, 25, 50, All Matching) and fine-grained slider.
  - **Option & Question Randomization**: Shuffle choices (A, B, C, D) and randomize question order.

### 4. Full-Length Mock Papers (Blueprint Weighted, Randomly Drawn)
Subject-wise practice trains recall. Only a full paper trains pacing across 200 questions and the cost of switching subjects, so this section always assembles a complete paper.

- **Weighted to the real exam**: every subject appears in the proportion the recorded INI-CET papers asked it (2020–2024), so Pharmacology and Pathology dominate and Anaesthesia and ENT stay small — not twenty equal slices.
- **You choose the source mix**: a single slider sets how much of the paper is **previous-year questions** (the real past papers) and how much is **practice-set questions** (the authored ones). 0% to 100%, either extreme works.
- **Randomly drawn every time**: no two papers are the same, no question repeats inside a paper, and answers are spread evenly across A–D so the paper cannot be gamed by habit.
- **Subjects interleaved**, as in the real paper, rather than twenty blocks back to back.
- **Paper length** 20–200 questions, with 50 / 100 / 150 / 200 presets.
- **Time limit** at exam pace (54s per question) or a fixed 45 / 90 / 120 / 150 / 180 minutes — a full 180-minute paper is timed correctly.
- **Honest about thin pools**: six subjects have no previous-year questions bundled, and the screen names them rather than quietly substituting.
- **Consistent analytics**: drawn questions are relabelled to one canonical subject name, so a mock's per-subject accuracy does not split across the two spellings the underlying pools use.

The subject weights live in `assets/fixtures/mock_tests/blueprint.json`. Regenerate it after changing any source set:

```powershell
python ..\scripts\build_mock_tests.py
```

Add `--count 2 --markdown` to that command to also write printable papers to `Practice_Sets/Mock_Tests/` for sitting a paper away from the app.

### 5. Custom Test Setup Filters
- **Multi-Subject & Sub-Topic Selection**: Select individual subjects, multiple subjects, or "All Subjects".
- **Exam Source Filter**: Filter questions by exam source (**All**, **INI-CET Only**, **NEET-PG Only**, **AIIMS Only**).
- **2X+ High-Yield Repeats Filter**: Focus exclusively on questions tested multiple times in previous years.
- **Option & Question Shuffling**: Independent toggles to shuffle choice order (A, B, C, D) and randomize question presentation.

### 6. Test History, Scorecards & Cumulative Analytics
- **Local Persistence**: Automatically records every completed test session to `user_history.json`.
- **Cumulative Performance Dashboard**: Tracks total tests taken, total questions attempted, overall accuracy %, and subject-by-subject accuracy bars.
- **Weak Subject Focus Indicator**: Automatically alerts users if accuracy in any subject falls below 60%.
- **Review Full Test**: Re-open any past test session in full review mode to inspect answers, explanations, and pearls.

### 7. Local JSON Storage, Import & Export
- **Offline First**: All 4,300+ bundled questions run 100% locally without requiring internet access.
- **Persistent Local Files**:
  - `user_questions.json`: Custom imported question banks.
  - `user_bookmarks.json`: Saved bookmarked questions.
  - `user_notes.json`: High-yield personal takeaway notes.
  - `user_history.json`: Test session history and performance scorecards.
- **Flexible Import**: Pick `.json` files or paste JSON directly in the in-app editor.

---

## Question JSON Schema

To import custom questions via the JSON manager, questions should follow this schema:

```json
[
  {
    "id": "custom-q001",
    "subject": "Anatomy",
    "sub_topic": "Upper Limb",
    "stem": "Which structure passes through Guyon's canal?",
    "options": [
      "Ulnar nerve and artery",
      "Radial nerve",
      "Median nerve",
      "Axillary nerve"
    ],
    "correct_index": 0,
    "explanation": "Guyon canal (pisohamate canal) transmits the ulnar nerve and ulnar artery into the hand.",
    "tag": "INI-CET",
    "exam": "2024 INI-CET",
    "repeats": 3
  }
]
```

### Field Definitions:
- `id` *(string)*: Unique question identifier.
- `subject` *(string)*: Medical subject (e.g. *Anatomy*, *Physiology*, *Pharmacology*).
- `sub_topic` *(string)*: Topic within the subject (e.g. *Upper Limb*, *Autonomic Nervous System*).
- `stem` *(string)*: The question text.
- `options` *(array of 4 strings)*: Exactly 4 multiple-choice options.
- `correct_index` *(integer 0-3)*: Index of the correct answer (0 = A, 1 = B, 2 = C, 3 = D).
- `explanation` *(string)*: Detailed explanation and rationale.
- `tag` *(optional string)*: Tag such as `"INI-CET"`, `"NEET-PG"`, or `"AIIMS"`.
- `exam` *(optional string)*: Exam year/session.
- `repeats` *(optional integer)*: Times this topic was tested.

---

## Getting Started

### Prerequisites
- **Flutter SDK**: 3.49.0+ installed on `PATH`.
- **Windows**: Visual Studio 2022 with Desktop development with C++.
- **Android**: Android SDK (API 33-36) and an emulator or connected device.
- **macOS / iOS / iPadOS**: macOS with Xcode.

Run all commands from the `inicet_app` directory:

```powershell
cd e:\BS\Inicet\inicet_app
```

### 1. Verify Environment and Tests
```powershell
flutter pub get
flutter analyze
flutter test --reporter expanded
```

### 2. Run on Target Platform

#### Windows Desktop:
```powershell
flutter run -d windows
```

#### Android (Phone or Tablet):
```powershell
flutter devices
flutter run -d <device-id>
```

#### macOS Desktop:
```powershell
flutter run -d macos
```

#### iOS / iPad:
```powershell
flutter run -d <ios-device-id>
```

---

## Directory Architecture

```
inicet_app/
├── assets/fixtures/
│   ├── subject_data/questions_bank.json # 4,303 offline curated MCQs across 20 subjects
│   └── practice_sets/                   # 6 curated 150-MCQ sets (900 MCQs)
├── lib/
│   ├── app/
│   │   └── inicet_prep_app.dart    # App root, light/dark theme state & routing
│   ├── data/
│   │   └── question_repository.dart# Local persistence, JSON import/export, filtering
│   ├── domain/models/
│   │   ├── mcq_question.dart       # MCQ model, option elimination, repeats, bookmarks
│   │   ├── test_config.dart        # Test configuration (modes, timer, shuffle, filters)
│   │   ├── test_result.dart        # Session results, scoring & accuracy stats
│   │   └── user_note.dart          # Personal high-yield note model
│   ├── design_system/              # Reusable M3 design tokens & atomic components
│   └── features/
│       ├── navigation/             # Adaptive MainNavigationShell (tabs & rail)
│       ├── setup/                  # Subject/subtopic filters, question count & timer setup
│       ├── practice_sets/          # Dedicated 150-MCQ subject practice tab
│       ├── test/                   # Active test session, timer bar, blackout pause, strike-through
│       ├── history/                # Test history log, cumulative analytics & review reload
│       ├── result/                 # Scorecard, review filters, re-attempt incorrect
│       ├── bookmarks/              # Saved questions screen & practice launch
│       └── import/                 # JSON file picker, paste editor, export dialog
└── test/
    ├── question_repository_test.dart# Repository filtering, notes, history & practice set tests
    ├── features_test.dart          # Timer, blackout pause, option elimination, notes, tracker tests
    ├── widget_test.dart            # Full UI flow (Setup -> Session -> Result)
    ├── bootstrap_startup_test.dart # App launch & theme switching tests
    └── bootstrap_manifest_test.dart# Typed bootstrap manifest validation
```
