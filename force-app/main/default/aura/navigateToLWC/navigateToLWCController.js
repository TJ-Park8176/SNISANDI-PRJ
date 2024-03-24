({
    init: function(component, event, helper) {
        var myPageRef = component.get("v.pageReference");
        var flagValue = myPageRef.state.c__flagValue;
        component.set("v.flagValue", flagValue);
    }

})