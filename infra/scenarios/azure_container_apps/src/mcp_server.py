from mcp.server import MCPServer
from task_store import store

mcp = MCPServer("TasksMCP")


@mcp.tool()
async def list_tasks() -> list[dict]:
    """List all tasks with their ID, title, description, and completion status."""
    return store.get_all()


@mcp.tool()
async def get_task(task_id: int) -> dict | None:
    """Get a single task by its numeric ID.

    Args:
        task_id: The numeric ID of the task to retrieve.
    """
    return store.get_by_id(task_id)


@mcp.tool()
async def create_task(title: str, description: str) -> dict:
    """Create a new task with the given title and description. Returns the created task.

    Args:
        title: A short title for the task.
        description: A detailed description of what the task involves.
    """
    return store.create(title, description)


@mcp.tool()
async def toggle_task_complete(task_id: int) -> str:
    """Toggle a task's completion status between complete and incomplete.

    Args:
        task_id: The numeric ID of the task to toggle.
    """
    task = store.toggle_complete(task_id)
    if task:
        status = "complete" if task["is_complete"] else "incomplete"
        return f"Task {task['id']} is now {status}."
    return f"Task with ID {task_id} not found."


@mcp.tool()
async def delete_task(task_id: int) -> str:
    """Delete a task by its numeric ID.

    Args:
        task_id: The numeric ID of the task to delete.
    """
    if store.delete(task_id):
        return f"Task {task_id} deleted."
    return f"Task with ID {task_id} not found."