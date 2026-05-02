import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/domain/concepts/concept_registry.dart';
import 'package:math_dash/domain/proficiency/proficiency_band.dart';
import 'package:math_dash/domain/questions/arithmetic_generator.dart';
import 'package:math_dash/domain/questions/question.dart';
import 'package:math_dash/presentation/question/number_pad_widget.dart';
import 'package:math_dash/presentation/result/result_screen.dart';
import 'package:math_dash/state/proficiency_provider.dart';

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({
    required this.conceptId,
    required this.band,
    super.key,
  });

  final String conceptId;

  /// The proficiency band at the time the wheel landed.
  /// Determines input mode (MC vs number pad) and stars awarded.
  final ProficiencyBand band;

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  late final Question _question;
  late final List<String> _shuffledChoices;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _question = ArithmeticGenerator().generateForConcept(widget.conceptId);
    _shuffledChoices = List.of(_question.allChoices)..shuffle();
  }

  Future<void> _onAnswerSubmitted(String answer) async {
    if (_answered) return;
    _answered = true;

    final isCorrect = answer == _question.correctAnswer;

    // Persist proficiency update before navigating.
    await ref
        .read(proficiencyProvider.notifier)
        .recordAnswer(widget.conceptId, correct: isCorrect);

    if (!mounted) return;

    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            question: _question,
            selectedAnswer: answer,
            isCorrect: isCorrect,
            starsEarned: isCorrect ? starsForBand(widget.band) : 0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conceptName =
        findConceptById(widget.conceptId)?.name ?? widget.conceptId;
    final useNumberPad = widget.band == ProficiencyBand.comfortable;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(conceptName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              _PromptCard(prompt: _question.prompt),
              const Spacer(),
              if (useNumberPad)
                NumberPadWidget(onSubmit: _onAnswerSubmitted)
              else
                ..._shuffledChoices.map(
                  (choice) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _ChoiceButton(
                      label: choice,
                      onTap: () => _onAnswerSubmitted(choice),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Text(
          prompt,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        textStyle: theme.textTheme.headlineSmall,
      ),
      child: Text(label),
    );
  }
}
