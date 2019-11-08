public class AccountOperations {
    public static Account setDefaultDescription(Account a) {        
        // If statements must use braces
        if (a.Description != null) return a;
	else a.Description = 'Default Description';
        
        // Avoid SOQL inside loops
        // Additional Comment to Review
         // Changes With State Farm
        // JM Family demo
        for (Integer i = 0; i < 10; i++) {
	    List<Account> accounts = [SELECT Id FROM Account];
	}
        
        // Avoid DML Statements inside loops
        for (Integer i = 0; i < 1; i++) {
	    update a;
	}
       	
        return a;
    }
}