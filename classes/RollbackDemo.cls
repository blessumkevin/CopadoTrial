public class RollbackDemo {
   Public static Account setDefaultDescription(Account a){
       If (a.Description != null) return a;
         Else {
                a.Description = 'Dev1 Version';    
                return a;
              }
           }
           }