import sys
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)
pdatabase="stedi-database"
ptrusted_table_name="customer_trusted"
pglueConnection="glx-dev-glue_stedi_connection"
paccelerometer_trusted_table_name="accelerometer_trusted"
pcustomer_curated_table_name="customer_curated"

customersTrustedDyF = glueContext.create_dynamic_frame.from_catalog(database = pdatabase,table_name= ptrusted_table_name, transformation_ctx= "customersTrustedDyF")
customersTrustedDyF.printSchema()

accelerometerTrustedDyF = glueContext.create_dynamic_frame.from_catalog(database = pdatabase,table_name= paccelerometer_trusted_table_name, transformation_ctx= "accelerometerTrustedDyF")

accelerometerTrustedDyF.printSchema()

accelerometerTrustedDyFPruned = DynamicFrame.drop_fields(accelerometerTrustedDyF,['timestamp','z','y','x'])

accelerometerTrustedOnlyUserId = DynamicFrame.fromDF(accelerometerTrustedDyFPruned.toDF().dropDuplicates(),glueContext,"accelerometerTrustedOnlyUserId")

customerCuratedDyF = customersTrustedDyF.join(
    paths1=['email'],
    paths2=['user'],
    frame2=accelerometerTrustedOnlyUserId)

customerCuratedPrunedDyF = DynamicFrame.drop_fields(customerCuratedDyF,['user'])

print('the count of customer Curated DyF is: '+ str(customerCuratedDyF.count()))

customerCuratedDyF.toDF().show()

sink = glueContext.getSink(
    connection_type="s3",
    path= "s3://datalake-stedi-69768220629220231206233751519300000001/stedi-datalake/customer/curated/",
    enableUpdateCatalog=True,
    updateBehavior="UPDATE_IN_DATABASE",
    transformation_ctx="sink",
    connection_options={"connectionName": pglueConnection}  # Specify Glue connection
)
sink.setCatalogInfo(catalogDatabase=(pdatabase), catalogTableName=(pcustomer_curated_table_name))
sink.setFormat("json")

sink.writeFrame(customerCuratedDyF)

job.commit()
