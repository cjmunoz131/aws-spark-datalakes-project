CREATE EXTERNAL TABLE `stedi-database`.`${step-trainer_landing_table}` (
  `sensorReadingTime` bigint,
  `serialNumber` string,
  `distanceFromObject` int
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES ('ignore.malformed.json' = 'false', 'dots.in.keys' = 'true', 'case.insensitive' = 'true' )
STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 's3://${datalake_bucket_name}${step-trainer_landing_path}'
TBLPROPERTIES ('classification' = 'json');