# Asynchronous Apex Batch Apex

Batch Apex is used to run large jobs (thousands or millions of records), eg. data cleansing or archiving.

Each time you invoke a batch class, job is placed on the Apex job queue and executed as a discrete transaction.
 
Advantages:
1. every transaction starts with a new set of governor limits, ensure code stays within the execution limits.
2. if one batch fails to process successfully, all other successful batch transactions aren't rolled back.

# Batch Apex Syntax

Implement ```Database.Batchable``` interface and include three methods
1. Start: collect the records or objects to be passed to the interface method execute