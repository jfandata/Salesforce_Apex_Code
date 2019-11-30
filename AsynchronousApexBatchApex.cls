//create an Apex class that uses Batch Apex to update Lead records
//create an Apex class that implements the Database.Batchable interface
//to update all Lead records in the org with a specific LeadSource.
//Write unit tests that achieve 100% code coverage for the class.

//create Apex class called 'LeadProcessor' that uses the Database.Batchable interface
//use QueryLocator in the start method to collect all Lead records in org
//the execute method must update all Lead records in the org with the LeadSource value of 'Dreamforce'

global class LeadProcessor implements
	Database.Batchable<sObject> {
        //start method
        global Database.QueryLocator start(Database.BatchableContext bc) {
            return Database.getQueryLocator([Select LeadSource from Lead]);
        }
        //execute method
        global void execute(Database.BatchableContext bc, List<Lead> scope) {
            for(Lead leads:scope) {
                leads.LeadSource = 'Dreamforce';
            }
            update scope;
        }
    	//finish method
        global void finish(Database.BatchableContext bc) {
        }
}