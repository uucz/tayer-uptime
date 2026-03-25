"""S2: Add list_tasks_sorted function — sorted by priority (high > medium > low)."""
import json
import os
import sys
import pytest


def test_list_tasks_sorted_exists_and_sorts(setup_env):
    tmp_path, tasks = setup_env
    output_dir = os.environ.get("BENCHMARK_OUTPUT_DIR", "")
    if not output_dir:
        pytest.skip("BENCHMARK_OUTPUT_DIR not set")

    app_path = os.path.join(output_dir, "app.py")
    if not os.path.exists(app_path):
        pytest.skip("app.py not found")

    with open(app_path) as f:
        with open(os.path.join(tmp_path, "app.py"), "w") as out:
            out.write(f.read())

    old_cwd = os.getcwd()
    os.chdir(tmp_path)
    sys.path.insert(0, str(tmp_path))
    for mod in ["app", "helpers"]:
        if mod in sys.modules:
            del sys.modules[mod]

    try:
        import app
        assert hasattr(app, "list_tasks_sorted"), "list_tasks_sorted function not found"
        result = app.list_tasks_sorted()
        assert len(result) > 0
        # Check ordering: all high before medium before low
        priorities = [t["priority"] for t in result]
        order = {"high": 0, "medium": 1, "low": 2}
        order_values = [order.get(p, 99) for p in priorities]
        assert order_values == sorted(order_values), f"Tasks not sorted by priority: {priorities}"
    finally:
        os.chdir(old_cwd)
        sys.path.remove(str(tmp_path))


def test_list_tasks_sorted_with_status_filter(setup_env):
    tmp_path, tasks = setup_env
    output_dir = os.environ.get("BENCHMARK_OUTPUT_DIR", "")
    if not output_dir:
        pytest.skip("BENCHMARK_OUTPUT_DIR not set")

    app_path = os.path.join(output_dir, "app.py")
    if not os.path.exists(app_path):
        pytest.skip("app.py not found")

    with open(app_path) as f:
        with open(os.path.join(tmp_path, "app.py"), "w") as out:
            out.write(f.read())

    old_cwd = os.getcwd()
    os.chdir(tmp_path)
    sys.path.insert(0, str(tmp_path))
    for mod in ["app", "helpers"]:
        if mod in sys.modules:
            del sys.modules[mod]

    try:
        import app
        result = app.list_tasks_sorted(status="pending")
        for t in result:
            assert t["status"] == "pending"
    finally:
        os.chdir(old_cwd)
        sys.path.remove(str(tmp_path))
