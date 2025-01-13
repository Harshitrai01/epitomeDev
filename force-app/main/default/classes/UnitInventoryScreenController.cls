public with sharing class UnitInventoryScreenController {
    @AuraEnabled(cacheable=true)
    public static List<Unit_Inventory_Box_Dimensions__c> getTableDimensions() {
        return [SELECT Name, Height__c, Width__c FROM Unit_Inventory_Box_Dimensions__c WHERE Name = 'Box Dimension'];
    }
}