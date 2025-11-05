-- slight differences in filename will not be easily identihed with this order of listing
SELECT SUBSTRING(file_name, 4) AS adjusted_filename, COUNT(*) AS filename_count
FROM mediafiledetail
GROUP BY adjusted_filename
ORDER BY filename_count desc;
