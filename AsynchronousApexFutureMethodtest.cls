//Apex text class = AccountProcessorTest with 100% coverage
@IsTest
public class AccountProcessorTest {
    public static testmethod void TestAccountProcessorTest() {
        //create new account
        Account a = new Account();
        a.Name = 'Test Account';
        Insert a;
        
        //create new contact
        Contact cont=New Contact();
        cont.FirstName = 'Bob';
        cont.LastName = 'Smith';
        cont.AccountId = a.Id;
        Insert cont;
    
        //tests the countContacts Set
        //add the above account and contact to the Set
        Set<Id> setAccId = new Set<Id>();
        SetAccId.add(a.Id);
        
        //run the Test
        Test.startTest();
        	AccountProcessor.countContacts (setAccId);
        Test.stopTest();
        
        Account acc = [Select Number_of_Contacts__c from Account Where Id=:a.Id LIMIT 1];
        System.assertEquals (Integer.valueOf(acc.Number_of_Contacts__c),1);
    }
}

