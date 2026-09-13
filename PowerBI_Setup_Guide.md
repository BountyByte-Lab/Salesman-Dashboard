# Power BI Setup Guide — Salesman Performance Dashboard

Claude can't generate a `.pbix` file directly (that format needs Power BI Desktop itself), so this guide gives you everything to build it there in about 15 minutes — plus the ready-to-use **HTML dashboard** (`salesman_dashboard.html`) as a version you can open and refresh right now without Power BI.

## 1. Load the data
**Home → Get Data → Excel** → select your monthly export (same columns as `Data_for_make_dashboard_salesman_Agustus_2026_nasional_only.xlsx`) → load the `NASIONAL AUG` sheet as a table named `Sales`.

Set these column types on load: `date` → Date, `quantity` → Whole Number, `sales_amount` → Decimal Number, `week`/`month`/`year`/`salesman`/`distributor`/`sub_area`/`sub_brand`/`ABS`/`customer_no` → Text (`customer_no` is required by the `Active Outlets` measure in step 3).

For every new period, drop the new export into the same query (Power Query lets you point `Get Data` at a folder of monthly files and append them automatically — set that up once via **Get Data → Folder** if you want it fully hands-off).

## 2. Build a Date table
**Modeling → New Table:**
```
DateTable = CALENDAR(MIN(Sales[date]), MAX(Sales[date]))
```
Mark it as a Date Table (Modeling → Mark as Date Table), then relate `DateTable[Date]` → `Sales[date]` (1-to-many).

## 3. Core measures (Modeling → New Measure)
```
Total Quantity      = SUM(Sales[quantity])
Total Sales Value   = SUM(Sales[sales_amount])
Active Salesmen     = DISTINCTCOUNT(Sales[salesman])
Avg Sales / Outlet  = DIVIDE([Total Sales Value], [Active Outlets])
Avg Sales / Salesman= DIVIDE([Total Sales Value], [Active Salesmen])

Active Outlets =
COUNTROWS(
  FILTER(
    SUMMARIZE(Sales, Sales[distributor], Sales[sub_area], Sales[customer_no], "TotalQty", SUM(Sales[quantity])),
    [TotalQty] > 0
  )
)
```
`Active Outlets` counts distinct (distributor, sub area, customer) combinations whose **summed** quantity over the filtered period is greater than 0 — not a simple `DISTINCTCOUNT` of customers with any single positive-quantity row, since the same customer number can recur under different distributors/sub areas.

## 4. Slicers (filters)
Add slicer visuals for:
- `Sales[sub_brand]`
- `Sales[ABS]`
- `Sales[sub_area]` → `Sales[distributor]` (put both slicers on the canvas; Power BI's cross-filtering will automatically narrow the distributor list to whatever's in the selected sub-area — no extra setup needed, since they're in the same table)

## 5. Daily / weekly / monthly view
Easiest approach: build three separate visuals (or one visual with a **field parameter**) bound to:
- Daily: `DateTable[Date]`
- Weekly: `Sales[week]` (already provided per row) — combine with `Sales[year]` if you'll ever load more than one year
- Monthly: `DateTable[Date].[Month]`

Field parameter version (single chart, dropdown to switch granularity): **Modeling → New Parameter → Fields**, add `DateTable[Date]`, `Sales[week]`, `DateTable[Date].[Month]` as the options, then bind your line chart's X-axis to the parameter.

## 6. Suggested visual layout
- **KPI cards** (top row): Total Quantity, Total Sales Value, Active Outlets, Active Salesmen
- **Line chart**: [Total Sales Value] by date/week/month parameter
- **Bar chart**: Top 10 `Sales[salesman]` by [Total Sales Value]
- **Table/matrix**: `salesman`, `ABS`, `distributor`, `sub_area`, [Total Quantity], [Total Sales Value], [Active Outlets], [Avg Sales / Outlet] — sorted by Total Sales Value descending

## 7. Refreshing with a new Excel file
- If you loaded a single file: **Home → Transform Data → Data Source Settings → Change Source**, point to the new file, then **Refresh**.
- If you set up the folder-based query in step 1: just drop the new monthly file into that folder and hit **Refresh** — no reconfiguration needed.

---
**In the meantime**, `salesman_dashboard.html` gives you the same filters (sub-brand, ABS, sub-area → distributor), the same daily/weekly/monthly toggle, and the same KPIs/leaderboard — open it in any browser and upload a new Excel file whenever you have fresh data, no Power BI license required.
