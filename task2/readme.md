# README: Plan Switch Detection Methodology

## 1. Objective

The goal of this task is to identify specific dates where the PostgreSQL Query Optimizer changes its execution strategy (the "plan") for a given query template. By varying a date parameter, we observe how data distribution and cardinality estimates trigger different physical operator trees.

## 2. Implementation Logic: Binary Search

Iterating through every single day between 1992 and 1998 would be computationally expensive and inefficient (over 2,500 executions per query). Instead, this implementation employs a Recursive Binary Search (also known as a "Divide and Conquer" approach) to find the "edge" where a plan changes.

### The Algorithm:

**Baseline Check:** Compare the execution plan of the `start_date` and the `end_date`.

**Identical Plans:** If the plans are structurally identical, the algorithm assumes no switch occurred in this range and returns.

**Different Plans:** If the plans differ, the algorithm:

* Checks if the dates are adjacent (1 day apart). If so, a switch point is found.
* If not adjacent, it calculates the `mid_date`.
* Recursively calls the function for the `[start, mid]` range and the `[mid, end]` range.

## 3. Structural Comparison

To ensure we only detect meaningful changes in strategy (and not just minor cost estimate fluctuations), the script relies on `extract_physical_operator_tree` function.

**Raw JSON:** PostgreSQL returns a highly detailed JSON plan including costs, widths, and actual timings.

**Structural Tree:** The auxiliary function filters these details to focus on the Physical Operators (e.g., Seq Scan, Hash Join, Index Scan). A "switch" is only registered if the tree of operators changes.

## 4. Technical Stack

* **Language:** Python 3
* **Database Driver:** `psycopg2` for PostgreSQL connectivity.
* **Query Source:** TPC-H Benchmark queries (modified for date injection).

### Output Formats:

* `output.txt`: Human-readable summary of switch dates.
* `switch_plans.json`: Full JSON plan comparison for downstream analysis (Task 3).

## 5. Execution Details

The script processes three specific TPC-H query variations:

**Query 1:** A simple aggregation with a WHERE clause on `l_shipdate`.
**Query 2:** A subquery-based EXISTS join involving `orders` and `lineitem`.
**Query 3:** A complex three-way join (`customer`, `orders`, `lineitem`) where dates influence the join order and scan types.

## 6. How to Run

Update `DB_CONFIG` in `task2.py` with your local PostgreSQL credentials.

Execute the script:

```bash
python task2.py
```