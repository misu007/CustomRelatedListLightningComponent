({
    doInit : function(cmp, evt, helper) {
        helper.createVLabels(cmp, helper);
        helper.getLabels(cmp, helper);
    },
    clickRecord : function(cmp, evt, helper){
        var id = evt.currentTarget.dataset.id;
        $A.get("e.force:navigateToSObject").setParams({
            "recordId": id
        }).fire();        
    }    
})