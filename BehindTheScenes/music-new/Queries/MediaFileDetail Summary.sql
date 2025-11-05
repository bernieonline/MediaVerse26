SELECT location, COUNT(*) AS record_count, SUM(file_size) AS total_file_size
FROM mediafiledetail
GROUP BY location
order by record_count desc;
