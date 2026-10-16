import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_currency.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/performance/managed_loader.dart';
import '../../core/performance/resource_budget.dart';
import '../../data/models/cashier_profile.dart';

import '../../data/models/cashier_session.dart';

import '../../data/repositories/game_repository.dart';

import '../../services/deposit_service.dart';

import '../layout/responsive_layout.dart';

import '../theme/bingo_colors.dart';

import '../widgets/app_loading.dart';
import '../widgets/cashier_dashboard_strip.dart';
import '../widgets/deposit_action_buttons.dart';
import '../widgets/deposit_history_dialog.dart';
import '../widgets/manual_deposit_modal.dart';
import '../widgets/package_deposit_modal.dart';
import '../widgets/staged_screen_content.dart';

enum _ReportPreset { today, yesterday, thisWeek, lastWeek, thisMonth, custom }

const _reportFilterHeight = 32.0;
const _reportFilterHeightCompact = 28.0;
const _reportDateFieldWidth = 92.0;
const _reportDateFieldWidthCompact = 78.0;
const _reportPresetWidthCompact = 88.0;
const _reportFilterGapCompact = 6.0;
const _reportFilterUnderline = Color(0xFF10616F);
const _freeDemoRowColor = Color(0xFF4A3F1F);

/// Column colors for the report table (bet time → net).
const _reportColumnColors = <Color>[
  Color(0xFF90CAF9), // bet time
  Color(0xFFE3F2FD), // round
  Color(0xFF4DD0E1), // on call
  BingoColors.primary, // winner (overridden per row)
  Color(0xFFB0BEC5), // total card
  BingoColors.gold, // birr
  Color(0xFFFFFFFF), // total bet
  Color(0xFFFFAB91), // paid
  Color(0xFF81C784), // income
  Color(0xFFFFD54F), // bonus
  Color(0xFF69F0AE), // net
];

const _reportWinnerColumnIndex = 3;
const _reportNetColumnIndex = 10;
const _reportColumnFlex = <int>[1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1];
const _reportMobileMinColWidth = 34.0;

class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,

    required this.session,

    required this.gameRepository,

    required     this.onBalanceChanged,
    this.refreshToken = 0,
    this.isActive = true,
  });

  final CashierSession session;

  final GameRepository gameRepository;

  final Future<void> Function() onBalanceChanged;
  final int refreshToken;
  final bool isActive;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _start = DateTime.now();

  DateTime _end = DateTime.now();

  _ReportPreset _preset = _ReportPreset.today;

  List<TransactionReportRow> _rows = [];

  bool _loading = true;

  String? _error;

  double _todayIncome = 0;

  double _todayBonus = 0;

  double _todayNetIncome = 0;

  String _currencyCode = AppCurrency.defaultCode;

  final ScrollController _tableScrollController = ScrollController();

  @override
  void dispose() {
    _tableScrollController.dispose();
    super.dispose();
  }

  Future<void> _openManualDepositModal() async {
    await showManualDepositModal(
      context: context,
      cashierId: widget.session.cashierId,
      partnerId: '${widget.session.partnerId}',
      packageBalance: widget.session.packageBalance,
      gameRepository: widget.gameRepository,
      onApplied: () async {
        await widget.onBalanceChanged();
        if (!mounted) return;
        await _load();
      },
    );
  }

  Future<void> _openPackageModal() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PackageDepositModal(
        cashierId: widget.session.cashierId,
        depositService: DepositService(),
        gameRepository: widget.gameRepository,
        onApplied: () async {
          await widget.onBalanceChanged();
          if (!mounted) return;
          await _load();
        },
      ),
    );
  }

  Future<void> _openDepositHistory() async {
    await showDepositHistoryDialog(
      context,
      cashierId: widget.session.cashierId,
      gameRepository: widget.gameRepository,
    );
  }

  @override
  void initState() {
    super.initState();

    _applyPreset(_ReportPreset.today, reload: false);

    _load();
  }

  @override
  void didUpdateWidget(covariant ReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive &&
        oldWidget.refreshToken != widget.refreshToken) {
      final token = widget.refreshToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.refreshToken != token) return;
        _reloadFromTab();
      });
    }
  }

  Future<void> _reloadFromTab() async {
    await widget.onBalanceChanged();
    if (!mounted) return;
    await _load();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _applyPreset(_ReportPreset preset, {bool reload = true}) {
    final today = _dateOnly(DateTime.now());

    late DateTime start;

    late DateTime end;

    switch (preset) {
      case _ReportPreset.today:
        start = end = today;

      case _ReportPreset.yesterday:
        start = end = today.subtract(const Duration(days: 1));

      case _ReportPreset.thisWeek:
        start = today.subtract(Duration(days: today.weekday - DateTime.monday));

        end = today;

      case _ReportPreset.lastWeek:
        final thisMonday = today.subtract(
          Duration(days: today.weekday - DateTime.monday),
        );

        start = thisMonday.subtract(const Duration(days: 7));

        end = start.add(const Duration(days: 6));

      case _ReportPreset.thisMonth:
        start = DateTime(today.year, today.month, 1);

        end = today;

      case _ReportPreset.custom:
        start = _start;

        end = _end;
    }

    setState(() {
      _preset = preset;

      _start = start;

      _end = end;

      _error = null;
    });

    if (reload) _load();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final s = context.read<LocaleController>().strings;
    final initial = isStart ? _start : _end;

    final picked = await showDatePicker(
      context: context,

      initialDate: initial,

      firstDate: DateTime.now().subtract(const Duration(days: 62)),

      lastDate: DateTime.now(),

      helpText: isStart ? s.fromDate : s.toDate,
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _start = _dateOnly(picked);
      } else {
        _end = _dateOnly(picked);
      }

      _preset = _ReportPreset.custom;

      _error = null;
    });
  }

  bool _validateRange(AppStrings s) {
    if (_start.isAfter(_end)) {
      setState(() => _error = s.fromDateBeforeToDate);

      return false;
    }

    final twoMonthsAgo = _dateOnly(
      DateTime.now(),
    ).subtract(const Duration(days: 62));

    if (_start.isBefore(twoMonthsAgo)) {
      setState(() => _error = s.onlyLastTwoMonths);

      return false;
    }

    setState(() => _error = null);

    return true;
  }

  ({double income, double bonus, double net}) _todaySummaryFromRows(
    List<TransactionReportRow> rows,
  ) {
    final income = rows.fold<double>(0, (sum, r) => sum + r.income);
    final bonus = rows.fold<double>(0, (sum, r) => sum + r.bonus);
    return (income: income, bonus: bonus, net: income - bonus);
  }

  Color _reportCellColor(int columnIndex, {required bool hasWinner}) {
    if (columnIndex == _reportWinnerColumnIndex) {
      return hasWinner ? BingoColors.primary : BingoColors.lastCalled;
    }
    if (columnIndex == _reportNetColumnIndex) {
      return const Color(0xFF69F0AE);
    }
    return _reportColumnColors[columnIndex];
  }

  Future<void> _load() async {
    final s = context.read<LocaleController>().strings;
    if (!_validateRange(s)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final today = _dateOnly(DateTime.now());

    try {
      late final List<Object?> results;
      if (ResourceBudget.sequentialScreenLoads) {
        results = await ManagedLoader.runSequential([
          () => widget.gameRepository.getReportRows(
                cashierId: widget.session.cashierId,
                startDate: _fmt(_start),
                endDate: _fmt(_end),
              ),
          () => widget.gameRepository.getReportRows(
                cashierId: widget.session.cashierId,
                startDate: _fmt(today),
                endDate: _fmt(today),
              ),
          () => widget.gameRepository.getCashierProfile(widget.session.cashierId),
        ]);
      } else {
        results = await Future.wait([
          widget.gameRepository.getReportRows(
            cashierId: widget.session.cashierId,
            startDate: _fmt(_start),
            endDate: _fmt(_end),
          ),
          widget.gameRepository.getReportRows(
            cashierId: widget.session.cashierId,
            startDate: _fmt(today),
            endDate: _fmt(today),
          ),
          widget.gameRepository.getCashierProfile(widget.session.cashierId),
        ]);
      }

      if (!mounted) return;

      final currencyCode = AppCurrency.fromSettings(
        (results[2] as CashierProfile).settings,
      );

      final todaySummary = _todaySummaryFromRows(
        results[1] as List<TransactionReportRow>,
      );

      setState(() {
        _rows = results[0] as List<TransactionReportRow>;
        _todayIncome = todaySummary.income;
        _todayBonus = todaySummary.bonus;
        _todayNetIncome = todaySummary.net;
        _currencyCode = currencyCode;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  String _shortTime(String date) {
    final parts = date.split(' ');

    if (parts.length >= 2) {
      final time = parts[1];

      return time.length >= 5 ? time.substring(0, 5) : time;
    }

    return date.length > 10 ? date.substring(0, 10) : date;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final desktop = context.isDesktop;

    if (kDebugMode) {
      final size = MediaQuery.sizeOf(context);
      final contentWidth = size.width;
      debugPrint(
        '[ReportScreen] logical=${size.width.toStringAsFixed(0)}x'
        '${size.height.toStringAsFixed(0)} desktop=$desktop '
        'content~${contentWidth.toStringAsFixed(0)}x'
        '${(size.height - 40).toStringAsFixed(0)} (ex top bar) '
        'stackedFilterBar=false compactBar=${contentWidth < 1100}',
      );
    }

    final rows = _rows;

    final totalBet = rows.fold<int>(0, (sum, r) => sum + r.totalBet);

    final totalPaid = rows.fold<double>(0, (sum, r) => sum + r.paid);

    final totalIncome = rows.fold<double>(0, (sum, r) => sum + r.income);

    final totalBonus = rows.fold<double>(0, (sum, r) => sum + r.bonus);

    final netIncome = totalIncome - totalBonus;

    return AppLoadingOverlay(
      loading: _loading,
      message: s.loadingReport,
      child: SafeArea(
        top: false,

        child: Padding(
          padding: EdgeInsets.fromLTRB(
            desktop ? 20 : 6,
            desktop ? 12 : 4,
            desktop ? 20 : 6,
            0,
          ),

          child: StagedScreenContent(
            steps: [
              CashierDashboardStrip(
                cashierId: widget.session.cashierId,
                packageBalance: widget.session.packageBalance,
                currencyCode: _currencyCode,
                extras: [
                  CashierDashboardExtra(
                    label: s.todaysBonus,
                    value:
                        '${_todayBonus.toStringAsFixed(0)} ${s.currencyLabel(_currencyCode)}',
                    valueColor: const Color(0xFFFFD54F),
                    tint: const Color(0xFFFFD54F).withValues(alpha: 0.08),
                  ),
                  CashierDashboardExtra(
                    label: s.todaysIncome,
                    value:
                        '${_todayIncome.toStringAsFixed(0)} ${s.currencyLabel(_currencyCode)}',
                    valueColor: const Color(0xFF81C784),
                    tint: const Color(0xFF81C784).withValues(alpha: 0.08),
                  ),
                  CashierDashboardExtra(
                    label: s.todaysNetIncome,
                    value:
                        '${_todayNetIncome.toStringAsFixed(0)} ${s.currencyLabel(_currencyCode)}',
                    valueColor: BingoColors.gold,
                    tint: const Color(0xFF6AB04C).withValues(alpha: 0.08),
                  ),
                ],
              ),
              SizedBox(height: desktop ? 12 : 8),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: BingoColors.lastCalled,
                      fontSize: 12,
                    ),
                  ),
                ),
              Expanded(
                child: _buildReportSection(
                  context,
                  s,
                  rows,
                  desktop,
                  totalBet,
                  totalPaid,
                  totalIncome,
                  totalBonus,
                  netIncome,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportSection(
    BuildContext context,
    AppStrings s,
    List<TransactionReportRow> rows,
    bool desktop,
    int totalBet,
    double totalPaid,
    double totalIncome,
    double totalBonus,
    double netIncome,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: BingoColors.accentTeal.withValues(alpha: 0.8),
            width: desktop ? 10 : 6,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReportControls(s, desktop),
          Expanded(
            child: _loading && rows.isEmpty
                ? AppLoadingView(message: s.loadingReport)
                : rows.isEmpty
                    ? Center(
                        child: Text(
                          s.noData,
                          style: const TextStyle(
                            color: BingoColors.textSecondary,
                          ),
                        ),
                      )
                    : _buildTable(context, s, rows, desktop),
          ),
          if (rows.isNotEmpty)
            _buildFooter(
              s,
              desktop,
              totalBet,
              totalPaid,
              totalIncome,
              totalBonus,
              netIncome,
            ),
        ],
      ),
    );
  }

  Widget _buildReportControls(AppStrings s, bool desktop) {
    final narrow = !desktop && context.isNarrowMobile;
    final mobileFilterHeight = narrow ? 26.0 : 30.0;
    final mobilePresetWidth = narrow ? 76.0 : 92.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactBar = desktop && constraints.maxWidth < 1100;
        final filterHeight = desktop
            ? (compactBar ? _reportFilterHeightCompact : _reportFilterHeight)
            : mobileFilterHeight;
        final filterGap =
            desktop && compactBar ? _reportFilterGapCompact : 6.0;
        final presetWidth = desktop
            ? (compactBar ? _reportPresetWidthCompact : 108.0)
            : mobilePresetWidth;
        final dateFieldWidth = desktop
            ? (compactBar ? _reportDateFieldWidthCompact : _reportDateFieldWidth)
            : null;
        final presetFontSize =
            desktop ? (compactBar ? 11.0 : 12.0) : (narrow ? 9.0 : 10.0);
        final presetIconSize =
            desktop ? (compactBar ? 14.0 : 16.0) : (narrow ? 14.0 : 16.0);
        final valueFontSize = desktop ? (compactBar ? 11.0 : 12.0) : 10.0;

        final presetDropdown = DropdownButton<_ReportPreset>(
          value: _preset,
          isExpanded: true,
          isDense: true,
          dropdownColor: const Color(0xFF0F2E50),
          style: TextStyle(
            fontSize: presetFontSize,
            color: const Color(0xFFC0BDBD),
            fontWeight: FontWeight.w600,
          ),
          icon: Icon(
            Icons.expand_more,
            color: const Color(0xFFC0BDBD).withValues(alpha: 0.75),
            size: presetIconSize,
          ),
          items: [
            DropdownMenuItem(value: _ReportPreset.today, child: Text(s.today)),
            DropdownMenuItem(
              value: _ReportPreset.yesterday,
              child: Text(s.yesterday),
            ),
            DropdownMenuItem(
              value: _ReportPreset.thisWeek,
              child: Text(s.thisWeek),
            ),
            DropdownMenuItem(
              value: _ReportPreset.lastWeek,
              child: Text(s.lastWeek),
            ),
            DropdownMenuItem(
              value: _ReportPreset.thisMonth,
              child: Text(s.thisMonth),
            ),
            DropdownMenuItem(value: _ReportPreset.custom, child: Text(s.custom)),
          ],
          onChanged: (v) {
            if (v == null) return;
            if (v == _ReportPreset.custom) {
              setState(() => _preset = v);
            } else {
              _applyPreset(v);
            }
          },
        );

        Widget underlineField({
          required double? width,
          required Widget child,
        }) {
          return Container(
            width: width,
            height: filterHeight,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _reportFilterUnderline, width: 1.5),
              ),
            ),
            child: child,
          );
        }

        final presetField = underlineField(
          width: desktop ? presetWidth : mobilePresetWidth,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: desktop ? 4 : 2),
            child: DropdownButtonHideUnderline(child: presetDropdown),
          ),
        );

        final fromDate = _DateField(
          label: s.fromDate,
          value: _fmt(_start),
          onTap: () => _pickDate(isStart: true),
          desktop: desktop,
          narrow: narrow,
          height: filterHeight,
          fieldWidth: dateFieldWidth,
          valueFontSize: valueFontSize,
        );

        final toDate = _DateField(
          label: s.toDate,
          value: _fmt(_end),
          onTap: () => _pickDate(isStart: false),
          desktop: desktop,
          narrow: narrow,
          height: filterHeight,
          fieldWidth: dateFieldWidth,
          valueFontSize: valueFontSize,
        );

        final searchButton = desktop
            ? SizedBox(
                height: filterHeight,
                child: EthiomarkActionButton(
                  label: s.search,
                  onPressed: _load,
                  loading: _loading,
                  minWidth: compactBar ? 64 : 88,
                  height: filterHeight,
                  fontSize: compactBar ? 11 : 13,
                  horizontalPadding: compactBar ? 8 : 12,
                ),
              )
            : SizedBox(
                height: filterHeight,
                child: FilledButton(
                  onPressed: _loading ? null : _load,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: narrow ? 8 : 10),
                    backgroundColor: const Color(0xFFE59400),
                    foregroundColor: Colors.black,
                    minimumSize: Size(narrow ? 56 : 64, filterHeight),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _loading
                      ? AppButtonLoader(
                          color: Colors.black,
                          size: narrow ? 14 : 16,
                        )
                      : Text(
                          s.search,
                          style: TextStyle(fontSize: narrow ? 9 : 10),
                        ),
                ),
              );

        return Padding(
          padding: EdgeInsets.fromLTRB(
            desktop ? 8 : 4,
            desktop ? 10 : 6,
            desktop ? 8 : 4,
            desktop ? 8 : 4,
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        presetField,
                        const SizedBox(width: 4),
                        Expanded(child: fromDate),
                        const SizedBox(width: 4),
                        Expanded(child: toDate),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: searchButton,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    presetField,
                    SizedBox(width: filterGap),
                    if (desktop) fromDate else Expanded(child: fromDate),
                    SizedBox(width: filterGap),
                    if (desktop) toDate else Expanded(child: toDate),
                    SizedBox(width: filterGap),
                    searchButton,
                    if (desktop) ...[
                      const Spacer(),
                      SizedBox(
                        height: filterHeight,
                        child: OfflineDepositButton(
                          onPressed: _openManualDepositModal,
                          compact: !compactBar,
                          tight: compactBar,
                        ),
                      ),
                      SizedBox(width: filterGap),
                      SizedBox(
                        height: filterHeight,
                        child: OnlineDepositButton(
                          onPressed: _openPackageModal,
                          compact: !compactBar,
                          tight: compactBar,
                        ),
                      ),
                      SizedBox(width: filterGap),
                      SizedBox(
                        height: filterHeight,
                        child: DepositHistoryButton(
                          onPressed: _openDepositHistory,
                          compact: !compactBar,
                          tight: compactBar,
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTable(
    BuildContext context,
    AppStrings s,
    List<TransactionReportRow> rows,
    bool desktop,
  ) {
    final headers = desktop
        ? [
            s.betTime,
            s.roundColumn,
            s.onCall,
            s.winnerNumber,
            s.totalCard,
            s.reportStakeColumnHeader(_currencyCode),
            s.totalBet,
            s.paid,
            s.income,
            s.bonus,
            s.net,
          ]
        : s.reportTableHeadersCompact(_currencyCode);

    final tableWidth = desktop
        ? null
        : _reportColumnFlex.fold<double>(
            0,
            (sum, flex) => sum + flex * _reportMobileMinColWidth,
          );

    return desktop
        ? Column(
            children: [
              EthiomarkTableHeader(
                  columns: headers,
                  columnColors: _reportColumnColors,
                  highlightColumnIndex: _reportWinnerColumnIndex,
                ),
                Expanded(
                  child: _wrapReportScroll(
                    desktop: desktop,
                    child: ListView.separated(
                      controller: _tableScrollController,
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: Color(0xFF105350),
                      ),
                      itemBuilder: (_, i) => _buildReportDataRow(
                        row: rows[i],
                        rowIndex: i,
                        desktop: desktop,
                        tableWidth: tableWidth,
                      ),
                    ),
                  ),
                ),
              ],
            )
        : LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth!.clamp(constraints.maxWidth, double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildReportHeaderRow(
                        headers: headers,
                        desktop: desktop,
                        tableWidth: tableWidth,
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            color: Color(0xFF105350),
                          ),
                          itemBuilder: (_, i) => _buildReportDataRow(
                            row: rows[i],
                            rowIndex: i,
                            desktop: desktop,
                            tableWidth: tableWidth,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  List<String> _reportRowCells(TransactionReportRow r) {
    final winners = r.checkedNumber.trim();
    return [
      _shortTime(r.date),
      '${r.gameRound}',
      '${r.drawnCount}',
      winners.isEmpty ? '—' : winners,
      '${r.sew}',
      '${r.santim}',
      '${r.totalBet}',
      r.paid.toStringAsFixed(0),
      r.income.toStringAsFixed(0),
      r.bonus.toStringAsFixed(0),
      (r.income - r.bonus).toStringAsFixed(0),
    ];
  }

  Widget _buildReportHeaderRow({
    required List<String> headers,
    required bool desktop,
    required double? tableWidth,
  }) {
    return Container(
      color: const Color(0xFF0F2E50),
      child: Row(
        children: List.generate(headers.length, (i) {
          final color = _reportColumnColors[i];
          return _reportColumnShell(
            columnIndex: i,
            desktop: desktop,
            tableWidth: tableWidth,
            child: Text(
              headers[i],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: desktop ? 14 : 10,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReportDataRow({
    required TransactionReportRow row,
    required int rowIndex,
    required bool desktop,
    required double? tableWidth,
  }) {
    final winners = row.checkedNumber.trim();
    final hasWinner = winners.isNotEmpty && winners != '0';
    final isFreeDemo = row.isFreeDemoRound;
    final cells = _reportRowCells(row);

    return Container(
      color: isFreeDemo
          ? _freeDemoRowColor.withValues(alpha: desktop ? 0.72 : 0.55)
          : rowIndex.isEven
          ? Colors.transparent
          : const Color(0xFF1D446D).withValues(alpha: 0.15),
      padding: EdgeInsets.symmetric(
        vertical: desktop ? 10 : 6,
        horizontal: desktop ? 4 : 0,
      ),
      child: Row(
        children: List.generate(cells.length, (ci) {
          final isNet = ci == _reportNetColumnIndex;

          return _reportColumnShell(
            columnIndex: ci,
            desktop: desktop,
            tableWidth: tableWidth,
            child: Container(
              padding: isNet
                  ? EdgeInsets.symmetric(
                      horizontal: desktop ? 4 : 2,
                      vertical: desktop ? 2 : 1,
                    )
                  : null,
              decoration: isNet
                  ? BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF69F0AE).withValues(alpha: 0.7),
                      ),
                    )
                  : null,
              child: Text(
                cells[ci],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: desktop ? (isNet ? 15 : 14) : (isNet ? 11 : 10),
                  fontWeight: FontWeight.w900,
                  color: _reportCellColor(
                    ci,
                    hasWinner: ci == _reportWinnerColumnIndex && hasWinner,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _reportColumnShell({
    required int columnIndex,
    required bool desktop,
    required double? tableWidth,
    required Widget child,
  }) {
    final flex = _reportColumnFlex[columnIndex];
    if (desktop || tableWidth == null) {
      return Expanded(flex: flex, child: child);
    }
    return SizedBox(
      width: flex * _reportMobileMinColWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: child,
      ),
    );
  }

  Widget _wrapReportScroll({
    required bool desktop,
    required Widget child,
  }) {
    if (!desktop) return child;
    return Scrollbar(
      controller: _tableScrollController,
      thumbVisibility: widget.isActive,
      child: child,
    );
  }

  Widget _buildFooter(
    AppStrings s,
    bool desktop,
    int totalBet,
    double totalPaid,
    double totalIncome,
    double totalBonus,
    double netIncome,
  ) {
    final text = s.reportTotalsSummary(
      totalBet: totalBet,
      totalPaid: totalPaid,
      totalIncome: totalIncome,
      totalBonus: totalBonus,
      netIncome: netIncome,
    );

    if (desktop) {
      return EthiomarkTotalsFooter(
        label: s.totals,

        values: [
          '',
          '',
          '',
          '',
          '',
          '',

          '$totalBet',

          totalPaid.toStringAsFixed(0),

          totalIncome.toStringAsFixed(0),

          totalBonus.toStringAsFixed(0),

          netIncome.toStringAsFixed(0),
        ],
        valueColors: [
          null,
          null,
          null,
          null,
          null,
          null,
          const Color(0xFFFFFFFF),
          const Color(0xFFFFAB91),
          const Color(0xFF81C784),
          const Color(0xFFFFD54F),
          BingoColors.gold,
        ],
        emphasizedIndices: {_reportNetColumnIndex},
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: BingoColors.surface,
        border: Border(
          top: BorderSide(color: BingoColors.accentTeal.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: BingoColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1B5E20).withValues(alpha: 0.55),
                  const Color(0xFF0D2E2E),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BingoColors.gold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: BingoColors.gold.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  s.net,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF69F0AE),
                  ),
                ),
                const Spacer(),
                Text(
                  '${netIncome.toStringAsFixed(0)} ${s.currencyLabel(_currencyCode)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: BingoColors.gold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.desktop,
    this.narrow = false,
    this.height = 38,
    this.fieldWidth,
    this.valueFontSize = 14,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool desktop;
  final bool narrow;
  final double height;
  final double? fieldWidth;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    final border = const BoxDecoration(
      border: Border(
        bottom: BorderSide(color: _reportFilterUnderline, width: 1.5),
      ),
    );

    if (desktop) {
      final width = fieldWidth ?? _reportDateFieldWidth;
      return Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: width,
              height: height,
              alignment: Alignment.center,
              decoration: border,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFFC0BDBD),
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: narrow ? 2 : 4),
          alignment: Alignment.centerLeft,
          decoration: border,
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: narrow ? 7 : 8,
                  color: const Color(0xFF8B8888),
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: narrow ? 9 : valueFontSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC0BDBD),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
