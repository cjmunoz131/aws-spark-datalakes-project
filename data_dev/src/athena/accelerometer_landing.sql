CREATE EXTERNAL TABLE IF NOT EXISTS  `stedi-database`.`${accelerometer_landing_table}` (
  `user` string,
  `timestamp` bigint,
  `x` float,
  `y` float,
  `z` float
)           
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES ('ignore.malformed.json' = 'false', 'dots.in.keys' = 'true', 'case.insensitive' = 'true' )
STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 's3://${datalake_bucket_name}${accelerometer_landing_path}'
TBLPROPERTIES ('classification' = 'json');