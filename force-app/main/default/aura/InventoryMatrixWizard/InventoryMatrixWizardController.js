({
    init: function (cmp, evt, helper) {
        var myPageRef = cmp.get("v.pageReference");
        var propertyValue = myPageRef.state.c__recordId;
        cmp.set("v.propertyValue", propertyValue);
        cmp.set("v.showComponent", true);
    }
})