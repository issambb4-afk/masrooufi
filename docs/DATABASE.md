# Database Architecture

## Technology
**Package:** `drift` & `drift_flutter`
**Version:** ^2.31.0
**Reason:** Mature, strongly-typed SQLite ORM for Flutter that natively supports Dart Streams, complex aggregations, schema migrations, and indexing.

## Entities & Conceptual Relationships

```text
Accounts
   │
   ├── (source) ───── Transactions ─────── Categories
   ├── (destination)         │
   │                         └──── Recurring Rules
   │                                     │
Budgets ───────────── Categories ────────┘
```

## Schema Details
- **Accounts:** Stores user financial stores. Defines `currency` dynamically so future non-TND accounts can be easily configured.
- **Categories:** Tagging for transactions. Never physically deleted if referenced; uses `isActive: false` soft-delete.
- **Budgets:** Tracks spending limits against `categoryId` or globally.
- **Transactions:** The core financial truth. Represents income, expenses, and transfers.
- **RecurringRules:** Templates evaluated dynamically to generate future `Transactions`.

## Money Representation
- Pure `INTEGER` (64-bit).
- Represents absolute minor units.
- Resolves all potential IEEE-754 floating point arithmetic issues natively in SQLite.

## Index Strategy
To support 50,000+ transactions without memory loading:
- `idx_transactions_date`: Accelerates monthly/daily views.
- `idx_transactions_category`: Accelerates category aggregation reports.
- `idx_transactions_account`: Accelerates per-account balance derivations.
- `idx_recurring_next`: Quickly identifies which recurring rules are due for processing.

## Date/Time Strategy
All `DateTime` fields are strictly persisted. We separate creation timestamps (`createdAt`) from actual financial context time (`transactionDate`) to allow historical entries to resolve into the correct monthly budget buckets.

## Transaction/Atomic Operation Strategy
Drift `db.transaction()` will be utilized extensively inside UseCases when operations span multiple tables.
