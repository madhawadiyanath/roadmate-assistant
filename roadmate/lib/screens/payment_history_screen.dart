import 'package:flutter/material.dart';
import '../models/payment_transaction.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/payment_widgets.dart';
import 'payment_details_screen.dart';

/// Payment History screen matching the Stitch design.
class PaymentHistoryScreen extends StatefulWidget {
  final PaymentService? paymentService;
  final String? driverUid;

  const PaymentHistoryScreen({
    super.key,
    this.paymentService,
    this.driverUid,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'All';
  String _statusFilter = 'All';
  late List<PaymentTransaction> _transactions;

  PaymentService get _service => widget.paymentService ?? PaymentService();
  String get _uid =>
      widget.driverUid ?? (AuthService().currentUser?.uid ?? '');

  final List<String> _dateFilters = ['All', 'This Month', 'Previous'];
  final List<String> _statusFilters = ['All', 'Completed', 'Pending'];

  @override
  void initState() {
    super.initState();
    _transactions = List.of(mockTransactions);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final list = await _service.getTransactions(driverUid: _uid);
      if (mounted && list.isNotEmpty) {
        setState(() => _transactions = list);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PaymentTransaction> get _filteredTransactions {
    return _transactions.where((tx) {
      final query = _searchCtrl.text.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          tx.serviceType.toLowerCase().contains(query) ||
          tx.transactionId.toLowerCase().contains(query) ||
          tx.jobId.toLowerCase().contains(query);

      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Completed' &&
              tx.status == TransactionStatus.completed) ||
          (_statusFilter == 'Pending' &&
              tx.status == TransactionStatus.pending);

      return matchesQuery && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _filteredTransactions;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateAppHeader(
              title: 'Payment History',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(8),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: AppTypography.titleMd(color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search by service or transaction ID...',
                    hintStyle: AppTypography.bodyMd(color: AppColors.outlineVariant),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.onSurfaceVariant, size: 22),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.onSurfaceVariant, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Date & Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ..._statusFilters.map((st) {
                    final isSelected = _statusFilter == st;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(st),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() => _statusFilter = st);
                        },
                        labelStyle: AppTypography.labelSm(
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                        backgroundColor: AppColors.surfaceContainerLow,
                        selectedColor: AppColors.primary,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.cardBorder,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  ..._dateFilters.map((df) {
                    final isSelected = _selectedFilter == df;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(df),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() => _selectedFilter = df);
                        },
                        labelStyle: AppTypography.labelSm(
                          color: isSelected ? Colors.white : AppColors.slateText,
                        ),
                        backgroundColor: AppColors.surfaceContainerLowest,
                        selectedColor: AppColors.primaryContainer,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Transaction list
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.mutedText,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No Transactions Found',
                            style: AppTypography.headlineSm(
                                color: AppColors.primary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try adjusting your search or filter options',
                            style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      itemCount: transactions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final statusStr =
                            tx.status == TransactionStatus.completed
                                ? 'Completed'
                                : 'Pending';

                        return TransactionListItem(
                          serviceType: tx.serviceType,
                          transactionId: tx.transactionId,
                          date: tx.date,
                          amount: formatCurrency(tx.totalAmount),
                          status: statusStr,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PaymentDetailsScreen(transaction: tx),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
