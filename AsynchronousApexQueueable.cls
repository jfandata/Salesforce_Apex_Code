//create a queueable apex class that inserts Contacts for Accounts
//create a queueable apex class that inserts the same Contact for each Account
//for a specific state. Write unit tests that achieve 100% code coverage for the class

//create Apex class 'AddPrimaryContact' that implements Queueable interface
//create a constructor for the class that accepts as its first argument a Contact sObject
//and a second argument as a string for the State abbreviation
//execute method must query max 200 accounts with the BillingState specified by the
//State abbreviation passed into the constructor and insert the Contact sObject
//record associated to eac Account. Look at the sObject clone() method

public class AddPrimaryContact implements Queueable {
	private Contact c;
    private String state;
    public AddPrimaryContact(Contact c, String state) {
        this.c = c;
        this.state = state;
    }
    public void execute (QueueableContext context){
        List<Account> listAccount = [SELECT Id, Name, (Select Id, FirstName, LastName from contacts)
                                    FROM Account WHERE BillingState =:state LIMIT 200];
        List<Contact> listContact = new List<Contact>();
        for(Account acc:listAccount) {
            Contact cont = c.clone(false,false,false,false);
            cont.AccountId = acc.Id;
            listContact.add(cont);
        }
        if(listContact.size() >0){
            insert listContact;
        }
    }
    
}