from datetime import datetime


PRIORITY_WEIGHTS = {
    "high": 3,
    "medium": 2,
    "low": 1,
}


def calculate_priority_score(task):
    weight = PRIORITY_WEIGHTS.get(task.get("priority", "medium"), 2)
    created = datetime.fromisoformat(task["created_at"])
    age_days = (datetime.now() - created).days
    return weight * 10 + age_days


def format_task_display(task, score=None):
    status_icon = "✓" if task["status"] == "completed" else "○"
    assignee = task.get("assignee", "unassigned")
    line = f"{status_icon} #{task['id']} [{task['priority']}] {task['title']} (@{assignee})"
    if score is not None:
        line += f" [score: {score}]"
    return line


def parse_date_string(date_str):
    try:
        return datetime.fromisoformat(date_str)
    except (ValueError, TypeError):
        return None
