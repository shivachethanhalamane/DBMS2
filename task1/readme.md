# Task 1: PostgreSQL Plan Comparator

## What This Program Does
When a database runs a query, it generates an "execution plan" that acts as a step-by-step roadmap for finding the data. However, the database optimizer constantly recalculates things like estimated costs, times, and row counts, meaning the raw plan files will almost always look different textually even if the core steps are exactly the same.

This program solves that problem. It takes two PostgreSQL query execution plans in JSON format and checks if they are **structurally identical**. It ignores all the changing numbers and focuses only on whether the database is using the exact same operations in the exact same order.

## How It Works
The script (`task1.py`) achieves this in three simple steps:

1. **Smart Parsing:** It reads the `plan1.json` and `plan2.json` files. It includes a custom loader that safely ignores extra terminal text, headers, footers, or trailing `+` characters that often accidentally get copied from the PostgreSQL console.
2. **Extracting the Skeleton (Physical Operator Tree):** Instead of comparing the massive raw JSON files, the script recursively strips away all the "noise" (like costs, startup times, and row estimates). It builds a simplified skeleton of the plan that only keeps track of:
   * **Node Type:** The operation being performed (e.g., Nested Loop, Hash Join, Seq Scan).
   * **Join Type:** How the tables are connected (e.g., Inner, Semi).
   * **Relation Name:** The specific tables being accessed.
3. **Deep Comparison:** It takes the simplified skeletons of both plans and compares them. If the structures match perfectly, the plans are considered equivalent.

## How to Run the Code

**Prerequisites:**
* Python 3 installed on your system.
* Two PostgreSQL execution plans saved as `plan1.json` and `plan2.json` in the same folder as the script.

**Execution:**
Run the following command in your terminal:
```bash
python3 task1.py