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
pstep_trainer_landing_table_name="stedi_table_landing_ac124ea23e8ffdb65696c01a8f26d222"
pcustomer_trusted_table_name="customer_trusted"
paccelerometer_trusted_table_name="accelerometer_trusted"
pglueConnection="glx-dev-glue_stedi_connection"
pstep_trainer_trusted_table_name="step_trainer_trusted"

customersTrustedDyF = glueContext.create_dynamic_frame.from_catalog(database = pdatabase,table_name= pcustomer_trusted_table_name, transformation_ctx= "customersTrustedDyF")
customersTrustedDyF.printSchema()

mappingList = [("serialNumber","string","customer_serialNumber","string")]

customersTrustedFormatedDyF = ApplyMapping.apply(frame=customersTrustedDyF,mappings=mappingList)

customersTrustedFormatedUniquesDyF = DynamicFrame.fromDF(customersTrustedFormatedDyF.toDF().dropDuplicates(),glueContext,"customersTrustedFormatedUniquesDyF")

step_trainerLandingDyF = glueContext.create_dynamic_frame.from_catalog(database = pdatabase,table_name= pstep_trainer_landing_table_name, transformation_ctx= "step_trainerLandingDyF")
step_trainerLandingDyF.printSchema()

step_trainerLandingDyF.toDF().show()

step_trainerLandingCount = step_trainerLandingDyF.count()
print("Number of records in the DynamicFrame stepTrainerLanding:", step_trainerLandingCount)

step_trainerTrusted1DyF = step_trainerLandingDyF.join(
    paths1=['serialNumber'],
    paths2=['customer_serialNumber'],
    frame2=customersTrustedFormatedUniquesDyF)

step_trainerTrusted1Count = step_trainerTrusted1DyF.count()

print("Number of records in the DynamicFrame stepTrainer1Trusted:", step_trainerTrusted1Count)

step_trainerTrusted1DyF.printSchema()

step_trainerTrusted1DyFPruned = DynamicFrame.drop_fields(step_trainerTrusted1DyF,['customer_serialNumber'])

# accelerometerTrustedDyF = glueContext.create_dynamic_frame.from_catalog(database = pdatabase,table_name= paccelerometer_trusted_table_name, transformation_ctx= "accelerometerTrustedDyF")

# accelerometerTrustedDyF.printSchema()

# accelerometerTrustedDyFPruned = DynamicFrame.drop_fields(accelerometerTrustedDyF,['z','birthDay','shareWithPublicAsOfDate','shareWithResearchAsOfDate','registrationDate','customerName','user','y','shareWithFriendsAsOfDate','x','email','lastUpdateDate','phone'])

# accelerometerTrustedDyFPruned.printSchema()
# accelerometerTrustedOnlyDeviceTime = DynamicFrame.fromDF(accelerometerTrustedDyFPruned.toDF().dropDuplicates(),glueContext,"accelerometerTrustedOnlyDeviceTime")

# print("Number of records in the DynamicFrame accelerometerTrustedOnlyDeviceTime:", accelerometerTrustedOnlyDeviceTime.count())

# step_trainerTrusted2DyF = step_trainerTrusted1DyF.join(
#     paths1=['sensorReadingTime','serialNumber'],
#     paths2=['timestamp','serialNumber'],
#     frame2=accelerometerTrustedOnlyDeviceTime)

# step_trainerTrusted2Count = step_trainerTrusted2DyF.count()

# print("Number of records in the DynamicFrame stepTrainer2Trusted:", step_trainerTrusted2Count)


sink = glueContext.getSink(
    connection_type="s3",
    path= "s3://datalake-stedi-69768220629220231206233751519300000001/stedi-datalake/step_trainer/trusted/",
    enableUpdateCatalog=True,
    updateBehavior="UPDATE_IN_DATABASE",
    transformation_ctx="sink",
    connection_options={"connectionName": pglueConnection}  # Specify Glue connection
)
sink.setCatalogInfo(catalogDatabase=(pdatabase), catalogTableName=(pstep_trainer_trusted_table_name))
sink.setFormat("json")

sink.writeFrame(step_trainerTrusted1DyFPruned)

job.commit()

