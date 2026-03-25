"""S3: Add status parameter to search function."""
import json
import os
import sys
import pytest


def test_search_with_status_filter(setup_env):
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
        # "bug" matches "Fix bug" which is completed
        all_results = app.search("bug")
        assert len(all_results) >= 1

        # With status filter
        pending_results = app.search("bug", status="pending")
        for r in pending_results:
            assert r["status"] == "pending"

        completed_results = app.search("bug", status="completed")
        for r in completed_results:
            assert r["status"] == "completed"
    finally:
        os.chdir(old_cwd)
        sys.path.remove(str(tmp_path))


def test_search_without_status_unchanged(setup_env):
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
        # Without status, should return all matches
        results = app.search("e")  # matches multiple tasks
        assert len(results) >= 2
    finally:
        os.chdir(old_cwd)
        sys.path.remove(str(tmp_path))
