LOAD 'pg_hint_plan';
-- ==========================================
-- QUERY 1
-- ==========================================

-- Query 1, Switch 1
-- RT(Pi, qi): 1992-01-10, Parallel 0
EXPLAIN ANALYZE /*+ Parallel(lineitem 0) */
SELECT SUM(l_quantity), SUM(l_extendedprice), SUM(l_extendedprice * (1 - l_discount)), SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)), AVG(l_quantity), AVG(l_extendedprice), AVG(l_discount), COUNT(*)
FROM lineitem WHERE l_shipdate <= DATE '1992-01-10';

-- RT(Pj, qj): 1992-01-11, Parallel 4
EXPLAIN ANALYZE /*+ Parallel(lineitem 4) */
SELECT SUM(l_quantity), SUM(l_extendedprice), SUM(l_extendedprice * (1 - l_discount)), SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)), AVG(l_quantity), AVG(l_extendedprice), AVG(l_discount), COUNT(*)
FROM lineitem WHERE l_shipdate <= DATE '1992-01-11';

-- RT(Pi, qj): 1992-01-11, Parallel 0
EXPLAIN ANALYZE /*+ Parallel(lineitem 0) */
SELECT SUM(l_quantity), SUM(l_extendedprice), SUM(l_extendedprice * (1 - l_discount)), SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)), AVG(l_quantity), AVG(l_extendedprice), AVG(l_discount), COUNT(*)
FROM lineitem WHERE l_shipdate <= DATE '1992-01-11';

-- RT(Pj, qi): 1992-01-10, Parallel 4
EXPLAIN ANALYZE /*+ Parallel(lineitem 4) */
SELECT SUM(l_quantity), SUM(l_extendedprice), SUM(l_extendedprice * (1 - l_discount)), SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)), AVG(l_quantity), AVG(l_extendedprice), AVG(l_discount), COUNT(*)
FROM lineitem WHERE l_shipdate <= DATE '1992-01-10';


-- Query 1, Switch 2
-- RT(Pi, qi): 1992-08-21, BitmapScan
EXPLAIN ANALYZE /*+ BitmapScan(lineitem) */
SELECT SUM(l_quantity), SUM(l_extendedprice), SUM(l_extendedprice * (1 - l_discount)), SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)), AVG(l_quantity), AVG(l_extendedprice), AVG(l_discount), COUNT(*)
FROM lineitem WHERE l_shipdate <= DATE '1992-08-21';

-- RT(Pj, qj): 1992-08-22, SeqScan
EXPLAIN ANALYZE /*+ SeqScan(lineitem) */
SELECT SUM(l_quantity), SUM(l_extendedprice), SUM(l_extendedprice * (1 - l_discount)), SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)), AVG(l_quantity), AVG(l_extendedprice), AVG(l_discount), COUNT(*)
FROM lineitem WHERE l_shipdate <= DATE '1992-08-22';

-- RT(Pi, qj): 1992-08-22, BitmapScan
EXPLAIN ANALYZE /*+ BitmapScan(lineitem) */
SELECT SUM(l_quantity), SUM(l_extendedprice), SUM(l_extendedprice * (1 - l_discount)), SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)), AVG(l_quantity), AVG(l_extendedprice), AVG(l_discount), COUNT(*)
FROM lineitem WHERE l_shipdate <= DATE '1992-08-22';

-- RT(Pj, qi): 1992-08-21, SeqScan
EXPLAIN ANALYZE /*+ SeqScan(lineitem) */
SELECT SUM(l_quantity), SUM(l_extendedprice), SUM(l_extendedprice * (1 - l_discount)), SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)), AVG(l_quantity), AVG(l_extendedprice), AVG(l_discount), COUNT(*)
FROM lineitem WHERE l_shipdate <= DATE '1992-08-21';


-- ==========================================
-- QUERY 2
-- ==========================================

-- Query 2, Switch 1
-- RT(Pi, qi): 1993-03-11, BitmapScan
EXPLAIN ANALYZE /*+ BitmapScan(orders) */
SELECT o_orderpriority, count(*) AS order_count FROM orders
WHERE o_orderdate >= DATE '1992-01-01' AND o_orderdate < DATE '1993-03-11'
AND EXISTS (SELECT 1 FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate) GROUP BY o_orderpriority;

-- RT(Pj, qj): 1993-03-12, SeqScan
EXPLAIN ANALYZE /*+ SeqScan(orders) */
SELECT o_orderpriority, count(*) AS order_count FROM orders
WHERE o_orderdate >= DATE '1992-01-01' AND o_orderdate < DATE '1993-03-12'
AND EXISTS (SELECT 1 FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate) GROUP BY o_orderpriority;

-- RT(Pi, qj): 1993-03-12, BitmapScan
EXPLAIN ANALYZE /*+ BitmapScan(orders) */
SELECT o_orderpriority, count(*) AS order_count FROM orders
WHERE o_orderdate >= DATE '1992-01-01' AND o_orderdate < DATE '1993-03-12'
AND EXISTS (SELECT 1 FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate) GROUP BY o_orderpriority;

-- RT(Pj, qi): 1993-03-11, SeqScan
EXPLAIN ANALYZE /*+ SeqScan(orders) */
SELECT o_orderpriority, count(*) AS order_count FROM orders
WHERE o_orderdate >= DATE '1992-01-01' AND o_orderdate < DATE '1993-03-11'
AND EXISTS (SELECT 1 FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate) GROUP BY o_orderpriority;


-- Query 2, Switch 2
-- RT(Pi, qi): 1993-04-28, enable_hashagg off
EXPLAIN ANALYZE /*+ Set(enable_hashagg off) */
SELECT o_orderpriority, count(*) AS order_count FROM orders
WHERE o_orderdate >= DATE '1992-01-01' AND o_orderdate < DATE '1993-04-28'
AND EXISTS (SELECT 1 FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate) GROUP BY o_orderpriority;

-- RT(Pj, qj): 1993-04-29, enable_sort off
EXPLAIN ANALYZE /*+ Set(enable_sort off) */
SELECT o_orderpriority, count(*) AS order_count FROM orders
WHERE o_orderdate >= DATE '1992-01-01' AND o_orderdate < DATE '1993-04-29'
AND EXISTS (SELECT 1 FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate) GROUP BY o_orderpriority;

-- RT(Pi, qj): 1993-04-29, enable_hashagg off
EXPLAIN ANALYZE /*+ Set(enable_hashagg off) */
SELECT o_orderpriority, count(*) AS order_count FROM orders
WHERE o_orderdate >= DATE '1992-01-01' AND o_orderdate < DATE '1993-04-29'
AND EXISTS (SELECT 1 FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate) GROUP BY o_orderpriority;

-- RT(Pj, qi): 1993-04-28, enable_sort off
EXPLAIN ANALYZE /*+ Set(enable_sort off) */
SELECT o_orderpriority, count(*) AS order_count FROM orders
WHERE o_orderdate >= DATE '1992-01-01' AND o_orderdate < DATE '1993-04-28'
AND EXISTS (SELECT 1 FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate) GROUP BY o_orderpriority;


-- Query 2, Switch 3
-- RT(Pi, qi): 1996-11-22, NestLoop
EXPLAIN ANALYZE /*+ NestLoop(orders lineitem) */
SELECT o_orderpriority, count(*) AS order_count FROM orders
WHERE o_orderdate >= DATE '1992-01-01' AND o_orderdate < DATE '1996-11-22'
AND EXISTS (SELECT 1 FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate) GROUP BY o_orderpriority;

-- RT(Pj, qj): 1996-11-23, HashJoin
EXPLAIN ANALYZE /*+ HashJoin(orders lineitem) */
SELECT o_orderpriority, count(*) AS order_count FROM orders
WHERE o_orderdate >= DATE '1992-01-01' AND o_orderdate < DATE '1996-11-23'
AND EXISTS (SELECT 1 FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate) GROUP BY o_orderpriority;

-- RT(Pi, qj): 1996-11-23, NestLoop
EXPLAIN ANALYZE /*+ NestLoop(orders lineitem) */
SELECT o_orderpriority, count(*) AS order_count FROM orders
WHERE o_orderdate >= DATE '1992-01-01' AND o_orderdate < DATE '1996-11-23'
AND EXISTS (SELECT 1 FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate) GROUP BY o_orderpriority;

-- RT(Pj, qi): 1996-11-22, HashJoin
EXPLAIN ANALYZE /*+ HashJoin(orders lineitem) */
SELECT o_orderpriority, count(*) AS order_count FROM orders
WHERE o_orderdate >= DATE '1992-01-01' AND o_orderdate < DATE '1996-11-22'
AND EXISTS (SELECT 1 FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate) GROUP BY o_orderpriority;


-- ==========================================
-- QUERY 3
-- ==========================================

-- Query 3, Switch 1
-- RT(Pi, qi): 1992-02-28, NestLoop
EXPLAIN ANALYZE /*+ NestLoop(o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1992-02-28' AND l.l_shipdate > DATE '1992-02-28';

-- RT(Pj, qj): 1992-02-29, HashJoin
EXPLAIN ANALYZE /*+ HashJoin(o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1992-02-29' AND l.l_shipdate > DATE '1992-02-29';

-- RT(Pi, qj): 1992-02-29, NestLoop
EXPLAIN ANALYZE /*+ NestLoop(o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1992-02-29' AND l.l_shipdate > DATE '1992-02-29';

-- RT(Pj, qi): 1992-02-28, HashJoin
EXPLAIN ANALYZE /*+ HashJoin(o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1992-02-28' AND l.l_shipdate > DATE '1992-02-28';


-- Query 3, Switch 2
-- RT(Pi, qi): 1993-04-06, BitmapScan
EXPLAIN ANALYZE /*+ BitmapScan(o) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1993-04-06' AND l.l_shipdate > DATE '1993-04-06';

-- RT(Pj, qj): 1993-04-07, SeqScan
EXPLAIN ANALYZE /*+ SeqScan(o) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1993-04-07' AND l.l_shipdate > DATE '1993-04-07';

-- RT(Pi, qj): 1993-04-07, BitmapScan
EXPLAIN ANALYZE /*+ BitmapScan(o) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1993-04-07' AND l.l_shipdate > DATE '1993-04-07';

-- RT(Pj, qi): 1993-04-06, SeqScan
EXPLAIN ANALYZE /*+ SeqScan(o) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1993-04-06' AND l.l_shipdate > DATE '1993-04-06';


-- Query 3, Switch 3
-- RT(Pi, qi): 1998-08-28, Leading(o c l)
EXPLAIN ANALYZE /*+ Leading(o c l) SeqScan(o) SeqScan(c) IndexScan(l) HashJoin(o c) NestLoop(o c l) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1998-08-28' AND l.l_shipdate > DATE '1998-08-28';

-- RT(Pj, qj): 1998-08-29, Leading(l o c)
EXPLAIN ANALYZE /*+ Leading(l o c) BitmapScan(l) IndexScan(o) SeqScan(c) NestLoop(l o) HashJoin(l o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1998-08-29' AND l.l_shipdate > DATE '1998-08-29';

-- RT(Pi, qj): 1998-08-29, Leading(o c l)
EXPLAIN ANALYZE /*+ Leading(o c l) SeqScan(o) SeqScan(c) IndexScan(l) HashJoin(o c) NestLoop(o c l) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1998-08-29' AND l.l_shipdate > DATE '1998-08-29';

-- RT(Pj, qi): 1998-08-28, Leading(l o c)
EXPLAIN ANALYZE /*+ Leading(l o c) BitmapScan(l) IndexScan(o) SeqScan(c) NestLoop(l o) HashJoin(l o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1998-08-28' AND l.l_shipdate > DATE '1998-08-28';


-- Query 3, Switch 4
-- RT(Pi, qi): 1998-09-19, Leading(l o c) SeqScan(c)
EXPLAIN ANALYZE /*+ Leading(l o c) BitmapScan(l) IndexScan(o) SeqScan(c) NestLoop(l o) HashJoin(l o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1998-09-19' AND l.l_shipdate > DATE '1998-09-19';

-- RT(Pj, qj): 1998-09-20, Leading(l o c) IndexScan(c)
EXPLAIN ANALYZE /*+ Leading(l o c) BitmapScan(l) IndexScan(o) IndexScan(c) NestLoop(l o) NestLoop(l o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1998-09-20' AND l.l_shipdate > DATE '1998-09-20';

-- RT(Pi, qj): 1998-09-20, Leading(l o c) SeqScan(c)
EXPLAIN ANALYZE /*+ Leading(l o c) BitmapScan(l) IndexScan(o) SeqScan(c) NestLoop(l o) HashJoin(l o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1998-09-20' AND l.l_shipdate > DATE '1998-09-20';

-- RT(Pj, qi): 1998-09-19, Leading(l o c) IndexScan(c)
EXPLAIN ANALYZE /*+ Leading(l o c) BitmapScan(l) IndexScan(o) IndexScan(c) NestLoop(l o) NestLoop(l o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1998-09-19' AND l.l_shipdate > DATE '1998-09-19';


-- Query 3, Switch 5
-- RT(Pi, qi): 1998-11-30, Leading(l o c) BitmapScan(l)
EXPLAIN ANALYZE /*+ Leading(l o c) BitmapScan(l) IndexScan(o) IndexScan(c) NestLoop(l o) NestLoop(l o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1998-11-30' AND l.l_shipdate > DATE '1998-11-30';

-- RT(Pj, qj): 1998-12-01, Leading(l o c) IndexScan(l)
EXPLAIN ANALYZE /*+ Leading(l o c) IndexScan(l) IndexScan(o) IndexScan(c) NestLoop(l o) NestLoop(l o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1998-12-01' AND l.l_shipdate > DATE '1998-12-01';

-- RT(Pi, qj): 1998-12-01, Leading(l o c) BitmapScan(l)
EXPLAIN ANALYZE /*+ Leading(l o c) BitmapScan(l) IndexScan(o) IndexScan(c) NestLoop(l o) NestLoop(l o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1998-12-01' AND l.l_shipdate > DATE '1998-12-01';

-- RT(Pj, qi): 1998-11-30, Leading(l o c) IndexScan(l)
EXPLAIN ANALYZE /*+ Leading(l o c) IndexScan(l) IndexScan(o) IndexScan(c) NestLoop(l o) NestLoop(l o c) */
SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, o.o_orderdate, o.o_shippriority
FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate < DATE '1998-11-30' AND l.l_shipdate > DATE '1998-11-30';