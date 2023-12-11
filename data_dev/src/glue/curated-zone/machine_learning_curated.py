import sys
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import functions as SqlFuncs

args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

pdatabase="stedi-database"
pstep_trainer_trusted_table_name="step_trainer_trusted"
pglueConnection="glx-dev-glue_stedi_connection"
paccelerometer_trusted_table_name="accelerometer_trusted"
pcustomer_curated_table_name="customer_curated"
pmachine_learning_curated_table_name="machine_learning_curated"

customerCuratedDyF = glueContext.create_dynamic_frame.from_catalog(database=pdatabase,table_name=pcustomer_curated_table_name,transformation_ctx="customerCuratedDyF")

step_trainerTrustedDyF = glueContext.create_dynamic_frame.from_catalog(database = pdatabase,table_name= pstep_trainer_trusted_table_name, transformation_ctx= "step_trainerTrustedDyF")
step_trainerTrustedDyF.printSchema()
print("Number of records in the DynamicFrame step_trainerTrustedDyFCount:", step_trainerTrustedDyF.count())
# step_trainerTrustedDyF.toDF().show()

accelerometerTrustedDyF = glueContext.create_dynamic_frame.from_catalog(database = pdatabase,table_name= paccelerometer_trusted_table_name, transformation_ctx= "accelerometerTrustedDyF")
accelerometerTrustedDyF.printSchema()
print("Number of records in the DynamicFrame accelerometerTrustedDyFCount:", accelerometerTrustedDyF.count())

# accelerometerTrustedDyF.toDF().show()

customerRenamedCuratedDyF = RenameField.apply(frame=customerCuratedDyF,old_name="serialNumber",new_name="customer_serialNumber")

customerRenamedCuratedDyF.printSchema()

customeraccelerometerDyF = accelerometerTrustedDyF.join(paths1=['user'],paths2=['email'],frame2=customerRenamedCuratedDyF)

step_trainerCuratedDyF = step_trainerTrustedDyF.join(
    paths1=['serialNumber','sensorReadingTime'],  # Specify the column(s) from DynamicFrame 1 for the join
    paths2=['customer_serialNumber','timestamp'],
    frame2=customeraccelerometerDyF)

step_trainerCuratedCount = step_trainerCuratedDyF.count()

print("Number of records in the DynamicFrame step_trainerCuratedCount", step_trainerCuratedCount)

sink = glueContext.getSink(
    connection_type="s3",
    path= "s3://datalake-stedi-69768220629220231206233751519300000001/stedi-datalake/machine-learning/curated/",
    enableUpdateCatalog=True,
    updateBehavior="UPDATE_IN_DATABASE",
    transformation_ctx="sink",
    connection_options={"connectionName": pglueConnection}  # Specify Glue connection
)
sink.setCatalogInfo(catalogDatabase=(pdatabase), catalogTableName=(pmachine_learning_curated_table_name))
sink.setFormat("json")

sink.writeFrame(step_trainerCuratedDyF)

job.commit()