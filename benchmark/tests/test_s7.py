"""S7: Fix delete_task to return True/False."""
import os
import sys
import pytest


def test_delete_task_returns_bool(setup_env):
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
        # Delete existing task
        result = app.delete_task(1)
        assert result is True, f"Expected True for existing task, got {result}"

        # Delete non-existent task
        result = app.delete_task(999)
        assert result is False, f"Expected False for missing task, got {result}"
    finally:
        os.chdir(old_cwd)
        sys.path.remove(str(tmp_path))
