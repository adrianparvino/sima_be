-- Migration number: 0002 	 2025-01-29T15:16:36.783Z
CREATE TABLE progress (
    progress_id INTEGER PRIMARY KEY,
    task_id INTEGER,
    email TEXT,
    finished_at TEXT,
    FOREIGN KEY (task_id) REFERENCES tasks(task_id),
    UNIQUE(task_id, email)
);
