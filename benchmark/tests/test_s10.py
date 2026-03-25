"""S10: Add docstrings to all public functions."""
import ast
import os
import pytest


PUBLIC_FUNCTIONS = [
    "load_tasks", "save_tasks", "add_task", "complete_task",
    "delete_task", "list_tasks", "search", "get_stats", "display_all"
]


def test_all_public_functions_have_docstrings(setup_env):
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
    missing = []
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef) and node.name in PUBLIC_FUNCTIONS:
            docstring = ast.get_docstring(node)
            if not docstring:
                missing.append(node.name)

    assert len(missing) == 0, f"Functions missing docstrings: {missing}"


def test_code_still_works(setup_env):
    """Docstring addition should not break functionality."""
    import sys
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
        assert len(app.load_tasks()) == 5
        task = app.add_task("Docstring test")
        assert task["title"] == "Docstring test"
    finally:
        os.chdir(old_cwd)
        sys.path.remove(str(tmp_path))
