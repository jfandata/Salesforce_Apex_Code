# Asynchronous Apex Batch Apex

Batch Apex is used to run large jobs (thousands or millions of records), eg. data cleansing or archiving.

Each time you invoke a batch class, job is placed on the Apex job queue and executed as a discrete transaction.
 
Advantages:
1. every transaction starts with a new set of governor limits, ensure code stays within the execution limits.
2. if one batch fails to process successfully, all other successful batch transactions aren't rolled back.

# Batch Apex Syntax

Implement ```Database.Batchable``` interface and include three methods
1. Start: collect the records or objects to be passed to the interface method ```execute``` for processing. This method is called once at the beginning of a Batch Apex job and returns either a Database.QueryLocator object or an Iterable that contains the records or objects passed to the job. Most common: ```QueryLocator``` with a simple SOQL query to generate the scope of objects in the batch job (query up to 50 million records). For Custom Iterators see documentation (limits apply).

2. Execute: performs actual processing for each chunk or "batch" of data passed to method. Default batch size 200 records. Batchesof records are not guaranteed to execute in the order they are received from the ```start``` method.

This method takes the following: 
    a. reference to the ```Database.BatchableContext``` object
    b. list of sObjects, such as ```List<sObject>``` or a list of parameterized types. If you are using a ```Database.QueryLocator```, use the returned list.

3. Finish: execute post-processing operations (for example, sending an email) and is called once after all batchesare processed.

Batch Apex class template:
```
global class MyBatchClass implements Database.Batchable<sObject> {
    global (Database.QueryLocator | Iterable<sObject>) start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
    }
    global void execute(Database.BatchableContext bc, List<P> records){
        // process each batch of records
    }    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }    
}
```

## Invoking a Batch Class
Instantiate it and then call ```Database.executeBatch``` with the instance:
```
MyBatchClass myBatchObject = new MyBatchClass(); 
Id batchId = Database.executeBatch(myBatchObject);
```

Optional: pass in ```scope``` parameter to specify the number of records that should be passed into the execute method for each batch. TIP limit this batch size if running into governor limits.
```
Id batchId = Database.executeBatch(myBatchObject, 100);
```

Track job progress: Each batch Apex invocation creates an AsynceApexJob record to view progress via SOQL or manage job in the Apex Job Queue.
```
AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID = :batchId ];
```



