BEGIN
-- check if json is valid
DECLARE is_valid BOOLEAN;
SET is_valid = JSON_VALID(json_input);
IF NOT is_valid THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid JSON input.', MYSQL_ERRNO = 333;  -- Throw error 333
END IF;
WITH RECURSIVE data AS (
  SELECT JSON_VALUE(JSON_KEYS(json_input), '$[0]') AS `key`, 0 AS id, NULL AS `value` -- extract first key from json_input
  UNION
  SELECT JSON_VALUE(JSON_KEYS(json_input), CONCAT('$[', d.id + 1, ']')) AS `key`, -- continue extraction using recursion
         d.id + 1 AS id, NULL AS `value`
  FROM data AS d
  WHERE d.id < JSON_LENGTH(JSON_KEYS(json_input)) - 1 -- recursion continues as long as index is less than number of keys
),
jsonTableResult AS (
  SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) -1 AS id, VALUE -- json_table to extract the values from the json
  FROM JSON_TABLE(
    json_input,
    '$.*' COLUMNS (value JSON PATH '$')
  ) AS jt
)
SELECT d.`key`, jt.value
FROM data AS d
JOIN jsonTableResult AS jt ON d.id = jt.id;
END
