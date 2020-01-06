public class SelectInspectionController {
    private boolean locate;

    public boolean located {get; set;}
    public Decimal latitude {get; set;}
    public Decimal longitude {get; set;}

    public List<Inspection__c> inspections {get; set;}
    public List<Store__c> stores {get; set;}

    public String inspection {get; set;}
    public String store {get; set;}
    public List<SelectOption> inspectionOptions {get; set;}
    public List<SelectOption> storeOptions {get; set;}
    
    public SelectInspectionController() {
        String loc = ApexPages.currentPage().getParameters().get('loc');
        locate = loc == null || loc != 'false';
        if (!locate) {
            latitude = 40.416646;
            longitude = -3.703818;
        }
        
        located = !locate;
        if (located) {
            prepareData();
        }
    }
    
    public void prepareData() {
        located = true;

        //Recuperar inspecciones no completadas ordenadas por 'outstanding' y por distancia a la localizaci?n actual (si hay localizaci?n)
        String q1 = 'SELECT Id, Store__c, Store__r.Name, Scheduled_Date__c, Completed_Date__c, Scheduled__c, Outstanding__c ' +
                    'FROM Inspection__c ' + 
                    'WHERE User__c = \'' + UserInfo.getUserId() + '\' AND Completed__c = false ' + 
                    'ORDER BY Outstanding__c DESC ';
        
        if (latitude != null && longitude != null) {
            q1 +=      ', DISTANCE(Store__r.Location__c, GEOLOCATION(' + latitude + ',' + longitude + '), \'km\')';
        }
        
        List<sObject> objs1 = Database.query(q1);
        inspections = new List<Inspection__c>();
        inspectionOptions = new List<SelectOption>();
        for (sObject o : objs1) {
            Inspection__c i = (Inspection__c)o;
            inspections.add(i);
            String dateStr = i.Scheduled_Date__c != null ? ((DateTime)i.Scheduled_Date__c).format('dd/MM/yyyy') : 'Not Scheduled';
            inspectionOptions.add(new SelectOption(i.id, i.Store__r.Name + ' (' + dateStr + ')'));
        }
        
        if (inspections.size() > 0) {
            inspection = inspections[0].id;
        }                               

        //Recuperar lista de tiendas ordenadas por distancia (si hay localizaci?n)
        //TODO Mostrar las tiendas favoritas primero
        String q2 = 'SELECT Id, Name, Location__latitude__s, Location__longitude__s ' + 
                    'FROM Store__c ';

        if (latitude != null && longitude != null) {
            q2 += ' ORDER BY DISTANCE(Location__c, GEOLOCATION(' + latitude + ',' + longitude + '), \'km\')';
        } else {
            q2 += ' ORDER BY Name';
        }
        
        List<sObject> objs2 = Database.query(q2);
        storeOptions = new List<SelectOption>();
        stores = new List<Store__c>();
        for (sObject o : objs2) {
            Store__c s = (Store__c)o;
            stores.add(s);
            storeOptions.add(new SelectOption(s.id, s.name));
        }

        if (stores.size() > 0) {
            store = stores[0].id;
        }
    }
    
    public PageReference processInspection() {    
        PageReference pr = Page.SurveyPage;
        pr.getParameters().put('insp', inspection);
        return pr;
    }

    public PageReference processStore() {
        Integer count = [SELECT Count() FROM Inspection__c WHERE Store__c = :store AND User__c = :UserInfo.getUserId() AND Completed__c = false];
        if (count > 0) {
            Inspection__c i = [SELECT Id FROM Inspection__c WHERE Store__c = :store AND User__c = :UserInfo.getUserId() AND Completed__c = false LIMIT 1];
            this.inspection = i.id;
        } else {
            Inspection__c i = new Inspection__c();
            i.User__c = UserInfo.getUserId();
            i.Store__c = store;
            insert(i);
            
            this.inspection = i.id;
        }

        return processInspection();
    }
}