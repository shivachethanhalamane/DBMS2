import json
import psycopg2
from datetime import date, timedelta
# from aux import extract_physical_operator_tree

def extract_physical_operator_tree(plan):
    """
    Extract the physical operator tree from a PostgreSQL compile-time query execution plan.

    Args:
        plan: A PostgreSQL compile-time query execution plan

    Returns:
        The physical operator tree structure as JSON
    """
    # Go to core'Plan' dictionary .
    if isinstance(plan,list):
        plan=plan[0]
    if "Plan" in plan:
        plan=plan["Plan"]

    
    tree={
        "Node Type":plan.get("Node Type")   # skeleton structure
    }
    
    # Keep relations and join types to check strict structural comparison
    if "Join Type" in plan:
        tree["Join Type"]=plan["Join Type"]
    if "Relation Name" in plan:
        tree["Relation Name"]=plan["Relation Name"]

    if "Plans" in plan:
        tree["Plans"]=[extract_physical_operator_tree(child) for child in plan["Plans"]]  # For all nodes recursively build the tree
    return tree

# --- Database Connection Config ---
DB_CONFIG = {
    "dbname": "tpch_db",
    "user": "postgres",
    "password": "shiva",
    "host": "localhost",
    "port": "5432"
}

def get_plan_for_date(conn, query_template, target_date):
    """Executes EXPLAIN and returns the structural plan tree AND raw JSON."""
    date_str=target_date.strftime('%Y-%m-%d')
    actual_query=query_template.replace("[DATE]", f"'{date_str}'")
    cur=conn.cursor()
    cur.execute(f"EXPLAIN (FORMAT JSON) {actual_query}")
    plan_json=cur.fetchone()[0]
    cur.close()
    return extract_physical_operator_tree(plan_json), plan_json  # Return both so we can compare the tree, but save the raw JSON for Task 3

def find_plan_switches(conn, query_template, start_date, end_date):
    #Recursively binary search for plan switch dates.
    tree_start, raw_start=get_plan_for_date(conn, query_template, start_date)
    tree_end, raw_end=get_plan_for_date(conn, query_template, end_date)

    if tree_start == tree_end:       # Plans are structurally identical. No switch 
        return []

    no_days=(end_date-start_date).days

    # Plans are different and dates are adjacent. 
    if no_days <= 1:
        # returning the raw plans
        return [(start_date, end_date, raw_start, raw_end)]

    # Split the date range in half (recursion)
    mid_date=start_date+timedelta(days=no_days//2)

    left_switches=find_plan_switches(conn, query_template, start_date, mid_date)
    right_switches=find_plan_switches(conn, query_template, mid_date, end_date)

    # Join from both halves
    return left_switches + right_switches

def main():
    queries = {
        1: """
            SELECT SUM(l_quantity), SUM(l_extendedprice), 
                   SUM(l_extendedprice * (1 - l_discount)), 
                   SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)), 
                   AVG(l_quantity), AVG(l_extendedprice), AVG(l_discount), COUNT(*) 
            FROM lineitem WHERE l_shipdate <= [DATE];
        """,
        2: """
            SELECT o_orderpriority, count(*) AS order_count 
            FROM orders 
            WHERE o_orderdate >= DATE '1992-01-01' AND o_orderdate < DATE [DATE] 
            AND EXISTS (
                SELECT 1 FROM lineitem 
                WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate
            ) 
            GROUP BY o_orderpriority;
        """,
        3: """
            SELECT l.l_orderkey, l.l_extendedprice * (1 - l.l_discount) AS revenue, 
                   o.o_orderdate, o.o_shippriority 
            FROM customer c 
            JOIN orders o ON c.c_custkey = o.o_custkey 
            JOIN lineitem l ON l.l_orderkey = o.o_orderkey 
            WHERE c.c_mktsegment = 'BUILDING' 
            AND o.o_orderdate < DATE [DATE] 
            AND l.l_shipdate > DATE [DATE];
        """
    }

    # Standard TPC-H date range endpoints
    overall_start = date(1992, 1, 2)
    overall_end = date(1998, 12, 1)

    all_switch_data = {}

    try:
        conn = psycopg2.connect(**DB_CONFIG)
        
        with open("output.txt", "w") as out_file:
            for q_num, q_text in queries.items():
                print(f"Analyzing Query {q_num}...")
                
                switches = find_plan_switches(conn, q_text, overall_start, overall_end)
                switch_list_for_json = []
                out_file.write(f"Query {q_num}:\n")
                if not switches:
                    out_file.write("No switches found.\n")
                
                for idx, (d1, d2, p1, p2) in enumerate(switches, 1):
                    # Output.txt formatting
                    out_file.write(f"Plan Switch {idx} : ")
                    out_file.write(f"{d1.strftime('%Y-%m-%d')} ")
                    out_file.write("and ")
                    out_file.write(f"{d2.strftime('%Y-%m-%d')}\n")
                    
                    # JSON formatting
                    switch_list_for_json.append({
                        "switch_num": idx,
                        "date_1": d1.strftime('%Y-%m-%d'),
                        "date_2": d2.strftime('%Y-%m-%d'),
                        "plan_1": p1,
                        "plan_2": p2
                    })
                    
                all_switch_data[f"Query_{q_num}"] = switch_list_for_json
                    
        conn.close()
        with open("switch_plans.json", "w") as jf:
            json.dump(all_switch_data, jf, indent=4)
            
        print("Results saved to output.txt and plans saved to switch_plans.json")

    except Exception as e:
        print(f"Database error: {e}")

if __name__ == "__main__":
    main()