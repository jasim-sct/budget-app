Created At: 2026-07-23T17:27:54Z
Completed At: 2026-07-24T18:40:00Z
File Path: `file:///home/sct/Desktop/budget-app/app.md`

# Application Documentation: MJSM FINANCE (Financial Operating System)

## 1. Application Overview

- **Product Name**: MJSM FINANCE
- **Developer**: Muhammed Jasim M C (Founder & Lead Software Developer)
- **Purpose**: A commercial-grade, ultra-low-end optimized personal finance operating system. Built for instant startup and high-performance execution on constrained hardware (eMMC storage, 1GB RAM target) with a calm, premium glass UI language.
- **Target Users**: Mobile (Android) and Desktop (Linux/Windows) users seeking a secure, offline-first financial OS with durable local storage, fixed daily spending discipline, multi-period envelope budgeting, two-leg self-transfers, and deterministic calculation engines.
- **Platform(s)**: Android 8.0+, Linux Desktop (GTK / Flutter FFI), Windows Desktop, Cross-Platform Flutter.
- **Storage**: All ledger and preference data persists in app-private SQLite (`getDatabasesPath()` on Android). Writes use `PRAGMA synchronous = FULL` and `wal_checkpoint(FULL)` via `DatabaseHelper.forcePersistToDisk()`.

---

## 2. Core Features & Capabilities

### 💾 Durable Local Persistence
- **SQLite Master Ledger** ([database_helper.dart](file:///home/sct/Desktop/budget-app/lib/core/database/database_helper.dart)): Single source of truth for transactions, accounts, categories, budgets, goals, and settings.
- **User Settings Store** ([user_settings_store.dart](file:///home/sct/Desktop/budget-app/lib/core/services/user_settings_store.dart)): Central write-through store for theme, PIN, currency, and biometrics flags in `user_settings` (flushed to disk on every write).
- **PIN Auth** ([pin_auth_service.dart](file:///home/sct/Desktop/budget-app/lib/core/services/pin_auth_service.dart)): Persisted 4-digit PIN; unlock required after splash when a PIN exists.
- **Theme / Currency**: Loaded at startup from SQLite; survive force-close and reopen.

### 🏠 Home — Fixed Daily Safe Amount (Discipline Model)
- **Intent Decision Engine** ([intent_decision_engine.dart](file:///home/sct/Desktop/budget-app/lib/core/services/intent_decision_engine.dart)):
  - **Fixed daily allocation** per budget = `Budget Amount ÷ Period Days` (monthly/weekly/yearly/daily). This target does **not** change when the user spends.
  - **Today’s safe amount (one number)** = `Σ(fixed daily allocations) − today’s actual spending`.
  - **Positive** = still available today; **negative** = exceeded today’s plan (show overrun as negative).
  - Never uses `remaining budget ÷ remaining days` (no dynamic compression / compensation).
- **Live circulation**: Dashboard listens to [FinancialSyncService](file:///home/sct/Desktop/budget-app/lib/core/services/financial_sync_service.dart) and recalculates when budgets or transactions change.

### 🔀 Self-Transfer Root Ledger Model (Two Legs)
- **Ledger types**: `0` Expense · `1` Income · `2` Transfer.
- **Self-transfer rule**: Always exactly **two** linked transactions:
  1. **Transfer Out** (`payment_method = Transfer Out`) — removes from source account
  2. **Transfer In** (`payment_method = Transfer In`) — adds to destination account
- Linked by shared `reference_number`. Net worth across wallets is conserved.
- **API**: `DatabaseHelper.createSelfTransfer(...)`. Single-leg `type = 2` inserts via `insertTransaction` are rejected.
- Transfers are **excluded** from income/expense and daily safe-spend (expense queries use `type = 0` only).
- Deleting one transfer leg deletes **both** legs and reverts both balances.

### 🏛️ Budget Remaining Transfer & Overspend Recovery (Two Ledgers)
- **Remaining Budget Transfer** ([budget_transfer_service.dart](file:///home/sct/Desktop/budget-app/lib/features/budgets/domain/services/budget_transfer_service.dart)): Moves unused envelope balance using the same two-ledger self-transfer model (out from source wallet + in to destination), updates `budgets.transferred_amount`, and writes audit logs.
- **Overspend Recovery**: Debits funding account and credits a destination wallet as two linked transfer legs; updates `budgets.recovered_amount`.

### 🔍 Centralized Enterprise Global Filter & Query Engine
- **Global Filter Controller** ([global_filter_controller.dart](file:///home/sct/Desktop/budget-app/lib/core/services/global_filter_controller.dart)): Single source of truth filtering state (`GlobalFilterState`).
- **Parameterized SQL Filter Builder** ([filter_query_builder.dart](file:///home/sct/Desktop/budget-app/lib/core/services/filter_query_builder.dart)): Indexed SQLite queries for large ledgers.
- **Cross-Module Sync** ([financial_sync_service.dart](file:///home/sct/Desktop/budget-app/lib/core/services/financial_sync_service.dart)): `persistAndNotify()` forces WAL checkpoint then broadcasts to calculation engine, ledger, accounts, budgets, goals, analytics, reports, and home intent.

### ⚡ Master Ledger & Level 10 Calculation Engine
- **Master Ledger**: Tables `transactions`, `accounts`, `categories`, `budgets`, `goals`, `budget_history`, `user_settings`, `audit_logs`.
- **Level 10 Calculation Engine** ([financial_calculation_engine.dart](file:///home/sct/Desktop/budget-app/lib/core/services/financial_calculation_engine.dart)): Event-driven aggregation for income, expense, cash flow, category, account, budget totals, goals, net worth, savings rate, financial score, forecast, and insights.
- **Net Worth Engine**: SQL aggregation of assets vs liabilities (`Assets − Liabilities`).

### 🏛️ Multi-Period Budgeting Engine
- **Periods** ([budget_period.dart](file:///home/sct/Desktop/budget-app/lib/features/budgets/domain/models/budget_period.dart)): Daily, Weekly, Monthly, Yearly with independent bounds and day counts for fixed daily allocation.
- **Budget Status Engine** ([budget_status_engine.dart](file:///home/sct/Desktop/budget-app/lib/features/budgets/domain/services/budget_status_engine.dart)): Allocation, spent, remaining, health, pacing, variance, and status classification for **period progress** (independent from today’s fixed daily plan).
- **History & Rollover** ([budget_history_engine.dart](file:///home/sct/Desktop/budget-app/lib/features/budgets/domain/services/budget_history_engine.dart)): Cycle snapshots and carry-forward rules. Unused daily allocation does **not** auto-roll into tomorrow’s plan.

### 🎨 Motion & Depth Foundation (Financial OS UI Language)
- **Motion tokens** ([app_motion.dart](file:///home/sct/Desktop/budget-app/lib/core/theme/app_motion.dart)): `AppDurations`, `AppCurves`, `AppElevation` — motion communicates change, not decoration.
- **Page routes** ([app_page_routes.dart](file:///home/sct/Desktop/budget-app/lib/core/navigation/app_page_routes.dart), [app_router.dart](file:///home/sct/Desktop/budget-app/lib/core/navigation/app_router.dart)): Context-preserving fade-slide / shared-axis transitions.
- **Micro-interactions**: Press scale on buttons, cards, and chips; animated number tweens for financial values.

### 💼 Multi-Account Wallets & Net Worth
- Account types: Cash, Checking/Bank, Savings, Credit Card, Loan, Investment, plus family/seed wallets.
- Balances update only through ledger rows (expense/income/transfer legs).

### 📜 Reports & Export
- Executive / P&L / Cash Flow statements ([reports_screen.dart](file:///home/sct/Desktop/budget-app/lib/features/reports/presentation/reports_screen.dart)).
- CSV + JSON backup/restore ([data_exporter.dart](file:///home/sct/Desktop/budget-app/lib/core/services/data_exporter.dart)) with durable checkpoint after restore.

### 🔐 Security
- PIN setup (enter + confirm) and unlock screens ([pin_lock_screen.dart](file:///home/sct/Desktop/budget-app/lib/features/authentication/presentation/screens/pin_lock_screen.dart)).
- Theme and PIN persisted in app SQLite storage.

---

## 3. Module Breakdown

| Module | Status | Primary Responsibilities |
| :--- | :--- | :--- |
| **Persistence** | Completed | Durable SQLite, `UserSettingsStore`, WAL checkpoint, theme/PIN/currency persistence. |
| **Intent / Home Safe Amount** | Completed | Fixed daily allocation − today’s spend (negative if exceeded); sync-driven refresh. |
| **Self-Transfer Ledger** | Completed | Two-leg transfer model (`createSelfTransfer`), pair delete, type guards. |
| **Budget Transfer / Recovery** | Completed | Remaining transfer & overspend recovery as two linked ledger legs. |
| **Global Filter Engine** | Completed | `GlobalFilterController` + `FilterQueryBuilder`. |
| **Motion / Navigation** | Completed | `AppMotion`, `AppPageRoutes`, micro-press, elevation. |
| **Calculation Engine** | Completed | `FinancialCalculationEngine` + `FinancialSyncService.persistAndNotify`. |
| **Authentication** | Completed | Splash + persisted PIN lock/setup. |
| **Dashboard** | Completed | Today’s safe amount hero, intent cards, month snapshot, recent activity. |
| **Ledger / Transactions** | Completed | Expense/income CRUD; transfers via two-leg API. |
| **Categories** | Completed | Hierarchy + custom categories. |
| **Budgets** | Completed | Multi-period envelopes, status, history, remaining transfer, recovery. |
| **Accounts / Wallets** | Completed | Multi-wallet balances driven by ledger. |
| **Goals** | Completed | Savings goals + required monthly savings. |
| **Analytics** | Completed | Category charts, burn rate, forecast, insights. |
| **Reports** | Completed | Statements + CSV/JSON export. |
| **Settings** | Completed | Theme, currency, PIN, diagnostics, clean data. |
| **Developer Settings** | Completed | Hardware metrics, feature flags, VACUUM. |

---

## 4. Financial Philosophy (Canonical Rules)

1. **Budgets** = commitments for a period.
2. **Daily allocations** = fixed targets (`amount ÷ period days`) set from the budget, unchanged by daily spend.
3. **Transactions** = behavior (expenses/income); self-transfers move money between wallets without changing spend totals.
4. **Today’s safe amount** = planned today − spent today (report overrun as negative; never rewrite tomorrow’s plan).
5. **Reports** = outcomes and adherence — not automatic redistribution of unused or overspent daily amounts.

---

## 5. Architecture & Directory Summary

```
lib/
├── app/
│   └── main_app.dart                     # Shell, splash, PIN gate, tab stack
├── core/
│   ├── database/
│   │   ├── app_database.dart
│   │   └── database_helper.dart          # Ledger CRUD, createSelfTransfer, forcePersistToDisk
│   ├── di/
│   │   └── service_locator.dart
│   ├── navigation/
│   │   ├── app_page_routes.dart          # Fade-slide / shared-axis routes
│   │   └── app_router.dart               # AppRouter.push helpers + page transitions theme
│   ├── services/
│   │   ├── currency_provider.dart
│   │   ├── data_exporter.dart
│   │   ├── filter_query_builder.dart
│   │   ├── financial_calculation_engine.dart
│   │   ├── financial_metrics.dart
│   │   ├── financial_sync_service.dart   # persistAndNotify
│   │   ├── intent_decision_engine.dart   # Fixed daily safe amount
│   │   ├── pin_auth_service.dart
│   │   ├── user_settings_store.dart      # Theme / PIN / currency persistence
│   │   └── ...
│   ├── theme/
│   │   ├── app_motion.dart               # Durations, curves, elevation
│   │   ├── app_spacing.dart              # Spacing / radius / shadows (+ exports motion)
│   │   ├── app_theme.dart
│   │   ├── glass_tokens.dart
│   │   └── theme_provider.dart
│   └── widgets/
│       ├── app_button.dart / app_card.dart / app_chip.dart / app_micro_pressable.dart
│       ├── animated_number_text.dart
│       └── glass/
└── features/
    ├── accounts/
    ├── analytics/
    ├── authentication/                   # Splash + PIN setup/unlock
    ├── budgets/
    │   └── domain/services/
    │       ├── budget_transfer_service.dart  # Two-ledger remaining + recovery
    │       └── ...
    ├── categories/
    ├── dashboard/                        # Home safe amount + intent cards
    ├── developer_settings/
    ├── goals/
    ├── reports/
    ├── settings/
    └── transactions/
        └── domain/transaction_model.dart # expense | income | transfer
```

---

## 6. Developer Identity (Metadata)

| Key | Value |
| :--- | :--- |
| developerName | Muhammed Jasim M C |
| developerBrand / company / productName | MJSM FINANCE |
| founder | Muhammed Jasim M C |
| copyright | © Muhammed Jasim M C. All Rights Reserved. |
