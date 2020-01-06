global class LocationServices {
    public class Location {
        public Decimal longitude {get; set;}
        public Decimal latitude {get; set;}
        public Decimal postalCode {get; set;}
    }
    
    @future (callout=true)
    public static void asyncLocate(string storeId) {
        LocationServices.locate(storeId);
    } 
    
    webservice static string locateAll(string storeIds) {
    	if (storeIds == null) {
    		return 'Error: you must provide an id';	
    	}
    	
        List<string> ids = storeIds.split(',');
        if (ids.size() > 10) {
            return 'Max number of locations is 10.';
        }
        
        List<Store__c> stores = [SELECT Id, Address__c, City__c, Postal_Code__c, Location__latitude__s, Location__longitude__s 
                             	 FROM Store__c
                               	 WHERE Id IN :ids];
        
        System.debug('Stores: ' + stores.size());
        
        Map<Store__c, Location> locs = new Map<Store__c, Location>();
        for (Store__c store : stores) {
            Location loc = new Location();
            string error = LocationServices.getLocation(store, loc);
            if (error != null) {
                return error;
            } else {
                locs.put(store, loc);
            }
        }
        
        for (Store__c store : locs.keySet()) {
            Location loc = (Location)locs.get(store);
            store.Location__Latitude__s = loc.latitude;
            store.Location__Longitude__s = loc.longitude;
            //store.Postal_Code__c = loc.postalCode;
        }
    
        update(stores);        
        return (stores.size() + ' stores successfully located.');
    }

    webservice static string locate(string storeId) {
        String res = locateAll(storeId);
        if (res.startsWithIgnoreCase('error')) {
        	return 'error';
        } else {
        	return res;
        }
    }
    
    public static string getLocation(Store__c store, Location loc) {
        string address = store.Address__c + ' ' + store.City__c  + ' ' + store.Postal_Code__c;
        address = EncodingUtil.urlEncode(address, 'UTF-8');
        System.debug('Address: ' + address);
        System.debug('Store: ' + store.Location__latitude__s + ' - ' + store.Postal_Code__c);
        
        String url = 'https://maps.googleapis.com/maps/api/geocode/json?address=' + address + '&sensor=false'; //&key=AIzaSyDEyp_6H7giIRfs373vsGDvLJLeJ8lUqSA';
    
        System.debug(url);
        http http = new http();
        HttpRequest request =  new HttpRequest();
        HttpResponse response = new HttpResponse();
        request.setMethod('GET');
        request.setEndPoint(url);
        
        try {
            response = http.send(request);
            System.debug('JSON response (location): ' + response.getBody());
            if (response.getStatusCode() == 200) {
                Map<String, Object> rMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                if (rMap != null && rMap.containsKey('results')) {
                    Map<String, Object> resMap = (Map<String, Object>)((List<Object>)rMap.get('results'))[0];
                    if (resMap.containsKey('address_components')) {
                        List<Object> aComps = (List<Object>)resMap.get('address_components');
                        for (Object comp : aComps) {
                            Map<String, Object> compMap = (Map<String, Object>)comp;
                            List<Object> types = (List<Object>)compMap.get('types');
                            String type = (String)types.get(0);
                            if ('postal_code'.equals(type)) {
                                //loc.codigoPostal = Integer.valueOf(compMap.get('long_name'));
                                System.debug('CP: ' + loc.postalCode);
                            }
                        }
                    }
                    
                    if (resMap.containsKey('geometry')) {
                        resMap = (Map<String, Object>)resMap.get('geometry');
                        resMap = (Map<String, Object>)resMap.get('location');
                        loc.latitude = (Decimal)resMap.get('lat');
                        loc.longitude = (Decimal)resMap.get('lng');
                        return null;
                    }
                }
                
                return 'Unable to locate store.';
            } else {
                Map<String, Object> errorMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                System.debug(String.valueOf(errorMap));
                return 'Error getting events [' + response.getStatusCode() + ']: ' + errorMap;
            }
        } catch(Exception e) {
            System.debug(response + ',' + e.getMessage());
            return 'Error getting events: ' + e;
        }        
    }
}