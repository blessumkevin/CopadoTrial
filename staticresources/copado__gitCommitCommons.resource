function setWithoutRebinding(list, newList) {
    list.splice(0, list.length); // clear the array, without re-binding it.
    console.debug('setWithoutRebinding:::newList',Array.isArray(newList));
    while(newList.length)
        Array.prototype.push.apply(list, newList.splice(0,10000));
}
var gitCommitCommons = {};
(function(app){
        app.selectDx;
        app.init = function(conf, force) {
            app.conf = conf;
            app.forceCall = force;
            //do normalize ns to empty string or value
            app.conf.ns = app.conf.ns || '';
            //set variant of the commit mode
            app.setCommitVariant();
            if(app.conf.scalableGrid == "true"){
                app.conf.isScalable = app.conf.scalableGrid;
            }
            //set extension of the commit mode
            app.setCommitExtension();
            //prepare metadataGrid2 render it in the page, load data and assign to object prop
            app.prepareGrid(true);
            gitCommitCommons.conf.elts.gitCommitMainForm = document.querySelector("[id$=gitcommit_header_form]");
            app.conf.elts.commitButton = $copado('#copadoCommit');
            app.conf.elts.advanceButton = $copado('#copadoAdvance');
            var preselectionId = app.returnParameter('MetadataPreselectionId');
            // If we store preselection attachment Id in config file which populated by apex controller that variable will be used instead of url parsing.
            if(app.conf.data.userStoryPreselectionId) {
                preselectionId = app.conf.data.userStoryPreselectionId;
            }
            app._getPreSelection(preselectionId);
        };
        app.prepareGrid = function(force){
            if(force){
                app.grid = new MetadataGrid2(app.conf);
            }
            app.grid.render(function(){
                if(app.conf.scalableGrid == "true"){
                    app.grid.loadMetaDataTypes();
                }
            });
            app.grid.loadMetaData();
            app.datasource = app.grid.datasource;
        }
        app.setCommitVariant = function(){
            if(app.conf.data.commitType === 'main') {
                app.variant = gitCommitMain;
            } else if(app.conf.data.commitType === 'dx') {
                app.variant = gitCommitDX;
            } else {
                alert('Not supported operation found. Please contact Copado support.');
            }
        };
        app.setCommitExtension = function(){
            if(app.conf.data.vlocityEnabled) {
                app.extension = gitCommitVlocity;
            }
        };
        app.returnParameter = (function(param){
            var url_string = window.location.href;
            var url = new URL(url_string);
            var pValue = url.searchParams.get(param);
            return pValue;
        });

        app.getRecommitSelection = function(){
            app.userStoryMD = app.userStoryMD || [];
            if(!app.userStoryMD || (app.userStoryMD && app.userStoryMD.length == 0)) {
                var gitMetadataAttachment = dw.u.getAttach(app.conf.data.userStoryId,'Git MetaData');
                var savedItems = Base64.decode(gitMetadataAttachment[0].Body);
                setWithoutRebinding(app.userStoryMD, JSON.parse(savedItems));
            }
            app.grid.reloadSelectionsJSON(app.userStoryMD,1);
            app.grid._reapplyFilters(1);
        };
        app._getPreSelection = function(attachmentId) {
            if(attachmentId) {
                app.userStoryMD = app.userStoryMD || [];
                var savedItems = dw.u.getAttachById(attachmentId);
                if(savedItems) {
                    savedItems = Base64.decode(savedItems[0].Body);
                    savedItems = $copado.parseJSON(savedItems);
                    setWithoutRebinding(app.userStoryMD, savedItems);
                    app.grid.reloadSelectionsJSON(app.userStoryMD,1);
                    app.grid._reapplyFilters(1);
                }else{
                    alert("Could not load selections from other User Story commits.");
                }
            }
        }
        app.previous;
        app.changeOperation = function(gitOperationType){
            console.log('gitOperationType===> ',gitOperationType);
            app.conf.data.type = gitOperationType;
            app.conf.data.operationLabel = gitOperationType;

            if(app.selectDx == true) app.resetGrid();

            if(!app.conf.gitOperationCall || !app.grid) return;

            var operationDetails = JSON.parse(app.conf.gitOperationCall)[gitOperationType];
            !operationDetails.showGrid && app.grid.eltMain.hide();
            !operationDetails.showAdvancedSection && app.conf.elts.advanceButton.hide();
            app.operationDetails = operationDetails;
            app.conf.attachmentName = app.operationDetails.attachmentName || 'MetaData';

            var currentMode = app.conf.gridMode;
            var gridMode = operationDetails.editGrid ? 'gitCommitEditable' : 'gitCommit';
            app.updateConfigData(app.conf,'gridMode', gridMode);

            if(currentMode !== gridMode || operationDetails.reloadGridData || (app.previous && app.previous.length > 0) || (operationDetails.gridMetadataTypes && operationDetails.gridMetadataTypes.length > 0)){
                app.resetGrid();
            }

            if(operationDetails.gridMetadataTypes && operationDetails.gridMetadataTypes.length > 0 || (!operationDetails.gridMetadataTypes && gitOperationType != 'Recommit Files')){
                app.setGridFiltersByCSV(operationDetails.gridMetadataTypes);
            }
            app.previous = operationDetails.gridMetadataTypes;
            operationDetails.showUserStorySelections && app.getRecommitSelection();

            if(app.conf.scalableGrid == "true"){
                app.grid.loadMetaDataTypes(undefined,undefined,(operationDetails.gridMetadataTypes && operationDetails.gridMetadataTypes.length > 0) ? operationDetails.gridMetadataTypes.split(',') : undefined);
            }
        };
        // Filter Grid given CSV
        app.setGridFiltersByCSV = function(filtersCSV) {
            if(!app.grid) return;
            var filteredMetadata = [];
            if(filtersCSV){
                var filteredTypes = filtersCSV.split(',');
                for(i=0 ; i < filteredTypes.length ; i++ ) {
                    for(j=0; j < app.grid.allMetaData.length ; j++){
                        if(app.grid.allMetaData[j].t == filteredTypes[i]){
                            filteredMetadata.push(app.grid.allMetaData[j]);
                        }
                    }
                }
                app.grid._setGridData(filteredMetadata);
                app.grid.render();
                app.grid._reapplyFilters(0);
            } else{
                app.resetGrid();
            }
        };
        app.resetGrid = function(){
            app.selectDx = false;
            app.grid.resetGrid(app.conf);
            app.grid.render();
            app.grid.loadMetaData();
            app.grid._reapplyFilters(0);
        };
        /**
         * this method retrieve the selected items
         * then create a record in salesforce, attach the items to be commited
         * and finally call heroku to procede
         * @return {[type]} [description]
         */
        app.doCommit = function(commitId,sel){
            app.conf.data.orgCommitId = commitId || null;
            lockScreen();
            //get selected
            coGridHelper.datasource = app.grid.datasource;

            // "sel" might come as a parameter (from gitcommitchangesDX, or from the grid itself)
            sel = sel || coGridHelper.getSelectedObj();

            // Attachment Name
            var attachmentName = app.conf.attachmentName || 'MetaData';
            app.conf.data.orgCommitId && coGridHelper.saveSelected(app.conf.data.orgCommitId , attachmentName, null, true, function(){
                app.redirectToOperation(app.conf.data.orgCommitId);
            },sel);
        };
        app.redirectToOperation = function(commitId){
            if(goToWaitingForPage && commitId) {
                // this means it is a user story commit, use the new UserStoryWaitingFor page
                goToWaitingForPage(commitId);
                return;
            } else {
                alert('Commit operation handler not found. Please contact with Copado support.');
                unlockScreen();
                return;
            }
        }

        /**
         * Update the config values from outside the closure. These values are different from the init values if the user changed the Git Operation in the UI.
         * Currently used in GitCommitChanges page
         * @param  {[type]} branchName        [description] new base branch name
         * @param  {[type]} type              [description] type of the selected Git Operation
         * @param  {[type]} label             [description] label of the selected Git Operation
         * @param  {[type]} attachmentName    [description] name of the Git Snapshot attachment
         * @param  {[type]} endpoint          [description] endpoint to replace in the CommitURL
         * @param  {[type]} formElementParams [description] list of parameters to append to the CommitURL
         * @param  {[type]} customSelections  [description] body of selected items to be saved as an attachment
         * @param  {[type]} showCommitMessage [description] bool if showMessage field is displayed to enforce that it is not BLANK
         * @param  {[type]} orgCommitId       [description] id of git commit record
         */
        app.updateConfigData = function(node, prop, value, callback){
            if("undefined" === typeof(node[prop])) {
                console.error('Property not found in git commit configuration: ',prop);
                return;
            } else {
                node[prop] = value;
            }

            if(callback) callback();
        }
        /**
        * Refresh metadata cache of subjected org credential
        * @see app.config.data.orgId
        */
        app.refreshCache = function(){
            app.grid.refreshCache();
            rerenderRefreshCachePoller();
        };
        /**
         * update or hide refresh button
         * @param  {[type]} date [description]
         * @return {[type]}      [description]
         */
        app.showRefreshButton = function(date){
            // TODO Add title to refresh button like : Last index date 22.03.2019 22:00
        };
        app.toggleGridFullScreen = function(sectionId){
            var gridSection = $copado('[Id$="'+sectionId+'"]');
            if(!gridSection){
                console.error('Grid section not found with Id:', sectionId);
                return;
            }
            var $window = $copado(window);
            var grid = $copado('.mg2_jqxgrid');
            if(!grid){
                console.error('Grid not found with class mg2_jqxgrid');
                return;
            }
            if(gridSection.hasClass('fullScreen')){
                gridSection.removeClass('fullScreen');
                grid.jqxGrid({ height: app.conf.style.height });
            } else {
                gridSection.addClass('fullScreen');
                grid.jqxGrid({ height: ($window.height() - 250).toString() });
            }
        };
        app.startCommit = function(){
            if(!app.variant) {
                unlockScreen();
                return;
            }
            app.conf.jsonData.selectedMetadata = app.grid.selectedMetadata;
            app.variant.startCommit(function(message,orgId,snapshotId,operationName){
                deleteUSMetadata();
                var core = app.conf.ns ? window[app.conf.ns.split('__')[0]] : window;
                (core).GitCommit_HeaderController.createGitOrgCommit(
                    message,
                    orgId,
                    snapshotId,
                    operationName,
                    function( result, event ) {
                        if(result && event.status)
                        app.doCommit(result);
                    }
                );
            });
        };
        app.loadSourceStatus = function(isDestructive) {
            var att = dw.u.getDecodedAttach(app.conf.data.orgId,"SourceStatus");
            if(att){
                var body = att.Body;
                try{
                    var metadataRecords = JSON.parse(body);
                    var actData = app.grid.allMetaData;
                    var actSelected = app.grid.selectedMetadata;
                    var toDelSet = new Set();

                    for(var i = 0; i < actData.length; i++){
                        for(var j = 0; j < metadataRecords.length; j++){
                            if(!isDestructive && actData[i].n == metadataRecords[j].n && actData[i].t == metadataRecords[j].t && (metadataRecords[j].st.includes("Remote Add") || (metadataRecords[j].st.includes("Remote Changed")))  ){
                                actData[i].s = true;
                                if(!(actSelected.some( item => item['t'] === actData[i].t) && actSelected.some(item => item['n'] === actData[i].n ))) actSelected.push(actData[i]);
                            }else if(isDestructive && actData[i].n == metadataRecords[j].n && actData[i].t == metadataRecords[j].t && (metadataRecords[j].st.includes("Remote Deleted"))){
                                actData[i].s = true;
                                if(!(actSelected.some( item => item['t'] === actData[i].t) && actSelected.some(item => item['n'] === actData[i].n ))) actSelected.push(actData[i]);
                            }else if(isDestructive && (metadataRecords[j].st.includes("Remote Deleted") && !toDelSet.has(metadataRecords[j]))){
                                //Item is not found in the Metadata Selections but still show in Source Status, auto select
                                toDelSet.add(metadataRecords[j]);
                                metadataRecords[j].s = true;
                                if(!(actSelected.some( item => item['t'] === metadataRecords[j].t) && actSelected.some(item => item['n'] === metadataRecords[j].n ))) actSelected.push(metadataRecords[j]);
                            }
                        }
                    }
                } catch(e){
                    console.error(e);
                }
            } else {
                alert('Please Check Org Status');
            }
            app.selectDx = true;
            app.grid.eltTabs.jqxTabs('select',0);
            app.grid.render();
            app.grid.eltTabs.jqxTabs('select',1);
        };
        app.getVlocityDependencies = function() {
            app.extension.getVlocityDependencies();
        };
    }
)(gitCommitCommons)