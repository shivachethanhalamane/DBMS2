import psycopg2
from datetime import datetime, timedelta

DB_CONFIG = {
    "dbname": "tpch_db",
    "user": "postgres",
    "password": "shiva",
    "host": "localhost",
    "port": "5432"
}

# Global maximum iterations to prevent excessively long runs
MAX_BINARY_SEARCH_ITERATIONS = 20


def get_exec_time(conn, query, date_val, hint=""):
    """Runs EXPLAIN ANALYZE twice to avoid cache bias and returns the second execution time."""
    date_str = date_val.strftime('%Y-%m-%d')
    actual_query = query.replace("[DATE]", f"'{date_str}'")
    
    if hint:
        actual_query = f"{hint}\n{actual_query}"
        
    cur = conn.cursor()
    
    # Run 1: Warm the cache
    cur.execute(f"EXPLAIN (ANALYZE, FORMAT JSON) {actual_query}")
    
    # Run 2: Get the actual correct time
    cur.execute(f"EXPLAIN (ANALYZE, FORMAT JSON) {actual_query}")
    result = cur.fetchone()[0]
    cur.close()
    
    if isinstance(result, list):
        result = result[0]
        
    return result.get("Execution Time", 0.0)


def find_optimal_switch(conn, query, start_date, end_date, hint_Pi, hint_Pj, switch_type):
    """
    Binary search to find the optimal plan switch date.
    
    Delayed Switch:
    Plan Pi was already slower than Pj before the switch happened.
    So the optimizer switched too late.
    We search in an earlier range to find the correct point where the switch should have happened.

    Early Switch:
    Plan Pi was still faster than Pj when the switch happened.
    So the optimizer switched too early.
    We search in a later range to find the correct point where the switch should actually occur.
    
    In both cases we binary search for the crossover point where 
    RT(Pi, date) transitions from being <= RT(Pj, date) to being > RT(Pj, date).
    
    Returns (qi_prime, qj_prime) — the optimal switch boundary dates.
    """
    low = start_date
    high = end_date
    iterations = 0
    
    while (high - low).days > 1 and iterations < MAX_BINARY_SEARCH_ITERATIONS:
        iterations+=1
        mid=low+timedelta(days=(high - low).days // 2)
        
        rt_pi=get_exec_time(conn, query, mid, hint_Pi)
        rt_pj=get_exec_time(conn, query, mid, hint_Pj)
        
        if rt_pi<=rt_pj:
            low = mid
        else:
            high=mid
    
    if iterations >= MAX_BINARY_SEARCH_ITERATIONS:
        print(f"  [WARNING] Binary search hit max iteration limit ({MAX_BINARY_SEARCH_ITERATIONS})")
            
    # low = last date where Pi was optimal, high = first date where Pj is optimal
    return low, high


def process_switch(conn, name, query, search_start_str, search_end_str,
                   hint_Pi, hint_Pj, orig_qi_str, orig_qj_str, switch_type):

    search_start = datetime.strptime(search_start_str, '%Y-%m-%d').date()
    search_end = datetime.strptime(search_end_str, '%Y-%m-%d').date()
    
    print(f"\n{'='*60}")
    print(f"  {name}")
    print(f"  Original switch: {orig_qi_str} -> {orig_qj_str} (classified: {switch_type})")
    print(f"  Search window: {search_start_str} to {search_end_str}")
    print(f"{'='*60}")
    
    # Binary search 
    qi_prime, qj_prime = find_optimal_switch(
        conn, query, search_start, search_end, hint_Pi, hint_Pj, switch_type
    )
    print(f"  >> Optimal Switch Found: qi' = {qi_prime}, qj' = {qj_prime}")
    
    print("  Validating optimal switch times")
    rt_pi_qi = get_exec_time(conn, query, qi_prime, hint_Pi)
    rt_pj_qj = get_exec_time(conn, query, qj_prime, hint_Pj)
    rt_pi_qj = get_exec_time(conn, query, qj_prime, hint_Pi)
    rt_pj_qi = get_exec_time(conn, query, qi_prime, hint_Pj)
    
    print(f"  RT(Pi', qi'): {rt_pi_qi:.3f} ms")
    print(f"  RT(Pj', qj'): {rt_pj_qj:.3f} ms")
    print(f"  RT(Pi', qj'): {rt_pi_qj:.3f} ms")
    print(f"  RT(Pj', qi'): {rt_pj_qi:.3f} ms")
    
    if rt_pj_qi < rt_pi_qi:
        classification = "DELAYED"
    elif rt_pi_qj < rt_pj_qj:
        classification = "EARLY"
    else:
        classification = "CORRECT"
    print(f"  >> Optimal switch classification: {classification}")
    print()


def main():

    q1_template = (
        "EXPLAIN (ANALYZE, FORMAT JSON) SELECT SUM(l_quantity), SUM(l_extendedprice), "
        "SUM(l_extendedprice * (1 - l_discount)), "
        "SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)), "
        "AVG(l_quantity), AVG(l_extendedprice), AVG(l_discount), COUNT(*) "
        "FROM lineitem WHERE l_shipdate <= [DATE];"
    )

    q2_template = (
        "EXPLAIN (ANALYZE, FORMAT JSON) SELECT o_orderpriority, count(*) AS order_count "
        "FROM orders "
        "WHERE o_orderdate >= DATE '1992-01-01' "
        "AND o_orderdate < DATE [DATE] "
        "AND EXISTS ("
        "  SELECT 1 FROM lineitem "
        "  WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate"
        ") "
        "GROUP BY o_orderpriority;"
    )

    q3_template = (
        "EXPLAIN (ANALYZE, FORMAT JSON) SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, "
        "o.o_orderdate, o.o_shippriority "
        "FROM customer c "
        "JOIN orders o ON c.c_custkey = o.o_custkey "
        "JOIN lineitem l ON l.l_orderkey = o.o_orderkey "
        "WHERE c.c_mktsegment = 'BUILDING' "
        "AND o.o_orderdate < DATE [DATE] "
        "AND l.l_shipdate > DATE [DATE];"
    )

   

    # Query 1 Switch 1: CORRECT — skip
    # Query 1 Switch 2: DELAYED — optimizer switched too late from BitmapScan to SeqScan
    #   Original switch: 1992-08-21 -> 1992-08-22
    #   Search earlier: from previous switch (1992-01-11) up to 1992-08-21
    switches_to_test = [
        (
            "Query 1 Switch 2 (DELAYED)",
            q1_template,
            "1992-01-12", "1992-08-21",    # search window (before original switch)
            "/*+ BitmapScan(lineitem) */",  # hint_Pi (plan before switch)
            "/*+ SeqScan(lineitem) */",     # hint_Pj (plan after switch)
            "1992-08-21", "1992-08-22",     # original switch dates
            "DELAYED"
        ),

        # Query 2 Switch 1: DELAYED — BitmapScan(orders) -> SeqScan(orders)
        #   Original switch: 1993-03-11 -> 1993-03-12
        #   Search earlier: from start of Q2 range (1992-01-01) to 1993-03-11
        (
            "Query 2 Switch 1 (DELAYED)",
            q2_template,
            "1992-01-02", "1993-03-11",
            "/*+ BitmapScan(orders) */",
            "/*+ SeqScan(orders) */",
            "1993-03-11", "1993-03-12",
            "DELAYED"
        ),

        # Query 2 Switch 2: DELAYED — GroupAgg (hashagg off) -> HashAgg (sort off)
        #   Original switch: 1993-04-28 -> 1993-04-29
        #   Search earlier: from Q2 Switch 1 boundary (1993-03-12) to 1993-04-28
        (
            "Query 2 Switch 2 (DELAYED)",
            q2_template,
            "1993-03-13", "1993-04-28",
            "/*+ Set(enable_hashagg off) */",
            "/*+ Set(enable_sort off) */",
            "1993-04-28", "1993-04-29",
            "DELAYED"
        ),

        # Query 2 Switch 3: DELAYED — NestLoop -> HashJoin
        #   Original switch: 1996-11-22 -> 1996-11-23
        #   Search earlier: from Q2 Switch 2 boundary (1993-04-29) to 1996-11-22
        (
            "Query 2 Switch 3 (DELAYED)",
            q2_template,
            "1993-04-30", "1996-11-22",
            "/*+ NestLoop(orders lineitem) */",
            "/*+ HashJoin(orders lineitem) */",
            "1996-11-22", "1996-11-23",
            "DELAYED"
        ),

        # Query 3 Switch 1: DELAYED — NestLoop(o c) -> HashJoin(o c)
        #   Original switch: 1992-02-28 -> 1992-02-29
        #   Search earlier: from start of Q3 range (1992-01-02) to 1992-02-28
        (
            "Query 3 Switch 1 (DELAYED)",
            q3_template,
            "1992-01-02", "1992-02-28",
            "/*+ NestLoop(o c) */",
            "/*+ HashJoin(o c) */",
            "1992-02-28", "1992-02-29",
            "DELAYED"
        ),

        # Query 3 Switch 2: DELAYED — BitmapScan(o) -> SeqScan(o)
        #   Original switch: 1993-04-06 -> 1993-04-07
        #   Search earlier: from Q3 Switch 1 boundary (1992-02-29) to 1993-04-06
        (
            "Query 3 Switch 2 (DELAYED)",
            q3_template,
            "1992-03-01", "1993-04-06",
            "/*+ BitmapScan(o) */",
            "/*+ SeqScan(o) */",
            "1993-04-06", "1993-04-07",
            "DELAYED"
        ),

        # Query 3 Switch 3: DELAYED — Leading((o c) l) -> Leading((l o) c)
        #   Original switch: 1998-08-28 -> 1998-08-29
        #   Search earlier: from Q3 Switch 2 boundary (1993-04-07) to 1998-08-28
        (
            "Query 3 Switch 3 (DELAYED)",
            q3_template,
            "1993-04-08", "1998-08-28",
            "/*+ Leading(o c l) SeqScan(o) SeqScan(c) IndexScan(l) HashJoin(o c) NestLoop(o c l) */",
            "/*+ Leading(l o c) BitmapScan(l) IndexScan(o) SeqScan(c) NestLoop(l o) HashJoin(l o c) */",
            "1998-08-28", "1998-08-29",
            "DELAYED"
        ),

        # Query 3 Switch 4: DELAYED — HashJoin(c o) HashJoin(c l) -> NestLoop(c o) NestLoop(c l)
        #   Original switch: 1998-09-19 -> 1998-09-20
        #   Search earlier: from Q3 Switch 3 boundary (1998-08-29) to 1998-09-19
        (
            "Query 3 Switch 4 (DELAYED)",
            q3_template,
            "1998-08-30", "1998-09-19",
            "/*+ Leading(l o c) BitmapScan(l) IndexScan(o) SeqScan(c) NestLoop(l o) HashJoin(l o c) */",
            "/*+ Leading(l o c) BitmapScan(l) IndexScan(o) IndexScan(c) NestLoop(l o) NestLoop(l o c) */",
            "1998-09-19", "1998-09-20",
            "DELAYED"
        ),

        # Query 3 Switch 5: DELAYED — BitmapScan(l) -> IndexScan(l)
        #   Original switch: 1998-11-30 -> 1998-12-01
        #   Search earlier: from Q3 Switch 4 boundary (1998-09-20) to 1998-11-30
        (
            "Query 3 Switch 5 (DELAYED)",
            q3_template,
            "1998-09-21", "1998-11-30",
            "/*+ Leading(l o c) BitmapScan(l) IndexScan(o) IndexScan(c) NestLoop(l o) NestLoop(l o c) */",
            "/*+ Leading(l o c) IndexScan(l) IndexScan(o) IndexScan(c) NestLoop(l o) NestLoop(l o c) */",
            "1998-11-30", "1998-12-01",
            "DELAYED"
        ),
    ]

    try:
        conn = psycopg2.connect(**DB_CONFIG)
        print("=" * 60)
        print("  Task 4: Plan Switch Correction")
        print(f"  Max binary search iterations: {MAX_BINARY_SEARCH_ITERATIONS}")
        print("=" * 60)
        
        for task in switches_to_test:
            process_switch(conn, *task)
            
        conn.close()
        print("\nAll tasks completed successfully!")
        
    except Exception as e:
        print(f"Database error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()