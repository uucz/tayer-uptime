"""S6: Add bulk_complete function."""
import json
import os
import sys
import pytest


def test_bulk_complete(setup_env):
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
        assert hasattr(app, "bulk_complete"), "bulk_complete function not found"

        # Complete tasks 1, 2, and a non-existent 999
        completed = app.bulk_complete([1, 2, 999])
        assert isinstance(completed, list)
        # Task 3 is already completed, 999 doesn't exist
        assert 1 in completed
        assert 2 in completed
        assert 999 not in completed

        # Verify tasks are actually completed
        with open(os.path.join(tmp_path, "tasks.json")) as f:
            saved = json.load(f)
        for t in saved:
            if t["id"] in [1, 2]:
                assert t["status"] == "completed"
    finally:
        os.chdir(old_cwd)
        sys.path.remove(str(tmp_path))
