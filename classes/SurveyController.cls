public class SurveyController {
    public List<String> categories {get; set;}
    public Inspection__c inspection {get; set;}
    public Survey__c survey {get; set;}
    public List<Survey_Response__c> responses {get; set;}
    public String answeredResponses {get; set;}
    public Attachment image {get; set;}
    public String state {get; set;}
    
    public SurveyController() {
        image = new Attachment();
        answeredResponses = '';
        String inspectionId = ApexPages.currentPage().getParameters().get('insp');
        inspection = [SELECT Id, Completed_Date__c, (SELECT Id FROM Surveys__r), Store__c FROM Inspection__c WHERE Id =:inspectionId  LIMIT 1];
        prepareCategories();
    }
    
    private void prepareCategories() {
        //Get all categories
        Schema.DescribeFieldResult fieldResult = Survey_Question__c.Category__c.getDescribe();
        List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();
        categories = new List<String>();
        for (Schema.PicklistEntry entry : entries) {
            categories.add(entry.value);
        }
        
        //categories.sort();
    }
    
    public void prepareData() {
        if (inspection.surveys__r == null || inspection.surveys__r.size() == 0) {
            survey = new Survey__c();
            survey.Inspection__c = inspection.id;

            insert(survey);

            List<Survey_Question__c> questions = [SELECT Id FROM Survey_Question__c ORDER BY Order__c];
            responses = new List<Survey_Response__c>();
            for (Survey_Question__c q : questions) {
                Survey_Response__c resp = new Survey_Response__c();
                resp.Survey__c = survey.id;
                resp.Question__c = q.id;
                responses.add(resp);
            }

            insert(responses);   

            reloadResponses();
        } else {
            survey = inspection.surveys__r[0];
            reloadResponses();
            if (responses.size() == 0) {
                delete(survey);
                inspection = [SELECT Id, Completed_Date__c, (SELECT Id FROM Surveys__r), Store__c FROM Inspection__c WHERE Id =:inspection.Id  LIMIT 1];                        
                prepareData();
            }
        }
    }
    
    private void reloadResponses() {
            responses = [SELECT Id, Passed__c, Comments__c, Answered__c,
                            Question__c, Question__r.Question__c, Question__r.Category__c, Question__r.Order__c,
                            (SELECT id FROM Attachments)
                         FROM Survey_Response__c
                         WHERE Survey__c = :survey.id
                         ORDER BY Question__r.Order__c];                         

    }

    private void checkAnswered() {
        Set<String> ids = new Set<String>(answeredResponses.split(','));
        for (Survey_Response__c response : responses) {
            if (ids.contains(response.id) && !response.answered__c) {
                response.answered__c = true;
            }
        }
    }
    
    public Integer getRespondedPercentage() {
        if (responses != null) {
            Decimal count = 0;
            for (Survey_Response__c response : responses) {
                if (response.answered__c) {
                    count++;
                }
            }
            
            return Math.round((count / responses.size()) * 100);
        }
        
        return -1;
    }
    
    public void save() {
        checkAnswered();
        update(responses);
        
        for (Survey_Response__c response : responses) {
            if (response.answered__c == false) {
                return;
            }
        }
        
        inspection.completed_date__c = Date.today();
        update(inspection);
    }

    public void upload() {
        if (image.parentId != null && image.body != null && image.name != null) {
            insert(image);
            image = new Attachment();

            reloadResponses();
        }
    }
}