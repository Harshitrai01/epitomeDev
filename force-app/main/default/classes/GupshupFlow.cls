/*
*********************************************************
Apex Class Name    : GupshupFlow
Created Date       : [Insert Date]
@description       : This class is used to call the Gupshup subflow for sending messages. It integrates with the Gupshup 
                     platform to send messages via a Salesforce flow.
@author            : Harshit Kumar Rai
Modification Log:
Ver   Date         Author               Modification
1.0   [Insert Date] Harshit Kumar Rai   Initial Version
*********************************************************
*/
public class GupshupFlow {

    /*
    *********************************************************
    @Method Name    : callGupshupSubFlow
    @author         : Harshit Kumar Rai
    @description    : Calls the Gupshup subflow to send messages. It takes an SObject record and the name of the flow 
                       configuration as inputs and initiates the flow.
    @param          : obj - The SObject record to be passed to the flow.
    @param          : flowConfigName - The name of the flow configuration to be used.
    *********************************************************
    */
    public static void callGupshupSubFlow(SObject obj, String flowConfigName) {
        try {
            // Prepare inputs for the flow
            Map<String, Object> flowInputs = new Map<String, Object>{
                'recordId' => obj,
                'flowName' => flowConfigName
            };

            // Create and start the flow interview
            Flow.Interview myFlow = Flow.Interview.createInterview('Gupshup_Send_Cancellation_Email', flowInputs);
            myFlow.start();
        } catch (Exception ex) {
            // Log the error and throw an AuraHandledException
            System.debug('Error In Calling Sub Flow: ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }
}