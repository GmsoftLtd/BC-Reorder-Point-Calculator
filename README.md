# BC Reorder Point Calculator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Business Central](https://img.shields.io/badge/BC-v27+-blue.svg)](https://learn.microsoft.com/en-us/dynamics365/business-central/)

A free, MIT-licensed Business Central extension that calculates the **Reorder Point** the way the planning engine actually means it: expected demand during the replenishment lead time, plus your safety stock buffer.

**Companion blog post:** [Reorder Point in Business Central — Make-to-Stock, Make-to-Order, and the Number That Triggers Replenishment](https://insidebusinesscentral.com/reorder-point-in-business-central-calculator/)

> ⭐ If this saves you time, please **star the repo** — it helps other Business Central folks find it.

This is the third piece of a three-part replenishment set:

- [bc-safety-stock](https://github.com/GmsoftLtd/bc-safety-stock) — how much buffer to hold (50100-50199)
- [bc-eoq-calculator](https://github.com/GmsoftLtd/bc-eoq-calculator) — how much to order (50200-50299)
- **bc-reorder-point** — when to order (50300-50399)

…plus [bc-ValueEntryGL-Audit](https://github.com/GmsoftLtd/bc-ValueEntryGL-Audit) — inventory-to-G/L audit.

---

## What it does

Most BC item cards have a `Reorder Point` that is either blank or a round number nobody can defend. The Microsoft documentation is blunt about what the field is supposed to be: *"A reorder point represents demand during lead time."* This extension computes it from each item's own data:

```
Reorder Point = (Average Daily Demand x Lead Time in days) + Safety Stock
```

- **Average Daily Demand** comes from posted sales (Item Ledger Entries of type `Sale`) over the history window, averaged across every calendar day so the rate lines up with a calendar-day lead time.
- **Lead Time** comes from purchase-receipt history (`Order Date` to `Posting Date`) for purchased items, or the `Lead Time Calculation` field for manufactured and assembled items, with a setup fallback.
- **Safety Stock** is the existing `Item."Safety Stock Quantity"` (optional, on by default).

## Make-to-stock vs make-to-order

This is the part most reorder-point tools get wrong. A reorder point only makes sense for **make-to-stock**: items you keep on the shelf and replenish to a level. For **make-to-order**, supply is created against one specific demand (Reordering Policy = `Order`, or Manufacturing Policy = `Make-to-Order`), the demand and supply stay pegged, and there is no stock level for a reorder point to defend.

So the extension **skips make-to-order items** by default and writes the reason to the log. It covers:

- Purchased make-to-stock items (buy to stock)
- Manufactured make-to-stock finished goods (produce to stock)
- Assembled make-to-stock items

and deliberately leaves make-to-order alone.

## Features

- **Item Card action** — *Calculate Reorder Point* — calculate for one item, see the result code and a plain-English reason, choose to apply
- **Item List bulk action** — *Calculate Reorder Point (Bulk)* — process all filtered/selected items, with a heads-up about how many are make-to-order (and therefore skipped)
- **Job Queue codeunit** — schedule recurring recalculation
- **Calculation log** — every run is logged (item, datetime, user, demand rate, lead time and its source, demand-during-lead-time, safety stock used, result code, reason)
- **Setup page** — history window, minimum observations, fallback lead time, whether to include safety stock, whether to switch a blank policy to Fixed Reorder Qty.

## How it works

1. Reads **Item Ledger Entries** of type `Sale` for the configured history window (default 365 days) and computes the average daily demand
2. Determines lead time by replenishment system: purchase-receipt history, then `Lead Time Calculation`, then the setup fallback
3. Adds `Item."Safety Stock Quantity"` if enabled
4. Writes the result to `Item."Reorder Point"` and, if the item had no reordering policy, switches it to `Fixed Reorder Qty.` so the planning engine reads the value
5. Logs the calculation

## Installation

### From source

1. Clone this repo
2. Open `app.json` and confirm the object ID range does not conflict (default 50300-50399)
3. In VS Code with the AL extension, run **AL: Publish** (Ctrl+F5) to your BC sandbox
4. Or build with `al package` and upload the `.app` via **Extension Management**

### From a packaged .app

Releases (when available) at the [Releases page](https://github.com/GmsoftLtd/bc-reorder-point/releases).

## Usage

### Single item

1. Open any Item Card
2. Click **Calculate Reorder Point** (Actions tab)
3. Review the calculated value and the reason
4. Confirm to apply, or preview

### Bulk

1. Open the Item List
2. Filter to the items you want (e.g. by Item Category Code)
3. Click **Calculate Reorder Point (Bulk)**
4. Each item is processed and logged; make-to-order items are skipped with a reason

### Job Queue

To schedule monthly recalculation of all FERT items:

1. **Job Queue Entries -> New**
2. Object Type to Run: **Codeunit**
3. Object ID: **50301** (Reorder Point Job Queue Run)
4. Parameter String: `FILTER=Item Category Code:FERT`
5. Set the recurring schedule

Without parameters, all inventory items are processed (make-to-order items skipped and logged).

### Sandbox: try it on a clean item

1. Open any Item Card in a **sandbox** environment
2. Click **Generate Demo Data (Sandbox)** — creates past Purchase Orders (lead time + inventory), past Sales Orders (demand history), and a few future Sales Orders
3. Post the Purchase Orders first (Post Batch), then the past Sales Orders
4. Back on the Item Card, click **Calculate Reorder Point** — you should now get a non-zero result with a meaningful reason

> This action floods your order tables with synthetic data. Sandbox only. Remove `ReorderPointDemoData.Codeunit.al` (and the `GenerateRPDemoData` action) before building a production `.app`.

## Configuration

**Reorder Point Setup** page (Search -> Reorder Point Setup):

- **Demand History Window (Days)** — how far back to look (365 = a full year, smooths seasonality)
- **Min Demand Observations** — minimum days-with-demand needed to calculate
- **Fallback Lead Time (Days)** — used when there is no receipt history and no Lead Time Calculation; set to 0 to refuse to guess
- **Add Item Safety Stock Quantity** — include the safety stock buffer (the textbook reorder point)
- **Round Up Result** — round to whole units
- **Auto-Update Item.Reorder Point** — write the result to the item
- **Set Policy to Fixed Reorder Qty. when None** — so the planning engine reads the reorder point
- **Skip Make-to-Order Items** — leave pegged items alone
- **Log History** — save every calculation

## Limitations

- **Sales-based demand** — counts Item Ledger Entries of type `Sale`. Components consumed in production (entry type `Consumption`) are out of scope; this tool is for products and finished items that are sold.
- **Lead time from PO receipts or the item field** — purchased lead time is averaged from receipts; manufactured and assembled lead time is read from `Lead Time Calculation`. It does not parse routing time.
- **Flat average, no seasonality curve** — a full-year window smooths seasonality into a steady rate. For sharply seasonal items, recalculate in-season.
- **No multi-location split** — calculates globally per item. Per-location reorder points (via SKUs) are not written.
- **Make-to-order is skipped by design** — these are pegged to demand and do not use a reorder point.

## When NOT to use this

- **Make-to-order / engineer-to-order items** — use the `Order` policy and let demand peg supply
- **Brand-new items** (below the minimum observations): use a category default
- **Intermittent / lumpy demand**: a flat daily average understates the spike risk; lean on safety stock or a category rule
- **Items with regulatory minimum stock**: that number comes from compliance, not from demand

## Related

- [Inside Business Central — blog](https://insidebusinesscentral.com)
- Companion: [bc-safety-stock](https://github.com/GmsoftLtd/bc-safety-stock) and [bc-eoq-calculator](https://github.com/GmsoftLtd/bc-eoq-calculator)
- Microsoft Learn: [Design details: Planning parameters](https://learn.microsoft.com/dynamics365/business-central/design-details-planning-parameters)

## License

MIT — see [LICENSE](LICENSE).

## Contributions

Issues and pull requests welcome, especially:

- Demand from consumption for component-level reorder points
- Lead time from production-order routing time
- Per-location (SKU) reorder points
- Seasonal demand profiles

## Author

**Grigorios Mavrogeorgis** — Director and Founder of [GMSOFT Limited](https://gmsoft.co.uk)
Microsoft Dynamics 365 Business Central Community Super User, Season 1 2026
