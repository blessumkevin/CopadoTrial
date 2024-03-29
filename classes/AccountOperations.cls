public class AccountOperations {
    Public static Account setDefaultDescription(Account a){
        If (a.Description != null) return a;
        Else {
            a.Description = 'Default description';
            return a;
        }
    }
       //New methods introduced by Developer 1 working on the US-003
       //testing once again
    public static Account setDefaultBillingAddress(Account a){
        a.billingstreet = 'Po Castellana, 77 5th floor'; // DEV 1 updates
        a.billingstate = 'Madrid';
        a.billingpostalcode ='28046'; // DEV 2 updates
        return a;
    }
    public static Account setDefaultShippingAddress(Account a){
        a.shippingstreet = 'Po Castellana, 77 5th floor'; // DEV 1 updates
        a.shippingstate = 'Madrid';
        a.shippingpostalcode ='28046'; // DEV 2 updates
        return a;
    }
    public static Account setDefaultPhone(Account a) {//DEV 1
        a.Phone='611111111'; // DEV 1 updates
        return a;
    }
    public static Account setDefaultURL(Account a) { //DEV 1
        a.website = 'www.copado-enterprise.com'; // DEV 1 updates
        return a;
    }
}