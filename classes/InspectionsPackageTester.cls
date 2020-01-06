@IsTest(SeeAllData=true)
global class InspectionsPackageTester implements HttpCalloutMock {
    static testMethod void testPackage() {
        //Insert two stores
        Store__c store1 = new Store__c();
        store1.Address__c = 'Paseo de la Castellana 135';
        store1.City__c = 'Madrid';
        store1.Country__c = 'Spain';
        store1.Postal_Code__c = 28046;
        store1.Region__c = 'Madrid';
        
        Store__c store2 = new Store__c();
        store2.Address__c = 'Gran Via 1';
        store2.City__c = 'Madrid';
        store2.Country__c = 'Spain';
        store2.Postal_Code__c = 28013;
        store2.Region__c = 'Madrid';
        
        insert(store1);
        insert(store2);
        
        //Insert 3 questions
        Survey_Question__c q1 = new Survey_Question__c();
        q1.Order__c = -1;
        q1.Category__c = 'Store Appearance';
        q1.Question__c = 'q1?';
        
        Survey_Question__c q2 = new Survey_Question__c();
        q2.Order__c = -2;
        q2.Category__c = 'Security';
        q2.Question__c = 'q2?';

        Survey_Question__c q3 = new Survey_Question__c();
        q3.Order__c = -3;
        q3.Category__c = 'Systems';
        q3.Question__c = 'q3?';

        insert(q1);
        insert(q2);
        insert(q3);
        
        Inspection__c inspection = new Inspection__c();
        inspection.Store__c = store1.id;
        insert(inspection);
        
        Survey__c survey = new Survey__c();
        survey.inspection__c = inspection.id;
        insert(survey);
        
        Test.setMock(HttpCalloutMock.class, new InspectionsPackageTester());
        Test.startTest();
        //Test LocationServices
        LocationServices.locate(store1.id);
        LocationServices.locateAll(store1.id + ',' + store2.id);
        
        //Test SelectInspectionController
        SelectInspectionController ic = new SelectInspectionController();
        ic.prepareData();
        ic.processInspection();
        ic.processStore();
        
        //Test SurveyController
        Test.setCurrentPage(Page.SurveyPage);
        ApexPages.currentPage().getParameters().put('insp',inspection.id);
        
        SurveyController sc = new SurveyController();   
        sc.prepareData();
        sc.getRespondedPercentage();
        sc.upload();
        sc.save();
        
        //Test InspectionServices
        InspectionServices.completeAllPendingSurveys();
        InspectionServices.completeSurveys(inspection.id);
        
        Test.stopTest();
    }
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"results":[{"address_components":[{"long_name":"135","short_name":"135","types":["street_number"]},{"long_name":"Paseo de la Castellana","short_name":"Paseo de la Castellana","types":["route"]},{"long_name":"Madrid","short_name":"Madrid","types":["locality","political"]},{"long_name":"Madrid","short_name":"Madrid","types":["administrative_area_level_4","political"]},{"long_name":"Madrid","short_name":"M","types":["administrative_area_level_2","political"]},{"long_name":"Comunidad de Madrid","short_name":"Comunidad de Madrid","types":["administrative_area_level_1","political"]},{"long_name":"Spain","short_name":"ES","types":["country","political"]},{"long_name":"28046","short_name":"28046","types":["postal_code"]}],"formatted_address":"Paseo de la Castellana, 135, 28046 Madrid, Madrid, Spain","geometry":{"location":{"lat":40.4588521,"lng":-3.690981},"location_type":"ROOFTOP","viewport":{"northeast":{"lat":40.4602010802915,"lng":-3.689632019708498},"southwest":{"lat":40.45750311970851,"lng":-3.692329980291502}}},"types":["street_address"]}],"status":"OK"}');
        res.setStatusCode(200);
        return res;
    }    
}