-- Migration number: 0003 	 2025-02-08T07:43:19.764Z
DROP TABLE progress;

CREATE TABLE progress (
    progress_id INTEGER PRIMARY KEY,
    task_id INTEGER,
    email TEXT,
    finished_at TEXT,
    FOREIGN KEY (task_id) REFERENCES tasks(task_id) ON DELETE CASCADE,
    UNIQUE(task_id, email)
);
