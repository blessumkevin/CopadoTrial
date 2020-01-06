global class InspectionServices {
    
	webservice static string completeSurveys(String ids) {
    	if (ids == null) {
    		return 'Error: you must provide an id';	
    	}
    	
        List<string> iids = ids.split(',');
        return complete([SELECT Passed__c, Answered__c, Survey__r.Inspection__c 
                         FROM Survey_Response__c 
                         WHERE Survey__r.Inspection__c in :iids]);
    }
    
    webservice static string completeAllPendingSurveys() {
		return complete([SELECT Passed__c, Answered__c, Survey__r.Inspection__c 
                         FROM Survey_Response__c 
                         WHERE Survey__r.Inspection__r.Completed_Date__c = null]);                
    }
    
    private static string complete(List<Survey_Response__c> resps) {
        Set<id> inspectionIds = new Set<id>();
        
        for (Survey_Response__c r : resps) {
            r.Passed__c = Math.random() > .33;
            r.Answered__c = true;
            inspectionIds.add(r.Survey__r.Inspection__c);
        }
        
        update(resps);
        
        List<Inspection__c> inspections = [Select Completed_Date__c  from Inspection__c where id in :inspectionIds];
        for (Inspection__c s : inspections) {
            s.Completed_Date__c  = Date.today();
        }
        
        try {
	        update (inspections);
            return inspections.size() + ' inspections completed sucessfully.';
        } catch (Exception e) {
            return 'Error: ' + e;
        }
    }
}