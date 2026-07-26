import json
import psycopg2
import sys
import os # <--- REQUIRED for directory creation

# Importing helper functions
from task2A import get_quantity_for_selectivity, get_total_rows

# Configuration
TABLE_NAME = "lineitem_copy"
COLUMN = "l_quantity"
INDEX_NAME = "idx_l_quantity_copy"
SELECTIVITIES = [i / 50.0 for i in range(51)]

def get_db_connection():
    return psycopg2.connect(
        dbname="tpch_db",
        user="asit",
        password="asit",
        host="localhost",
        port="5432"
    )

def setup_temp_table(cur):
    print(f"--- SETUP: Creating temporary table '{TABLE_NAME}' ---")
    cur.execute(f"DROP TABLE IF EXISTS {TABLE_NAME};")
    cur.execute(f"CREATE TEMP TABLE {TABLE_NAME} AS SELECT * FROM lineitem;")
    cur.execute(f"ANALYZE {TABLE_NAME};")
    print(f"Table '{TABLE_NAME}' created and analyzed.")

def task_2b():
    conn = None
    try:
        conn = get_db_connection()
        conn.autocommit = True
        cur = conn.cursor()
        
        # --- CRITICAL FIX 1: Ensure directory exists ---
        if not os.path.exists("query_plans"):
            os.makedirs("query_plans")

        print("--- Starting Task 2B Performance Analysis ---")
        setup_temp_table(cur)

        # Get total rows and precompute thresholds
        cur.execute(f"SELECT COUNT(*) FROM {TABLE_NAME};")
        total_rows = cur.fetchone()[0]
        
        print("Computing selectivity thresholds...")
        thresholds = []
        for s in SELECTIVITIES:
            x, actual_s, _ = get_quantity_for_selectivity(cur, COLUMN, s, total_rows)
            thresholds.append((actual_s, x))

        # This dictionary is strictly for the PLOTTING SCRIPT
        graph_results = {
            "no_index": [],
            "with_index": [],
            "no_seqscan": [],
            "clustered_index": [],
            "select_column": []
        }

        # Helper to run a scenario
        def run_scenario(scenario_key, json_filename):
            print(f"Running {scenario_key}...")
            
            plans_for_export = [] # List to hold the 51 full JSON plans
            
            for s, x in thresholds:
                # Use query appropriate for the current scenario context
                if scenario_key == "select_column":
                    query = f"EXPLAIN (ANALYZE, FORMAT JSON) SELECT {COLUMN} FROM {TABLE_NAME} WHERE {COLUMN} <= %s;"
                else:
                    query = f"EXPLAIN (ANALYZE, FORMAT JSON) SELECT * FROM {TABLE_NAME} WHERE {COLUMN} <= %s;"
                
                cur.execute(query, (x,))
                
                # --- CRITICAL FIX 2: Capture Full Plan ---
                # fetchone()[0] returns the list [ { "Plan": ..., "Execution Time": ... } ]
                full_plan_data = cur.fetchone()[0]
                
                # 1. Store Timing for Graph
                exec_time = full_plan_data[0]["Execution Time"]
                graph_results[scenario_key].append((s, exec_time))
                
                # 2. Store Full Plan for JSON Submission
                # We wrap it in a structure identifying the selectivity step
                plans_for_export.append({
                    "selectivity": s,
                    "parameter": x,
                    "query_plan": full_plan_data[0] 
                })

            # Save the query plans to the specific file required by assignment
            with open(f"query_plans/{json_filename}", "w") as f:
                json.dump(plans_for_export, f, indent=2)
            print(f"  -> Saved query_plans/{json_filename}")


        # ---------------------------------------------------------
        # CASE (a): NO INDEX
        # ---------------------------------------------------------
        cur.execute(f"DROP INDEX IF EXISTS {INDEX_NAME};")
        run_scenario("no_index", "without_index.json")

        # ---------------------------------------------------------
        # CASE (b): WITH INDEX
        # ---------------------------------------------------------
        print(f"Creating index {INDEX_NAME}...")
        cur.execute(f"CREATE INDEX {INDEX_NAME} ON {TABLE_NAME}({COLUMN});")
        cur.execute(f"ANALYZE {TABLE_NAME};")
        run_scenario("with_index", "with_index.json")

        # ---------------------------------------------------------
        # CASE (c): INDEX + NO SEQSCAN
        # ---------------------------------------------------------
        cur.execute("SET enable_seqscan = OFF;")
        run_scenario("no_seqscan", "no_sequential_scan.json")
        cur.execute("SET enable_seqscan = ON;")

        # ---------------------------------------------------------
        # CASE (e): SELECT COLUMN ONLY (Index Only Scan)
        # ---------------------------------------------------------
        # Run BEFORE clustering
        run_scenario("select_column", "select_column.json")

        # ---------------------------------------------------------
        # CASE (d): CLUSTERED INDEX
        # ---------------------------------------------------------
        print(f"Clustering table...")
        cur.execute(f"CLUSTER {TABLE_NAME} USING {INDEX_NAME};")
        cur.execute(f"ANALYZE {TABLE_NAME};")
        run_scenario("clustered_index", "clustered_index.json")

        # ---------------------------------------------------------
        # FINAL SAVE: Graph Data
        # ---------------------------------------------------------
        with open("task2B_results.json", "w") as f:
            json.dump(graph_results, f, indent=2)
        print("\nSaved graph data to 'task2B_results.json'")

        # Cleanup
        cur.execute(f"DROP TABLE IF EXISTS {TABLE_NAME};")
        print("Task 2B Completed Successfully.")

    except psycopg2.Error as e:
        print(f"Database Error: {e}")
    finally:
        if conn:
            cur.close()
            conn.close()

if __name__ == "__main__":
    task_2b()