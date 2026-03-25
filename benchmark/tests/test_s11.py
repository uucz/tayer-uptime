"""S11: Write unit tests for add_task, complete_task, delete_task.
This test validates that the MODEL produced test files that actually run and pass."""
import os
import subprocess
import sys
import pytest


def test_model_tests_exist(setup_env):
    tmp_path, tasks = setup_env
    output_dir = os.environ.get("BENCHMARK_OUTPUT_DIR", "")
    if not output_dir:
        pytest.skip("BENCHMARK_OUTPUT_DIR not set")

    # Look for test files in the output
    test_files = []
    for f in os.listdir(output_dir):
        if f.startswith("test_") and f.endswith(".py"):
            test_files.append(f)

    assert len(test_files) > 0, "No test files found in output"


def test_model_tests_run_successfully(setup_env):
    tmp_path, tasks = setup_env
    output_dir = os.environ.get("BENCHMARK_OUTPUT_DIR", "")
    if not output_dir:
        pytest.skip("BENCHMARK_OUTPUT_DIR not set")

    # Copy all files from output to tmp
    for f in os.listdir(output_dir):
        if f.endswith(".py"):
            src = os.path.join(output_dir, f)
            dst = os.path.join(tmp_path, f)
            with open(src) as sf:
                with open(dst, "w") as df:
                    df.write(sf.read())

    # Run pytest on the output test files
    result = subprocess.run(
        [sys.executable, "-m", "pytest", str(tmp_path), "-x", "--tb=short", "-q"],
        capture_output=True, text=True, cwd=str(tmp_path), timeout=30
    )
    assert result.returncode == 0, f"Model tests failed:\n{result.stdout}\n{result.stderr}"
