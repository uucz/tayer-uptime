"""Shared test fixtures for benchmark validation tests."""
import json
import os
import sys
import tempfile
import importlib
import pytest


@pytest.fixture
def setup_env(tmp_path):
    """Set up a clean environment for testing generated code."""
    # Copy helpers.py to tmp
    source_dir = os.path.join(os.path.dirname(__file__), "..", "source-v2")
    helpers_src = os.path.join(source_dir, "helpers.py")
    helpers_dst = os.path.join(tmp_path, "helpers.py")
    with open(helpers_src) as f:
        with open(helpers_dst, "w") as out:
            out.write(f.read())

    # Create sample tasks.json
    tasks = [
        {"id": 1, "title": "Buy groceries", "status": "pending", "assignee": "alice", "priority": "high", "created_at": "2025-01-01T10:00:00"},
        {"id": 2, "title": "Write report", "status": "pending", "assignee": "bob", "priority": "medium", "created_at": "2025-01-02T10:00:00"},
        {"id": 3, "title": "Fix bug", "status": "completed", "assignee": "alice", "priority": "high", "created_at": "2025-01-03T10:00:00", "completed_at": "2025-01-04T10:00:00"},
        {"id": 4, "title": "Review PR", "status": "pending", "assignee": "bob", "priority": "low", "created_at": "2025-01-04T10:00:00"},
        {"id": 5, "title": "Deploy service", "status": "pending", "assignee": None, "priority": "medium", "created_at": "2025-01-05T10:00:00"},
    ]
    tasks_file = os.path.join(tmp_path, "tasks.json")
    with open(tasks_file, "w") as f:
        json.dump(tasks, f)

    return tmp_path, tasks


def load_app_module(output_dir, tmp_path):
    """Load app.py from an output directory, using tmp_path as working dir."""
    app_path = os.path.join(output_dir, "app.py")
    if not os.path.exists(app_path):
        pytest.skip(f"app.py not found in {output_dir}")

    # Copy app.py to tmp_path
    with open(app_path) as f:
        content = f.read()
    dst = os.path.join(tmp_path, "app.py")
    with open(dst, "w") as f:
        f.write(content)

    # Change to tmp_path so DATA_FILE resolves there
    old_cwd = os.getcwd()
    os.chdir(tmp_path)

    # Import the module
    sys.path.insert(0, str(tmp_path))
    if "app" in sys.modules:
        del sys.modules["app"]
    if "helpers" in sys.modules:
        del sys.modules["helpers"]
    import app
    importlib.reload(app)

    yield app

    os.chdir(old_cwd)
    sys.path.remove(str(tmp_path))
