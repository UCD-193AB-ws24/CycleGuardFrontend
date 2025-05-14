import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:cycle_guard_app/data/packs_accessor.dart';
import 'package:cycle_guard_app/data/pack_invites_accessor.dart';
import 'package:confetti/confetti.dart';

class PacksPage extends StatefulWidget {
  const PacksPage({super.key});

  @override
  State<PacksPage> createState() => _PacksPageState();
}

class _PacksPageState extends State<PacksPage> {
  PackData? _myPack;
  PackInvites? _myInvites;
  bool _loading = true;
  bool _sendingInvite = false;
  bool isConfettiPlaying = false;

  final List<int> _challengeDistances = [50, 100, 250, 500];
  final _confettiController = ConfettiController(duration: Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final pack = await PacksAccessor.getPackData();
      final invites = await PackInvitesAccessor.getInvites();

      if (mounted) {
        setState(() {
          _myPack = pack;
          _myInvites = invites;
          _loading = false;

          if (pack == null) {
            if (mounted) {
              setState(() {
                _loading = false;
              });
            }
            return;
          }

          final goal = pack.packGoal;
          final goalReached = goal.totalContribution >= goal.goalAmount && goal.goalAmount != 0;

          if (goalReached && !isConfettiPlaying) {
            _confettiController.play();
            isConfettiPlaying = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to load data: $e');
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _leavePack() async {
    final userStats = Provider.of<UserStatsProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (userStats.username == _myPack?.owner) {
      final members = _myPack!.memberList;

      final selectableMembers =
          members.where((m) => m != userStats.username).toList();

      String newOwnerToAssign = PacksAccessor.NO_NEW_OWNER;

      if (selectableMembers.isNotEmpty) {
        String? selectedNewOwner;

        // Show dropdown dialog
        await showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: isDarkMode
                      ? Theme.of(context).colorScheme.onPrimaryFixed
                      : null,
                  title: Text(
                    "Select New Pack Leader",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : null,
                    ),
                  ),
                  content: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: isDarkMode
                        ? Theme.of(context).colorScheme.onPrimaryFixed
                        : null,
                    hint: Text(
                      "Select a member",
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : null,
                      ),
                    ),
                    value: selectedNewOwner,
                    items: selectableMembers.map((member) {
                      return DropdownMenuItem(
                        value: member,
                        child: Text(
                          member,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : null,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedNewOwner = value;
                      });
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : null,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (selectedNewOwner == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Please select a new leader")),
                          );
                          return;
                        }
                        newOwnerToAssign = selectedNewOwner!;
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "Confirm",
                        style: TextStyle(
                          color: isDarkMode ? Colors.red[300] : null,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );

        // If still NO_NEW_OWNER, that means dialog was cancelled or no selection was made
        if (newOwnerToAssign == PacksAccessor.NO_NEW_OWNER &&
            selectableMembers.isNotEmpty) {
          return; // Abort leave process
        }
      }

      try {
        await PacksAccessor.leavePackAsOwner(newOwnerToAssign);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to leave pack: $e")),
        );
        return;
      }
    } else {
      try {
        await PacksAccessor.leavePack();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to leave pack: $e")),
        );
        return;
      }
    }

    await _loadData();
  }

  void _showInviteMemberDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            isDarkMode ? Theme.of(context).colorScheme.onPrimaryFixed : null,
        title: Text(
          'Invite Member',
          style: TextStyle(color: isDarkMode ? Colors.white : null),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
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
              final username = usernameController.text.trim();
              if (username.isNotEmpty) {
                Navigator.of(context).pop();
                if (!mounted) return;
                setState(() {
                  _sendingInvite = true;
                });

                try {
                  await PackInvitesAccessor.sendInvite(username);
                  if (!mounted) return;
                  _showMessage('Invite sent to $username');
                  await _loadData();
                } catch (e) {
                  if (!mounted) return;
                  _showMessage('Failed to send invite: $e');
                } finally {
                  if (mounted) {
                    setState(() {
                      _sendingInvite = false;
                    });
                  }
                }
              }
            },
            child: Text(
              'Send Invite',
              style: TextStyle(color: isDarkMode ? Colors.white : null),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelInvite(String username) async {
    try {
      await PackInvitesAccessor.cancelInvite(username);
      _showMessage('Invite to $username canceled');
      await _loadData();
    } catch (e) {
      _showMessage('Failed to cancel invite: $e');
    }
  }

  Future<void> _acceptInvite(String packName) async {
    try {
      await PackInvitesAccessor.acceptInvite(packName);
      _showMessage('Joined pack: $packName');
      await _loadData();
    } catch (e) {
      _showMessage('Failed to accept invite: $e');
    }
  }

  Future<void> _declineInvite(String packName) async {
    try {
      await PackInvitesAccessor.declineInvite(packName);
      _showMessage('Declined invite from: $packName');
      await _loadData();
    } catch (e) {
      _showMessage('Failed to decline invite: $e');
    }
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

              // Check if either field is empty
              if (name.isEmpty || pass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Please fill in both the name and password.')),
                );
                return;
              }

              try {
                // Create the pack if both fields are filled
                bool success = await PacksAccessor.createPack(name, pass);
                if (success) {
                  await PacksAccessor.setPackGoal(
                    60 * 60 * 24 * 7,
                    PacksAccessor.GOAL_DISTANCE,
                    goalAmount,
                  );
                  Navigator.of(context).pop();
                  _loadData();
                }
              } catch (e) {
                String errorMessage = 'An unexpected error occurred';
                if (e is String) {
                  errorMessage = e;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMessage)),
                );
              }
            },
            child: Text(
              'Create',
              style: TextStyle(color: isDarkMode ? Colors.white : null),
            ),
          )
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
                _loadData();
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

  Map<String, Color> _buildMemberColors(
      Map<String, double> contributions, BuildContext context) {
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
    final goalReached =
        goal.totalContribution >= goal.goalAmount && goal.goalAmount != 0;

    goal.contributionMap.forEach((member, value) {
      if (value <= 0.0) return;
      sections.add(PieChartSectionData(
        color: colorMap[member],
        value: value,
        title: '',
        radius: 100,
        borderSide: goalReached
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ));
    });

    // Add "Remaining" slice
    sections.add(PieChartSectionData(
      color: Colors.grey.shade400,
      value: remainder,
      title: '',
      radius: 100,
      borderSide: goalReached
          ? const BorderSide(color: Colors.amber, width: 2)
          : BorderSide.none,
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
    final invites = _myPack!.invites;
    final double progress = (goal.goalAmount > 0)
        ? (goal.totalContribution / goal.goalAmount).clamp(0.0, 1.0)
        : 0.0;
    final bool goalReached = goal.totalContribution >= goal.goalAmount && goal.goalAmount != 0;

    final memberColors = _buildMemberColors(goal.contributionMap, context);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
      Card(
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
                  color: (goal.totalContribution >= goal.goalAmount &&
                          goal.goalAmount != 0)
                      ? Colors.amber
                      : (isDarkMode
                          ? Theme.of(context).colorScheme.primary
                          : null),
                  backgroundColor: isDarkMode
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                const SizedBox(height: 8),
                goal.totalContribution >= goal.goalAmount &&
                        goal.goalAmount != 0
                    ? Text.rich(
                        TextSpan(
                          text:
                              'Congratulations! You completed the ${goal.goalAmount.toStringAsFixed(0)} mi challenge!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      )
                    : Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: goal.goalAmount == 0
                                  ? 'No goal set, the pack owner can set a new goal!\n'
                                  : 'Goal: ${goal.goalAmount} mi\n',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? Colors.white : null,
                              ),
                            ),
                            if (goal.goalAmount != 0) ...[
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
                                    'Remaining: ${(goal.goalAmount - goal.totalContribution).clamp(0.0, goal.goalAmount).toStringAsFixed(1)} mi\n',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.white : null,
                                ),
                              ),
                              TextSpan(
                                text:
                                    'Ends on: ${DateTime.fromMillisecondsSinceEpoch(goal.endTime * 1000).toLocal().toString().split(' ')[0]}\n',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.white : null,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                // cancel goal
                if (isOwner) ...[
                  if (goal.goalAmount > 0)
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 2,
                        ),
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
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text(
                                    'No',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white70 : null,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text(
                                    'Yes',
                                    style: TextStyle(
                                      color:
                                          isDarkMode ? Colors.red[300] : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (shouldCancel == true) {
                            try {
                              final success =
                                  await PacksAccessor.cancelPackGoal();
                              if (success) {
                                await _loadData();
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
                      ),
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
                          children: [50, 100, 250, 500].map((amount) {
                            return ElevatedButton(
                              onPressed: () async {
                                try {
                                  await PacksAccessor.setPackGoal(
                                    60 * 60 * 24 * 7,
                                    PacksAccessor.GOAL_DISTANCE,
                                    amount,
                                  );
                                  await _loadData();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Failed to set goal: $e')),
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
                const Divider(height: 28),
                Center(
                  child: Text(
                    'Pack Member Contribution:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : null,
                    ),
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
                            (goal.goalAmount == 0 || value == 0)
                                ? '    ---    '
                                : '${value.toStringAsFixed(1)} mi : ${((value / goal.goalAmount) * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  });
                })(),
                const SizedBox(height: 20),
                if (goal.goalAmount > 0) ...[
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                        sections:
                            _buildContributionChartSections(goal, memberColors),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Invites section (for pack owner)
                if (isOwner) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pending Invites:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : null,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          elevation: 2,
                        ),
                        onPressed:
                            _sendingInvite ? null : _showInviteMemberDialog,
                        icon: _sendingInvite
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDarkMode ? Colors.white54 : null,
                                ),
                              )
                            : const Icon(Icons.person_add),
                        label: const Text('Invite Member'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (invites.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No pending invites',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: isDarkMode ? Colors.white70 : Colors.grey,
                        ),
                      ),
                    )
                  else
                    ...invites
                        .map((username) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    username,
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : null,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _cancelInvite(username),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Cancel'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                ],

                if (isOwner) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(elevation: 2),
                      onPressed: () async {
                        String? selectedUser;
                        final confirmedKickUser = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                final kickableMembers = members
                                    .where((m) => m != userStats.username)
                                    .toList();

                                return AlertDialog(
                                  backgroundColor: isDarkMode
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryFixed
                                      : null,
                                  title: Text(
                                    "Kick Pack Member",
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : null,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DropdownButton<String>(
                                        hint: Text(
                                          "Select a member",
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white70
                                                : null,
                                          ),
                                        ),
                                        dropdownColor: isDarkMode
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryFixed
                                            : null,
                                        value: selectedUser,
                                        items: kickableMembers.map((user) {
                                          return DropdownMenuItem(
                                            value: user,
                                            child: Text(
                                              user,
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : null,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedUser = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(null),
                                      child: Text(
                                        "Close",
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : null,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        if (selectedUser == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "Please select a member"),
                                            ),
                                          );
                                          return;
                                        }
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: isDarkMode
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryFixed
                                                : null,
                                            title: Text(
                                              "Confirm Kick",
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : null,
                                              ),
                                            ),
                                            content: Text(
                                              "Are you sure you want to kick $selectedUser from the pack? Their progress will be lost.",
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : null,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: Text(
                                                  "No",
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white70
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: Text(
                                                  "Confirm",
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.red[300]
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          Navigator.of(context)
                                              .pop(selectedUser);
                                        }
                                      },
                                      child: Text(
                                        "Kick",
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.red[300]
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );

                        if (confirmedKickUser != null) {
                          try {
                            await PacksAccessor.kickUser(confirmedKickUser);
                            if (!context.mounted) return;
                            await _loadData();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("$confirmedKickUser was kicked.")),
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Failed to kick $confirmedKickUser: $e")),
                              );
                            }
                          }
                        }
                      },
                      child: const Text("Kick Pack Members"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(elevation: 2),
                      onPressed: () async {
                        String? selectedNewOwner;
                        final confirmedNewOwner = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                final selectableMembers = members
                                    .where((m) => m != userStats.username)
                                    .toList();

                                return AlertDialog(
                                  backgroundColor: isDarkMode
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryFixed
                                      : null,
                                  title: Text(
                                    "Change Pack Leader",
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : null,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DropdownButton<String>(
                                        hint: Text(
                                          "Select new leader",
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white70
                                                : null,
                                          ),
                                        ),
                                        dropdownColor: isDarkMode
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryFixed
                                            : null,
                                        value: selectedNewOwner,
                                        items: selectableMembers.map((user) {
                                          return DropdownMenuItem(
                                            value: user,
                                            child: Text(
                                              user,
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : null,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedNewOwner = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(null),
                                      child: Text(
                                        "Close",
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : null,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        if (selectedNewOwner == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "Please select a member")),
                                          );
                                          return;
                                        }
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: isDarkMode
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryFixed
                                                : null,
                                            title: Text(
                                              "Confirm Leadership Change",
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : null,
                                              ),
                                            ),
                                            content: Text(
                                              "Are you sure you want to make $selectedNewOwner the new Pack Leader?",
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : null,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: Text(
                                                  "No",
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white70
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: Text(
                                                  "Confirm",
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.red[300]
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          Navigator.of(context)
                                              .pop(selectedNewOwner);
                                        }
                                      },
                                      child: Text(
                                        "Confirm",
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.red[300]
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );

                        if (confirmedNewOwner != null) {
                          try {
                            await PacksAccessor.changeOwner(confirmedNewOwner);
                            if (!context.mounted) return;
                            await _loadData();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "$confirmedNewOwner is now the Pack Leader.")),
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("Failed to change leader: $e")),
                              );
                            }
                          }
                        }
                      },
                      child: const Text("Change Pack Leader"),
                    ),
                  ),
                ],

                const Divider(height: 24),
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
      ),
      ConfettiWidget(
        confettiController: _confettiController,
        shouldLoop: false,

        blastDirectionality: BlastDirectionality.explosive,
        numberOfParticles: 50,
        gravity: 0.5,
      ),
    ]);
  }

  Widget _buildInvitesSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final invites = _myInvites?.invites ?? [];

    if (invites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      color: isDarkMode ? Theme.of(context).colorScheme.onPrimaryFixed : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pack Invites',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 12),
            ...invites
                .map((packName) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              packName,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? Colors.white : null,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _acceptInvite(packName),
                            icon: const Icon(Icons.check),
                            label: const Text('Accept'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _declineInvite(packName),
                            icon: const Icon(Icons.close),
                            label: const Text('Decline'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
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

        // Show invites section if there are any
        if (_myInvites != null && _myInvites!.invites.isNotEmpty)
          _buildInvitesSection(),

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
