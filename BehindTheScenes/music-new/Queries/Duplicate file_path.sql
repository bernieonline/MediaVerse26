SELECT file_path, COUNT(*) AS path_count
FROM mediafiledetail
GROUP BY file_path
HAVING path_count > 1;
