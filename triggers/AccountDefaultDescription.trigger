trigger AccountDefaultDescription on Account (before insert) {
    for(Account a : Trigger.New) {
        a = AccountOperations.setDefaultDescription(a);
        a = AccountOperations.setDefaultURL(a);
        a = AccountOperations.setDefaultPhone(a);
        a = AccountOperations.setDefaultBillingAddress(a);
    } 
}