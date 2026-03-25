"""S8: Add get_tasks_by_assignee function."""
import os
import sys
import pytest


def test_get_tasks_by_assignee(setup_env):
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
        assert hasattr(app, "get_tasks_by_assignee"), "get_tasks_by_assignee function not found"

        alice = app.get_tasks_by_assignee("alice")
        assert len(alice) == 2
        for t in alice:
            assert t["assignee"] == "alice"

        bob = app.get_tasks_by_assignee("bob")
        assert len(bob) == 2

        nobody = app.get_tasks_by_assignee("nobody")
        assert len(nobody) == 0
    finally:
        os.chdir(old_cwd)
        sys.path.remove(str(tmp_path))
