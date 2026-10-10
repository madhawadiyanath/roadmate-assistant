import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/mechanic_service.dart';
import '../services/auth_service.dart';
import '../services/mechanic_service_service.dart';
import '../theme/app_colors.dart';
import '../widgets/roadmate_top_bar.dart';
import '../widgets/state_message.dart';
import 'service_form_screen.dart';

/// Services Offered management page (Read + List + Quick Toggle + Delete + Add).
/// Replaces the placeholder ComingSoonScreen on the mechanic profile.
class ServicesOfferedScreen extends StatefulWidget {
  final String uid;
  final MechanicServiceService? service;
  final VoidCallback? onAvatarTap;

  const ServicesOfferedScreen({
    super.key,
    required this.uid,
    this.service,
    this.onAvatarTap,
  });

  @override
  State<ServicesOfferedScreen> createState() => _ServicesOfferedScreenState();
}

class _ServicesOfferedScreenState extends State<ServicesOfferedScreen> {
  final TextEditingController _search = TextEditingController();
  String _selectedCategory = 'All';

  Stream<List<MechanicService>>? _stream;
  bool get _connected => widget.service != null || firebaseReady;

  MechanicServiceService get _service =>
      widget.service ?? MechanicServiceService();

  // Demo fallback items for offline/preview mode
  static final _demoServices = [
    const MechanicService(
      id: 'demo-s1',
      title: 'Tire Puncture Repair & Replacement',
      category: ServiceCategory.tyre,
      basePrice: 3500,
      estimatedDurationMinutes: 30,
      description: 'On-site spare tire fitment, puncture plug, or inflation',
      isAvailable: true,
    ),
    const MechanicService(
      id: 'demo-s2',
      title: 'Battery Jump Start',
      category: ServiceCategory.battery,
      basePrice: 2500,
      estimatedDurationMinutes: 20,
      description: 'Heavy-duty jump starter pack booster cables service',
      isAvailable: true,
    ),
    const MechanicService(
      id: 'demo-s3',
      title: 'Emergency Towing',
      category: ServiceCategory.towing,
      basePrice: 6500,
      estimatedDurationMinutes: 60,
      description: 'Flatbed or wheel-lift tow to nearest verified workshop',
      isAvailable: true,
    ),
    const MechanicService(
      id: 'demo-s4',
      title: 'Emergency Fuel Delivery',
      category: ServiceCategory.fuel,
      basePrice: 2000,
      estimatedDurationMinutes: 25,
      description: '5L petrol or diesel delivered directly to vehicle location',
      isAvailable: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _subscribe() {
    _stream = _connected ? _service.watchServices(widget.uid) : null;
  }

  void _add() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceFormScreen(
          uid: widget.uid,
          serviceService: widget.service,
        ),
      ),
    );
  }

  void _edit(MechanicService s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceFormScreen(
          uid: widget.uid,
          service: s,
          serviceService: widget.service,
        ),
      ),
    );
  }

  Future<void> _toggle(MechanicService s) async {
    if (!_connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect Firebase to sync live state.')),
      );
      return;
    }
    try {
      await _service.toggleAvailability(widget.uid, s.id, !s.isAvailable);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyMessage(e))),
      );
    }
  }

  List<MechanicService> _filter(List<MechanicService> list) {
    final query = _search.text.trim().toLowerCase();
    return list.where((item) {
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.category.label.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      final matchesCat = _selectedCategory == 'All' ||
          item.category.label == _selectedCategory;
      return matchesQuery && matchesCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateTopBar(onAvatarTap: widget.onAvatarTap),
            RoadMatePageTitle(
              title: 'Services Offered',
              onBack: () => Navigator.pop(context),
            ),
            // Search Bar & Category Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: AppColors.navy),
                  suffixIcon: _search.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.fieldFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Category Filter Chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  _filterChip('All'),
                  ...ServiceCategory.values.map((c) => _filterChip(c.label)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Content
            Expanded(
              child: _stream == null
                  ? _buildList(_demoServices, isDemo: true)
                  : StreamBuilder<List<MechanicService>>(
                      stream: _stream,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return StateMessage(
                            icon: Icons.error_outline_rounded,
                            color: const Color(0xFFB02A37),
                            title: 'Could not load services',
                            message: AuthService.friendlyMessage(snap.error!),
                          );
                        }
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return _buildList(snap.data!, isDemo: false);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Add Service',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedCategory = label),
        selectedColor: AppColors.orange,
        checkmarkColor: Colors.white,
        backgroundColor: AppColors.fieldFill,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.navy,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildList(List<MechanicService> all, {required bool isDemo}) {
    final filtered = _filter(all);
    final activeCount = all.where((s) => s.isAvailable).length;

    if (all.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.build_circle_outlined,
                    size: 38, color: AppColors.orange),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Services Added Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add the breakdown and repair services your garage provides so drivers can request them.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.greyText),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Your First Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Summary bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${all.length} Services (${activeCount} Active)',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              if (isDemo)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF2F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'DEMO PREVIEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // List items
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No services match your search.',
                    style: TextStyle(color: AppColors.greyText),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    return _ServiceCard(
                      service: item,
                      onTap: () => _edit(item),
                      onToggle: () => _toggle(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final MechanicService service;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _ServiceCard({
    required this.service,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: service.isAvailable
              ? AppColors.fieldFill
              : Colors.grey.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: service.isAvailable
                          ? AppColors.orange.withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      service.category.icon,
                      color: service.isAvailable
                          ? AppColors.orange
                          : AppColors.greyText,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: service.isAvailable
                                ? AppColors.navy
                                : AppColors.greyText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          service.category.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Availability Switch
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: service.isAvailable,
                      activeColor: AppColors.orange,
                      onChanged: (_) => onToggle(),
                    ),
                  ),
                ],
              ),
              if (service.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  service.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.greyText.withValues(alpha: 0.9),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.fieldFill),
              const SizedBox(height: 8),
              // Price + Duration Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 15, color: AppColors.greyText),
                      const SizedBox(width: 4),
                      Text(
                        service.durationText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7EE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      service.formattedPrice,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF22B573),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
