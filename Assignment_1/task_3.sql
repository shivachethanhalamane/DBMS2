-- DROP INDEX IF EXISTS idx_shipdate;
-- DROP INDEX IF EXISTS idx_discount;
-- DROP INDEX IF EXISTS idx_quantity;
-- DROP INDEX IF EXISTS idx_q6;
-- DROP INDEX IF EXISTS idx_q6_cover;

-- ANALYZE lineitem;

-- \o /home/asit/SEM-4/DBMS/Assignment_1/without_indexes.json
-- EXPLAIN (ANALYZE, FORMAT JSON)
-- SELECT
--     SUM(l_extendedprice * l_discount) AS revenue
-- FROM lineitem
-- WHERE
--     l_shipdate >= DATE '1994-01-01'
--     AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
--     AND l_discount BETWEEN 0.05 AND 0.07
--     AND l_quantity < 24;
-- \o


-- DROP INDEX IF EXISTS idx_shipdate;

-- CREATE INDEX idx_shipdate ON lineitem(l_shipdate);
-- ANALYZE lineitem;

-- \o /home/asit/SEM-4/DBMS/Assignment_1/with_index_shipdate.json
-- EXPLAIN (ANALYZE, FORMAT JSON)
-- SELECT
--     SUM(l_extendedprice * l_discount) AS revenue
-- FROM lineitem
-- WHERE
--     l_shipdate >= DATE '1994-01-01'
--     AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
--     AND l_discount BETWEEN 0.05 AND 0.07
--     AND l_quantity < 24;
-- \o

-- DROP INDEX idx_shipdate;


-- DROP INDEX IF EXISTS idx_discount;

-- CREATE INDEX idx_discount ON lineitem(l_discount);
-- ANALYZE lineitem;

-- \o /home/asit/SEM-4/DBMS/Assignment_1/with_index_discount.json
-- EXPLAIN (ANALYZE, FORMAT JSON)
-- SELECT
--     SUM(l_extendedprice * l_discount) AS revenue
-- FROM lineitem
-- WHERE
--     l_shipdate >= DATE '1994-01-01'
--     AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
--     AND l_discount BETWEEN 0.05 AND 0.07
--     AND l_quantity < 24;
-- \o

-- DROP INDEX idx_discount;


-- DROP INDEX IF EXISTS idx_quantity;

-- CREATE INDEX idx_quantity ON lineitem(l_quantity);
-- ANALYZE lineitem;

-- \o /home/asit/SEM-4/DBMS/Assignment_1/with_index_quantity.json
-- EXPLAIN (ANALYZE, FORMAT JSON)
-- SELECT
--     SUM(l_extendedprice * l_discount) AS revenue
-- FROM lineitem
-- WHERE
--     l_shipdate >= DATE '1994-01-01'
--     AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
--     AND l_discount BETWEEN 0.05 AND 0.07
--     AND l_quantity < 24;
-- \o

-- DROP INDEX idx_quantity;


-- DROP INDEX IF EXISTS idx_shipdate;
-- DROP INDEX IF EXISTS idx_discount;
-- DROP INDEX IF EXISTS idx_quantity;

-- CREATE INDEX idx_shipdate ON lineitem(l_shipdate);
-- CREATE INDEX idx_discount ON lineitem(l_discount);
-- CREATE INDEX idx_quantity ON lineitem(l_quantity);
-- ANALYZE lineitem;

-- \o /home/asit/SEM-4/DBMS/Assignment_1/with_multiple_single_indexes.json
-- EXPLAIN (ANALYZE, FORMAT JSON)
-- SELECT
--     SUM(l_extendedprice * l_discount) AS revenue
-- FROM lineitem
-- WHERE
--     l_shipdate >= DATE '1994-01-01'
--     AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
--     AND l_discount BETWEEN 0.05 AND 0.07
--     AND l_quantity < 24;
-- \o

-- DROP INDEX idx_shipdate;
-- DROP INDEX idx_discount;
-- DROP INDEX idx_quantity;


-- DROP INDEX IF EXISTS idx_q6;

-- CREATE INDEX idx_q6
-- ON lineitem(l_shipdate, l_discount, l_quantity);
-- ANALYZE lineitem;

-- \o /home/asit/SEM-4/DBMS/Assignment_1/with_composite_index.json
-- EXPLAIN (ANALYZE, FORMAT JSON)
-- SELECT
--     SUM(l_extendedprice * l_discount) AS revenue
-- FROM lineitem
-- WHERE
--     l_shipdate >= DATE '1994-01-01'
--     AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
--     AND l_discount BETWEEN 0.05 AND 0.07
--     AND l_quantity < 24;
-- \o

-- DROP INDEX idx_q6;


-- DROP INDEX IF EXISTS idx_q6_cover;

-- CREATE INDEX idx_q6_cover
-- ON lineitem(l_shipdate, l_discount, l_quantity)
-- INCLUDE (l_extendedprice);
-- ANALYZE lineitem;

-- \o /home/asit/SEM-4/DBMS/Assignment_1/with_covering_index.json
-- EXPLAIN (ANALYZE, FORMAT JSON)
-- SELECT
--     SUM(l_extendedprice * l_discount) AS revenue
-- FROM lineitem
-- WHERE
--     l_shipdate >= DATE '1994-01-01'
--     AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
--     AND l_discount BETWEEN 0.05 AND 0.07
--     AND l_quantity < 24;
-- \o


-- CLUSTER lineitem USING idx_q6_cover;
-- ANALYZE lineitem;

-- \o /home/asit/SEM-4/DBMS/Assignment_1/with_clustered_index.json
-- EXPLAIN (ANALYZE, FORMAT JSON)
-- SELECT
--     SUM(l_extendedprice * l_discount) AS revenue
-- FROM lineitem
-- WHERE
--     l_shipdate >= DATE '1994-01-01'
--     AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
--     AND l_discount BETWEEN 0.05 AND 0.07
--     AND l_quantity < 24;
-- \o


-- ==================================================================
-- Task 3: Index Selection & Performance Analysis (SAFE MODE)
-- Total Scenarios: 9
-- DATA SAFETY: Using a TEMP COPY to protect original data.
-- ==================================================================

-- ------------------------------------------------------------------
-- SETUP: Create a temporary copy of the data
-- ------------------------------------------------------------------
-- Drop it just in case a previous run in this session left it hanging
DROP TABLE IF EXISTS lineitem_copy;

-- Create a fresh temporary table with all data from the original
CREATE TEMP TABLE lineitem_copy AS 
SELECT * FROM lineitem;

-- Crucial: Analyze the new table so the query planner knows row counts/stats
ANALYZE lineitem_copy;

-- ------------------------------------------------------------------
-- CLEANUP: Ensure no stale indexes exist on the copy
-- ------------------------------------------------------------------
DROP INDEX IF EXISTS idx_shipdate;
DROP INDEX IF EXISTS idx_discount;
DROP INDEX IF EXISTS idx_quantity;
DROP INDEX IF EXISTS idx_pair_1;
DROP INDEX IF EXISTS idx_pair_2;
DROP INDEX IF EXISTS idx_pair_3;
DROP INDEX IF EXISTS idx_triple;
DROP INDEX IF EXISTS idx_cover;

-- ==================================================================
-- SCENARIO 1: No Indexing (Baseline)
-- ==================================================================
\o /home/asit/SEM-4/DBMS/Assignment_1/without_indexes.json
EXPLAIN (ANALYZE, FORMAT JSON)
SELECT
    SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem_copy
WHERE
    l_shipdate >= DATE '1994-01-01'
    AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
    AND l_discount BETWEEN 0.05 AND 0.07
    AND l_quantity < 24;
\o

-- ==================================================================
-- SCENARIO 2: Single Index on l_shipdate
-- ==================================================================
CREATE INDEX idx_shipdate ON lineitem_copy(l_shipdate);
ANALYZE lineitem_copy;

\o /home/asit/SEM-4/DBMS/Assignment_1/with_index_shipdate.json
EXPLAIN (ANALYZE, FORMAT JSON)
SELECT
    SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem_copy
WHERE
    l_shipdate >= DATE '1994-01-01'
    AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
    AND l_discount BETWEEN 0.05 AND 0.07
    AND l_quantity < 24;
\o

DROP INDEX idx_shipdate;

-- ==================================================================
-- SCENARIO 3: Single Index on l_discount
-- ==================================================================
CREATE INDEX idx_discount ON lineitem_copy(l_discount);
ANALYZE lineitem_copy;

\o /home/asit/SEM-4/DBMS/Assignment_1/with_index_discount.json
EXPLAIN (ANALYZE, FORMAT JSON)
SELECT
    SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem_copy
WHERE
    l_shipdate >= DATE '1994-01-01'
    AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
    AND l_discount BETWEEN 0.05 AND 0.07
    AND l_quantity < 24;
\o

DROP INDEX idx_discount;

-- ==================================================================
-- SCENARIO 4: Single Index on l_quantity
-- ==================================================================
CREATE INDEX idx_quantity ON lineitem_copy(l_quantity);
ANALYZE lineitem_copy;

\o /home/asit/SEM-4/DBMS/Assignment_1/with_index_quantity.json
EXPLAIN (ANALYZE, FORMAT JSON)
SELECT
    SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem_copy
WHERE
    l_shipdate >= DATE '1994-01-01'
    AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
    AND l_discount BETWEEN 0.05 AND 0.07
    AND l_quantity < 24;
\o

DROP INDEX idx_quantity;

-- ==================================================================
-- LEAKY INDEXING DEMONSTRATION (Composite Pairs)
-- ==================================================================

-- ==================================================================
-- SCENARIO 5: Pair Order (l_discount, l_shipdate)
-- Rationale: l_discount has a narrow range (0.05-0.07). 
-- This tests if the planner can effectively use the second column 
-- when the first column is a range predicate.
-- ==================================================================
CREATE INDEX idx_pair_1 ON lineitem_copy(l_discount, l_shipdate);
ANALYZE lineitem_copy;

\o /home/asit/SEM-4/DBMS/Assignment_1/with_pair_discount_shipdate.json
EXPLAIN (ANALYZE, FORMAT JSON)
SELECT
    SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem_copy
WHERE
    l_shipdate >= DATE '1994-01-01'
    AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
    AND l_discount BETWEEN 0.05 AND 0.07
    AND l_quantity < 24;
\o

DROP INDEX idx_pair_1;

-- ==================================================================
-- SCENARIO 6: Pair Order (l_shipdate, l_discount)
-- Rationale: Swapping the order. l_shipdate (1 year range) is usually
-- more selective than the discount range.
-- ==================================================================
CREATE INDEX idx_pair_2 ON lineitem_copy(l_shipdate, l_discount);
ANALYZE lineitem_copy;

\o /home/asit/SEM-4/DBMS/Assignment_1/with_pair_shipdate_discount.json
EXPLAIN (ANALYZE, FORMAT JSON)
SELECT
    SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem_copy
WHERE
    l_shipdate >= DATE '1994-01-01'
    AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
    AND l_discount BETWEEN 0.05 AND 0.07
    AND l_quantity < 24;
\o

DROP INDEX idx_pair_2;

-- ==================================================================
-- SCENARIO 7: Pair Order (l_quantity, l_shipdate)
-- Rationale: l_quantity < 24 is an inequality.
-- B-Trees generally stop being efficient for secondary columns 
-- once an inequality is encountered in the column list.
-- ==================================================================
CREATE INDEX idx_pair_3 ON lineitem_copy(l_quantity, l_shipdate);
ANALYZE lineitem_copy;

\o /home/asit/SEM-4/DBMS/Assignment_1/with_pair_quantity_shipdate.json
EXPLAIN (ANALYZE, FORMAT JSON)
SELECT
    SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem_copy
WHERE
    l_shipdate >= DATE '1994-01-01'
    AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
    AND l_discount BETWEEN 0.05 AND 0.07
    AND l_quantity < 24;
\o

DROP INDEX idx_pair_3;

-- ==================================================================
-- SCENARIO 8: All Three Columns (Best Sequence)
-- Rationale: Ordered by selectivity of the range predicates.
-- ==================================================================
CREATE INDEX idx_triple ON lineitem_copy(l_shipdate, l_discount, l_quantity);
ANALYZE lineitem_copy;

\o /home/asit/SEM-4/DBMS/Assignment_1/with_composite_all_columns.json
EXPLAIN (ANALYZE, FORMAT JSON)
SELECT
    SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem_copy
WHERE
    l_shipdate >= DATE '1994-01-01'
    AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
    AND l_discount BETWEEN 0.05 AND 0.07
    AND l_quantity < 24;
\o

DROP INDEX idx_triple;

-- ==================================================================
-- SCENARIO 9: Covering Index (The Optimal Solution)
-- Rationale: INCLUDES l_extendedprice to allow Index Only Scan.
-- ==================================================================
CREATE INDEX idx_cover ON lineitem_copy(l_shipdate, l_discount, l_quantity) 
INCLUDE (l_extendedprice);
ANALYZE lineitem_copy;

\o /home/asit/SEM-4/DBMS/Assignment_1/with_covering_index.json
EXPLAIN (ANALYZE, FORMAT JSON)
SELECT
    SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem_copy
WHERE
    l_shipdate >= DATE '1994-01-01'
    AND l_shipdate < DATE '1994-01-01' + INTERVAL '1 year'
    AND l_discount BETWEEN 0.05 AND 0.07
    AND l_quantity < 24;
\o

DROP INDEX idx_cover;

-- ==================================================================
-- OPTIONAL: Clean up the temp table explicitly (good habit)
-- ==================================================================
DROP TABLE IF EXISTS lineitem_copy;