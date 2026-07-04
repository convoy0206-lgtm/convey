import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trip_model.dart';
import '../../models/expense_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/sync_service.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  final TripModel trip;

  const ExpenseScreen({
    super.key,
    required this.trip,
  });

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  List<String> _selectedMembers = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showAddExpenseDialog(BuildContext context, List<String> tripMembers) {
    setState(() {
      _selectedMembers = List.from(tripMembers); // Default split with everyone
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: const Text('Add Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g. Camp Groceries',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount (\$)',
                        hintText: '0.00',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Split With:',
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Checkbox list of members
                    ...tripMembers.map((memberId) {
                      final isSelected = _selectedMembers.contains(memberId);
                      final isMe = memberId == ref.read(authServiceProvider).currentUser?.uid;
                      
                      return CheckboxListTile(
                        title: Text(isMe ? 'You' : 'Member ID: ${memberId.substring(0, 5)}...'),
                        value: isSelected,
                        dense: true,
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              _selectedMembers.add(memberId);
                            } else {
                              _selectedMembers.remove(memberId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _submitExpense(context),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitExpense(BuildContext dialogContext) async {
    final desc = _descriptionController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (desc.isEmpty || amount <= 0.0 || _selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields and select members.')),
      );
      return;
    }

    Navigator.of(dialogContext).pop(); // Close Dialog
    
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      final expense = ExpenseModel(
        id: '',
        tripId: widget.trip.id,
        description: desc,
        amount: amount,
        paidBy: user.uid,
        splitWith: _selectedMembers,
        timestamp: DateTime.now(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      final syncService = ref.read(syncServiceProvider);
      
      await firestoreService.addExpense(widget.trip.id, expense, syncService);

      _descriptionController.clear();
      _amountController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense logged successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final syncService = ref.watch(syncServiceProvider);
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final isOfflineSimulated = !syncService.isOnline;

    return Scaffold(
      body: Column(
        children: [
          // Offline mode banner simulator control
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isOfflineSimulated ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer.withOpacity(0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isOfflineSimulated ? Icons.cloud_off_outlined : Icons.cloud_queue_outlined,
                      color: isOfflineSimulated ? theme.colorScheme.error : theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isOfflineSimulated ? 'Offline Mode - Queue Caching Active' : 'Online Mode - Live Sync Active',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOfflineSimulated ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    ref.read(syncServiceProvider).setOnlineStatus(isOfflineSimulated);
                    setState(() {});
                  },
                  child: Text(
                    isOfflineSimulated ? 'GO ONLINE' : 'GO OFFLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isOfflineSimulated ? theme.colorScheme.error : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Expenses List stream subscription
          Expanded(
            child: StreamBuilder<List<ExpenseModel>>(
              stream: firestoreService.streamExpenses(widget.trip.id),
              builder: (context, snapshot) {
                // If offline and stream is empty, we fall back to SQLite local_expenses cache!
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: syncService.getLocalExpenses(widget.trip.id),
                    builder: (context, localSnapshot) {
                      if (!localSnapshot.hasData || localSnapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'No expenses logged yet.\nTap the button below to add.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      
                      final localExpenses = localSnapshot.data!.map((map) {
                        return ExpenseModel(
                          id: map['id'],
                          tripId: map['tripId'],
                          description: map['description'],
                          amount: map['amount'],
                          paidBy: map['paidBy'],
                          splitWith: (map['splitWith'] as String).split(','),
                          timestamp: DateTime.parse(map['timestamp']),
                        );
                      }).toList();

                      return _buildExpenseContent(theme, localExpenses, currentUser?.uid ?? '');
                    },
                  );
                }

                final expenses = snapshot.data!;
                return _buildExpenseContent(theme, expenses, currentUser?.uid ?? '');
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context, widget.trip.members),
        label: const Text('Add Expense'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpenseContent(ThemeData theme, List<ExpenseModel> expenses, String myUid) {
    // Math balance calculations
    double totalSpent = 0.0;
    double myShare = 0.0;

    for (var exp in expenses) {
      totalSpent += exp.amount;
      if (exp.paidBy == myUid) {
        // You paid: you get back the split value for other people
        final share = exp.amount / exp.splitWith.length;
        final othersCount = exp.splitWith.where((id) => id != myUid).length;
        myShare += (share * othersCount);
      } else if (exp.splitWith.contains(myUid)) {
        // Someone else paid: you owe them your share
        myShare -= (exp.amount / exp.splitWith.length);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Balance HUD Card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL SPENT', style: theme.textTheme.labelSmall),
                        const SizedBox(height: 4),
                        Text(
                          '\$${totalSpent.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  elevation: 0,
                  color: myShare >= 0 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('YOUR BALANCE', style: theme.textTheme.labelSmall),
                        const SizedBox(height: 4),
                        Text(
                          '${myShare >= 0 ? "+" : ""}\$${myShare.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: myShare >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // List Header label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'EXPENSE HISTORY',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        // List view
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final exp = expenses[index];
              final isPaidByMe = exp.paidBy == myUid;
              final splitCount = exp.splitWith.length;
              final myOwedAmount = exp.amount / splitCount;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: ListTile(
                  title: Text(exp.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    isPaidByMe 
                        ? 'You paid \$${exp.amount.toStringAsFixed(2)} • Split with $splitCount'
                        : 'Paid by member... • You owe \$${myOwedAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  trailing: Text(
                    '\$${exp.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPaidByMe ? Colors.green : Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
