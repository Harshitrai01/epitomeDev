({
    // Method to call when the component is initialized
    doInit: function(component, event, helper) {
        var action = component.get("c.getCurrentUserStatus");
        
        // Set callback function to handle the response
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var userStatus = response.getReturnValue(); // Get the status value
                component.set("v.userStatus", userStatus); // Optionally store it in an attribute
                
                // Update the utility bar label with emojis
                var utilityAPI = component.find("utilitybar");
                utilityAPI.setUtilityLabel({
                    label: helper.getStatusLabelWithEmoji(userStatus)
                });
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    console.error("Error message: " + errors[0].message);
                } else {
                    console.error("Unknown error while fetching User Status.");
                }
            }
        });
        
        // Enqueue the action
        $A.enqueueAction(action);
    },

    // Method to handle value change from LWC
    getValueFromLwc: function(component, event, helper) {
        var updatedStatus = event.getParam('value'); // Get the updated status from LWC
        component.set("v.userStatus", updatedStatus);

        // Update the utility bar label with emojis
        var utilityAPI = component.find("utilitybar");
        utilityAPI.setUtilityLabel({
            label: helper.getStatusLabelWithEmoji(updatedStatus)
        });
    }
})