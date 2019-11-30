//create an Apex test class called 'LeadProcessorTest'
//test class, insert 200 Lead records, execute the 'LeadProcessor' Batch class
//test that all Lead records were updated correctly
//unit tests must cover all lines of the code inlcuded in the LeadProcessor class, 100% code coverage

@isTest
public class LeadProcessorTest {
    static testMethod void testMethodLead() {
        List<Lead> listLead = new List<Lead>();
        for(Integer i=0; i<200; i++) {
            Lead lead = new Lead();
            lead.FirstName = 'FirstName';
            lead.LastName = 'LastName'+i;
            lead.Company = 'Company'+i;
            listLead.add(lead);            
        }
        insert listLead;
            
        Test.startTest();
        	LeadProcessor obj=new LeadProcessor();
        	Database.executeBatch(obj);
        Test.stopTest();
    }	
}