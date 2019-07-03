//Namespaces
var urlCallout = urlCallout || {};
urlCallout.bindings = urlCallout.bindings || {};
urlCallout.template = urlCallout.template || {};
urlCallout.param = urlCallout.param || {};
urlCallout.header = urlCallout.header || {};
urlCallout.config = urlCallout.config || {};
urlCallout.hookUrl = urlCallout.hookUrl || {};
urlCallout.webhookLookup = urlCallout.webhookLookup || {};

//Properties
urlCallout.config.ns = '';
urlCallout.config.herokuServer = '';
urlCallout.host = '';
urlCallout.url = '';
urlCallout.urlParams = [];
urlCallout.headers = [];
urlCallout.responseUrl = '';
urlCallout.webhookLookup.currentUrl = '';

//LABELS
urlCallout.config.VIEW_DOCUMENTATION = 'View Documentation';
urlCallout.config.NAME = 'Name';
urlCallout.config.DESCRIPTION = 'Description';

/*Hook URL namespace*/
urlCallout.hookUrl.show = function(){
    if(!copadoStep || !copadoStep.stepId || copadoStep.stepId.length==0){
        alert('You must save the step first before a Resume URL can be produced.');
        return false;
    }
    if(!copadoApp.data.destinations || copadoApp.data.destinations.length==0 || !copadoApp.data.destinations[0].Id){
        alert('You must have 1 Destination Org before a Resume URL can be produced.');
        return false;
    }
    urlCallout.hookUrl.get();
    return false;
};
urlCallout.hookUrl.hide = function(){
    $copado('#js-urlCallOut-hide-div').hide();
    $copado('#js-urlCallOut-show-div').show();
    $copado('#jsUrlCalloutResumeUrl').text('');
    urlCallout.responseUrl = '';
    return false;
};
urlCallout.hookUrl.get = function(){
    var ns = urlCallout.config.ns;
    console.info("ns: "+ns);

    JsRemoting.apiKey.createKey(ns,
        function(result){
            var thisJobId = JsRemoting.deploymentJobs.getJobForCalloutStep(ns, copadoStep.stepId, copadoApp.data.destinations[0].Id);
            if(thisJobId && thisJobId==''){
                alert('The job Id for this step could not be retrieved.  Please ensure it was not deleted and reload the page.');
                return;
            }
            urlCallout.responseUrl = 'POST  '+urlCallout.config.herokuServer+'/json/v1/webhook/resumeDeployment/'+thisJobId+'?api_key='+result+'&deploymentId='+copadoApp.data.dep.Id+'&success=TRUE';
            $copado('#js-urlCallOut-hide-div').show();
            $copado('#js-urlCallOut-show-div').hide();
            $copado('#jsUrlCalloutResumeUrl').text(urlCallout.responseUrl);    
        }, function(event){
            alert('Exception: '+event.message);
        }, function(event){
            alert('Error: '+event.message);
        }
    );
};
urlCallout.hookUrl.toggleVisibility = function(){
    if($copado('[id=jsUrlCalloutType]').val()=='wait'){
        $copado('[id$=js-stepBlock-UrlCallout-ResumeUrl]').show();
    }
    else{
        $copado('[id$=js-stepBlock-UrlCallout-ResumeUrl]').hide();
    }
};

/*
 *  This method will parse the url and create the params list
 *  return {[]}  nothing
*/
urlCallout.parseUrl = function(value){
    var parseUrl = value;
    if(value==''){
        var parent = document.getElementById('urlCalloutUrlParameters');
        while (parent.firstChild) {
            parent.removeChild(parent.firstChild);
        }
        urlCallout.urlParams = [];
    }
    
    var query="";
    if(value.indexOf("?")>-1){
        query=value.substring(value.indexOf("?"));
        value=value.substring(0,value.indexOf("?"));
    }
    urlCallout.host = value;
    urlCallout.url = value+query;
    urlCallout.urlParams = urlCallout.paramsToObject(query);
    urlCallout.createChildRows(urlCallout.urlParams, 'param');
};

/*
 *  converts string parameters to object and sets against urlParams
 *  return { array }  object array
*/
urlCallout.paramsToObject = function(value){
    var value = (value.charAt(0) === '?')?value.substr(1):value;
    if(value.indexOf("=") == -1)return urlCallout.urlParams;
    var kvps = value.replace(/&/g, '|');
    kvps = kvps.split('|');
    urlCallout.urlParams = [];
    for(var i=0; i<kvps.length; i++){
        var pair = kvps[i].split('=');
        if(pair.length==2){
            urlCallout.urlParams.push([pair[0], pair[1]]);  
        }
        if(pair.length==0){
            urlCallout.urlParams.push(['', '']);    
        }
        if(pair.length==1){
            urlCallout.urlParams.push([pair[0], '']);  
        }
    }
    return urlCallout.urlParams;
};

/*
 *  This method will create the rows depending on which type is selected (for as Header or as Param).
 *  type = param | header
 *   return {[]}
*/
urlCallout.createChildRows = function(array, type){
    var parentId = (type=='param')?'urlCalloutUrlParameters':'urlCalloutUrlHeaders';
    
    var parent = document.getElementById(parentId);
    while (parent.firstChild) {
        parent.removeChild(parent.firstChild);
    }

    if(array.length==0 && type=='param'){
        urlCallout.urlParams = [];
        return;
    }
    for(var i=0; i<array.length; i++){
        var wrapper = (type=='param')?urlCallout.template.paramRow(i, array[i]):urlCallout.template.headerRow(i, array[i]);
        $copado(wrapper).appendTo('#'+parentId);
    }
};
/**
 * [createChildRows description]
 * @param  {[type]} array [description]
 * @param  {[type]} type  [description]
 * @return {[type]}       [description]
 */
urlCallout.createStaticChildRows = function(array, type){
    var parentId = (type=='param')?'urlCalloutUrlParametersView':'urlCalloutUrlHeadersView';
    
    var parent = document.getElementById(parentId);
    while (parent.firstChild) {
        parent.removeChild(parent.firstChild);
    }

    if(array.length==0 && type=='param'){
        urlCallout.urlParams = [];
        return;
    }
    for(var i=0; i<array.length; i++){
        var wrapper = (type=='param')?urlCallout.template.staticParamRow(i, array[i]):urlCallout.template.staticHeaderRow(i, array[i]);
        $copado(wrapper).appendTo('#'+parentId);
    }
};

/*
 *  Convert the object array to a flat string url
 *  return { string }  the flattened url
*/
urlCallout.paramsToUrl = function($obj){
    var me = urlCallout;
    var al = $obj?$obj.data('al'):0;
    var at = $obj?$obj.data('type'):'';

    //set host if not already set
    if(me.host=='' && me.url!=''){
        if(me.url.indexOf("?")>-1){
            me.host = me.url.substring(0,me.url.indexOf("?"));
        }
        else{
            me.host = me.url;
        }
    }

    var url = me.host;
    if($obj)me.urlParams[al] = [(at=='name')?$obj.val():me.urlParams[al][0], (at=='value')?$obj.val():me.urlParams[al][1]];
    var data = me.urlParams;
    for(var i=0; i<data.length; i++){
        url = url+((i==0)?'?':'&')+data[i][0]+'='+data[i][1];
    }
    me.url = url;
    $copado('[id$=jsUrlCalloutUrl]').val(url);
    return url;
};

/*
 *  The object of the field that cause this method to be triggered is called.
 *  $obj = jQuery object for field
 *  return {[]} nothing
*/
urlCallout.setHeaderProperty = function($obj){
    var al = $obj?$obj.data('al'):0;
    var at = $obj?$obj.data('type'):'';
    if($obj)urlCallout.headers[al] = [(at=='name')?$obj.val():urlCallout.headers[al][0], (at=='value')?$obj.val():urlCallout.headers[al][1]];
};


/* BINDINGS METHODS */
urlCallout.bindings.headerKeyUp = function(){
    $copado('#urlCalloutUrlHeaders').on('keyup', '.js-header', function(event){
        if((event.which>=16&&event.which<=20)||(event.which>=36&&event.which<=40))return;
        urlCallout.setHeaderProperty($copado(this));
    });
};   
urlCallout.bindings.paramKeyUp = function(){
    $copado('div[id=urlCalloutUrlParameters]').on('keyup', '.js-param', function(event){
        if((event.which>=16&&event.which<=20)||(event.which>=36&&event.which<=40))return;
        urlCallout.paramsToUrl($copado(this));
    });
};
urlCallout.bindings.urlKeyUp = function(){
    $copado('input[id$=jsUrlCalloutUrl]').on('keyup blur', function(event){
        urlCallout.url = $copado(this).val()
        urlCallout.parseUrl($copado(this).val());
    });
};
urlCallout.bindings.typeChange = function(){
    $copado('[id=jsUrlCalloutType]').on('change', function(event){
        urlCallout.hookUrl.toggleVisibility();
    });
};
urlCallout.bindings.bindActions = function(){
    urlCallout.bindings.urlKeyUp();
    urlCallout.bindings.paramKeyUp();
    urlCallout.bindings.headerKeyUp();
    urlCallout.bindings.typeChange();
};

/* PARAM METHODS */
urlCallout.param.addRow = function(){
    var wrapper;
    var parentId = 'urlCalloutUrlParameters';
    wrapper = urlCallout.template.paramRow(urlCallout.urlParams.length, null);
    urlCallout.urlParams.push(["",""]);
    $copado(wrapper).appendTo('#'+parentId);
};
urlCallout.param.deleteRow = function(i){
    urlCallout.urlParams.splice(i,1);
    urlCallout.createChildRows(urlCallout.urlParams, 'param');
    urlCallout.paramsToUrl();
};
/*
    Pre-save validation method to ensure we don't have empty params.
*/
urlCallout.param.validate = function(){
    var isValid = true;
    var params = urlCallout.urlParams;
    for(var i=0; i<params.length; i++){
        if(isValid==false)break;
        isValid = (params[i][0].length>0 && params[i][1].length>0);
    }
    return isValid;
};

/* HEADER METHODS */
urlCallout.header.addRow = function(){
    var wrapper;
    var parentId = 'urlCalloutUrlHeaders';
    wrapper = urlCallout.template.headerRow(urlCallout.headers.length, null);
    urlCallout.headers.push(["",""]);
    $copado(wrapper).appendTo('#'+parentId);
};
urlCallout.header.deleteRow = function(i){
    urlCallout.headers.splice(i,1);
    urlCallout.createChildRows(urlCallout.headers, 'header');
};
urlCallout.header.decode = function(){
    for(var i=0; i<urlCallout.headers.length; i++){
        urlCallout.headers[i][0] = decodeURIComponent(urlCallout.headers[i][0]);
        urlCallout.headers[i][1] = decodeURIComponent(urlCallout.headers[i][1]);
    }
};
urlCallout.header.encode = function(){
    for(var i=0; i<urlCallout.headers.length; i++){
        urlCallout.headers[i][0] = encodeURIComponent(urlCallout.headers[i][0]);
        urlCallout.headers[i][1] = encodeURIComponent(urlCallout.headers[i][1]);
    }
};
/*
    Pre-save validation method to ensure we don't have empty header params.
*/
urlCallout.header.validate = function(){
    var isValid = true;
    var params = urlCallout.headers;
    for(var i=0; i<params.length; i++){
        if(isValid==false)break;
        isValid = (params[i][0].length>0 && params[i][1].length>0);
    }
    return isValid;
};

/* TEMPLATES */
urlCallout.template.paramRow = function(rowNumber, keyPair){
    var n = keyPair?keyPair[0]:'';
    var v = keyPair?keyPair[1]:'';
    if(typeof datasetup === "undefined"){
        var btn = '<button id="del-param-'+rowNumber+'" onclick="urlCallout.param.deleteRow('+rowNumber+'); return false;" class="btn copado-lightning">Delete</button';
        var nameField =   '<input type="text" class="js-param" id="param-'+rowNumber+'-name" data-type="name" data-al="'+rowNumber+'" value="'+n+'" />';
        var valueField = '<input type="text" class="js-param" id="param-'+rowNumber+'-value" data-type="value" data-al="'+rowNumber+'" value="'+v+'" />';
        var wrapper = '<div id="paramWrapper-'+rowNumber+'" style="clear:both;">'+nameField+valueField+btn+'</div>';
        return wrapper;
    }else{
        var btn = '<button id="del-param-'+rowNumber+'" onclick="urlCallout.param.deleteRow('+rowNumber+'); return false;" class="btn slds-button slds-button--neutral">Delete</button>';
        var nameField =   '<input type="text" class="js-param slds-input" id="param-'+rowNumber+'-name" data-type="name" data-al="'+rowNumber+'" value="'+n+'" />';
        var valueField = '<input type="text" class="js-param slds-input" id="param-'+rowNumber+'-value" data-type="value" data-al="'+rowNumber+'" value="'+v+'" />';
        var wrapper = '<div class="slds-grid" id="paramWrapper-'+rowNumber+'" style="clear:both;"><div class="slds-col">'+nameField+'</div><div class="slds-col">'+valueField+'</div><div class="slds-col">'+btn+'</div></div>';
        return wrapper;
        
    }
};
urlCallout.template.headerRow = function(rowNumber, keyPair){
    var n = keyPair?keyPair[0]:'';
    var v = keyPair?keyPair[1]:'';
    if(typeof datasetup === "undefined"){
        var btn = '<button id="del-header-'+rowNumber+'" onclick="urlCallout.header.deleteRow('+rowNumber+'); return false;" class="btn copado-lightning">Delete</button';
        var nameField =   '<input type="text" class="js-header" id="header-'+rowNumber+'-name" data-type="name" data-al="'+rowNumber+'" value="'+n+'" />';
        var valueField = '<input type="text" class="js-header" id="header-'+rowNumber+'-value" data-type="value" data-al="'+rowNumber+'" value="'+v+'" />';
        var wrapper = '<div id="headerWrapper-'+rowNumber+'" style="clear:both;">'+nameField+valueField+btn+'</div>';
        return wrapper;
    }else{
        var btn = '<button id="del-header-'+rowNumber+'" onclick="urlCallout.header.deleteRow('+rowNumber+'); return false;" class="btn slds-button slds-button--neutral">Delete</button>';
        var nameField =   '<input type="text" class="js-header slds-input" id="header-'+rowNumber+'-name" data-type="name" data-al="'+rowNumber+'" value="'+n+'" />';
        var valueField = '<input type="text" class="js-header slds-input" id="header-'+rowNumber+'-value" data-type="value" data-al="'+rowNumber+'" value="'+v+'" />';
        var wrapper = '<div class="slds-grid" id="headerWrapper-'+rowNumber+'" style="clear:both;"><div class="slds-col">'+nameField+'</div><div class="slds-col">'+valueField+'</div><div class="slds-col">'+btn+'</div></div>';    
        return wrapper;        
    }

    
};
urlCallout.template.staticParamRow = function(rowNumber, keyPair){
    var n = keyPair?keyPair[0]:'';
    var v = keyPair?keyPair[1]:'';
    
    var nameField =   '<input disabled type="text" class="js-param slds-input" id="param-'+rowNumber+'-name" data-type="name" data-al="'+rowNumber+'" value="'+n+'" />';
    var valueField = '<input disabled type="text" class="js-param slds-input" id="param-'+rowNumber+'-value" data-type="value" data-al="'+rowNumber+'" value="'+v+'" />';
    var wrapper = '<div class="slds-grid" id="paramWrapper-'+rowNumber+'" style="clear:both;"><div class="slds-col">'+nameField+'</div><div class="slds-col">'+valueField+'</div></div>';
    return wrapper;
};
urlCallout.template.staticHeaderRow = function(rowNumber, keyPair){
    var n = keyPair?keyPair[0]:'';
    var v = keyPair?keyPair[1]:'';
    
    var nameField =   '<input disabled type="text" class="js-header slds-input" id="header-'+rowNumber+'-name" data-type="name" data-al="'+rowNumber+'" value="'+n+'" />';
    var valueField = '<input disabled type="text" class="js-header slds-input" id="header-'+rowNumber+'-value" data-type="value" data-al="'+rowNumber+'" value="'+v+'" />';
    var wrapper = '<div class="slds-grid" id="headerWrapper-'+rowNumber+'" style="clear:both;"><div class="slds-col">'+nameField+'</div><div class="slds-col">'+valueField+'</div></div>';    
    return wrapper;
};