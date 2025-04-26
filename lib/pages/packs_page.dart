import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:cycle_guard_app/data/packs_accessor.dart';

class PacksPage extends StatefulWidget {
  const PacksPage({super.key});

  @override
  State<PacksPage> createState() => _PacksPageState();
}

class _PacksPageState extends State<PacksPage> {
  PackData? _myPack;
  bool _loading = true;

  final List<int> _challengeDistances = [50, 100, 250, 500];

  @override
  void initState() {
    super.initState();
    _loadPack();
  }

  Future<void> _loadPack() async {
    final pack = await PacksAccessor.getPackData();
    setState(() {
      _myPack = pack;
      _loading = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _leavePack() async {
    final userStats = Provider.of<UserStatsProvider>(context, listen: false);
    if (userStats.username == _myPack?.owner) {
      await PacksAccessor.leavePackAsOwner(PacksAccessor.NO_NEW_OWNER);
    } else {
      await PacksAccessor.leavePack();
    }

    await _loadPack();
  }

  void _showCreatePackDialog(int goalAmount) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            isDarkMode ? Theme.of(context).colorScheme.onPrimaryFixed : null,
        title: Text(
          'Create Pack',
          style: TextStyle(color: isDarkMode ? Colors.white : null),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Pack Name',
                labelStyle:
                    TextStyle(color: isDarkMode ? Colors.white70 : null),
                enabledBorder: isDarkMode
                    ? const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      )
                    : null,
                focusedBorder: isDarkMode
                    ? const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      )
                    : null,
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : null),
            ),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle:
                    TextStyle(color: isDarkMode ? Colors.white70 : null),
                enabledBorder: isDarkMode
                    ? const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      )
                    : null,
                focusedBorder: isDarkMode
                    ? const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      )
                    : null,
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDarkMode ? Colors.white : null),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final pass = passController.text;
              await PacksAccessor.createPack(name, pass);
              await PacksAccessor.setPackGoal(
                60 * 60 * 24 * 7,
                PacksAccessor.GOAL_DISTANCE,
                goalAmount,
              );
              Navigator.of(context).pop();
              _loadPack();
            },
            child: Text(
              'Create',
              style: TextStyle(color: isDarkMode ? Colors.white : null),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinPackDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            isDarkMode ? Theme.of(context).colorScheme.onPrimaryFixed : null,
        title: Text(
          'Join Pack',
          style: TextStyle(color: isDarkMode ? Colors.white : null),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Pack Name',
                labelStyle:
                    TextStyle(color: isDarkMode ? Colors.white70 : null),
                enabledBorder: isDarkMode
                    ? const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      )
                    : null,
                focusedBorder: isDarkMode
                    ? const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      )
                    : null,
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : null),
            ),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle:
                    TextStyle(color: isDarkMode ? Colors.white70 : null),
                enabledBorder: isDarkMode
                    ? const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      )
                    : null,
                focusedBorder: isDarkMode
                    ? const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      )
                    : null,
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDarkMode ? Colors.white : null),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final pass = passController.text;
              try {
                await PacksAccessor.joinPack(name, pass);
                Navigator.of(context).pop();
                _loadPack();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pack does not exist')),
                );
              }
            },
            child: Text(
              'Join',
              style: TextStyle(color: isDarkMode ? Colors.white : null),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _buildMemberColors(Map<String, double> contributions, BuildContext context) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.onPrimaryFixedVariant,
      Theme.of(context).colorScheme.onSecondaryFixedVariant,
      Theme.of(context).colorScheme.onTertiaryFixedVariant,
    ];

    final map = <String, Color>{};
    int index = 0;

    // Ensure each member gets a color (including non-contributors)
    for (final member in contributions.keys) {
      map[member] = colors[index];
      index++;
      if (index >= colors.length) {
        index = 0;
      }
    }

    return map;
  }

  List<PieChartSectionData> _buildContributionChartSections(
      PackGoal goal, Map<String, Color> colorMap) {
    final List<PieChartSectionData> sections = [];
    final total = goal.goalAmount.toDouble();
    final remainder = (total - goal.totalContribution).clamp(0.0, total);

    goal.contributionMap.forEach((member, value) {
      if (value <= 0.0) return;
      sections.add(PieChartSectionData(
        color: colorMap[member],
        value: value,
        title: '',
        radius: 60,
      ));
    });

    // Add "Remaining" slice
    sections.add(PieChartSectionData(
      color: Colors.grey.shade400,
      value: remainder == 0.0 ? total : remainder,
      title: '',
      radius: 60,
    ));

    return sections;
  }

  Widget _buildMyPackSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_myPack == null) return const SizedBox();

    final userStats = Provider.of<UserStatsProvider>(context, listen: false);
    final isOwner = userStats.username == _myPack?.owner;

    final goal = _myPack!.packGoal;
    final members = _myPack!.memberList;
    final double progress = (goal.goalAmount > 0)
        ? (goal.totalContribution / goal.goalAmount).clamp(0.0, 1.0)
        : 0.0;

    final memberColors = _buildMemberColors(goal.contributionMap, context);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(12),
      color: isDarkMode ? Theme.of(context).colorScheme.onPrimaryFixed : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  _myPack!.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color:
                    isDarkMode ? Theme.of(context).colorScheme.primary : null,
                backgroundColor: isDarkMode
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: goal.goalAmount == 0
                          ? 'No goal set, the pack owner can set a new goal!'
                          : 'Goal: ${goal.goalAmount} mi\n',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : null,
                      ),
                    ),
                    TextSpan(
                      text:
                          'Total: ${goal.totalContribution.toStringAsFixed(1)} mi\n',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : null,
                      ),
                    ),
                    TextSpan(
                      text:
                          'Remaining: ${(goal.goalAmount - goal.totalContribution).clamp(0.0, goal.goalAmount).toStringAsFixed(1)} mi',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              Text(
                'Pack Members:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              ...(() {
                final memberEntries = members.map((member) {
                  final value = goal.contributionMap[member] ?? 0.0;
                  return MapEntry(member, value);
                }).toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return List.generate(memberEntries.length, (index) {
                  final entry = memberEntries[index];
                  final member = entry.key;
                  final value = entry.value;
                  final color = memberColors[member];
                  final percent =
                      (value / goal.goalAmount * 100).toStringAsFixed(1);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.rectangle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            member,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : null,
                            ),
                          ),
                        ),
                        Text(
                          '${value.toStringAsFixed(1)} mi : $percent%',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : null,
                          ),
                        ),
                      ],
                    ),
                  );
                });
              })(),
              const SizedBox(height: 12),
              if (goal.goalAmount > 0) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Contribution Breakdown',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections:
                          _buildContributionChartSections(goal, memberColors),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (isOwner) ...[
                if (goal.goalAmount > 0)
                  ElevatedButton(
                    onPressed: () async {
                      final shouldCancel = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: isDarkMode
                              ? Theme.of(context).colorScheme.onPrimaryFixed
                              : null,
                          title: Text(
                            'Are you sure?',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : null,
                            ),
                          ),
                          content: Text(
                            "Canceling a goal will lose all goal progress forever.",
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : null,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'No',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : null,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                'Yes',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.red[300] : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (shouldCancel == true) {
                        try {
                          final success = await PacksAccessor.cancelPackGoal();
                          if (success) {
                            await _loadPack();
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Failed to cancel goal: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Cancel Goal'),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set a new goal:',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : null,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [100, 250, 500].map((amount) {
                          return ElevatedButton(
                            onPressed: () async {
                              try {
                                await PacksAccessor.setPackGoal(
                                  60 * 60 * 24 * 7,
                                  PacksAccessor.GOAL_DISTANCE,
                                  amount,
                                );
                                await _loadPack();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Failed to set goal: $e')),
                                );
                              }
                            },
                            child: Text('$amount mi'),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final shouldLeave = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: isDarkMode
                          ? Theme.of(context).colorScheme.onPrimaryFixed
                          : null,
                      title: Text(
                        'Are you sure?',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : null,
                        ),
                      ),
                      content: Text(
                        "If you leave a pack your progress towards its contribution will be lost forever.",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : null,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'No',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : null,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            'Yes',
                            style: TextStyle(
                              color: isDarkMode ? Colors.red[300] : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (shouldLeave == true) {
                    _leavePack();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  'Leave Pack',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeCard(int distance) {
    final bool disabled = _myPack != null;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      color: isDarkMode ? Theme.of(context).colorScheme.onPrimaryFixed : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '$distance Mile Challenge',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : null,
              ),
            ),
            ElevatedButton(
              onPressed: disabled
                  ? () => _showMessage('You can only be in one pack at a time.')
                  : () => _showCreatePackDialog(distance),
              style: ElevatedButton.styleFrom(
                elevation: 4,
                backgroundColor: disabled
                    ? Colors.grey
                    : isDarkMode
                        ? Theme.of(context).colorScheme.secondary
                        : null,
                foregroundColor: isDarkMode ? Colors.white70 : null,
              ),
              child: const Text('Accept Challenge'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final bool isInPack = _myPack != null;

    if (isInPack) {
      return _buildMyPackSection();
    }

    return ListView(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ElevatedButton(
            onPressed: _showJoinPackDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDarkMode ? Theme.of(context).colorScheme.secondary : null,
              foregroundColor: isDarkMode ? Colors.white : null,
              elevation: 4,
            ),
            child: const Text('Join Pack'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Center(
            child: Text(
              'Available Challenges',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ..._challengeDistances.map(_buildChallengeCard).toList(),
      ],
    );
  }
}
