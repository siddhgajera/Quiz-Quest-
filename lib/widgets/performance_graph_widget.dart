import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class PerformanceGraphWidget extends StatefulWidget {
  final String userId;

  const PerformanceGraphWidget({super.key, required this.userId});

  @override
  State<PerformanceGraphWidget> createState() => _PerformanceGraphWidgetState();
}

class _PerformanceGraphWidgetState extends State<PerformanceGraphWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quizAttempts')
          .where('uid', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error Loading Graph',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Quiz Data Yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete some quizzes to see your performance graph',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Process the data
        final quizData = _processQuizData(snapshot.data!.docs);
        
        if (quizData.isEmpty) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Quiz Data Yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildPerformanceGraph(quizData);
      },
    );
  }

  List<Map<String, dynamic>> _processQuizData(List<QueryDocumentSnapshot> docs) {
    try {
      
      if (docs.isEmpty) {
        return [];
      }

      // Sort by createdAt manually and take last 10
      final sortedDocs = docs.toList()
        ..sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return aTime.compareTo(bTime);
        });

      // Take last 10
      final recentDocs = sortedDocs.length > 10 
          ? sortedDocs.sublist(sortedDocs.length - 10) 
          : sortedDocs;

      final result = recentDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'percentage': data['percentage'] ?? 0,
          'score': data['score'] ?? 0,
          'correctAnswers': data['correctAnswers'] ?? 0,
          'totalQuestions': data['totalQuestions'] ?? 0,
          'subject': data['subject'] ?? 'Quiz',
          'createdAt': data['createdAt'] as Timestamp?,
        };
      }).toList();

      return result;
    } catch (e) {
      return [];
    }
  }

  Widget _buildPerformanceGraph(List<Map<String, dynamic>> quizData) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.teal[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Last ${quizData.length} quizzes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
                child: ClipRect(
                  child: LineChart(
                  LineChartData(
                    clipData: FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < quizData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                'Q${value.toInt() + 1}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          // Only show labels for 0, 25, 50, 75, 100
                          if (value == 0 || value == 25 || value == 50 || value == 75 || value == 100) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                '${value.toInt()}%',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey[300]!),
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  minX: 0,
                  maxX: (quizData.length - 1).toDouble(),
                  minY: 0,
                  maxY: 105, // Add 5% padding at top to prevent line from going out
                  lineBarsData: [
                    LineChartBarData(
                      spots: quizData.asMap().entries.map((entry) {
                        final percentage = (entry.value['percentage'] as int).toDouble();
                        return FlSpot(
                          entry.key.toDouble(),
                          percentage,
                        );
                      }).toList(),
                      isCurved: false, // Use straight lines instead of curves
                      color: Colors.teal[600],
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final percentage = spot.y;
                          Color dotColor;
                          if (percentage >= 80) {
                            dotColor = Colors.green;
                          } else if (percentage >= 60) {
                            dotColor = Colors.blue;
                          } else if (percentage >= 40) {
                            dotColor = Colors.orange;
                          } else {
                            dotColor = Colors.red;
                          }
                          return FlDotCirclePainter(
                            radius: 5,
                            color: dotColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.teal[600]!.withValues(alpha: 0.3),
                            Colors.teal[600]!.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final quizIndex = spot.x.toInt();
                          if (quizIndex >= 0 && quizIndex < quizData.length) {
                            final quiz = quizData[quizIndex];
                            final subject = quiz['subject'] ?? 'Quiz';
                            final percentage = quiz['percentage'] ?? 0;
                            final correct = quiz['correctAnswers'] ?? 0;
                            final total = quiz['totalQuestions'] ?? 0;
                            
                            return LineTooltipItem(
                              '$subject\n$percentage%\n$correct/$total correct',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                    touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                      // Optional: Add haptic feedback or other interactions
                    },
                    handleBuiltInTouches: true,
                  ),
                  ),
                ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildLegendItem('Excellent', Colors.green, '80%+'),
        _buildLegendItem('Good', Colors.blue, '60-79%'),
        _buildLegendItem('Fair', Colors.orange, '40-59%'),
        _buildLegendItem('Needs Work', Colors.red, '<40%'),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String range) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($range)',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
