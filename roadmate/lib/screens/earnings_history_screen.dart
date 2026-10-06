import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/earnings_record.dart';
import '../services/auth_service.dart';
import '../services/earnings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/payment_widgets.dart';
import 'earnings_details_screen.dart';

/// Earnings History screen for mechanics matching the Stitch design.
class EarningsHistoryScreen extends StatefulWidget {
  final EarningsService? earningsService;
  final String? mechanicUid;

  const EarningsHistoryScreen({
    super.key,
    this.earningsService,
    this.mechanicUid,
  });

  @override
  State<EarningsHistoryScreen> createState() => _EarningsHistoryScreenState();
}

class _EarningsHistoryScreenState extends State<EarningsHistoryScreen> {
  String _selectedRange = 'This Month';
  final List<String> _ranges = ['This Week', 'This Month', 'All Time'];
  late List<EarningsRecord> _earningsList;

  EarningsService get _service => widget.earningsService ?? EarningsService();
  String get _uid =>
      widget.mechanicUid ?? (AuthService().currentUser?.uid ?? '');

  @override
  void initState() {
    super.initState();
    _earningsList = List.of(mockEarnings);
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    try {
      final list = await _service.getEarnings(mechanicUid: _uid);
      if (mounted && list.isNotEmpty) {
        setState(() => _earningsList = list);
      }
    } catch (_) {}
  }

  List<EarningsRecord> get _filteredEarnings {
    final now = DateTime.now();
    if (_selectedRange == 'This Week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return _earningsList.where((e) => e.completedDate.isAfter(weekAgo)).toList();
    } else if (_selectedRange == 'This Month') {
      final monthAgo = now.subtract(const Duration(days: 30));
      return _earningsList.where((e) => e.completedDate.isAfter(monthAgo)).toList();
    }
    return _earningsList;
  }

  double get _totalFilteredEarnings {
    return _filteredEarnings.fold(0.0, (sum, item) => sum + item.netEarnings);
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredEarnings;
    final total = _totalFilteredEarnings;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateAppHeader(
              title: 'Earnings History',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            // Header Hero Banner with Total and Completed Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL NET EARNINGS',
                          style: AppTypography.labelSm(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        AmountDisplay(
                          amount: total,
                          style: AppTypography.headlineLg(
                              color: AppColors.tertiaryFixed),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${list.length}',
                            style: AppTypography.headlineSm(
                                color: Colors.white),
                          ),
                          Text(
                            'Jobs Done',
                            style: AppTypography.labelSm(
                                color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Date Range Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _ranges.map((range) {
                  final isSelected = _selectedRange == range;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(range),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedRange = range);
                      },
                      labelStyle: AppTypography.labelSm(
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      backgroundColor: AppColors.surfaceContainerLowest,
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
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // List of earnings records
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              color: AppColors.mutedText, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No Earnings in this Period',
                            style: AppTypography.titleMd(
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final record = list[index];
                        final formattedDate =
                            dateFormat.format(record.completedDate);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EarningsDetailsScreen(record: record),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.cardBorder, width: 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.build_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.serviceType,
                                        style: AppTypography.titleMd(
                                            color: AppColors.onSurface),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${record.jobId} • $formattedDate',
                                        style: AppTypography.bodySm(
                                            color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+ ${formatCurrency(record.netEarnings)}',
                                      style: AppTypography.titleMd(
                                          color:
                                              AppColors.onTertiaryContainer),
                                    ),
                                    const SizedBox(height: 3),
                                    StatusBadge.completed(),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.mutedText,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
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
