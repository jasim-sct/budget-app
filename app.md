Created At: 2026-07-23T17:27:54Z
Completed At: 2026-07-24T10:52:00Z
File Path: `file:///home/sct/Desktop/budget-app/app.md`

# Application Documentation: Budget Lite Pro (Enterprise Financial OS)

## 1. Application Overview

- **Purpose**: A commercial-grade, ultra-low-end optimized personal finance operating system. Built for instant startup (< 1 second) and high-performance execution on constrained hardware (eMMC storage, 1GB RAM target) using an Apple VisionOS & macOS Big Sur inspired Glassmorphism UI engine.
- **Target Users**: Mobile (Android) and Desktop (Linux/Windows) users seeking a secure, offline-first personal financial operating system with zero latency, month-based data isolation, sub-category hierarchies, multi-period envelope budgeting engine, budget pacing & target spending engine, remaining budget transfer, overspend recovery, historical archiving, period comparison analytics, required monthly savings calculators, executive P&L statements, level 10 deterministic calculation engine, enterprise global filter & query engine, advanced frosted glass aesthetics, and automated cash flow analytics.
- **Platform(s)**: Android 8.0+, Linux Desktop (GTK / Flutter FFI), Windows Desktop, Cross-Platform Flutter.

---

## 2. Core Features & Capabilities

### 🔍 Centralized Enterprise Global Filter & Query Engine
- **Global Filter Controller ([global_filter_controller.dart](file:///home/sct/Desktop/budget-app/lib/core/services/global_filter_controller.dart))**: Central application service maintaining a single source of truth filtering state (`GlobalFilterState`).
- **Parameterized SQL Filter Builder ([filter_query_builder.dart](file:///home/sct/Desktop/budget-app/lib/core/services/filter_query_builder.dart))**: Constructs indexed SQLite queries (`WHERE` clauses utilizing `date`, `month`, `year`, `category`, `account_id`, `type`, `amount`) optimized for 100,000+ records.
- **Cross-Module Reactive Integration ([financial_sync_service.dart](file:///home/sct/Desktop/budget-app/lib/core/services/financial_sync_service.dart))**: Modifying filters triggers real-time recalculations across [FinancialCalculationEngine](file:///home/sct/Desktop/budget-app/lib/core/services/financial_calculation_engine.dart), Ledger, Accounts, Budgets, Goals, Analytics, and Reports.
- **VisionOS Glass Filter Bar ([global_filter_bar.dart](file:///home/sct/Desktop/budget-app/lib/core/widgets/global_filter_bar.dart)) & Modal Sheet ([glass_filter_modal.dart](file:///home/sct/Desktop/budget-app/lib/core/widgets/glass/glass_filter_modal.dart))**: Live search bar, active filter count badge, date range selectors, transaction type toggles, and reset button.

### ⚡ Master Ledger & Level 10 Calculation Engine
- **Master Ledger**: SQLite tables (`transactions`, `accounts`, `categories`, `budgets`, `goals`, `budget_history`) managed by [DatabaseHelper](file:///home/sct/Desktop/budget-app/lib/core/database/database_helper.dart) and [AppDatabase](file:///home/sct/Desktop/budget-app/lib/core/database/app_database.dart).
- **Level 10 Calculation Engine ([financial_calculation_engine.dart](file:///home/sct/Desktop/budget-app/lib/core/services/financial_calculation_engine.dart))**: Real-time event-driven calculation pipeline triggering automatic aggregation across Income, Expense, Net Cash Flow, Category, Account, Budget Engine metrics, Goal, Net Worth, Savings Rate, Financial Score (0–100), Forecast, and Insights.
- **Dynamic Net Worth & Asset/Liability Engine**: SQL-level aggregation (`DatabaseHelper.getNetWorthMetrics()`) dynamically calculating total assets (liquid accounts + overpayments) and liabilities (credit cards, loans, overdrafts) to produce accurate Net Worth (`Assets - Liabilities`).

### 🏛️ Enterprise Multi-Period Budgeting Engine & Split-Wise Dashboard
- **Multi-Period Budgeting Engine ([budget_period.dart](file:///home/sct/Desktop/budget-app/lib/features/budgets/domain/models/budget_period.dart))**: Supports `Daily`, `Weekly`, `Monthly`, and `Yearly` budget periods simultaneously with independent data, date boundaries, allocations, spending, pacing, and historical snapshots.
- **Budget Status Engine ([budget_status_engine.dart](file:///home/sct/Desktop/budget-app/lib/features/budgets/domain/services/budget_status_engine.dart))**: Real-time single source of truth calculator computing 15+ metrics per category: Allocation, Spent, Remaining, Available Balance, Progress %, Daily Target Spending, Current Burn Rate, Estimated End-of-Period Spending, Budget Health Score (0–100), Pacing Ratio, Variance, Remaining Days, Transaction Count, Category Contribution %, and Status Classification (`Under Budget`, `On Track`, `Near Limit`, `Over Budget`, `Critical Overspend`).
- **Remaining Budget Transfer Flow ([budget_transfer_service.dart](file:///home/sct/Desktop/budget-app/lib/features/budgets/domain/services/budget_transfer_service.dart))**: Atomic workflow allowing users to transfer unused remaining budget balance to destination accounts (Savings, Cash, Bank, Wife, Son, Daughter, Investment, Emergency Fund, Loan) via master ledger transactions (`type = 2`), updating account balances, net worth, and cash flows.
- **Budget Overspend Recovery Flow ([budget_overspend_recovery_sheet.dart](file:///home/sct/Desktop/budget-app/lib/features/budgets/presentation/widgets/budget_overspend_recovery_sheet.dart))**: Automatic adjustment workflow debiting a selected funding source account to credit and recover overspent budget categories with full audit logging.
- **Automatic Cycle Reset & History Archiving ([budget_history_engine.dart](file:///home/sct/Desktop/budget-app/lib/features/budgets/domain/services/budget_history_engine.dart))**: Automated cycle rollover checking daily, weekly, monthly, and yearly boundaries, preserving immutable snapshots in `budget_history`, and executing configurable Carry Forward rules (`Carry Forward Remaining`, `Carry Forward Overspend`, `Ignore`, `Reset Completely`).
- **Period-Over-Period Comparison Engine ([budget_history_comparison_widget.dart](file:///home/sct/Desktop/budget-app/lib/features/budgets/presentation/widgets/budget_history_comparison_widget.dart))**: Comparative analytics (`Today vs Yesterday`, `This Week vs Last Week`, `This Month vs Last Month`, `This Year vs Last Year`).

### 📊 Financial Score (0–100), Insights & Forecast Engine
- **Deterministic Financial Score (0–100)**: Multi-factor weighted score calculated from savings rate %, budget health, net worth, and cash flow ratio.
- **Insights Engine ([insights_engine.dart](file:///home/sct/Desktop/budget-app/lib/core/services/insights_engine.dart))**: Automated rule-based advice generation based on cash flow health and spending habits.
- **Forecast Engine**: Linear trend projection predicting Next Month Expense, Income, and Net Cash Flow.

### 📅 Month-Based Data Engine
- **Global Month Selector Bar ([month_selector_bar.dart](file:///home/sct/Desktop/budget-app/lib/core/widgets/month_selector_bar.dart))**: Interactive header controller ([month_selector_controller.dart](file:///home/sct/Desktop/budget-app/lib/core/state/month_selector_controller.dart)) allowing month/year navigation (`< February 2026 >`).
- **Application-Wide Month Filtering**: Dynamically recalculates all metrics, envelope budgets, donut charts, and report statements without requiring application restarts.

### 🏷️ Sub-Category Taxonomy & Custom Categories
- **Hierarchical Category Engine**: Supports nested sub-categories (e.g. `Food & Dining` -> `Groceries`, `Restaurants`) with parent-child rollups.
- **Custom Taxonomy Manager ([categories_screen.dart](file:///home/sct/Desktop/budget-app/lib/features/categories/presentation/categories_screen.dart))**: Interface to view, add, and manage custom category and sub-category structures.

### 💼 Multi-Account Wallets & Net Worth Management
- **Accounts & Wallets Manager ([accounts_screen.dart](file:///home/sct/Desktop/budget-app/lib/features/accounts/presentation/screens/accounts_screen.dart))**: Supports Cash, Checking/Bank, Savings, Credit Card, Loan, and Investment account types. Includes dedicated family funding wallets (`Wife Wallet`, `Son Wallet`, `Daughter Wallet`, `Emergency Reserve`, `Investment Portfolio`).
- **Direct Wallet Ledger Integration**: Includes a prominent **"+ Add Ledger"** action button on the Wallets screen as well as per-card **"+ Ledger"** quick action buttons to log transactions directly into specific wallets.
- **Ledger-Driven Balances ([accounts_controller.dart](file:///home/sct/Desktop/budget-app/lib/features/accounts/application/accounts_controller.dart), [database_helper.dart](file:///home/sct/Desktop/budget-app/lib/core/database/database_helper.dart))**: Automatically computes real-time account balances and Net Worth metrics through atomic SQLite transaction ledger updates and inter-module event bus synchronization.

### 📈 Analytics & Custom Pie Chart Renderer
- **Analytics Engine ([analytics_screen.dart](file:///home/sct/Desktop/budget-app/lib/features/analytics/presentation/screens/analytics_screen.dart))**: Displays category spending breakdown, daily burn rate, savings rate %, and cash flow forecast.
- **Custom Hardware GPU Pie Chart ([gpu_pie_chart_painter.dart](file:///home/sct/Desktop/budget-app/lib/features/analytics/presentation/widgets/gpu_pie_chart_painter.dart))**: Direct `CustomPainter` rendering for category donut charts eliminating heavy widget tree rebuilds.

### 📜 Executive Financial Statements & CSV Data Export
- **Tabbed Financial Statements ([reports_screen.dart](file:///home/sct/Desktop/budget-app/lib/features/reports/presentation/reports_screen.dart))**: Displays Executive Summary, Income Statement (P&L), and Cash Flow Statement.
- **CSV Data Exporter ([data_exporter.dart](file:///home/sct/Desktop/budget-app/lib/core/services/data_exporter.dart))**: RFC-4180 compliant CSV exporter and encrypted backup utilities.

### 🔐 Security PIN & Biometric Screen
- **PIN Verification ([pin_lock_screen.dart](file:///home/sct/Desktop/budget-app/lib/features/authentication/presentation/screens/pin_lock_screen.dart))**: 4-digit security PIN lock with biometric prompt, failure haptic feedback, and secure state handling.

### 🛠️ Hardware Diagnostics & Developer Tools
- **Developer Settings ([developer_settings_screen.dart](file:///home/sct/Desktop/budget-app/lib/features/developer_settings/presentation/screens/developer_settings_screen.dart))**: Hardware monitor (60 FPS target, < 25MB RAM heap limit), feature flags (Aggressive Background Memory Purge, Fixed ListExtent rendering, SQL Query Diagnostics), and eMMC database compaction (`VACUUM;`).
- **Clean Application Data & Benchmarking ([settings_screen.dart](file:///home/sct/Desktop/budget-app/lib/features/settings/presentation/settings_screen.dart))**: Diagnostic tools including 500 test item seeder, RAM/Image cache purging, SQLite storage vacuuming, and permanent data wipe modal.

---

## 3. Module Breakdown

| Module | Status | Primary Responsibilities |
| :--- | :--- | :--- |
| **Global Filter Engine** | Completed | Single source of truth filter controller (`GlobalFilterController`) and parameterized SQL query builder (`FilterQueryBuilder`). |
| **Glassmorphism UI Engine** | Completed | VisionOS frosted glass UI system, ambient mesh gradient backdrop, scale tap animations (`GlassCard`, `GlassButton`, `GlassInput`, `GlassBottomBar`). |
| **Calculation Engine** | Completed | Deterministic Level 10 engine driving real-time metric updates across all modules (`FinancialCalculationEngine`). |
| **Authentication** | Completed | Manages initial splash sequence (`SplashScreen`) and 4-digit security PIN verification (`PinLockScreen`). |
| **Dashboard** | Completed | Displays holographic credit-card header, Financial Score (0–100), quick action glass buttons, and real-time Net Worth metrics. |
| **Ledger / Transactions** | Completed | Master transaction ledger with date grouping, search/filters, and transaction creation dialog (`TransactionsScreen`, `AddTransactionDialog`). |
| **Categories** | Completed | System category definitions, sub-category hierarchy, and custom category manager (`CategoriesScreen`, `AddCategoryDialog`). |
| **Budgets** | Completed | Multi-period budgeting engine (Daily, Weekly, Monthly, Yearly), split-wise dashboard, budget status engine, remaining budget transfer, overspend recovery, cycle archiving, and period comparison analytics (`BudgetsScreen`, `BudgetsController`, `BudgetStatusEngine`, `BudgetTransferService`, `BudgetHistoryEngine`). |
| **Accounts / Wallets** | Completed | Multi-account wallet manager (cash, bank, savings, credit card, loan, investment, family wallets), live balance updates, asset/liability SQL aggregation, and Net Worth engine (`AccountsScreen`, `AccountsController`). |
| **Goals** | Completed | Savings goals manager with required monthly savings calculator and progress tracking (`GoalsScreen`, `AddGoalDialog`). |
| **Analytics** | Completed | Category donut chart (`GpuPieChartPainter`), daily average burn rate, savings rate %, next month forecast, and insights (`AnalyticsScreen`). |
| **Reports** | Completed | Tabbed financial statements (Executive Summary, P&L, Cash Flow) and CSV export dialog (`ReportsScreen`, `DataExporter`). |
| **Profile & Settings** | Completed | Theme switching (`ThemeProvider`), security PIN, device diagnostics, SQLite vacuuming, RAM cache purging, test data seeder, and Clean Application Data dialog (`SettingsScreen`). |
| **Developer Settings** | Completed | Frame rate & RAM heap hardware metrics, memory purge & rendering feature flags, and eMMC SQLite compaction (`DeveloperSettingsScreen`). |

---

## 4. Architecture & Directory Summary

```
lib/
├── app/
│   └── main_app.dart                     # Main entrypoint with Glass bottom navigation & tab stack
├── core/
│   ├── database/
│   │   ├── app_database.dart             # SQLite schema initialization and migrations (v4)
│   │   └── database_helper.dart          # Master SQL queries, filter builders, Net Worth aggregation & budget_history
│   ├── di/
│   │   └── service_locator.dart          # Zero-dependency service locator container
│   ├── services/
│   │   ├── data_exporter.dart            # RFC-4180 CSV exporter
│   │   ├── filter_query_builder.dart     # Parameterized SQL query builder for 100k+ records
│   │   ├── financial_calculation_engine.dart # Level 10 Deterministic Calculation Engine
│   │   ├── financial_metrics.dart        # Master calculated financial metrics model
│   │   ├── financial_sync_service.dart   # Real-time inter-module sync event bus
│   │   ├── global_filter_controller.dart # Application-wide filter controller singleton
│   │   ├── global_filter_state.dart      # Immutable global filter state model
│   │   └── insights_engine.dart          # Automated rule-based financial insights engine
│   ├── state/
│   │   ├── micro_notifier.dart           # Lightweight change notifier for micro-state
│   │   └── month_selector_controller.dart# Global month/year state controller
│   ├── theme/
│   │   ├── app_colors.dart               # Palette definitions & glass gradients
│   │   ├── app_theme.dart                # Light/Dark Flutter ThemeData definitions
│   │   ├── glass_tokens.dart             # Blur, border & opacity design tokens
│   │   └── theme_provider.dart           # Application theme switcher state
│   ├── utils/
│   │   ├── formatters.dart               # Currency, date, and percentage formatters
│   │   └── memory_optimizer.dart         # Low-memory lifecycle listener & image cache trimmer
│   └── widgets/
│       ├── floating_bottom_nav.dart      # Floating navigation bar widget
│       ├── global_filter_bar.dart        # Floating glass filter bar with live search input
│       ├── month_selector_bar.dart       # Month navigation bar widget
│       └── glass/                        # VisionOS frosted glass UI primitives
│           ├── ambient_background.dart
│           ├── glass_bottom_bar.dart
│           ├── glass_bottom_sheet.dart
│           ├── glass_button.dart
│           ├── glass_card.dart
│           ├── glass_chip.dart
│           ├── glass_container.dart
│           ├── glass_filter_modal.dart
│           └── glass_input.dart
└── features/
    ├── accounts/                         # Multi-account & Net Worth module
    ├── analytics/                        # Donut charts, forecasts, and metrics screen
    ├── authentication/                   # Splash sequence & PIN lock security
    ├── budgets/                          # Enterprise Financial Budgeting Engine
    │   ├── application/
    │   │   └── budgets_controller.dart
    │   ├── data/
    │   │   └── datasources/
    │   │       └── budget_dao.dart
    │   ├── domain/
    │   │   ├── models/
    │   │   │   ├── budget_model.dart
    │   │   │   ├── budget_pacing_model.dart
    │   │   │   └── budget_period.dart
    │   │   └── services/
    │   │       ├── budget_history_engine.dart
    │   │       ├── budget_pacing_calculator.dart
    │   │       ├── budget_status_engine.dart
    │   │       └── budget_transfer_service.dart
    │   └── presentation/
    │       ├── screens/
    │       │   └── budgets_screen.dart
    │       └── widgets/
    │           ├── add_budget_bottom_sheet.dart
    │           ├── budget_envelope_card.dart
    │           ├── budget_health_card.dart
    │           ├── budget_history_comparison_widget.dart
    │           ├── budget_overspend_recovery_sheet.dart
    │           ├── budget_pacing_card.dart
    │           ├── budget_pacing_chart.dart
    │           ├── budget_pacing_hero_gauge.dart
    │           └── remaining_budget_transfer_sheet.dart
    ├── categories/                       # System & custom category hierarchy module
    ├── dashboard/                        # Financial summary dashboard module
    ├── developer_settings/              # Hardware diagnostic metrics & tuning screen
    ├── goals/                            # Savings goals & required monthly savings calculator
    ├── reports/                          # P&L statements & CSV export screen
    ├── settings/                         # Profile, theme & clean data management screen
    └── transactions/                     # Master transaction ledger module
```
