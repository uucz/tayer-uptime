"""S4: Add export_csv function."""
import csv
import os
import sys
import pytest


def test_export_csv(setup_env):
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
        assert hasattr(app, "export_csv"), "export_csv function not found"

        csv_file = os.path.join(tmp_path, "test_export.csv")
        count = app.export_csv(csv_file)
        assert count == 5, f"Expected 5 tasks exported, got {count}"
        assert os.path.exists(csv_file)

        with open(csv_file) as f:
            reader = csv.reader(f)
            rows = list(reader)
        # header + 5 data rows
        assert len(rows) >= 6, f"Expected at least 6 rows (header + 5), got {len(rows)}"
    finally:
        os.chdir(old_cwd)
        sys.path.remove(str(tmp_path))
