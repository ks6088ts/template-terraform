from dataclasses import dataclass, field
from datetime import datetime, timezone


@dataclass
class TaskItem:
    id: int
    title: str
    description: str
    is_complete: bool = False
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "is_complete": self.is_complete,
            "created_at": self.created_at.isoformat(),
        }


class TaskStore:
    def __init__(self):
        self._tasks: list[TaskItem] = [
            TaskItem(1, "Buy groceries", "Milk, eggs, bread"),
            TaskItem(2, "Write docs", "Draft the MCP tutorial", True),
        ]
        self._next_id = 3

    def get_all(self) -> list[dict]:
        return [t.to_dict() for t in self._tasks]

    def get_by_id(self, task_id: int) -> dict | None:
        task = next((t for t in self._tasks if t.id == task_id), None)
        return task.to_dict() if task else None

    def create(self, title: str, description: str) -> dict:
        task = TaskItem(self._next_id, title, description)
        self._next_id += 1
        self._tasks.append(task)
        return task.to_dict()

    def toggle_complete(self, task_id: int) -> dict | None:
        task = next((t for t in self._tasks if t.id == task_id), None)
        if task is None:
            return None
        task.is_complete = not task.is_complete
        return task.to_dict()

    def delete(self, task_id: int) -> bool:
        task = next((t for t in self._tasks if t.id == task_id), None)
        if task is None:
            return False
        self._tasks.remove(task)
        return True


# For demonstration only — not thread-safe.
store = TaskStore()
