public with sharing class UnitInventoryScreenController {
    @AuraEnabled(cacheable=true)
    public static List<Unit_Inventory_Specifications__c> getTableDimensions() {
        return [SELECT Name, Height__c, Width__c, Available_Plot__c, Booked_Plot__c, Hold_Plot__c, Road__c, Garden__c, Blocked_Plot__c, Management_Blocked_Plot__c,
                Mortgage_Plot__c, Not_For_Sale_Plot__c, Registered_Plot__c, Sold_Plot__c, Temp_Blocked_Plot__c, Multi_Select_Color__c
                FROM Unit_Inventory_Specifications__c 
                WHERE Name = 'Box Specification'];
    }
    @AuraEnabled(cacheable=true)
    public static List<Unit__c> searchPlots(String plotName, String phaseId) {
        // Query to search for plots by name
        if (String.isNotBlank(plotName) && plotName.length() >= 3) {
            String searchTerm = '%' + plotName + '%';  // Wildcard for partial matching
            List<Unit__c> plots = [SELECT Id, Name, Base_Price_per_Sq_Ft__c, Plot_Price__c, RecordType.Name, Status__c, Phase__r.Name, Plot_Size__c, Plot_Facing__c
                                    FROM Unit__c 
                                    WHERE Name LIKE :searchTerm AND Phase__c =: phaseId LIMIT 50];
            return plots;
        }
        // If no search term is provided or less than 3 characters, return first 4 plots
        List<Unit__c> plots = [SELECT Id, Name, Base_Price_per_Sq_Ft__c, Plot_Price__c, RecordType.Name, Status__c, Phase__r.Name, Plot_Size__c, Plot_Facing__c
                                FROM Unit__c 
                                WHERE Phase__c =: phaseId LIMIT 50];  // Fetch first 4 plots
        return plots;
    }
    @AuraEnabled
    public static boolean updatePlotStatus(Map<Id, String> plotStatusMap) {
        if (plotStatusMap == null || plotStatusMap.isEmpty()) {
            return false;
        }
        List<Unit__c> plotsToUpdate = new List<Unit__c>();
        for (Id plotId : plotStatusMap.keySet()) {
            plotsToUpdate.add(new Unit__c(Id = plotId, Status__c = plotStatusMap.get(plotId)));
        }
        try {
            if (!plotsToUpdate.isEmpty()) {
                update plotsToUpdate;  // Bulk update in a single DML operation
            }
            return true;
        } catch (DmlException e) {
            System.debug('Error updating plots: ' + e.getMessage());
            return false;
        }
    }
    @AuraEnabled
    public static Unit__c getCellData(String plotId) {
        Unit__c plotData = [SELECT Id, Name, Base_Price_per_Sq_Ft__c, Plot_Price__c, RecordType.Name, Status__c, Phase__r.Name, Plot_Size__c, Plot_Facing__c
                                FROM Unit__c 
                                WHERE Id =: plotId];
        return plotData;
    }
}