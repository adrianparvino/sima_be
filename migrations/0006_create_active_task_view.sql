-- Migration number: 0006 	 2025-08-19T09:30:10.069Z
CREATE VIEW active_tasks AS
SELECT * FROM tasks WHERE active = TRUE;