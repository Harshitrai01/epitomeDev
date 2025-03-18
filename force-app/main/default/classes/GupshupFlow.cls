/**
* Author: Harshit Kumar Rai
* Description: For calling Gupshup Flow For Sending Messages
*/
public class GupshupFlow {
    public static void callGupshupSubFlow(Sobject obj, String flowConfigName){
        try{
            Map<String, Object> flowInputs = new Map<String, Object>{
            	'recordId' => obj,
                'flowName' => flowConfigName
        	};
			Flow.Interview myFlow = Flow.Interview.createInterview('Gupshup_Send_Cancellation_Email', flowInputs);
        	myFlow.start();
        }catch(Exception ex){
            System.Debug('Error In Calling Sub Flow :'+ex.getMessage());
            throw New AuraHandledException(ex.getMessage());
        }
    }
}