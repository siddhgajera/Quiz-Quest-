import 'package:flutter/material.dart';
import 'add_edit_question_screen.dart';
import 'question_bank.dart';
import 'services/question_service.dart';
import 'utils/question_update_notifier.dart';

class AdminQuestionManagementScreen extends StatefulWidget {
  const AdminQuestionManagementScreen({super.key});

  @override
  State<AdminQuestionManagementScreen> createState() =>
      _AdminQuestionManagementScreenState();
}

class _AdminQuestionManagementScreenState
    extends State<AdminQuestionManagementScreen> {

  String selectedSubject = "All";
  String selectedDifficulty = "all";
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  List<String> subjects = ["All"];
  final List<String> difficulties = ["all", "easy", "medium", "hard"];

  bool isLoading = true;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    // No longer need to manually load subjects here as they are streamed
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _importFromQuestionBank() async {
    if (_importing) return;
    setState(() => _importing = true);

    try {
      final created = await QuestionService().importInitialData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import completed: Created $created questions in Firestore'),
          backgroundColor: Colors.green,
        ),
      );
      _loadSubjects();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.blue,
        ),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // Removed _getLocalQuestions and old _loadSubjects logic in favor of Streams

  Future<bool> _deleteFirestoreQuestion(String docId) async {
    try {
      await QuestionService().deleteQuestion(docId);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Management'),
        backgroundColor: Colors.blue[700],
        actions: [
          if (_importing)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSubjects(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 600;
                    final subjectField = StreamBuilder<List<String>>(
                      stream: QuestionService().streamCategories(),
                      builder: (context, catSnapshot) {
                        final currentSubjects = ["All", ...(catSnapshot.data ?? [])];
                        // Ensure selectedSubject is still valid
                        final displaySubject = currentSubjects.contains(selectedSubject) ? selectedSubject : "All";
                        
                        return DropdownButtonFormField<String>(
                          value: displaySubject,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: currentSubjects.map((subject) {
                            return DropdownMenuItem(
                              value: subject,
                              child: Text(subject, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSubject = value ?? "All";
                            });
                          },
                        );
                      },
                    );

                    final difficultyField = DropdownButtonFormField<String>(
                      value: difficulties.contains(selectedDifficulty) ? selectedDifficulty : "all",
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: difficulties.map((difficulty) {
                        return DropdownMenuItem(
                          value: difficulty,
                          child: Text(difficulty == "all" ? "All" : difficulty.toUpperCase(), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDifficulty = value ?? "all";
                        });
                      },
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: subjectField),
                          const SizedBox(width: 16),
                          Expanded(child: difficultyField),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          subjectField,
                          const SizedBox(height: 12),
                          difficultyField,
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search question text',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Question Count Badge
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: QuestionService().streamQuestions(
                    subject: selectedSubject,
                    difficulty: selectedDifficulty,
                  ),
                  builder: (context, qSnap) {
                    final count = qSnap.data?.where((q) {
                      if (searchQuery.trim().isEmpty) return true;
                      final text = (q['question'] ?? '').toString().toLowerCase();
                      return text.contains(searchQuery.toLowerCase());
                    }).length ?? 0;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count questions found',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditQuestionScreen(
                            subject: selectedSubject == "All" ? "History" : selectedSubject,
                            difficulty: selectedDifficulty == "all" ? "easy" : selectedDifficulty,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      await _loadSubjects();
                      setState(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Questions List from Firestore
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: QuestionService().streamQuestions(
                subject: selectedSubject,
                difficulty: selectedDifficulty,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final questions = snapshot.data ?? [];
                
                // Client-side search filtering
                final filteredQuestions = questions.where((q) {
                  if (searchQuery.trim().isEmpty) return true;
                  final text = (q['question'] ?? '').toString().toLowerCase();
                  return text.contains(searchQuery.toLowerCase());
                }).toList();

                if (filteredQuestions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          questions.isEmpty ? 'No questions in Firestore' : 'No matches found',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        if (questions.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _importFromQuestionBank,
                            icon: const Icon(Icons.download),
                            label: const Text('Import from QuestionBank'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredQuestions.length,
                  itemBuilder: (context, index) {
                    final questionData = filteredQuestions[index];
                    final docId = questionData['id'] as String;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(
                          'Q${index + 1}: ${questionData['question'] ?? 'No question text'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // ... (rest of the ExpansionTile content remains mostly same except using docId)
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Correct: ${questionData['correct'] ?? 'No answer'}',
                              style: TextStyle(color: Colors.green[700]),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    questionData['subject'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getDifficultyColor(questionData['difficulty']),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (questionData['difficulty'] ?? 'unknown').toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Answer Options:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...(questionData['answers'] as List? ?? []).map<Widget>(
                                      (answer) => Padding(
                                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          answer == questionData['correct']
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: answer == questionData['correct']
                                              ? Colors.green
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(answer.toString())),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _insertQuestionToUserUI(questionData),
                                      icon: const Icon(Icons.add_circle, color: Colors.green),
                                      label: const Text('Insert',
                                          style: TextStyle(color: Colors.green)),
                                    ),
                                    TextButton.icon(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddEditQuestionScreen(
                                              subject: questionData['subject'] ?? 'History',
                                              difficulty: questionData['difficulty'] ?? 'easy',
                                              questionToEdit: questionData,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      label: const Text('Edit',
                                          style: TextStyle(color: Colors.blue)),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        _showDeleteConfirmation(
                                          context,
                                          docId,
                                          (questionData['question'] ?? 'this question') as String,
                                        );
                                      },
                                      icon: const Icon(Icons.delete, color: Colors.blue),
                                      label: const Text('Delete',
                                          style: TextStyle(color: Colors.blue)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // No FAB; only refresh available as per requirements
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showDeleteConfirmation(BuildContext context, String docId, String questionText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Question'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to delete this question?'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  questionText,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.blue)),
              onPressed: () async {
                Navigator.of(context).pop();

                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleting question...')),
                );

                bool success = await _deleteFirestoreQuestion(docId);

                if (success) {
                  // Notify that questions have been updated
                  QuestionUpdateNotifier().notifyQuestionUpdated();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Question deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete question. Please try again.'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _insertQuestionToUserUI(Map<String, dynamic> questionData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String targetSubject = questionData['subject'] ?? 'General';
        String targetDifficulty = questionData['difficulty'] ?? 'easy';
        bool createNewSubject = false;
        String newSubjectName = "";
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.add_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Insert Question'),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Question to insert:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            questionData['question'] ?? 'No question text',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current: ${questionData['subject']} - ${questionData['difficulty']?.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Target subject selection
                    const Text(
                      'Insert into subject:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    RadioListTile<bool>(
                      title: const Text('Use existing subject'),
                      value: false,
                      groupValue: createNewSubject,
                      onChanged: (value) {
                        setDialogState(() {
                          createNewSubject = value!;
                        });
                      },
                    ),
                    
                    if (!createNewSubject)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: DropdownButtonFormField<String>(
                          value: subjects.contains(targetSubject) ? targetSubject : 
                                 (subjects.isNotEmpty && subjects.first != "All" ? subjects.first : "History"),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: subjects.where((s) => s != "All").map((subject) {
                            return DropdownMenuItem(
                              value: subject,
                              child: Text(subject),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              targetSubject = value ?? targetSubject;
                            });
                          },
                        ),
                      ),
                    
                    RadioListTile<bool>(
                      title: const Text('Create new subject'),
                      value: true,
                      groupValue: createNewSubject,
                      onChanged: (value) {
                        setDialogState(() {
                          createNewSubject = value!;
                        });
                      },
                    ),
                    
                    if (createNewSubject)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'New Subject Name',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (value) {
                            newSubjectName = value;
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Difficulty selection
                    const Text(
                      'Difficulty:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: targetDifficulty,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const ['easy', 'medium', 'hard'].map((difficulty) {
                        return DropdownMenuItem(
                          value: difficulty,
                          child: Text(difficulty.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          targetDifficulty = value ?? targetDifficulty;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final finalSubject = createNewSubject ? newSubjectName.trim() : targetSubject;
                    if (finalSubject.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid subject name'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    _performQuestionInsert(questionData, finalSubject, targetDifficulty);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Insert Question'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performQuestionInsert(
    Map<String, dynamic> questionData, 
    String targetSubject, 
    String targetDifficulty
  ) async {
    try {
      // Ensure target subject exists in QuestionBank
      QuestionBank.questions.putIfAbsent(targetSubject, () => {
        'easy': <Map<String, Object>>[],
        'medium': <Map<String, Object>>[],
        'hard': <Map<String, Object>>[],
      });

      final targetData = QuestionBank.questions[targetSubject]!;
      targetData.putIfAbsent(targetDifficulty, () => <Map<String, Object>>[]);
      final targetQuestions = targetData[targetDifficulty]!;

      // Create question object
      final newQuestion = {
        'question': questionData['question'],
        'answers': questionData['answers'],
        'correct': questionData['correct'],
      };

      // Check for duplicates
      final questionText = newQuestion['question'] as String;
      final isDuplicate = targetQuestions.any((q) => q['question'] == questionText);

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question already exists in "$targetSubject" - $targetDifficulty'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Insert the question
      targetQuestions.add(Map<String, Object>.from(newQuestion));

      // Notify that questions have been updated
      QuestionUpdateNotifier().notifyQuestionUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Question inserted into "$targetSubject" - $targetDifficulty successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Refresh the UI
      await _loadSubjects();
      setState(() {});

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inserting question: $e'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

}
