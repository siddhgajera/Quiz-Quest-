import 'package:flutter/material.dart';
import 'question_bank.dart';
import 'utils/question_update_notifier.dart';

class AddEditQuestionScreen extends StatefulWidget {
  final String subject;
  final String difficulty;
  final Map<String, dynamic>? questionToEdit;
  final int? questionIndex;

  const AddEditQuestionScreen({
    super.key,
    required this.subject,
    required this.difficulty,
    this.questionToEdit,
    this.questionIndex,
  });

  @override
  State<AddEditQuestionScreen> createState() => _AddEditQuestionScreenState();
}

class _AddEditQuestionScreenState extends State<AddEditQuestionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _questionController = TextEditingController();
  final List<TextEditingController> _answerControllers =
  List.generate(4, (_) => TextEditingController());

  int _correctAnswerIndex = 0;
  bool _isEditing = false;
  bool _isLoading = false;

  String _selectedSubject = '';
  String _selectedDifficulty = '';

  List<String> _availableSubjects = [];
  final List<String> _difficulties = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.questionToEdit != null;
    _selectedSubject = widget.subject;
    _selectedDifficulty = widget.difficulty;

    _loadAvailableSubjects();

    if (_isEditing) {
      _populateFields();
    }
  }

  Future<void> _loadAvailableSubjects() async {
    // Load subjects from local QuestionBank
    final subjects = QuestionBank.questions.keys.toList()..sort();
    setState(() {
      _availableSubjects = subjects.isEmpty
          ? [
              'History',
              'Science',
              'Geography',
              'Literature',
              'Artificial Intelligence',
              'Python',
              'Cross Platform',
              'Mathematical'
            ]
          : subjects;
      if (!_availableSubjects.contains(_selectedSubject)) {
        _availableSubjects.add(_selectedSubject);
        _availableSubjects.sort();
      }
    });
  }

  void _populateFields() {
    final question = widget.questionToEdit!;
    _questionController.text = question['question'] as String? ?? '';

    // Set subject and difficulty from question data
    _selectedSubject = question['subject'] as String? ?? widget.subject;
    _selectedDifficulty = question['difficulty'] as String? ?? widget.difficulty;

    final answers = question['answers'] as List<dynamic>? ?? [];
    for (int i = 0; i < answers.length && i < 4; i++) {
      _answerControllers[i].text = answers[i].toString();
    }

    final correctAnswer = question['correct'] as String? ?? '';
    _correctAnswerIndex = answers.indexWhere((answer) => answer.toString() == correctAnswer);
    if (_correctAnswerIndex == -1) _correctAnswerIndex = 0;
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final answers = _answerControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

        if (answers.length < 2) {
          throw Exception('Please provide at least 2 answer options');
        }

        if (_correctAnswerIndex >= answers.length) {
          throw Exception('Please select a valid correct answer');
        }

        final correctAnswer = answers[_correctAnswerIndex];

        final questionData = {
          'question': _questionController.text.trim(),
          'answers': answers,
          'correct': correctAnswer,
        };

        if (_isEditing && widget.questionIndex != null) {
          // Update existing question
          final success = QuestionBank.updateQuestion(
            subject: _selectedSubject,
            difficulty: _selectedDifficulty,
            index: widget.questionIndex!,
            question: _questionController.text.trim(),
            answers: answers,
            correct: correctAnswer,
          );
          
          if (!success) {
            throw Exception('Failed to update question');
          }
          
          print('Admin: Updated question in $_selectedSubject/$_selectedDifficulty');
        } else {
          // Add new question
          QuestionBank.addQuestion(
            subject: _selectedSubject,
            difficulty: _selectedDifficulty,
            question: _questionController.text.trim(),
            answers: answers,
            correct: correctAnswer,
          );
          
          final newCount = QuestionBank.getQuestionCount(_selectedSubject, _selectedDifficulty);
          print('Admin: Added new question to $_selectedSubject/$_selectedDifficulty. Total questions now: $newCount');
        }

        // Notify that questions have been updated
        QuestionUpdateNotifier().notifyQuestionUpdated();

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Question updated successfully!'
                : 'Question added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success

      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Question' : 'Add New Question'),
        backgroundColor: Colors.blue[700],
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveQuestion,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject and Difficulty Selection
              Card(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'Question Settings',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Subject Dropdown
                      DropdownButtonFormField<String>(
                        value: _availableSubjects.contains(_selectedSubject) ? _selectedSubject : null,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.subject),
                        ),
                        items: _availableSubjects.map((subject) {
                          return DropdownMenuItem(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSubject = value ?? _selectedSubject;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a subject';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Difficulty Dropdown
                      DropdownButtonFormField<String>(
                        value: _difficulties.contains(_selectedDifficulty) ? _selectedDifficulty : 'easy',
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.speed),
                        ),
                        items: _difficulties.map((difficulty) {
                          return DropdownMenuItem(
                            value: difficulty,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getDifficultyColor(difficulty),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(difficulty.toUpperCase()),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDifficulty = value ?? _selectedDifficulty;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select difficulty level';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Question Text
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.quiz, color: Colors.green[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'Question',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _questionController,
                        decoration: const InputDecoration(
                          labelText: 'Enter your question',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          hintText: 'What is the capital of France?',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a question';
                          }
                          if (value.trim().length < 10) {
                            return 'Question should be at least 10 characters long';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {}); // Refresh preview
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Answer Options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.list, color: Colors.orange[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'Answer Options',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ...List.generate(4, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: index,
                                groupValue: _correctAnswerIndex,
                                activeColor: Colors.green,
                                onChanged: (value) {
                                  setState(() {
                                    _correctAnswerIndex = value!;
                                  });
                                },
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _answerControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Option ${String.fromCharCode(65 + index)}',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _correctAnswerIndex == index
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : null,
                                    filled: _correctAnswerIndex == index,
                                    fillColor: _correctAnswerIndex == index
                                        ? Colors.green[50]
                                        : null,
                                  ),
                                  validator: (value) {
                                    // At least first two options are required
                                    if (index < 2 && (value == null || value.trim().isEmpty)) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {}); // Refresh preview
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Correct Answer Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          border: Border.all(color: Colors.green[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select the correct answer by clicking the radio button. The correct answer is: Option ${String.fromCharCode(65 + _correctAnswerIndex)}',
                                style: TextStyle(color: Colors.green[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(_isEditing ? 'Updating...' : 'Adding...'),
                    ],
                  )
                      : Text(
                    _isEditing ? 'Update Question' : 'Add Question',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Preview Section
              if (_questionController.text.isNotEmpty) ...[
                const SizedBox(height: 30),
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.preview, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'Preview',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Subject: $_selectedSubject | Difficulty: ${_selectedDifficulty.toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _questionController.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(4, (index) {
                          if (_answerControllers[index].text.trim().isEmpty) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text('${String.fromCharCode(65 + index)}. '),
                                Expanded(child: Text(_answerControllers[index].text)),
                                if (_correctAnswerIndex == index)
                                  const Icon(Icons.check, color: Colors.green, size: 16),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.blue[300]!;
      default:
        return Colors.grey;
    }
  }
}
