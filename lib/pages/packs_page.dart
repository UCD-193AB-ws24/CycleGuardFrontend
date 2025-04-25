import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  final List<int> _challengeDistances = [100, 250, 500];

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
    final nameController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Pack'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Pack Name'),
            ),
            TextField(
              controller: passController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
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
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinPackDialog() {
    final nameController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Join Pack'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Pack Name'),
            ),
            TextField(
              controller: passController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
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
                // Show an error message to the user
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pack does not exist')),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPackSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_myPack == null) return const SizedBox();

    final goal = _myPack!.packGoal;
    final members = _myPack!.memberList;
    final double progress = (goal.goalAmount > 0)
        ? (goal.totalContribution / goal.goalAmount).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Pack: ${_myPack!.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 10),
            const SizedBox(height: 8),
            Text(
              'Goal: ${goal.goalAmount} mi — Total: ${goal.totalContribution.toStringAsFixed(1)} mi',
            ),
            const Divider(height: 20),
            const Text('Members:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...members.map((member) {
              final contribution = goal.contributionMap[member] ?? 0.0;
              return Text('$member — ${contribution.toStringAsFixed(1)} mi');
            }),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _leavePack,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Leave Pack'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(int distance) {
    final bool disabled = _myPack != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '$distance Mile Challenge',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: disabled
                  ? () => _showMessage('You can only be in one pack at a time.')
                  : () => _showCreatePackDialog(distance),
              style: ElevatedButton.styleFrom(
                elevation: 4,
                backgroundColor: disabled ? Colors.grey : null,
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
    final bool isInPack = _myPack != null;

    return ListView(
      children: [
        _buildMyPackSection(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ElevatedButton(
            onPressed: isInPack
                ? () => _showMessage('You can only be in one pack at a time.')
                : _showJoinPackDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: isInPack ? Colors.grey : null,
            ),
            child: const Text('Join Pack'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Center(
            child: Text('Available Challenges',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        ),
        ..._challengeDistances.map(_buildChallengeCard).toList(),
      ],
    );
  }
}