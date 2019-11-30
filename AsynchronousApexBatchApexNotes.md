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

Optional: pass in ```scope``` parameter to specify the number of records that should be passed into the execute method for each batch. TIP! limit this batch size if running into governor limits.
```
Id batchId = Database.executeBatch(myBatchObject, 100);
```

Track job progress: Each batch Apex invocation creates an AsynceApexJob record to view progress via SOQL or manage job in the Apex Job Queue.
```
AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID = :batchId ];
```

## Using State in Batch Apex
Stateless - each execution of a batch Apex job is considered a discrete transaction. 
Example: a batch Apex job that contains 1,000 records and uses the default batch size is considered five transactions of 200 records each.

```Database.Stateful```
If specified in the class definition, can maintain state across all transactions. Only instance member variables retain their values between transactions. Maintaining state is useful for counting or summarizing records as they are processed. 

#### Example: Business requirement: all contacts for companies in the USA must have their parent company's billing address as their mailing address. Write a Batch Apex class that ensures that this requirement is enforced. Update contact records in batch job and keep track of the total records affected and include it in the notification email. 

To do: Find all account records that are passed in by the ```start()``` method using ```QueryLocator``` and update the associated contacts with their account's mailing address. Finally, sends of an email with the results of the bulk job, using ```Database.Stateful``` to track state, the number of records updated. 

```
global class UpdateContactAddresses implements 
    Database.Batchable<sObject>, Database.Stateful {
    
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID, BillingStreet, BillingCity, BillingState, ' +
            'BillingPostalCode, (SELECT ID, MailingStreet, MailingCity, ' +
            'MailingState, MailingPostalCode FROM Contacts) FROM Account ' + 
            'Where BillingCountry = \'USA\''
        );
    }
    global void execute(Database.BatchableContext bc, List<Account> scope){
        // process each batch of records
        List<Contact> contacts = new List<Contact>();
        for (Account account : scope) {
            for (Contact contact : account.contacts) {
                contact.MailingStreet = account.BillingStreet;
                contact.MailingCity = account.BillingCity;
                contact.MailingState = account.BillingState;
                contact.MailingPostalCode = account.BillingPostalCode;
                // add contact to list to be updated
                contacts.add(contact);
                // increment the instance member counter
                recordsProcessed = recordsProcessed + 1;
            }
        }
        update contacts;
    }    
    global void finish(Database.BatchableContext bc){
        System.debug(recordsProcessed + ' records processed. Shazam!');
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];
        // call some utility to send email
        EmailUtils.sendMessage(job, recordsProcessed);
    }    
}
```

Code explained: 
1. ```start``` method provides the collection of all records that the ```execute``` method will process as individual batches. It returns the list of records to be processed by calling ```Database.getQueryLocator``` with a SOQL query. Simply quering for all Account records with a BillingCountry of 'USA'.
2. each batch of 200 records is passed in the second parameter of the ```execute``` method. The ```execute``` method sets each contact's mailing address to the accounts billing address and increments ```recordsProcessed``` to track the number of records processed.
3. When the job is complete, ```finish``` method performs a query on the AsyncApexJob object (a table that lists information about batch jobs) to get the status of the job, the submitter's email address, and some other information. It then sends a notification email to the job submitter that includes the job info and number of contacts updated.

#### Testing Batch Apex
To do: Insert some records, call the Batch Apex class and then assert that the records were updated properly with the correct address.

```
@isTest
private class UpdateContactAddressesTest {
    @testSetup 
    static void setup() {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        // insert 10 accounts
        for (Integer i=0;i<10;i++) {
            accounts.add(new Account(name='Account '+i, 
                billingcity='New York', billingcountry='USA'));
        }
        insert accounts;
        // find the account just inserted. add contact for each
        for (Account account : [select id from account]) {
            contacts.add(new Contact(firstname='first', 
                lastname='last', accountId=account.id));
        }
        insert contacts;
    }
    static testmethod void test() {        
        Test.startTest();
        UpdateContactAddresses uca = new UpdateContactAddresses();
        Id batchId = Database.executeBatch(uca);
        Test.stopTest();
        // after the testing stops, assert records were updated properly
        System.assertEquals(10, [select count() from contact where MailingCity = 'New York']);
    }
    
}
```

Test Code explained:
1. ```setup``` method inserts 10 account records with the billing city of 'New York' and the billing country of 'USA'. Then for each account, it creates an associated contact record. This data is used by the batch class. TIP! make sure that the number of records inserted is less than the batch size of 200 because test methods can execute only one batch total.
2. In the test method, the ```UpdateContactAddresses``` batch class is instantiated, invoked by calling ```Database.executeBatch``` and passing in the instance of the batch class.
3. The call to ```Database.executeBatch``` is included within the ```Test.startTest``` and ```Test.stopTest``` block. This is where all of the magic happens. The job executes after the call to ```Test.stopTest```. Any asynchonous code included within ```Test.startTest``` and ```Test.stopTest``` is executed synchronously after ```Test.stopTest```.
4. Finally, the test verifies that all contact records were updated correctly by checking that the number of contact records with the billing city of 'New York' matches the number of records inserted (ie. 10).