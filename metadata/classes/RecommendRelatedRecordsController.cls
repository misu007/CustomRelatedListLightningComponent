public with sharing class RecommendRelatedRecordsController {
    
    // Get Field Lables
    @AuraEnabled
    public static Map<String, String> getLabels(List<String> rFields, String rTargetObject){   
        Map<String, String> fmaps = new Map<String, String>();        
        Map<String, Schema.SObjectField> gf = Schema.getGlobalDescribe().get(rTargetObject).getDescribe().fields.getMap();
        for(String fld : rFields){
            String tmpVal = '';
           	String aa = fld;
            if (fld.contains('.')){
                List<String> splits = fld.split('\\.');
                aa = splits.get(0);
            }
            try {
                tmpVal = gf.get(aa).getDescribe().getLabel();
            } catch (Exception ex){
                tmpVal = '---';
            }
           
            fmaps.put(fld, tmpVal);
        }
        return fmaps;
    }
    
    // Get Filtered Records of Target Object    
    @AuraEnabled
    public static List<Sobject> getRecords(String rThisObject, String rThisId, String rThisField, List<String> rFields, String rTargetObject, String rTargetField, String orderString){
        List<Sobject> results;        
        try {
            String query0 = '';
            query0 = 'SELECT ' + rThisField + ' FROM ' + rThisObject + ' WHERE Id = \'' + rThisId + '\' LIMIT 1';
            Sobject so = database.query(query0);
            Map<String, Object> fieldsToValue = so.getPopulatedFieldsAsMap();
            String query = '';
            String thisValue = String.valueOf(fieldsToValue.get(rThisField));
            query = 'SELECT Id, ' + String.join(rFields, ', ') + ' FROM ' + rTargetObject + ' WHERE Id <>\'' + rThisId + '\' AND ' + rTargetField + ' = \'' + thisValue + '\'';        
            if(orderString != null && orderString.length() > 3){
                query += ' ORDER BY ' + orderString;
            }
            results = database.query(query);
        } catch (Exception ex){
            results = null;
        }
        return results;
    }
    
    // Get Filtered Records of Target Object    
    @AuraEnabled
    public static List<Sobject> getRecords2(String rThisObject, String rThisId, List<String> rThisFields, List<String> rFields, String rTargetObject, List<String> rTargetFields, String orderString, List<String> conditions){
        List<Sobject> results;        
        try {
            Integer minSize = rThisFields.size();
            if (minSize > rTargetFields.size()){
                minSize = rTargetFields.size();
            }
            String query0 = '';
            List<String> tFlds = new List<String>();
            for (String rThisField : rThisFields){
                if (rThisField.contains('"') == false){
                    tFlds.add(rThisField);
                }
            }
            Map<String, String> fmaps = new Map<String, String>();        
            Map<String, Schema.SObjectField> gf = Schema.getGlobalDescribe().get(rTargetObject).getDescribe().fields.getMap();
            Map<String, Object> fieldsToValue = new Map<String, Object>();
            if(tFlds.size() > 0){
                query0 = 'SELECT ' + String.join(tFlds, ', ') + ' FROM ' + rThisObject + ' WHERE Id = \'' + rThisId + '\' LIMIT 1';
                Sobject so = database.query(query0);
                fieldsToValue = so.getPopulatedFieldsAsMap();
            }
            String query = '';
            query = 'SELECT Id, ' + String.join(rFields, ', ') + ' FROM ' + rTargetObject + ' WHERE Id <>\'' + rThisId + '\'';
            for (Integer i = 0; i < minSize; i++){
                Boolean tActive = true;
                String condition;
                if (conditions.size() > i){
                    condition = conditions.get(i);
                } else {
                    condition = '=';
                }                
                String tValue = '';
                Object rawValue;                
                if (rThisFields.get(i).contains('"')){
                    rawValue = rThisFields.get(i).replaceAll('\"', '');
                } else {
                    rawValue = fieldsToValue.get(rThisFields.get(i));
                }
                Schema.DisplayType dtype = gf.get(rTargetFields.get(i)).getDescribe().getType();
                if (rawValue == null || String.valueOf(rawValue).length() < 1) {
                    tValue = 'null';
                    if (condition != '='){
                        tActive = false;
                    }
                } else if (dtype == Schema.DisplayType.Integer || dtype == Schema.DisplayType.Currency || dtype == Schema.DisplayType.Double || dtype == Schema.DisplayType.Percent){
                    tValue = String.valueOf(rawValue);                    
                } else if (dtype == Schema.DisplayType.Boolean ){
                    tValue = String.valueOf(rawValue);                    
                } else if (dtype == Schema.DisplayType.DateTime){
                    if (rThisFields.get(i).contains('"')){
                        String ttt = String.valueOf(rawValue);
                        if (ttt.length() < 12){
                            ttt += ' 00:00:00';
                        }
                        Datetime dt = datetime.valueOf(ttt);
                        tValue = dt.format('yyyy-MM-dd') + 'T' + dt.format('hh:mm:ss') + 'Z';
                    } else {
                        Datetime dt = Datetime.valueOf(rawValue);
                        tValue = dt.format('yyyy-MM-dd') + 'T' + dt.format('hh:mm:ss') + 'Z';
                    }
                } else if (dtype == Schema.DisplayType.Date){
                    if (rThisFields.get(i).contains('"')){
                        tValue = String.valueOf(rawValue);
                    } else {
                        Date dte = Date.valueOf(rawValue);
                        String sMonth = String.valueof(dte.month());
                        String sDay = String.valueof(dte.day());
                        if(sMonth.length() == 1){
                            sMonth = '0' + sMonth;
                        }
                        if(sDay.length() == 1){
                            sDay = '0' + sDay;
                        }
                        tValue = String.valueOf(dte.year()) + '-' + sMonth + '-' + sDay;
                    }
                } else {
                    tValue = '\'' + String.valueOf(rawValue) + '\'';
                }
                if (tActive){
                    query += ' AND ' + rTargetFields.get(i) + ' ' + condition + ' ' + tValue;
                }
            }            
            if(orderString != null && orderString.length() > 3){
                query += ' ORDER BY ' + orderString;
            }
            System.debug('query : ' + query);
            results = database.query(query);
        } catch (Exception ex){
            results = null;
        }
        return results;
    }
    
}