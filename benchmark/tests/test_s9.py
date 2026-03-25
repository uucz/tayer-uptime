"""S9: Refactor load_tasks/save_tasks to use context managers."""
import ast
import os
import sys
import pytest


def test_uses_context_managers(setup_env):
    tmp_path, tasks = setup_env
    output_dir = os.environ.get("BENCHMARK_OUTPUT_DIR", "")
    if not output_dir:
        pytest.skip("BENCHMARK_OUTPUT_DIR not set")

    app_path = os.path.join(output_dir, "app.py")
    if not os.path.exists(app_path):
        pytest.skip("app.py not found")

    with open(app_path) as f:
        source = f.read()

    tree = ast.parse(source)
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef) and node.name in ("load_tasks", "save_tasks"):
            # Check for With statements
            has_with = any(isinstance(n, ast.With) for n in ast.walk(node))
            assert has_with, f"{node.name} should use a context manager (with statement)"


def test_load_save_still_work(setup_env):
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
        loaded = app.load_tasks()
        assert len(loaded) == 5
        app.add_task("Test task")
        loaded2 = app.load_tasks()
        assert len(loaded2) == 6
    finally:
        os.chdir(old_cwd)
        sys.path.remove(str(tmp_path))
