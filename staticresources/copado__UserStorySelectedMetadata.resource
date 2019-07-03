var USselectedMetadata = USselectedMetadata || {};

//closure
(function(app){

    app = app || {};

    //app properties
    app.metadataArray = [];
    app.deletions = [];
    app.gitSelections = [];
    app.testClassSelections = [];
    app.dataArray = [];
    app.maxretries = 30;
    app.retries = 0;

    /**
     * Load Git Metadata
     * @param  {[type]} [description]
     * @return {[type]} nothing
     */
    app.getGitMetadata = function(){
        var url = "Select Id, __NAMESPACE__Snapshot_Commit__c, __NAMESPACE__Snapshot_Commit__r.__NAMESPACE__Git_Backup__r.__NAMESPACE__Branch__c, __NAMESPACE__Snapshot_Commit__r.__NAMESPACE__Git_Backup__r.__NAMESPACE__Git_Repository__c from __NAMESPACE__User_Story_Commit__c where __NAMESPACE__User_Story__c='"+app.conf.data.userStoryId+"' limit 1";
        url = url = url.replace(new RegExp('__NAMESPACE__','g'), app.conf.ns);
        console.info(url);
        var result = sforce.connection.query(url);
        var records = result.getArray("records");
        if(records.length>0){
            var repoId = records[0][app.conf.ns+'Snapshot_Commit__r'][app.conf.ns+'Git_Backup__r'][app.conf.ns+'Git_Repository__c'];
            var branch = records[0][app.conf.ns+'Snapshot_Commit__r'][app.conf.ns+'Git_Backup__r'][app.conf.ns+'Branch__c'];
            app.callBackEnd(repoId, branch);
        }
    },
    app.onComplete = function(){
        lockScreen();
        app.init(app.conf);
    },
    /**
     * Call Heroku to perform calculation
     * @param  {[type]}    repoId       [description]
     * @param  {[type]}    branch       [description]
     * @return {[type]}                 [description]
     */
    app.callBackEnd = function(repoId, branch){
        setLockScreenMessage(copadoLabels.loading);
        var me = app;
        if((typeof(repoId)!=="undefined" && repoId!==null)&&(typeof(branch)!=="undefined" && branch!==null)){
            lockScreen();
            console.log('Calling Copado to get Git Metadata ');
            var url =  app.conf.server.USgitMetadataUrl.replace('__USERSTORYID__', app.conf.data.userStoryId).replace('__repoId__', repoId).replace('__branch__', branch);
            utilsV2.onFailureCB = function(obj){
                unlockScreen();
                alert('Error: '+obj.error);
                console.error(obj.error);
            }
            utilsV2.onSuccessCB = function(res){
                console.log('Response callback', res);
                var obj = $copado.parseJSON(res);
                console.log('Callback object', obj);
                if(obj && obj.status && obj.status=='done'){
                    app.onComplete();
                    return true;
                }
                if(obj && obj.ok){
                    setTimeout(function(){
                        me.callBackEnd(repoId, branch);
                        me.retries++;
                    }, 2000);
                }
                else{
                    setTimeout(function(){
                        me.callBackEnd(repoId, branch);
                        me.retries++;
                    }, 2000);
                }
            }
            try{
                setLockScreenMessage(copadoLabels.FETCHING_COMMITS_FOR_USER_STORY);
                utilsV2.getRemote(url);
            }
            catch(e){
                console.error('Caught Exception: '+e);
            }
        }
        else{
            alert(copadoLabels.REPO_OR_BRANCH_NOT_DEFINED);
        }
    },
    app.getAttachments = function(){
        var fileNames = ['Delete MetaData', 'Git MetaData', 'MetaData', 'Git Deletion', 'Test Classes'];
        var results = [];
        var counter = fileNames.length;
        for(var i=0; i<fileNames.length; i++){
            sforce.connection.query("select Id, Name, ParentId, Body from Attachment where ParentId='"+app.conf.data.userStoryId+"' and Name='"+fileNames[i]+"'", {
                onSuccess : function(result){
                    var records = result.getArray("records");
                    if(records.length == 1){
                        var fn = records[0].Name;
                        var b = Base64.decode(records[0].Body);
                        //below replaces opening and closing tags based on xss concerns
                        while(b.indexOf('<') > -1 || b.indexOf('>') > -1){
                            b = b.replace('<','').replace('>','');
                        }
                        var obj = JSON.parse(b);
                        if(fn=='Delete MetaData')app.deletions = obj;
                        if(fn=='Git Deletion')app.deletions = obj;
                        if(fn=='Git MetaData')app.gitSelections = obj;
                        if(fn=='MetaData')app.metadataArray = obj;
                        if(fn=='Test Classes')app.testClassSelections = obj;
                    }
                    else{
                        console.log('Attachment not found:',app.conf.data.userStoryId, records[0].Name);
                    }
                    counter--;
                    if(counter == 0){
                        app.dedupeDataArrays();
                    }
                },
                onFailure : function(error){
                    counter--;
                    if(counter == 0){
                        app.dedupeDataArrays();
                    }
                }
            });
        }
    },
    /**
     * Helper to find element in array
     * Because IE doesnt support indexOf in Array
     * @param  {[type]} arr [description]
     * @param  {[type]} val [description]
     * @return {[type]}     [description]
     */
    app.valueInArray = function(arr, val) {
        return $copado.inArray(val, arr)>-1;
    },
    app.createDataArrayRow = function(obj, type){
        var row = [];
        if(obj){
            var ms = ((type=='metadataSelection'||obj.s) && type !== 'testClasses')?true:false;
            var gs = (type=='gitSelection')?true:false;
            var gd = (type=='gitDeletion')?true:false;
            var to = (type === 'testClasses')?true:false;
            var t = (obj.t)?obj.t:(type === 'testClasses')?'ApexClass':'';
            var n = (obj.n)?obj.n:'';
            var b = (obj.b)?obj.b:'';
            var d = (obj.d)?obj.d:'';
            var cb = (obj.cb)?obj.cb:'';
            var cd = (obj.cd)?obj.cd:'';
            var row = {'ms':ms, 'gs':gs, 'gd':gd, 'to':to, 't':t, 'n':n, 'b':b, 'd':d, 'cb':cb, 'cd':cd};
        }
        return row;
    },

    /*
     * start grid
     * @param {[Array]} data    the data array to be loaded
     * @return {[type]}         [description]
    */
    app.startGrid = function(data){
        var theme = 'base',
        source = {
            datatype: "array",
            updaterow: function (rowid, rowdata, commit) {
                commit(true);
                data[rowid] = rowdata;
            }
        };

        source_meta = {
            localdata: data,
            datafields: [
                { name: 'ms', type: 'bool' },
                { name: 'gs', type: 'bool' },
                { name: 'gd', type: 'bool' },
                { name: 'to', type: 'bool' },
                { name: 't', type: 'string' },
                { name: 'n', type: 'string' },
                { name: 'b', type: 'string' },
                { name: 'd', type: 'string' },
                { name: 'cb', type: 'string' },
                { name: 'cd', type: 'string' }
            ],
            datatype: "array",
            updaterow: function (rowid, rowdata, commit) {
                commit(true);
                data[rowid] = rowdata;
            }
        };

        var metadatagrid = $copado('#jqxgrid_metadata');

        var height = utilsV2.getUrlParameter('height');
        height = (height)?height:300;

        var pageSize = utilsV2.getUrlParameter('pageSize');
        pageSize = (pageSize)?parseInt(pageSize):50;

        setLockScreenMessage('Loading grid...');
        dataAdapter_meta = new $copado.jqx.dataAdapter(source_meta);
        console.log('Metadata adaptaber: ', dataAdapter_meta);
        $gridm = $copado('<div>');
        metadatagrid.html($gridm);
        $gridm.jqxGrid({
            width: '100%',
            height: height,
            source: dataAdapter_meta,
            showfilterrow: true,
            filterable: true,
            theme: theme,
            editable: false,
            selectionmode: 'none',
            enablebrowserselection: true,
            pageable: true,
            pagesizeoptions: ['10', '20', '50','100','200','500','1000','2000','5000'],
            pagesize: pageSize,
            sortable: true,
            columnsresize: true,
            localization: localizationobj,
            columns: [
                {text: copadoLabels.STEP_TYPE_METADATA, columntype:'checkbox', filtertype:'bool', datafield:'ms', width:80},
                {text: copadoLabels.GIT_UPSERTS, columntype:'checkbox', filtertype:'bool', datafield:'gs', width:80},
                {text: copadoLabels.GIT_DELETIONS, columntype:'checkbox', filtertype:'bool', datafield:'gd', width:80},
                {text: 'Test Only', columntype:'checkbox', filtertype:'bool', datafield:'to', width:80},
                {text: copadoLabels.name, filtertype:'textbox', filtercondition: 'contains', editable:false, datafield:'n',width:220},
                {text: copadoLabels.type, datafield:'t', filtertype:'checkedlist', editable:false, columntype:'textbox',width:150},
                {text: copadoLabels.LastModifiedById, filtertype:'checkedlist', editable:false, datafield:'b', width:150},
                {text: copadoLabels.LastModifiedDate, filtertype:'textbox', editable:false, datafield:'d', width:100},
                {text: copadoLabels.CREATEDBY, filtertype:'checkedlist', editable:false, datafield:'cb', width:150},
                {text: copadoLabels.CREATEDDATE, filtertype:'textbox', editable:false, datafield:'cd', width:100}
            ]
        });
        $copado('#loadingDiv').hide();
        unlockScreen();
    },

    /*
     * Deduplicate data arrays and load grid when done.
     * param {[type]}           [description]
     * @return {[type]}         [description]
    */
    app.dedupeDataArrays = function(){
        setLockScreenMessage('Merging grid data...');
        var keyDictionary = [];
        if(app.metadataArray.length>0){
            for(var k in app.metadataArray){
                keyDictionary.push(app.metadataArray[k].n+app.metadataArray[k].t);
                app.dataArray.push(app.createDataArrayRow(app.metadataArray[k], 'metadataSelection'));
            }
        }
        
        var tmp_del_names = [];
        if(app.deletions.length>0){
            setLockScreenMessage('Merging git deletions into grid...');
            for(var k in app.deletions){
                if(app.valueInArray(keyDictionary, app.deletions[k].n+app.deletions[k].t)==false){
                    keyDictionary.push(app.deletions[k].n+app.deletions[k].t);
                    app.dataArray.push(app.createDataArrayRow(app.deletions[k], 'gitDeletion'));
                }
                tmp_del_names.push(app.deletions[k].n+app.deletions[k].t);
            }
        }
        var tmp_git_names = [];
        if(app.gitSelections.length>0){
            setLockScreenMessage('Merging git selections into grid...');
            for(var k in app.gitSelections){
                if(app.valueInArray(keyDictionary, app.gitSelections[k].n+app.gitSelections[k].t)==false){
                    keyDictionary.push(app.gitSelections[k].n+app.gitSelections[k].t);
                    app.dataArray.push(app.createDataArrayRow(app.gitSelections[k], 'gitSelection'));
                }
                tmp_git_names.push(app.gitSelections[k].n+app.gitSelections[k].t);
            }
        }

        if(app.testClassSelections.length>0){
            for(var k in app.testClassSelections){
                console.log('testclass pace keydic',keyDictionary);
                console.log('testclass pace key',app.testClassSelections[k].n+app.testClassSelections[k].t);
                if(app.valueInArray(keyDictionary, app.testClassSelections[k].n+'ApexClass')==false){
                    app.dataArray.push(app.createDataArrayRow(app.testClassSelections[k], 'testClasses'));
                }
            }
        }

        setLockScreenMessage('Finalising grid data...');
        for(var i=0; i<app.dataArray.length; i++){
            var key = app.dataArray[i].n+app.dataArray[i].t;
            var gitBooly = app.valueInArray(tmp_git_names, key);
            var delBooly = app.valueInArray(tmp_del_names, key);
            app.dataArray[i].gs = gitBooly;
            app.dataArray[i].gd = delBooly;
        }

        app.updateFieldMetadata_Types_in_Selection(app.dataArray);

        app.startGrid(app.dataArray);
    },

    /**
     * updates the field Metadata_Types_in_Selection__c
     * @param  {[type]}      [description]
     * @return {[type]}      [description]
     */
    app.updateFieldMetadata_Types_in_Selection = function(records) {
        var i, t, selectedTypes={};

        // Collect a unique list selected of types
        // selected as metadata, git upsert, or git delete
        for(i=0; i < records.length ; i++) {
            t = records[i];
            if(t.ms || t.gs || t.gd)
                selectedTypes[t.t]=1;
        }

        var compareArrays = function(array1, array) {
            // if the other array is a falsy value, return
            if (!array)
                return false;

            // compare lengths - can save a lot of time 
            if (array1.length != array.length)
                return false;

            for (var i = 0, l=array1.length; i < l; i++) {
                // Check if we have nested arrays
                if (array1[i] instanceof Array && array[i] instanceof Array) {
                    // recurse into the nested arrays
                    if (!array1[i].equals(array[i]))
                        return false;       
                }           
                else if (array1[i] != array[i]) { 
                    // Warning - two different object instances will never be equal: {x:20} != {x:20}
                    return false;   
                }           
            }       
            return true;
        };

        // this creates a semicolon-separated list with the keys of selectedTypes
        var setofSelectedType = Object.keys(selectedTypes);
        setofSelectedType.sort();
        var changes = {};
        try{
            var oldResult = sforce.connection.query("Select Id, Name, "+app.conf.ns+"Metadata_Types_in_Selection__c"+ " FROM " +app.conf.ns+"User_Story__c WHERE Id='"+app.conf.data.userStoryId+"' limit 1");
            usRecord = oldResult.getArray("records")[0];
            var t = usRecord[app.conf.ns+'Metadata_Types_in_Selection__c'];
            var setOfUserStoryTypes = t? t.split(/\s*;\s*/g) : [];
            setOfUserStoryTypes.sort();
            
            var areThereDifferences= (setofSelectedType || setOfUserStoryTypes) && !compareArrays(setofSelectedType, setOfUserStoryTypes);
            
            console.log('userStorySelectedMetadata:::', areThereDifferences, setofSelectedType, setOfUserStoryTypes);

            if( areThereDifferences ) {
                // NOTE: it must be null in order to clear the multipicklist Metadata_Types_in_Selection__c. Empty string wont do.
                changes[app.conf.ns+'Metadata_Types_in_Selection__c'] = setofSelectedType&&setofSelectedType.length?setofSelectedType.join(';'):null;
                console.log('userStorySelectedMetadata: sending to update', changes);
                window.parent.postMessage({"from":"userStorySelectedMetadata", "hasChanges":true, "change":changes}, "*");
            } else {
                window.parent.postMessage({"from":"userStorySelectedMetadata", "hasChanges":false, "change":changes}, "*");
            }
        } catch(e){
            window.parent.postMessage({"from":"userStorySelectedMetadata", "hasChanges":false, "change":changes}, "*");
            console.error(e);
        }
    },

    /**
     * init method
     * @param  {[type]}      [description]
     * @return {[type]}      [description]
     */
    app.init = function(conf){
        app.conf = conf;
        //do normalize ns to empty string or value
        app.conf.ns = app.conf.ns || '';

        app.dataArray = [];
        lockScreen();
        
        try{
            app.getAttachments();
        }
        catch(e){
            console.error(e);
            unlockScreen();
        }
    }
}(USselectedMetadata)); //end closure