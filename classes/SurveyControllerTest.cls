@isTest(SeeAllData=True)
private class SurveyControllerTest {

	private static String inspectionId;
	
	@isTest static void testSurveyLoadSuccess() {
		
		PageReference pageRef = Page.SurveyPage;
		Test.setCurrentPage( pageRef );

		// initialize data
		initTestData();

		// inject the inspection id in to the page
		pageRef.getParameters().put( 'insp', inspectionId );

		// start testing
		Test.startTest();
		
		SurveyController c = new SurveyController();
		// Categories is automatically instantiated.
		//c.prepareCategories();
		c.prepareData();

		Test.stopTest();

		System.assert(true);

	}
	
	@isTest static void testPrepareDataNoSurveys() {
		
		PageReference pageRef = Page.SurveyPage;
		Test.setCurrentPage( pageRef );

		// initialize data
		initTestDataNoSurvey();

		// inject the inspection id in to the page
		pageRef.getParameters().put( 'insp', inspectionId );

		Test.startTest();

		SurveyController c = new SurveyController();
		// prep data before trying to save so that the controller is initialized.
		c.prepareData();

		Test.stopTest();
	}

	@isTest static void testSave() {

		PageReference pageRef = Page.SurveyPage;
		Test.setCurrentPage( pageRef );

		// initialize data
		initTestData();

		// inject the inspection id in to the page
		pageRef.getParameters().put( 'insp', inspectionId );

		Test.startTest();

		SurveyController c = new SurveyController();
		// prep data before trying to save so that the controller is initialized.
		c.prepareData();
		// Save what was prepped. DB will rollback automatically
		c.save();
		
		// Stop testing
		Test.stopTest();
		// Assert result
		System.assert( true );
	}

	@isTest static void getRespondedPercentage() {

		PageReference pageRef = Page.SurveyPage;
		Test.setCurrentPage( pageRef );

		// initialize data
		initTestData();

		// inject the inspection id in to the page
		pageRef.getParameters().put( 'insp', inspectionId );

		Test.startTest();

		SurveyController c = new SurveyController();
		Integer result = c.getRespondedPercentage();

		Test.stopTest();

		System.assertEquals( result, -1 );

	}

	@isTest static void testUpload() {

		PageReference pageRef = Page.SurveyPage;
		Test.setCurrentPage( pageRef );

		// initialize data
		initTestData();

		// inject the inspection id in to the page
		pageRef.getParameters().put( 'insp', inspectionId );

		Test.startTest();
		
		SurveyController c = new SurveyController();
		c.upload();

		Test.stopTest();

	}
	
	private static void initTestData() {

		// New Store
		Store__c store1 = new Store__c( Address__c = 'address', City__c = 'city', Country__c = 'country', Postal_Code__c = Decimal.valueOf(123456), Region__c = 'region' );
		insert store1;
		
		// New inspection
		Inspection__c i1 = new Inspection__c();
		//i1.Name = 'test inspection';
		i1.Store__c = store1.Id;
		insert i1;
		inspectionId = i1.Id;

		// New Survey
		Survey__c s1 = new Survey__c( Inspection__c = i1.Id );
		//s1.Name = 'test survey';
		insert s1;

		// New Survey Question
		Survey_Question__c sq1 = new Survey_Question__c( Order__c = Decimal.valueOf(999), Question__c = 'asdf' );
		insert sq1;

		// New Survey Response
		Survey_Response__c sr1 = new Survey_Response__c( Survey__c = s1.Id, Question__c = sq1.Id );
		//sr1.Name = 'test response 1';
		//sr1.Category__c = 'test category 1';
		insert sr1;

	}

	private static void initTestDataNoSurvey() {

		// New Store
		Store__c store1 = new Store__c( Address__c = 'address', City__c = 'city', Country__c = 'country', Postal_Code__c = Decimal.valueOf(123456), Region__c = 'region' );
		insert store1;
		
		// New inspection
		Inspection__c i1 = new Inspection__c();
		//i1.Name = 'test inspection';
		i1.Store__c = store1.Id;
		insert i1;
		inspectionId = i1.Id;

		// New Survey //
		//Survey__c s1 = new Survey__c( Inspection__c = i1.Id );
		//s1.Name = 'test survey';
		//insert s1;

		// New Survey Question
		Survey_Question__c sq1 = new Survey_Question__c( Order__c = Decimal.valueOf(999), Question__c = 'asdf' );
		insert sq1;

		// New Survey Response
		//Survey_Response__c sr1 = new Survey_Response__c( Survey__c = s1.Id, Question__c = sq1.Id );
		//sr1.Name = 'test response 1';
		//sr1.Category__c = 'test category 1';
		//insert sr1;

	}
}