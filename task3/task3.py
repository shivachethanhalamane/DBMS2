import psycopg2
import json

# Config 
DB_CONFIG = {
    "dbname": "tpch_db",
    "user": "asit",
    "password": "asit",
    "host": "localhost",
    "port": "5432"
}

def extract_physical_operator_tree(plan):
    """Extracts the simplified structure to verify hints worked."""
    if isinstance(plan, list): plan = plan[0]
    if "Plan" in plan: plan = plan["Plan"]

    tree = {"Node Type": plan.get("Node Type")}
    
    if "Join Type" in plan: tree["Join Type"] = plan["Join Type"]
    if "Relation Name" in plan: tree["Relation Name"] = plan["Relation Name"]

    if "Plans" in plan:
        tree["Plans"] = [extract_physical_operator_tree(child) for child in plan["Plans"]]

    return tree

def get_exec_time_and_plan(conn, query, date_val, hint=""):
    
    actual_query = query.replace("[DATE]", f"'{date_val}'")
    
    if hint:
        actual_query = f"{hint}\n{actual_query}"
        
    cur = conn.cursor()
    
    # Warming the cache
    cur.execute(f"EXPLAIN (ANALYZE, FORMAT JSON) {actual_query}")
    
    # Recording the actual execution result
    cur.execute(f"EXPLAIN (ANALYZE, FORMAT JSON) {actual_query}")
    result = cur.fetchone()[0]
    cur.close()
    
    if isinstance(result, list):
        result = result[0]
        
    exec_time = result.get("Execution Time", 0.0)
    plan_tree = extract_physical_operator_tree(result)
    
    return exec_time, plan_tree, result

def main():
    query_template = """
        SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, 
                o.o_orderdate, o.o_shippriority 
        FROM customer c 
        JOIN orders o ON c.c_custkey = o.o_custkey 
        JOIN lineitem l ON l.l_orderkey = o.o_orderkey 
        WHERE c.c_mktsegment = 'BUILDING' 
        AND o.o_orderdate < DATE [DATE] 
        AND l.l_shipdate > DATE [DATE];
    """

    date_i = "1998-11-30"
    date_j = "1998-12-01"
    # Identical to Pj from Switch 4
    hint_Pi = "/*+ Leading(l o c) BitmapScan(l) IndexScan(o) IndexScan(c) NestLoop(l o) NestLoop(l o c) */"
    # Drops BitmapScan for IndexScan on 'l'
    hint_Pj = "/*+ Leading(l o c) IndexScan(l) IndexScan(o) IndexScan(c) NestLoop(l o) NestLoop(l o c) */"

    try:
        conn = psycopg2.connect(**DB_CONFIG)
        print(f"Testing Switch: {date_i} -> {date_j}\n")
        
        # Unpack the time, the tree, and the raw JSON
        rt_pi_qi, tree_pi, raw_pi_qi = get_exec_time_and_plan(conn, query_template, date_i)
        rt_pj_qj, tree_pj, raw_pj_qj = get_exec_time_and_plan(conn, query_template, date_j)
        
        rt_pi_qj, tree_forced_pi, raw_pi_qj = get_exec_time_and_plan(conn, query_template, date_j, hint_Pi)
        rt_pj_qi, tree_forced_pj, raw_pj_qi = get_exec_time_and_plan(conn, query_template, date_i, hint_Pj)
        
        print("--- Plan Verification ---")
        if tree_forced_pi == tree_pi:
            print("hint_Pi successfully forced Plan Pi!")
        else:
            print("hint_Pi failed. The database ignored it.")
            
        if tree_forced_pj == tree_pj:
            print("hint_Pj successfully forced Plan Pj!")
        else:
            print("hint_Pj failed. The database ignored it.")
        
        print("\n--- Execution Times ---")
        print(f"RT(Pi, qi): {rt_pi_qi:.3f} ms")
        print(f"RT(Pj, qj): {rt_pj_qj:.3f} ms")
        print(f"RT(Pi, qj): {rt_pi_qj:.3f} ms  <-- (Forced Pi on qj)")
        print(f"RT(Pj, qi): {rt_pj_qi:.3f} ms  <-- (Forced Pj on qi)\n")
        
        print("--- Classification ---")
        if rt_pj_qi < rt_pi_qi:
            print("Result: DELAYED")
        elif rt_pi_qj < rt_pj_qj:
            print("Result: EARLY")
        else:
            print("Result: CORRECT")
            
        # Saving json data
        output_filename = f"forced_plans_{date_i}_to_{date_j}.json"
        
        output_data = {
            "Switch Info": f"Testing switch from {date_i} to {date_j}",
            "RT(Pi, qi)": raw_pi_qi,
            "RT(Pj, qj)": raw_pj_qj,
            "RT(Pi, qj)_forced": raw_pi_qj,
            "RT(Pj, qi)_forced": raw_pj_qi
        }
        
        with open(output_filename, "w") as f:
            json.dump(output_data, f, indent=4)
            
        print(f"\nAll 4 raw execution plans have been saved to '{output_filename}'")
        
        conn.close()
        
    except Exception as e:
        print(f"Database error: {e}")

if __name__ == "__main__":
    main()