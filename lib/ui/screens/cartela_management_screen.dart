import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../data/models/cartela.dart';
import '../../data/repositories/game_repository.dart';
import '../layout/responsive_layout.dart';
import '../theme/bingo_colors.dart';
import '../widgets/app_loading.dart';
import '../widgets/cartela_editor_dialog.dart';
import '../widgets/cartela_preview.dart';
import '../widgets/staged_screen_content.dart';

class CartelaManagementScreen extends StatefulWidget {
  const CartelaManagementScreen({
    super.key,
    required this.gameRepository,
    required this.activeCategory,
    this.refreshToken = 0,
    this.isActive = true,
  });

  final GameRepository gameRepository;
  /// Cashier's active cartela category from play settings.
  final String activeCategory;
  final int refreshToken;
  final bool isActive;

  @override
  State<CartelaManagementScreen> createState() => _CartelaManagementScreenState();
}

class _CartelaManagementScreenState extends State<CartelaManagementScreen> {
  static const _pageSize = 40;

  bool _loading = true;
  String? _error;
  List<({String name, int count})> _categories = [];
  final Set<String> _emptyCategories = {};
  String? _selectedCategory;
  List<Cartela> _cartelas = [];
  bool _loadingCartelas = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  int _lastRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadCategories();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CartelaManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive &&
        widget.refreshToken != _lastRefreshToken &&
        widget.refreshToken != oldWidget.refreshToken) {
      _lastRefreshToken = widget.refreshToken;
      _loadCategories();
      return;
    }
    if (widget.isActive &&
        widget.activeCategory != oldWidget.activeCategory) {
      _syncToActiveCategoryIfNeeded();
    }
  }

  String? _pickCategory(List<({String name, int count})> merged) {
    if (merged.isEmpty) return null;

    final active = widget.activeCategory.trim();
    if (active.isNotEmpty && merged.any((c) => c.name == active)) {
      return active;
    }

    if (_selectedCategory != null &&
        merged.any((c) => c.name == _selectedCategory)) {
      return _selectedCategory;
    }

    return merged.first.name;
  }

  Future<void> _syncToActiveCategoryIfNeeded() async {
    final merged = _mergedCategories;
    final active = widget.activeCategory.trim();
    if (active.isEmpty ||
        !merged.any((c) => c.name == active) ||
        _selectedCategory == active) {
      return;
    }
    await _selectCategory(active);
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (_selectedCategory != null) {
        _resetAndLoadCartelas(_selectedCategory!);
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingCartelas || _loadingMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      _loadMoreCartelas();
    }
  }

  List<({String name, int count})> get _mergedCategories {
    final names = <String>{};
    final merged = <({String name, int count})>[];
    for (final c in _categories) {
      names.add(c.name);
      merged.add(c);
    }
    for (final name in _emptyCategories) {
      if (!names.contains(name)) {
        merged.add((name: name, count: 0));
      }
    }
    merged.sort((a, b) => a.name.compareTo(b.name));
    return merged;
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories =
          await widget.gameRepository.listCartelaCategoriesWithCounts();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loading = false;
        final merged = _mergedCategoriesAfter(categories);
        _selectedCategory = _pickCategory(merged);
      });
      if (_selectedCategory != null) {
        await _resetAndLoadCartelas(_selectedCategory!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  List<({String name, int count})> _mergedCategoriesAfter(
    List<({String name, int count})> categories,
  ) {
    final names = categories.map((c) => c.name).toSet();
    final merged = [...categories];
    for (final name in _emptyCategories) {
      if (!names.contains(name)) {
        merged.add((name: name, count: 0));
      }
    }
    merged.sort((a, b) => a.name.compareTo(b.name));
    return merged;
  }

  Future<void> _resetAndLoadCartelas(String category) async {
    setState(() {
      _loadingCartelas = true;
      _loadingMore = false;
      _hasMore = true;
      _cartelas = [];
    });
    await _loadMoreCartelas(reset: true);
  }

  Future<void> _loadMoreCartelas({bool reset = false}) async {
    final category = _selectedCategory;
    if (category == null) return;
    if (!reset && (!_hasMore || _loadingMore || _loadingCartelas)) return;

    setState(() {
      if (reset) {
        _loadingCartelas = true;
      } else {
        _loadingMore = true;
      }
    });

    try {
      if (!reset) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
      }

      final search = _searchController.text.trim();
      final batch = await widget.gameRepository.listCartelas(
        category: category,
        search: search.isEmpty ? null : search,
        limit: _pageSize,
        offset: reset ? 0 : _cartelas.length,
      );
      if (!mounted) return;

      setState(() {
        if (reset) {
          _cartelas = List<Cartela>.from(batch);
        } else {
          _appendCartelaBatch(batch);
        }
        _hasMore = batch.length >= _pageSize;
        _loadingCartelas = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCartelas = false;
        _loadingMore = false;
      });
    }
  }

  void _appendCartelaBatch(List<Cartela> batch) {
    if (batch.isEmpty) return;
    final seen = _cartelas.map((c) => c.id).toSet();
    for (final cartela in batch) {
      if (!seen.contains(cartela.id)) {
        _cartelas.add(cartela);
        seen.add(cartela.id);
      }
    }
    _cartelas.sort((a, b) => a.number.compareTo(b.number));
  }

  Future<void> _showCategoryDialog({String? existing}) async {
    if (existing != null) {
      await _showRenameCategoryDialog(existing);
      return;
    }

    final s = context.read<LocaleController>().strings;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BingoColors.bgDark,
        title: Text(
          s.newCategory,
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: s.categoryNameLabel,
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;

    final normalized = result.trim();
    if (normalized.isEmpty) {
      _showSnack(s.categoryNameRequired);
      return;
    }

    final existsInDb =
        await widget.gameRepository.cartelaCategoryExists(normalized);
    final existsLocal = _mergedCategories.any((c) => c.name == normalized);
    if (existsInDb || existsLocal) {
      _showSnack(s.categoryNameExists);
      return;
    }
    setState(() {
      _emptyCategories.add(normalized);
      _selectedCategory = normalized;
    });
    await _resetAndLoadCartelas(normalized);
  }

  Future<void> _showRenameCategoryDialog(String existing) async {
    final s = context.read<LocaleController>().strings;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BingoColors.bgDark,
        title: Text(
          s.editCategory,
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.categoryRenameWarning,
                style: TextStyle(
                  color: BingoColors.gold.withValues(alpha: 0.95),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      s.renameCategoryTo(existing),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: s.categoryNameLabel,
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0F2E50),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: BingoColors.accentTeal.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;

    final normalized = result.trim();
    if (normalized.isEmpty) {
      _showSnack(s.categoryNameRequired);
      return;
    }

    if (normalized == existing) return;

    final exists =
        await widget.gameRepository.cartelaCategoryExists(normalized);
    if (exists || _mergedCategories.any((c) => c.name == normalized)) {
      _showSnack(s.categoryNameExists);
      return;
    }

    await widget.gameRepository.renameCartelaCategory(
      from: existing,
      to: normalized,
    );
    _emptyCategories.remove(existing);
    if (_selectedCategory == existing) {
      _selectedCategory = normalized;
    }
    await _loadCategories();
  }

  Future<void> _selectCategory(String name) async {
    if (_selectedCategory == name) return;
    setState(() => _selectedCategory = name);
    await _resetAndLoadCartelas(name);
  }

  Future<void> _deleteCategory(String name) async {
    final s = context.read<LocaleController>().strings;
    if (_emptyCategories.contains(name)) {
      setState(() {
        _emptyCategories.remove(name);
        if (_selectedCategory == name) {
          final merged = _mergedCategories;
          _selectedCategory =
              merged.isEmpty ? null : merged.first.name;
        }
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BingoColors.bgDark,
        title: Text(s.delete, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.categoryDeleteWarning,
              style: TextStyle(
                color: BingoColors.gold.withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.deleteCategoryConfirm(name),
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: BingoColors.lastCalled,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.gameRepository.deleteCartelaCategory(name);
    _emptyCategories.remove(name);
    await _loadCategories();
  }

  Future<void> _addOrEditCartela({Cartela? cartela}) async {
    final s = context.read<LocaleController>().strings;
    final category = _selectedCategory;
    if (category == null) return;

    int? suggested;
    if (cartela == null) {
      final max = await widget.gameRepository.getMaxCartelaNumber(category);
      suggested = max + 1;
    }

    if (!mounted) return;

    final result = await showCartelaEditorDialog(
      context: context,
      strings: s,
      cartela: cartela,
      suggestedNumber: suggested,
    );
    if (result == null) return;

    final duplicate = await widget.gameRepository.cartelaNumberExists(
      category: category,
      number: result.number,
      excludeId: cartela?.id,
    );
    if (duplicate) {
      _showSnack(s.cartelaNumberExists);
      return;
    }

    if (cartela == null) {
      await widget.gameRepository.insertCartela(
        category: category,
        number: result.number,
        b: result.b,
        i: result.i,
        n: result.n,
        g: result.g,
        o: result.o,
      );
      _emptyCategories.remove(category);
    } else {
      await widget.gameRepository.updateCartela(
        id: cartela.id,
        number: result.number,
        b: result.b,
        i: result.i,
        n: result.n,
        g: result.g,
        o: result.o,
      );
    }

    await _loadCategories();
    if (_selectedCategory == category) {
      await _resetAndLoadCartelas(category);
    }
  }

  Future<void> _deleteCartela(Cartela cartela) async {
    final s = context.read<LocaleController>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BingoColors.bgDark,
        title: Text(s.delete, style: const TextStyle(color: Colors.white)),
        content: Text(
          s.deleteCartelaConfirm(cartela.number),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: BingoColors.lastCalled,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.gameRepository.deleteCartela(cartela.id);
    if (_selectedCategory != null) {
      await _loadCategories();
      await _resetAndLoadCartelas(_selectedCategory!);
    }
  }

  Future<void> _previewCartela(Cartela cartela) async {
    final s = context.read<LocaleController>().strings;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BingoColors.bgDark,
        title: Text(
          s.cartelaNumber(cartela.number),
          style: const TextStyle(color: Colors.white),
        ),
        content: CartelaPreview(
          cartela: cartela,
          drawn: const [],
          lightSurface: true,
          cellWidth: 40,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    if (_loading) {
      return AppLoadingView(message: s.loading);
    }

    final categories = _mergedCategories;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: BingoColors.lastCalled),
              ),
            ),
          Expanded(child: _buildMainPanel(s, categories)),
        ],
      ),
    );
  }

  Widget _buildCategoryToolbar(
    AppStrings s,
    List<({String name, int count})> categories, {
    required bool isMobile,
  }) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCategoryPickerField(s, categories),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _categoryActionButton(
                  icon: Icons.add_circle_outline,
                  label: s.newCategory,
                  color: BingoColors.gold,
                  compact: true,
                  onPressed: () => _showCategoryDialog(),
                ),
              ),
              if (_selectedCategory != null) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: _categoryActionButton(
                    icon: Icons.edit_outlined,
                    label: s.editCategory,
                    color: BingoColors.gold,
                    compact: true,
                    onPressed: () =>
                        _showCategoryDialog(existing: _selectedCategory),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _categoryActionButton(
                    icon: Icons.delete_outline,
                    label: s.delete,
                    color: BingoColors.lastCalled,
                    compact: true,
                    onPressed: () => _deleteCategory(_selectedCategory!),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: _buildCategoryPickerField(s, categories),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _categoryActionButton(
                icon: Icons.add_circle_outline,
                label: s.newCategory,
                color: BingoColors.gold,
                onPressed: () => _showCategoryDialog(),
              ),
              if (_selectedCategory != null) ...[
                _categoryActionButton(
                  icon: Icons.edit_outlined,
                  label: s.editCategory,
                  color: BingoColors.gold,
                  onPressed: () =>
                      _showCategoryDialog(existing: _selectedCategory),
                ),
                _categoryActionButton(
                  icon: Icons.delete_outline,
                  label: s.delete,
                  color: BingoColors.lastCalled,
                  onPressed: () => _deleteCategory(_selectedCategory!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainPanel(
    AppStrings s,
    List<({String name, int count})> categories,
  ) {
    final isMobile = !context.isDesktop;

    // Material (not DecoratedBox) so ListTile ink/selection paint on this layer.
    return Material(
      color: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: BingoColors.accentTeal.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: StagedScreenContent(
        steps: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: _buildCategoryToolbar(s, categories, isMobile: isMobile),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: s.searchNumber,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0F2E50),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: BingoColors.accentTeal.withValues(alpha: 0.45),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: BingoColors.accentTeal.withValues(alpha: 0.45),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: BingoColors.accentTeal),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _selectedCategory == null
                      ? null
                      : () => _addOrEditCartela(),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(s.newCartela),
                  style: FilledButton.styleFrom(
                    backgroundColor: BingoColors.accentTeal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: BingoColors.border),
          Expanded(child: _buildCartelaList(s)),
        ],
      ),
    );
  }

  Widget _categoryActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool compact = false,
  }) {
    if (compact) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          side: BorderSide(color: color.withValues(alpha: 0.55)),
          backgroundColor: Colors.black.withValues(alpha: 0.15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        side: BorderSide(color: color.withValues(alpha: 0.55)),
        backgroundColor: Colors.black.withValues(alpha: 0.15),
      ),
    );
  }

  Widget _buildCategoryPickerField(
    AppStrings s,
    List<({String name, int count})> categories,
  ) {
    if (categories.isEmpty) {
      return Text(
        s.noCategoriesYet,
        maxLines: 2,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.65),
          fontSize: 12,
        ),
      );
    }

    final selected = _selectedCategory;
    final count = categories
        .where((c) => c.name == selected)
        .map((c) => c.count)
        .firstOrNull;
    final display = selected == null
        ? s.category
        : '$selected (${s.cartelasCount(count ?? 0)})';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCategoryPickerDialog(s, categories),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2E50),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: BingoColors.accentTeal.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: BingoColors.gold.withValues(alpha: 0.9),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCategoryPickerDialog(
    AppStrings s,
    List<({String name, int count})> categories,
  ) async {
    final searchController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? categories
                : categories
                    .where((c) => c.name.toLowerCase().contains(query))
                    .toList();

            return AlertDialog(
              backgroundColor: BingoColors.bgDark,
              title: Text(
                s.category,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SizedBox(
                width: 320,
                height: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: searchController,
                      onChanged: (_) => setLocalState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: s.searchCategory,
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withValues(alpha: 0.55),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0F2E50),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: BingoColors.accentTeal.withValues(alpha: 0.45),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: BingoColors.accentTeal.withValues(alpha: 0.45),
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: BingoColors.accentTeal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                s.noCategoriesYet,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              itemBuilder: (context, i) {
                                final cat = filtered[i];
                                final isSelected =
                                    cat.name == _selectedCategory;
                                return ListTile(
                                  dense: true,
                                  selected: isSelected,
                                  selectedTileColor:
                                      BingoColors.sideNavSelected,
                                  title: Text(
                                    cat.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    s.cartelasCount(cat.count),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.55),
                                      fontSize: 11,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(dialogContext).pop();
                                    _selectCategory(cat.name);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(s.close),
                ),
              ],
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  Widget _buildCartelaList(AppStrings s) {
    if (_selectedCategory == null) {
      return Center(
        child: Text(
          s.noCategoriesYet,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
        ),
      );
    }

    if (_loadingCartelas && _cartelas.isEmpty) {
      return Center(
        child: AppLoadingIndicator(
          color: BingoColors.gold,
          message: s.loadingCards,
        ),
      );
    }

    if (_cartelas.isEmpty) {
      return Center(
        child: Text(
          s.noCartelasInCategory,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
        ),
      );
    }

    final itemCount = _cartelas.length + (_hasMore || _loadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      cacheExtent: 480,
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (i >= _cartelas.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLoadingIndicator(
                  color: BingoColors.gold,
                  size: 22,
                  strokeWidth: 2.5,
                ),
                const SizedBox(width: 10),
                Text(
                  s.loadingCards,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        final cartela = _cartelas[i];
        return ListTile(
          dense: true,
          title: Text(
            s.cartelaNumber(cartela.number),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                color: Colors.white.withValues(alpha: 0.75),
                tooltip: s.cartelaNumber(cartela.number),
                onPressed: () => _previewCartela(cartela),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: BingoColors.gold,
                tooltip: s.editCartela,
                onPressed: () => _addOrEditCartela(cartela: cartela),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: BingoColors.lastCalled,
                tooltip: s.delete,
                onPressed: () => _deleteCartela(cartela),
              ),
            ],
          ),
          onTap: () => _previewCartela(cartela),
        );
      },
    );
  }
}
