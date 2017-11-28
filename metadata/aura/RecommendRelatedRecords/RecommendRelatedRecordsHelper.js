({
    createVLabels : function(cmp, helper) {
        var showFields = cmp.get("v.showFields").split(",");
        var asLabels = [];
        var nasLabels = [];
        for (var i = 0; i < showFields.length; i ++){
            var v1;
            var v2;
            var sl = showFields[i];
            sl = sl.replace(/(AS)/, 'as');
            var spls = sl.split(' as ');
            v1 = spls[0];
            v2 = spls[1] ? spls[1]: '';
            nasLabels.push(v1);
            asLabels.push(v2);
        }
        cmp.set("v.sFields", helper._normList(nasLabels));
        cmp.set("v.asFields", helper._normList(asLabels));
        cmp.set("v.targetFieldList", helper._normList(cmp.get("v.fieldTargetObject").split(",")));
        cmp.set("v.thisFieldList", helper._normList(cmp.get("v.fieldThisObject").split(",")));
        cmp.set("v.conditionList", helper._normList(cmp.get("v.conditions").split(",")));
        var stargetObject = cmp.get("v.targetObject");
        var tObject;
        if(stargetObject && stargetObject.length > 3){
            tObject = stargetObject;
        } else {
            tObject = cmp.get("v.sObjectName");
        }
        cmp.set("v.targetObject", tObject);
    },
    getLabels : function(cmp, helper) {
        var action = cmp.get("c.getLabels");
        action.setParams({ 
            rFields : cmp.get("v.sFields"),
            rTargetObject : cmp.get("v.targetObject"),
        });
        action.setCallback(this, function(res){
            var state = res.getState();
            if (state === "SUCCESS") {
                var ret = res.getReturnValue();
                cmp.set("v.labelMaps", ret);
                helper.getRecords(cmp, helper);
            } else {
                console.log('ERROR!');
            }
        });
        $A.enqueueAction(action);
    },
    getRecords : function(cmp, helper) {
        var xmyList = cmp.get("v.sFields").slice(0);
        var imageField = cmp.get("v.fieldImage");
        var myBool = false;
        if(!imageField || (imageField && imageField.length < 2)){
            myBool = true;
        }
        for(var i=0; i<xmyList.length; i++){
            if(myBool == false && imageField && imageField.length > 2 && xmyList[i].toUpperCase() == imageField.toUpperCase()){
                myBool = true;
            }
            if(xmyList[i].toUpperCase() == "Id".toUpperCase()){
                xmyList.splice(i, 1);
            }
        }
        if (!myBool){
            xmyList.push(imageField);
        } 
        var action = cmp.get("c.getRecords2");
        action.setParams({ 
            rThisObject : cmp.get("v.sObjectName"),
            rThisId : cmp.get("v.recordId"),
            rThisFields : cmp.get("v.thisFieldList"),
            rFields : xmyList,
            rTargetObject : cmp.get("v.targetObject"),
            rTargetFields : cmp.get("v.targetFieldList"),
            orderString : cmp.get("v.recordOrder"),
            conditions : cmp.get("v.conditionList")
        });
        action.setCallback(this, function(res){
            var state = res.getState();
            if (state === "SUCCESS") {
                var ret = res.getReturnValue();
                cmp.set("v.raws", ret);
                helper.createShow(cmp, helper);
            } else {
                console.log('ERROR!');
            }
        });
        $A.enqueueAction(action);
    },
    createShow : function(cmp, helper) {
        var labels = cmp.get("v.sFields");
        var aslabels = cmp.get("v.asFields");
        var raws = cmp.get("v.raws");
        var labelMaps = cmp.get("v.labelMaps");
        var fieldOfImage = cmp.get("v.fieldImage");
        var max = cmp.get("v.maxShowRecordCount");        
        var details = [];
        var recordCount = 0;
        if(raws && raws.length > 0){
            for (var i=0; i < raws.length; i++){
                if (max > 0 && i < max || max < 1){
                    var raw = raws[i];
                    var detail = {};
                    var fvs = [];
                    for (var j=0; j < labels.length; j++){
                        var label = labels[j];
                        var aslabel = aslabels[j];
                        var calcValue = raw[label];
                        if (~label.indexOf('\.')){
                            var splits = label.split('\.');
                            calcValue = raw[splits[0]][splits[1]];
                        }
                        
                        if (j == 0){
                            detail.title = helper._sepNum(calcValue);
                        } else {
                            var tmp = {};
                            tmp.label = aslabel.length > 0 ? aslabel: labelMaps[label];
                            tmp.value = helper._sepNum(calcValue);
                            fvs.push(tmp);                    
                        }
                    }
                    detail.id = raw.Id;
                    detail.detail = fvs;
                    if(fieldOfImage && fieldOfImage.length > 1){
                        detail.image = raw[fieldOfImage];  
                        detail.imageBool = true;
                    } else {
                        detail.imageBool = false;
                    }
                    details.push(detail);
                    recordCount ++;
                } else {
                    break;
                }
            }
        }
        cmp.set("v.details", details);
        cmp.set("v.allRecordCount", recordCount);
    },
    _normList : function(lst){
        var nw = [];
        for (var i = 0; i < lst.length; i ++){
            var val = lst[i];
            if(val && val.length > 1){
                val = val.replace(/^\s+/g, "").replace(/\s+$/g, "").replace(new RegExp("'", 'g'), '"');                    
            }
            nw.push(val);
        }
        return nw;
    },
    _sepNum : function (nums){
        nums = nums + '';
        var ret = '';
        if(nums && nums.length > 2 && nums.match(/^[0-9]+$/)){
            ret = nums.replace( /(\d)(?=(\d\d\d)+(?!\d))/g, '$1,');
        } else {
            ret = nums;
        }
        return ret;
    }
})