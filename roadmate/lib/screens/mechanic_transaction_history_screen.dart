import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/earnings_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/payment_widgets.dart';
import 'earnings_details_screen.dart';

/// Transaction History screen for service providers matching the Stitch design.
class MechanicTransactionHistoryScreen extends StatefulWidget {
  const MechanicTransactionHistoryScreen({super.key});

  @override
  State<MechanicTransactionHistoryScreen> createState() =>
      _MechanicTransactionHistoryScreenState();
}

class _MechanicTransactionHistoryScreenState
    extends State<MechanicTransactionHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedType = 'All';
  final List<String> _types = ['All', 'Job Payouts', 'Tips', 'Adjustments'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<EarningsRecord> get _filteredList {
    final query = _searchCtrl.text.toLowerCase().trim();
    return mockEarnings.where((e) {
      final matchesQuery = query.isEmpty ||
          e.jobId.toLowerCase().contains(query) ||
          e.transactionId.toLowerCase().contains(query) ||
          e.serviceType.toLowerCase().contains(query);
      return matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredList;
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateAppHeader(
              title: 'Transaction History',
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
                    hintText: 'Search by Transaction or Job ID...',
                    hintStyle:
                        AppTypography.bodyMd(color: AppColors.outlineVariant),
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
            const SizedBox(height: 8),

            // Type Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _types.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedType = type);
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

            // Transaction items list
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              color: AppColors.mutedText, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No Transactions Found',
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
                                    color: AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    color: AppColors.onTertiaryContainer,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.transactionId,
                                        style: AppTypography.labelLg(
                                            color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${record.jobId} • ${record.serviceType}',
                                        style: AppTypography.bodySm(
                                            color: AppColors.onSurfaceVariant),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formattedDate,
                                        style: AppTypography.labelSm(
                                            color: AppColors.slateText),
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
                                    const SizedBox(height: 4),
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
