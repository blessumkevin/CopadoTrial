public class RollbackDemo {
   Public static Account setDefaultDescription(Account a){
       If (a.Description != null) return a;
         Else {
                a.Description = 'Original From UAT';    
                return a;
              }
           }
           }