# Application Documentation: Budget Lite Pro (Enterprise Financial OS)

## 1. Application Overview

- **Purpose**: A commercial-grade, ultra-low-end optimized personal finance operating system. Built for instant startup (< 1 second) and high-performance execution on constrained hardware (eMMC storage, 1GB RAM) using an Apple VisionOS & macOS Big Sur inspired Glassmorphism UI engine.
- **Target Users**: Mobile (Android) and Desktop (Linux) users seeking a secure, offline-first personal financial operating system with zero latency, month-based data isolation, sub-category hierarchies, envelope budgeting, required monthly savings calculators, executive P&L statements, level 10 deterministic calculation engine, enterprise global filter & query engine, advanced frosted glass aesthetics, and automated cash flow analytics.
- **Platform(s)**: Android, Linux Desktop (GTK / Flutter FFI), Cross-Platform Flutter Desktop & Mobile.

---

## 2. Core Features

### Centralized Enterprise Global Filter & Query Engine
- **Global Filter Controller (`GlobalFilterController`)**: Central application service maintaining single source of truth filtering state (`GlobalFilterState`).
- **Parameterized SQL Filter Builder (`FilterQueryBuilder`)**: Constructs indexed SQLite queries (`WHERE` clauses utilizing `date`, `month`, `year`, `category`, `account_id`, `type`, `amount`) for 100,000+ transaction speed.
- **Cross-Module Reactive Integration**: Modifying filters triggers real-time recalculation across `FinancialCalculationEngine`, Dashboard, Transactions Ledger, Accounts, Budgets, Goals, Analytics, and Reports.
- **VisionOS Glass Filter Bar (`GlobalFilterBar`) & Modal Sheet (`GlassFilterModal`)**: Live search bar, active filter count badge, date range chip selectors, transaction type toggles, and reset button.

### Master Ledger & Level 10 Calculation Engine (Version 3)
- **Master Ledger**: Single source of truth database (`transactions`) for all financial records.
- **Level 10 Calculation Engine (`FinancialCalculationEngine`)**: Real-time event-driven calculation pipeline triggering automatic SQL aggregation across Merchant, Category, Subcategory, Account, Budget, Goal, Net Worth, Cash Flow, Savings, Debt, Investment, Monthly Snapshot, Quarter, Year, Analytics, Financial Score (0–100), Forecast, and Insights engines.

### Financial Score (0–100) & Forecast Engine
- **Deterministic Financial Score (0–100)**: Multi-factor weighted score calculated from savings rate %, budget health, net worth, and cash flow ratio.
- **Forecast Engine**: Linear trend projection predicting Next Month Expense, Income, and Net Cash Flow.

### Month-Based Data Engine
- **Global Month Selector Bar**: Interactive header (`< February 2026 >`) embedded across screens allowing instant month/year selection.
- **Application-Wide Month Filtering**: Changing the active month recalculates all balances, charts, categories, budget health scores, and report statements dynamically without app restarts.

### Sub-Category Taxonomy & Custom Categories
- **Hierarchical Category Engine**: Nested sub-categories (e.g. `Food & Dining` -> `Groceries`, `Restaurants`, `Coffee`) with parent-child rollups.
- **Custom Taxonomy Manager**: Category management screen (`CategoriesScreen`) to view, add, and delete custom categories and sub-categories.

### Envelope Budgets & Goal Tracking
- **Envelope Budget Caps**: Monthly budget allocation with envelope carry-forward overspend adjustments.
- **Budget Health Score (0–100)**: Real-time budget health score indicator based on total envelope usage ratio.
- **Financial Savings Goals**: Savings goals manager (`GoalsScreen`, `AddGoalDialog`) featuring an automated **Required Monthly Savings Calculator** ($\frac{\text{Target} - \text{Current}}{\text{Months Remaining}}$).

### Executive Financial Statements & Data Backup
- **Tabbed Financial Statements**: Executive Summary, Income Statement (P&L), and Cash Flow Statement.
- **CSV Data Exporter & Relational JSON Backup**: RFC-4180 compliant CSV export and encrypted JSON backup/restore service.

---

## 3. Module Breakdown

| Module | Status | Primary Responsibilities |
| :--- | :--- | :--- |
| **Global Filter Engine** | Completed | Single source of truth filter controller and parameterized SQL query builder (`GlobalFilterController`). |
| **Glassmorphism UI Engine** | Completed | Advanced VisionOS frosted glass system, scale tap animations, and mesh gradients. |
| **Calculation Engine** | Completed | Deterministic Level 10 engine driving real-time metric updates across all modules (`FinancialCalculationEngine`). |
| **Authentication** | Completed | Manages initial splash sequence and 4-digit security PIN verification (`PinLockScreen`). |
| **Dashboard** | Completed | Displays holographic credit-card header, Financial Score (0-100), quick action glass buttons, and metrics. |
| **Ledger / Transactions** | Completed | Master transaction ledger with paginated list, live search, filter chips, and transaction creation sheet. |
| **Categories** | Completed | System category definitions, sub-category hierarchy, and custom category manager (`CategoriesScreen`). |
| **Budgets** | Completed | Envelope budget limits, carry-forwards, progress bars, and Budget Health Score (`BudgetsScreen`). |
| **Accounts** | Completed | Multi-account wallet manager, checking, credit card limits, and net worth overview (`AccountsScreen`). |
| **Goals** | Completed | Savings goals manager with required monthly savings calculator and progress tracks (`GoalsScreen`). |
| **Analytics** | Completed | Category donut chart, daily average burn rate, savings rate %, and next month forecast (`AnalyticsScreen`). |
| **Reports** | Completed | Tabbed financial statements (Summary, P&L, Cash Flow) and CSV export dialog (`ReportsScreen`). |

---

## 4. Architecture Summary

```
lib/
├── core/
│   ├── services/
│   │   ├── filter_query_builder.dart     # Parameterized SQL query builder for 100k+ records
│   │   ├── financial_calculation_engine.dart # Level 10 Deterministic Calculation Engine
│   │   ├── financial_metrics.dart        # Master calculated financial metrics model
│   │   ├── financial_sync_service.dart   # Real-time inter-module sync event bus
│   │   ├── global_filter_controller.dart # Application-wide filter controller singleton
│   │   ├── global_filter_state.dart      # Immutable global filter state model
│   │   └── insights_engine.dart          # Automated financial insights generator
│   └── widgets/
│       ├── global_filter_bar.dart        # Floating glass filter bar with live search input
│       └── glass/
│           └── glass_filter_modal.dart   # Glass filter modal sheet with time & category toggles
```
