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
job = Job(glueContext)
job.init(args["JOB_NAME"], args)    
pdatabase="stedi-database"
ptrusted_table_name="customer_trusted"
paccelerometer_landing_table_name="stedi_table_landing"
paccelerometer_trusted_table_name="accelerometer_trusted"
pglueConnection="glx-dev-glue_stedi_connection"

customersTrustedDyF = glueContext.create_dynamic_frame.from_catalog(database = pdatabase,table_name= ptrusted_table_name, transformation_ctx= "customersTrustedDyF")
customersTrustedDyF.printSchema()
record_count = customersTrustedDyF.count()

print("Number of records in the DynamicFrame:", record_count)

customersTrustedDyF.toDF().show()

accelerometerLandingDyF = glueContext.create_dynamic_frame.from_catalog(database = pdatabase, table_name = paccelerometer_landing_table_name, transformation_ctx= "accelerometerLandingDyF")

accelerometerTrustedDyF = customersTrustedDyF.join(
    paths1=['email'],
    paths2=['user'],
    frame2=accelerometerLandingDyF)

accelerometerTrustedCount = accelerometerTrustedDyF.count()

print("Number of records in the DynamicFrame accelerometerTrusted:", accelerometerTrustedCount)

joined_data_frame = accelerometerTrustedDyF.toDF()

joined_data_frame.show()

accelerometerTrustedDyF.printSchema()

accelerometerTrustedDyFPruned = DynamicFrame.drop_fields(accelerometerTrustedDyF,['birthDay','shareWithPublicAsOfDate','shareWithResearchAsOfDate','registrationDate','customerName','serialNumber','shareWithFriendsAsOfDate','email','lastUpdateDate','phone'])

sink = glueContext.getSink(
    connection_type="s3",
    path= "s3://datalake-stedi-69768220629220231206233751519300000001/stedi-datalake/accelerometer/trusted/",
    enableUpdateCatalog=True,
    updateBehavior="UPDATE_IN_DATABASE",
    transformation_ctx="sink",
    connection_options={"connectionName": pglueConnection}
)
sink.setCatalogInfo(catalogDatabase=(pdatabase), catalogTableName=(paccelerometer_trusted_table_name))
sink.setFormat("json")
sink.writeFrame(accelerometerTrustedDyFPruned)

job.commit()