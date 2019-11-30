//Set Class a collection of unique elements with no duplicate values
//documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_set.htm

//Apex class = AccountProcessor
public class AccountProcessor {
	//use @future
    @future
    //method = countContacts
    public static void countContacts(Set<id> setId) {
        //accepts a List of Account Ids
        //each Account Id, count # of contact records 'Number_of_Contacts__c'value
        List<Account> listAccount = [Select Id, Number_of_Contacts__c, (Select id from Contacts)
                                    from Account
                                    Where id in :setId];
        for (Account acc :listAccount) {
            List<Contact> listContact=acc.Contacts;
            
            acc.Number_of_Contacts__c = listContact.size();
        }
        update listAccount;
    }
    
}