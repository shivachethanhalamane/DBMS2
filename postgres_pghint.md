---

# PostgreSQL and pg\_hint\_plan Guide

---

## Prerequisites

* **PostgreSQL version 14 or higher** installed and running on your system.

---

## Part 1: pg\_hint\_plan Installation

`pg_hint_plan` is a PostgreSQL extension that allows you to force the query execution plan chosen by PostgreSQL's optimizer.

By default, PostgreSQL uses a cost-based optimizer and does not support optimizer hints. pg\_hint\_plan enables hints using special SQL comments, allowing controlled experimentation with execution plans.

Official documentation:
[https://pg-hint-plan.readthedocs.io/en/latest/](https://pg-hint-plan.readthedocs.io/en/latest/)

Full list of supported hints:
[https://pg-hint-plan.readthedocs.io/en/latest/hint_list.html](https://pg-hint-plan.readthedocs.io/en/latest/hint_list.html)

---

### Linux / WSL

```bash
sudo apt install postgresql-18-pg-hint-plan
```

### macOS

```bash
brew install pg_hint_plan
```

---

### Enable pg\_hint\_plan

#### Step 1: Edit PostgreSQL Configuration

```bash
sudo nano /etc/postgresql/18/main/postgresql.conf
```

Find:

```
#shared_preload_libraries = ''
```

Change to:

```
shared_preload_libraries = 'pg_hint_plan'
```

Save and exit.

---

#### Step 2: Restart PostgreSQL

```bash
sudo systemctl restart postgresql
```

---

#### Step 3: Enable Extension in Database

Open PostgreSQL:

```bash
sudo -u postgres psql
```

Connect to your database:

```sql
\c tpch_db
```

Enable extension:

```sql
CREATE EXTENSION pg_hint_plan;
```

---

#### Step 4: Verify Installation

```sql
SHOW shared_preload_libraries;
```

Expected output:

```
pg_hint_plan
```

Extension check:

```sql
\dx
```

You should see `pg_hint_plan` listed.

---

## Part 2: How to Use pg\_hint\_plan

Hints are written as special SQL comments:

```sql
/*+ hint */
SELECT ...
```

Hints must:

* Start with `/*+`
* Be placed before the query
* Use table aliases if defined

---

### Table Scan Hints

Assume table: `lineitem`

#### Sequential Scan

```sql
EXPLAIN ANALYZE
/*+ SeqScan(lineitem) */
SELECT *
FROM lineitem
WHERE l_quantity < 5;
```

#### Index Scan

```sql
EXPLAIN ANALYZE
/*+ IndexScan(lineitem lineitem_quantity_idx) */
SELECT *
FROM lineitem
WHERE l_quantity < 5;
```

#### Index Only Scan

```sql
EXPLAIN ANALYZE
/*+ IndexOnlyScan(lineitem lineitem_quantity_idx) */
SELECT l_quantity
FROM lineitem
WHERE l_quantity < 5;
```

#### Bitmap Scan

```sql
EXPLAIN ANALYZE
/*+ BitmapScan(lineitem) */
SELECT *
FROM lineitem
WHERE l_quantity < 5;
```

---

### Join Hints

Assume:

```sql
SELECT *
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey;
```

#### Nested Loop Join

```sql
EXPLAIN ANALYZE
/*+ NestLoop(o c) */
SELECT *
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey;
```

#### Hash Join

```sql
EXPLAIN ANALYZE
/*+ HashJoin(o c) */
SELECT *
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey;
```

#### Merge Join

```sql
EXPLAIN ANALYZE
/*+ MergeJoin(o c) */
SELECT *
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey;
```

---

### Join Order Hint

Controls which table is joined first:

```sql
EXPLAIN ANALYZE
/*+ Leading(o c) */
SELECT *
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey;
```

---

### Parallel Execution Hint

Force parallel scan:

```sql
EXPLAIN ANALYZE
/*+ Parallel(lineitem 4) */
SELECT *
FROM lineitem;
```

This uses 4 parallel workers.

---

### Combining Multiple Hints

```sql
EXPLAIN ANALYZE
/*+
  IndexScan(o orders_pkey)
  HashJoin(o c)
  Leading(o c)
*/
SELECT *
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey;
```

---

### Important Rules

If table has alias:

```sql
FROM orders o
```

Use alias in hint:

```sql
IndexScan(o orders_pkey)
```

Not:

```sql
IndexScan(orders orders_pkey)
```

---

### Key Notes

pg\_hint\_plan **can** control:

* Scan strategy
* Join method
* Join order
* Parallel workers

pg\_hint\_plan **cannot** control:

* Query result correctness
* Data distribution
* Cost estimation values

---

## Part 3: Obtaining Query Execution Plans

PostgreSQL provides the `EXPLAIN` command to inspect query execution plans.

---

### Compile-Time Execution Plan

This gives the execution plan with **estimated cost and cardinality values**, without actually running the query:

```sql
EXPLAIN (FORMAT JSON) <your_query>;
```

---

### Run-Time Execution Plan

This **actually executes the query** and provides the plan with real execution times, actual row counts, and other runtime statistics:

```sql
EXPLAIN ANALYZE (FORMAT JSON) <your_query>;
```

---