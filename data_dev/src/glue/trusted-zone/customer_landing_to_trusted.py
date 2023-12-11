import sys
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)    
pdatabase="stedi-database"
planding_table_name="stedi_table_landing_2ef78232bf40ae762110340c69c5ec26"
ptrusted_table_name="customer_trusted"
pglueConnection="glx-dev-glue_stedi_connection"

customersDyF = glueContext.create_dynamic_frame.from_catalog(database = pdatabase,table_name= planding_table_name, transformation_ctx= "customersDyF")
customersDyF.printSchema()

customersDyF.toDF().show()


field_to_check = 'shareWithResearchAsOfDate'

trustedCustomersDyF = customersDyF.filter( lambda x: x[field_to_check] > 0)

record_count = trustedCustomersDyF.count()


print("Number of records in the DynamicFrame:", record_count)

sink = glueContext.getSink(
    connection_type="s3",
    path= "s3://datalake-stedi-69768220629220231206233751519300000001/stedi-datalake/customer/trusted/",
    enableUpdateCatalog=True,
    updateBehavior="UPDATE_IN_DATABASE",
    transformation_ctx="sink",
    connection_options={"connectionName": pglueConnection}  # Specify Glue connection
)
sink.setCatalogInfo(catalogDatabase=(pdatabase), catalogTableName=(ptrusted_table_name))
sink.setFormat("json")

sink.writeFrame(trustedCustomersDyF)

job.commit()