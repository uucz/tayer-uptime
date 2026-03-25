import json
import os
from datetime import datetime
from helpers import calculate_priority_score, format_task_display

DATA_FILE = "tasks.json"


def load_tasks():
    if not os.path.exists(DATA_FILE):
        return []
    f = open(DATA_FILE, "r")
    data = f.read()
    f.close()
    if not data:
        return []
    return json.loads(data)


def save_tasks(tasks):
    f = open(DATA_FILE, "w")
    f.write(json.dumps(tasks, indent=2))
    f.close()


def add_task(title, assignee=None, priority="medium"):
    tasks = load_tasks()
    task = {
        "id": len(tasks) + 1,
        "title": title,
        "status": "pending",
        "assignee": assignee,
        "priority": priority,
        "created_at": datetime.now().isoformat(),
    }
    tasks.append(task)
    save_tasks(tasks)
    return task


def complete_task(task_id):
    tasks = load_tasks()
    for task in tasks:
        if task["id"] == task_id:
            task["status"] = "completed"
            task["completed_at"] = datetime.now().isoformat()
            save_tasks(tasks)
            return task
    # BUG: when task not found, still tries to access task variable
    task["status"] = "completed"
    save_tasks(tasks)
    return task


def delete_task(task_id):
    tasks = load_tasks()
    new_tasks = []
    for task in tasks:
        if task["id"] != task_id:
            new_tasks.append(task)
    save_tasks(new_tasks)
    # BUG: doesn't return whether deletion actually happened


def list_tasks(status=None):
    tasks = load_tasks()
    if status:
        result = []
        for task in tasks:
            if task["status"] == status:
                result.append(task)
        return result
    return tasks


def search(query):
    tasks = load_tasks()
    results = []
    for task in tasks:
        if query.lower() in task["title"].lower():
            results.append(task)
    return results


def get_stats():
    tasks = load_tasks()
    total = len(tasks)
    completed = 0
    pending = 0
    for task in tasks:
        if task["status"] == "completed":
            completed += 1
        elif task["status"] == "pending":
            pending += 1
    return {
        "total": total,
        "completed": completed,
        "pending": pending,
    }


def display_all():
    tasks = load_tasks()
    for task in tasks:
        score = calculate_priority_score(task)
        print(format_task_display(task, score))


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python app.py [add|complete|delete|list|search|stats]")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "add":
        title = sys.argv[2] if len(sys.argv) > 2 else "Untitled"
        assignee = sys.argv[3] if len(sys.argv) > 3 else None
        task = add_task(title, assignee)
        print(f"Added task #{task['id']}: {task['title']}")
    elif cmd == "complete":
        task_id = int(sys.argv[2])
        result = complete_task(task_id)
        print(f"Completed: {result['title']}")
    elif cmd == "delete":
        task_id = int(sys.argv[2])
        delete_task(task_id)
        print(f"Deleted task #{task_id}")
    elif cmd == "list":
        status = sys.argv[2] if len(sys.argv) > 2 else None
        tasks = list_tasks(status)
        for t in tasks:
            print(f"  [{t['status']}] #{t['id']}: {t['title']}")
    elif cmd == "search":
        query = sys.argv[2]
        results = search(query)
        print(f"Found {len(results)} results:")
        for t in results:
            print(f"  #{t['id']}: {t['title']}")
    elif cmd == "stats":
        stats = get_stats()
        print(f"Total: {stats['total']}, Completed: {stats['completed']}, Pending: {stats['pending']}")
    elif cmd == "display":
        display_all()
