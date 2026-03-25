"""S5: Add assignee parameter to list_tasks."""
import os
import sys
import pytest


def test_list_tasks_with_assignee(setup_env):
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
        # Filter by assignee
        alice_tasks = app.list_tasks(assignee="alice")
        assert len(alice_tasks) == 2
        for t in alice_tasks:
            assert t["assignee"] == "alice"

        # Filter by both
        alice_pending = app.list_tasks(status="pending", assignee="alice")
        assert len(alice_pending) == 1
        assert alice_pending[0]["title"] == "Buy groceries"

        # No filter still returns all
        all_tasks = app.list_tasks()
        assert len(all_tasks) == 5
    finally:
        os.chdir(old_cwd)
        sys.path.remove(str(tmp_path))
