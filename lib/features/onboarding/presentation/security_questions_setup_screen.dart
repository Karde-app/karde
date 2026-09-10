import 'package:flutter/material.dart';
import '../../../core/widgets/karde_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/security/security_question_catalog.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../theme/theme.dart';
import 'onboarding_finish.dart';

class SecurityQuestionsSetupScreen extends ConsumerStatefulWidget {
  /// True when reached from Settings rather than from onboarding.
  ///
  /// Governs where the screen goes and how it looks: finishing returns to
  /// Settings instead of entering the app, and the screen follows the app theme
  /// rather than onboarding's fixed dark palette.
  ///
  /// It deliberately does *not* govern the wording. Settings can reach this
  /// screen with no questions saved yet — a Phone Lock user adding a Karde PIN,
  /// or anyone who chose Phone Lock or No Recovery at the recovery step — and
  /// calling that "Change your security questions" describes something they have
  /// never done. The wording follows [_hasExistingQuestions], which is read from
  /// storage.
  final bool isChanging;

  const SecurityQuestionsSetupScreen({super.key, this.isChanging = false});

  @override
  ConsumerState<SecurityQuestionsSetupScreen> createState() => _SecurityQuestionsSetupScreenState();
}

class _SecurityQuestionsSetupScreenState extends ConsumerState<SecurityQuestionsSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedQ1;
  String? _selectedQ2;

  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = false;

  /// Whether questions were already saved before this screen opened.
  ///
  /// The one thing that decides "Add" wording from "Change" wording. Held
  /// separately from [SecurityQuestionsSetupScreen.isChanging] because that flag
  /// answers a different question — see its documentation.
  bool _hasExistingQuestions = false;

  /// Stored question values, not sentences. A value from an older build is an
  /// English sentence rather than a code; `securityQuestionText` shows those
  /// verbatim, so a user keeps the question their answer was hashed against.
  final List<String> _questions = [
    for (final question in SecurityQuestion.values) question.code,
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingQuestions();
  }

  /// Pre-selects the questions already in use.
  ///
  /// Only the questions. The answers are stored as salted PBKDF2 hashes and
  /// cannot be read back — that is the entire point of hashing them, and if
  /// Karde could redisplay them so could anyone holding the phone. The note near
  /// the bottom of the screen says so, rather than leaving the user hunting for
  /// fields that were never going to fill themselves in.
  Future<void> _loadExistingQuestions() async {
    // The spinner is only for the Settings path. Onboarding has nothing stored to
    // wait for, and flashing a loading state at someone three screens into setup
    // reads as the app stalling.
    if (widget.isChanging) setState(() => _isLoading = true);
    final stored = await ref.read(settingsRepositoryProvider).getSecurityQuestions();
    if (!mounted) return;
    setState(() {
      final q1 = stored['q1'];
      final q2 = stored['q2'];
      // Both, not either: recovery asks for the pair, so one alone is not a set
      // of questions the user could be said to be "changing".
      _hasExistingQuestions =
          q1 != null && q1.isNotEmpty && q2 != null && q2.isNotEmpty;
      // A question saved by an older build might no longer be in the list. Adding
      // it back is better than silently dropping the user's own choice and
      // showing "Choose a question" as though they had never set one.
      if (q1 != null && q1.isNotEmpty) {
        if (!_questions.contains(q1)) _questions.add(q1);
        _selectedQ1 = q1;
      }
      if (q2 != null && q2.isNotEmpty) {
        if (!_questions.contains(q2)) _questions.add(q2);
        _selectedQ2 = q2;
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    // FIX 2-4: security answers are recovery credentials. Clear them rather than
    // leaving them in heap memory for whenever the GC gets to it.
    _answer1Controller.clear();
    _answer2Controller.clear();
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    super.dispose();
  }

  Future<void> _onFinishSetup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedQ1 == null || _selectedQ2 == null) {
      KardeFeedback.error(context, AppLocalizations.of(context)!.chooseBothQuestions);
      return;
    }
    if (_selectedQ1 == _selectedQ2) {
      KardeFeedback.error(context, AppLocalizations.of(context)!.chooseTwoDifferentQuestions);
      return;
    }

    setState(() => _isSaving = true);
    final settings = ref.read(settingsRepositoryProvider);

    // The answers are passed in as typed. This screen used to SHA-256 them first
    // and hand the digest to setSecurityQuestions, which then applied PBKDF2 to
    // that digest — while verification hashed the raw answer. The two could never
    // match, so security-question recovery could not succeed for anyone who set
    // it up here. Hashing belongs in one place, and that place is the repository.
    await settings.setSecurityQuestions(
      _selectedQ1!,
      _answer1Controller.text,
      _selectedQ2!,
      _answer2Controller.text,
    );

    // Setting questions is a statement of intent. A user who previously chose
    // "no recovery", or biometrics, and has now filled this in means to use it.
    await settings.setRecoveryPreference('questions');

    if (!mounted) return;

    if (widget.isChanging) {
      Navigator.pop(context);
      KardeFeedback.success(
        context,
        _hasExistingQuestions
            ? AppLocalizations.of(context)!.securityQuestionsUpdated
            : AppLocalizations.of(context)!.securityQuestionsSaved,
      );
      return;
    }

    await finishOnboarding(context, settings);
  }

  // Onboarding is fixed dark on every screen, so this one stays dark there. From
  // Settings it has to follow the app theme instead: hardcoded white-on-graphite
  // in a light-theme app is the same defect as audit finding 5-4.
  bool get _followsAppTheme => widget.isChanging;

  Color get _background => _followsAppTheme
      ? Theme.of(context).scaffoldBackgroundColor
      : KardeColors.graphite;

  Color get _foreground =>
      _followsAppTheme ? Theme.of(context).colorScheme.onSurface : Colors.white;

  Color get _surface => _followsAppTheme
      ? Theme.of(context).colorScheme.surface
      : KardeColors.obsidian;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _foreground),
          tooltip: loc.goBack,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: KardeColors.champagneGold),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    Text(
                      _hasExistingQuestions
                          ? loc.changeSecurityQuestionsTitle
                          : loc.setupQuestionsTitle,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: _foreground,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _hasExistingQuestions
                          ? loc.changeSecurityQuestionsSubtitle
                          : loc.setupQuestionsSubtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: _foreground.withValues(alpha: 0.65),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),

                    _buildQuestionBlock(
                      index: 1,
                      label: loc.question1,
                      selected: _selectedQ1,
                      other: _selectedQ2,
                      onPick: (value) => setState(() => _selectedQ1 = value),
                      answerController: _answer1Controller,
                      loc: loc,
                    ),
                    const SizedBox(height: 20),
                    _buildQuestionBlock(
                      index: 2,
                      label: loc.question2,
                      selected: _selectedQ2,
                      other: _selectedQ1,
                      onPick: (value) => setState(() => _selectedQ2 = value),
                      answerController: _answer2Controller,
                      loc: loc,
                    ),

                    const SizedBox(height: 24),
                    _buildHashNote(loc),
                  ],
                ),
              ),
      ),
      // Pinned rather than scrolled off the bottom, matching the Add Card form.
      bottomNavigationBar: _isLoading ? null : _buildSaveBar(loc),
    );
  }

  Widget _buildSaveBar(AppLocalizations loc) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _onFinishSetup,
            style: ElevatedButton.styleFrom(
              backgroundColor: KardeColors.champagneGold,
              foregroundColor: KardeColors.graphite,
              disabledBackgroundColor:
                  KardeColors.champagneGold.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 17),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KardeColors.graphite,
                    ),
                  )
                : Text(
                    widget.isChanging ? loc.saveQuestions : loc.finishSetup,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// One numbered question, its picker and its answer field.
  Widget _buildQuestionBlock({
    required int index,
    required String label,
    required String? selected,
    required String? other,
    required ValueChanged<String> onPick,
    required TextEditingController answerController,
    required AppLocalizations loc,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _followsAppTheme
            ? _surface
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected == null
              ? _foreground.withValues(alpha: 0.10)
              : KardeColors.champagneGold.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: KardeColors.champagneGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: KardeColors.champagneGold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: _foreground.withValues(alpha: 0.5),
                  fontSize: 11,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // The question itself: a tappable row opening a themed sheet, which is
          // the picker pattern the rest of the app already uses. It replaced a
          // bare DropdownButtonFormField, which looked out of place next to
          // everything else and made the current selection hard to read.
          InkWell(
            onTap: () => _showQuestionPicker(selected, other, onPick, loc),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: _foreground.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selected == null
                          ? loc.chooseAQuestion
                          : securityQuestionText(selected, loc),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.5,
                        height: 1.35,
                        fontWeight:
                            selected == null ? FontWeight.w400 : FontWeight.w600,
                        color: selected == null
                            ? _foreground.withValues(alpha: 0.45)
                            : _foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.expand_more,
                      color: _foreground.withValues(alpha: 0.5), size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: answerController,
            style: TextStyle(color: _foreground, fontFamily: 'Inter'),
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: loc.answer,
              labelStyle: TextStyle(
                color: _foreground.withValues(alpha: 0.5),
                fontFamily: 'Inter',
              ),
              filled: true,
              fillColor: _foreground.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: KardeColors.champagneGold,
                  width: 1.4,
                ),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return loc.answerRequired;
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// Explains why the answer boxes are empty even when questions are already set.
  Widget _buildHashNote(AppLocalizations loc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline,
            size: 17, color: _foreground.withValues(alpha: 0.45)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _hasExistingQuestions
                ? loc.securityAnswersHashNoteChanging
                : loc.securityAnswersHashNoteNew,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              height: 1.45,
              color: _foreground.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }

  void _showQuestionPicker(
    String? selected,
    String? other,
    ValueChanged<String> onPick,
    AppLocalizations loc,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: _foreground.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    loc.chooseAQuestion,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: _foreground,
                    ),
                  ),
                ),
              ),
              // Scrollable, because the list is taller than the sheet the moment
              // any row grows — and rows do grow: picking the first question adds
              // an "Already used above" line to it in the second picker, and a
              // long question wraps to two lines.
              //
              // Without this the Column simply overflowed and Flutter clipped it,
              // so the last question sat half-hidden behind the navigation bar,
              // dimmed and unreachable. Reported from the device as "picking the
              // first question greys out two questions": one of the two was the
              // genuine "already used above", the other was this clipped row.
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
              ..._questions.map((question) {
                final isSelected = question == selected;
                // Greyed rather than hidden, so the list does not reshuffle
                // between the two pickers and leave the user hunting.
                final takenByOther = question == other;

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                  enabled: !takenByOther,
                  title: Text(
                    securityQuestionText(question, loc),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      height: 1.35,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: takenByOther
                          ? _foreground.withValues(alpha: 0.3)
                          : (isSelected
                              ? KardeColors.champagneGold
                              : _foreground),
                    ),
                  ),
                  subtitle: takenByOther
                      ? Text(
                          loc.alreadyUsedAbove,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: _foreground.withValues(alpha: 0.35),
                          ),
                        )
                      : null,
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: KardeColors.champagneGold, size: 20)
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onPick(question);
                  },
                );
              }),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        );
      },
    );
  }
}
