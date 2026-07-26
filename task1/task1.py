import json

def load_psql_json(filepath):
    """Helper function to parse standard JSON or raw psql output containing headers, footers, and trailing '+' characters."""
    json_str = ""
    recording = False
    
    with open(filepath, 'r') as f:
        for line in f:
            clean_line=line.strip()
            # Remove psql line-continuation '+'
            if clean_line.endswith('+'):
                clean_line=clean_line[:-1]   
            if clean_line.startswith('['):
                recording=True
            if recording:
                json_str+=clean_line  
            if clean_line.endswith(']'):
                break
                
    try:
        return json.loads(json_str)
    except json.JSONDecodeError:
        with open(filepath, 'r') as f:
            return json.load(f)


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


def compare_plans(plan1, plan2):
    """
    Compare two PostgreSQL query execution plans for structural equivalence.
    Args:
        plan1: A PostgreSQL compile-time query execution plan
        plan2: A PostgreSQL compile-time query execution plan
    Returns:
        True if plans are structurally identical, False otherwise
    """
    tree1=extract_physical_operator_tree(plan1)
    tree2=extract_physical_operator_tree(plan2)
    return tree1==tree2


if __name__=="__main__":
    plan1=load_psql_json("plan1.json")
    plan2=load_psql_json("plan2.json")
    if compare_plans(plan1, plan2):
        print("YES: Both plans are structurally identical") 
    else:
        print("NO: Plans are structurally different")