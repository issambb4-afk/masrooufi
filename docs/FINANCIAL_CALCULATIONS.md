# Financial Calculations Strategy

## Core Principles
1. **NEVER use floating point arithmetic (Dart `double`) for money.**
2. Use **Integer minor units** for authoritative persistence and calculation.
3. Decouple storage from presentation and domain entity boundaries.

## Storage Representation
We represent money as a 64-bit integer (`IntColumn` in Drift / SQLite `INTEGER`) representing the smallest minor unit of the currency.

For the primary currency **TND (Tunisian Dinar)**, which has 3 decimal places:
- 1 TND = 1000 minor units
- Stored value for 25.500 TND = `25500`

### Multi-Currency Considerations
The database stores `currency` (e.g., `'TND'`, `'USD'`) on Accounts and Budgets. The application domain will map the currency code to its respective decimal precision.
- USD: 2 decimal places (1 USD = 100 minor units).
- TND: 3 decimal places (1 TND = 1000 minor units).

## Rounding Rules
Since we do not use `double` for calculation, rounding errors are prevented by design for addition and subtraction.
If calculations like percentages (for budgets) are required:
- They should be calculated as `(usedAmount * 100) ~/ budgetAmount`.
- They are derived dynamically and not stored permanently in the database to maintain source of truth integrity.

## Transaction Types & Sign Conventions
Amounts in the database are stored as **absolute (positive) minor units**.
The `type` field dictates the algebraic sign during aggregation queries:
- `income`: +
- `expense`: -
- `transfer`: Source account (`accountId`) -, Destination account (`destinationAccountId`) +. Transfers are fundamentally neutral regarding personal net worth.

## Transfers
Transfers map directly to the `Transactions` table but contain an additional non-null reference when `type == 'transfer'`:
- `accountId` represents the withdrawal source.
- `destinationAccountId` represents the deposit destination.
This ensures a single, atomic, unambiguous record exists for moving funds between user accounts.

## Future Cloud Sync
The integer representation guarantees stability across local databases, memory, and future JSON APIs (e.g., `{"amount": 25500}`).
