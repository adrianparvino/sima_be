-- Migration number: 0005 	 2025-08-19T09:28:07.757Z
ALTER TABLE tasks ADD COLUMN ext_id TEXT;

CREATE UNIQUE INDEX tasks_ext_id_index ON tasks(ext_id);