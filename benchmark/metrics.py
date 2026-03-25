#!/usr/bin/env python3
"""Moyu Benchmark Metrics Extractor.

Computes automated metrics from raw experiment outputs:
- LOC, diff lines, AST node count changes
- Cyclomatic complexity (radon)
- Over-engineering signals (docstrings, try/except, isinstance, raise, new imports)
- Correctness (syntax check, functional tests)

Outputs: results/metrics.csv
"""

import ast
import csv
import difflib
import json
import os
import py_compile
import re
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).parent
SOURCE_DIR = BASE_DIR / "source-v2"
RESULTS_DIR = BASE_DIR / "results"
RAW_DIR = RESULTS_DIR / "raw"
TESTS_DIR = BASE_DIR / "tests"

# ---------------------------------------------------------------------------
# Source baseline
# ---------------------------------------------------------------------------

def load_baseline():
    """Load the original source files for diff comparison."""
    files = {}
    for fname in ["app.py", "helpers.py"]:
        path = SOURCE_DIR / fname
        with open(path) as f:
            files[fname] = f.read()
    return files


# ---------------------------------------------------------------------------
# Metric functions
# ---------------------------------------------------------------------------

def count_loc(code):
    """Count non-empty, non-comment lines."""
    count = 0
    for line in code.split("\n"):
        stripped = line.strip()
        if stripped and not stripped.startswith("#"):
            count += 1
    return count


def compute_diff(original, modified):
    """Compute unified diff stats (added, removed lines)."""
    orig_lines = original.split("\n")
    mod_lines = modified.split("\n")
    diff = list(difflib.unified_diff(orig_lines, mod_lines, lineterm=""))
    added = sum(1 for l in diff if l.startswith("+") and not l.startswith("+++"))
    removed = sum(1 for l in diff if l.startswith("-") and not l.startswith("---"))
    return added, removed


def count_ast_nodes(code):
    """Count total AST nodes in code."""
    try:
        tree = ast.parse(code)
        return sum(1 for _ in ast.walk(tree))
    except SyntaxError:
        return -1


def count_docstrings(code):
    """Count function/class docstrings."""
    try:
        tree = ast.parse(code)
    except SyntaxError:
        return 0
    count = 0
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            if ast.get_docstring(node):
                count += 1
    return count


def count_try_except(code):
    """Count try/except blocks."""
    try:
        tree = ast.parse(code)
    except SyntaxError:
        return 0
    return sum(1 for n in ast.walk(tree) if isinstance(n, ast.Try))


def count_raise(code):
    """Count raise statements."""
    try:
        tree = ast.parse(code)
    except SyntaxError:
        return 0
    return sum(1 for n in ast.walk(tree) if isinstance(n, ast.Raise))


def count_isinstance(code):
    """Count isinstance() calls."""
    try:
        tree = ast.parse(code)
    except SyntaxError:
        return 0
    count = 0
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            if isinstance(node.func, ast.Name) and node.func.id == "isinstance":
                count += 1
    return count


def compute_new_imports(original_code, modified_code):
    """Count imports in modified that don't exist in original."""
    def get_imports(code):
        try:
            tree = ast.parse(code)
        except SyntaxError:
            return set()
        imports = set()
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    imports.add(alias.name)
            elif isinstance(node, ast.ImportFrom):
                module = node.module or ""
                for alias in node.names:
                    imports.add(f"{module}.{alias.name}")
        return imports

    orig_imports = get_imports(original_code)
    mod_imports = get_imports(modified_code)
    return len(mod_imports - orig_imports)


def compute_cyclomatic_complexity(code):
    """Compute average cyclomatic complexity using radon."""
    try:
        from radon.complexity import cc_visit
        results = cc_visit(code)
        if not results:
            return 0.0
        return round(sum(r.complexity for r in results) / len(results), 2)
    except Exception:
        return -1.0


def check_syntax(file_path):
    """Check if file has valid Python syntax."""
    try:
        py_compile.compile(str(file_path), doraise=True)
        return True
    except py_compile.PyCompileError:
        return False


def count_new_files(output_dir, baseline_files):
    """Count files in output that aren't in baseline."""
    output_files = set()
    for f in os.listdir(output_dir):
        if f.endswith(".py") and f not in ("raw_response.txt", "meta.json"):
            output_files.add(f)
    baseline = set(baseline_files.keys())
    return len(output_files - baseline)


def run_scenario_test(output_dir, scenario):
    """Run the validation test for a scenario. Returns (passed, total)."""
    test_file = TESTS_DIR / f"test_{scenario}.py"
    if not test_file.exists():
        return -1, -1

    env = os.environ.copy()
    env["BENCHMARK_OUTPUT_DIR"] = str(output_dir)

    try:
        result = subprocess.run(
            [sys.executable, "-m", "pytest", str(test_file), "-v", "--tb=short", "-q"],
            capture_output=True, text=True, timeout=30, env=env,
            cwd=str(BASE_DIR)
        )
        # Parse pytest output for pass/fail counts
        output = result.stdout
        passed_match = re.search(r"(\d+) passed", output)
        failed_match = re.search(r"(\d+) failed", output)
        passed = int(passed_match.group(1)) if passed_match else 0
        failed = int(failed_match.group(1)) if failed_match else 0
        return passed, passed + failed
    except Exception:
        return -1, -1


# ---------------------------------------------------------------------------
# Main extraction
# ---------------------------------------------------------------------------

def extract_metrics_for_run(run_dir, baseline_files):
    """Extract all metrics for a single experiment run."""
    meta_path = run_dir / "meta.json"
    if not meta_path.exists():
        return None

    with open(meta_path) as f:
        meta = json.load(f)

    app_path = run_dir / "app.py"
    if not app_path.exists():
        return None

    with open(app_path) as f:
        app_code = f.read()

    orig_app = baseline_files.get("app.py", "")

    # Compute metrics
    loc = count_loc(app_code)
    orig_loc = count_loc(orig_app)
    added, removed = compute_diff(orig_app, app_code)
    ast_nodes = count_ast_nodes(app_code)
    orig_ast_nodes = count_ast_nodes(orig_app)
    complexity = compute_cyclomatic_complexity(app_code)
    orig_complexity = compute_cyclomatic_complexity(orig_app)
    docstrings = count_docstrings(app_code)
    orig_docstrings = count_docstrings(orig_app)
    try_except = count_try_except(app_code)
    orig_try_except = count_try_except(orig_app)
    raise_count = count_raise(app_code)
    orig_raise = count_raise(orig_app)
    isinstance_count = count_isinstance(app_code)
    orig_isinstance = count_isinstance(orig_app)
    new_imports = compute_new_imports(orig_app, app_code)
    new_files = count_new_files(run_dir, baseline_files)
    syntax_ok = check_syntax(app_path)

    # Over-engineering score = sum of delta signals
    oe_score = (
        max(0, docstrings - orig_docstrings) +
        max(0, try_except - orig_try_except) +
        max(0, raise_count - orig_raise) +
        max(0, isinstance_count - orig_isinstance) +
        new_imports +
        new_files
    )

    # Run functional tests
    scenario = meta.get("scenario", "")
    tests_passed, tests_total = run_scenario_test(run_dir, scenario)

    return {
        "model": meta.get("model", ""),
        "condition": meta.get("condition", ""),
        "scenario": scenario,
        "trial": meta.get("trial", ""),
        "loc": loc,
        "loc_delta": loc - orig_loc,
        "diff_added": added,
        "diff_removed": removed,
        "diff_total": added + removed,
        "ast_nodes": ast_nodes,
        "ast_nodes_delta": ast_nodes - orig_ast_nodes if orig_ast_nodes > 0 else -1,
        "complexity": complexity,
        "complexity_delta": round(complexity - orig_complexity, 2) if complexity >= 0 and orig_complexity >= 0 else -1,
        "docstrings": docstrings,
        "docstrings_delta": docstrings - orig_docstrings,
        "try_except": try_except,
        "try_except_delta": try_except - orig_try_except,
        "raise_count": raise_count,
        "raise_delta": raise_count - orig_raise,
        "isinstance_count": isinstance_count,
        "isinstance_delta": isinstance_count - orig_isinstance,
        "new_imports": new_imports,
        "new_files": new_files,
        "overengineering_score": oe_score,
        "syntax_ok": syntax_ok,
        "tests_passed": tests_passed,
        "tests_total": tests_total,
        "input_tokens": meta.get("usage", {}).get("input_tokens", 0),
        "output_tokens": meta.get("usage", {}).get("output_tokens", 0),
        "elapsed_seconds": meta.get("usage", {}).get("elapsed_seconds", 0),
    }


def extract_all():
    """Extract metrics for all experiment runs and write to CSV."""
    baseline = load_baseline()

    if not RAW_DIR.exists():
        print("No results/raw directory found. Run experiments first.")
        return

    runs = sorted(RAW_DIR.iterdir())
    if not runs:
        print("No experiment runs found.")
        return

    rows = []
    for run_dir in runs:
        if not run_dir.is_dir():
            continue
        print(f"  Processing {run_dir.name}...", end="", flush=True)
        metrics = extract_metrics_for_run(run_dir, baseline)
        if metrics:
            rows.append(metrics)
            print(f" OK (LOC={metrics['loc']}, OE={metrics['overengineering_score']})")
        else:
            print(" SKIP (no data)")

    if not rows:
        print("No metrics extracted.")
        return

    # Write CSV
    csv_path = RESULTS_DIR / "metrics.csv"
    fieldnames = list(rows[0].keys())
    with open(csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"\nWrote {len(rows)} rows to {csv_path}")
    return rows


if __name__ == "__main__":
    print("Moyu Benchmark Metrics Extractor")
    print("=" * 50)
    extract_all()
