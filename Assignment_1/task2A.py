import psycopg2
import sys

TOLERANCE = 0.01   # ±1% tolerance
MAX_ITER = 50      # safety bound


def get_total_rows(cursor):
    """
    Return total number of rows in lineitem table.
    """
    cursor.execute("SELECT COUNT(*) FROM lineitem;")
    return cursor.fetchone()[0]


def get_min_max(cursor, column):
    """
    Return (min_value, max_value) for the given column.
    """
    query = f"SELECT MIN({column}), MAX({column}) FROM lineitem;"
    cursor.execute(query)
    return cursor.fetchone()


def get_quantity_for_selectivity(cursor, column, target_selectivity, total_rows):
    """
    Binary search on column values to find threshold achieving target selectivity.
    Returns:
        best_threshold, best_selectivity, queries_executed
    """

    cursor.execute(f"SELECT MIN({column}), MAX({column}) FROM lineitem;")
    min_val, max_val = cursor.fetchone()

    low = float(min_val)
    high = float(max_val)

    queries_executed = 1  # min/max query
    best_threshold = None
    best_diff = float("inf")
    best_selectivity = None
    prev_selectivity = None

    for i in range(MAX_ITER):
        if(i == 0):
            mid = low + (high-low)*target_selectivity
        else:
            mid = (low + high) / 2 
        cursor.execute(
            f"SELECT COUNT(*) FROM lineitem WHERE {column} <= %s;",
            (mid,)
        )
        count = cursor.fetchone()[0]
        queries_executed += 1

        actual_selectivity = count / total_rows
        diff = abs(actual_selectivity - target_selectivity)

        # Track closest result
        if diff < best_diff:
            best_diff = diff
            best_threshold = mid
            best_selectivity = actual_selectivity

        # Check tolerance
        if diff <= TOLERANCE:
            break

        if low >= high:
            break

        epsilon = max((high - low) * 0.0001, 1e-6)

        if actual_selectivity < target_selectivity:
            low = mid + epsilon
        else:
            high = mid - epsilon

        prev_selectivity = actual_selectivity
        # if actual_selectivity < target_selectivity:
        #     low = mid+0.01
        # else:
        #     high = mid-0.01

    return best_threshold, best_selectivity, queries_executed


def verify_selectivity(cursor, column, quantity_threshold, total_rows):
    """
    Verify actual selectivity for the chosen threshold.
    """
    cursor.execute(
        f"SELECT COUNT(*) FROM lineitem WHERE {column} <= %s;",
        (quantity_threshold,)
    )
    count = cursor.fetchone()[0]
    return count / total_rows


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 task2A.py <column_name> <selectivity>")
        sys.exit(1)

    column = sys.argv[1]
    target_selectivity = float(sys.argv[2])

    # ---- DB CONNECTION (EDIT IF NEEDED) ----
    conn = psycopg2.connect(
        dbname="tpch_db",
        user="asit",
        password="asit",
        host="localhost"
    )
    cursor = conn.cursor()

    total_rows = get_total_rows(cursor)

    threshold, achieved_selectivity, queries_executed = \
        get_quantity_for_selectivity(
            cursor,
            column,
            target_selectivity,
            total_rows
        )

    final_selectivity = verify_selectivity(
        cursor,
        column,
        threshold,
        total_rows
    )
    queries_executed += 1

    # ---- REQUIRED OUTPUT FORMAT ----
    print(f"QUERY_PARAMETER: {round(threshold, 4)}")
    print(f"QUERIES_EXECUTED: {queries_executed}")
    print(f"ACTUAL_SELECTIVITY: {round(final_selectivity, 4)}")

    cursor.close()
    conn.close()


if __name__ == "__main__":
    main()
