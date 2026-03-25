"""S1: Fix complete_task null pointer bug — should return None for missing ID."""
import json
import os
import sys
import importlib
import pytest


def test_complete_task_missing_id(setup_env):
    tmp_path, tasks = setup_env
    output_dir = os.environ.get("BENCHMARK_OUTPUT_DIR", "")
    if not output_dir:
        pytest.skip("BENCHMARK_OUTPUT_DIR not set")

    app_path = os.path.join(output_dir, "app.py")
    if not os.path.exists(app_path):
        pytest.skip("app.py not found")

    # Copy files to tmp
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
        # Should not crash, should return None
        result = app.complete_task(999)
        assert result is None, f"Expected None for missing task, got {result}"

        # Existing task should still work
        result = app.complete_task(1)
        assert result is not None
        assert result["status"] == "completed"
    finally:
        os.chdir(old_cwd)
        sys.path.remove(str(tmp_path))


def test_complete_existing_task_still_works(setup_env):
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
        result = app.complete_task(2)
        assert result["id"] == 2
        assert result["status"] == "completed"
    finally:
        os.chdir(old_cwd)
        sys.path.remove(str(tmp_path))
