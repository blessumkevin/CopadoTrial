var webhookLookup = webhookLookup || {};
webhookLookup.bindings = webhookLookup.bindings || {};
webhookLookup.template = webhookLookup.template || {};
webhookLookup.param = webhookLookup.param || {};
webhookLookup.header = webhookLookup.header || {};
webhookLookup.config = webhookLookup.config || {};
webhookLookup.hookUrl = webhookLookup.hookUrl || {};
webhookLookup.webhookLookup = webhookLookup.webhookLookup || {};

var $copado = $copado || jQuery.noConflict();

//Properties
webhookLookup.config.ns = '';
webhookLookup.config.herokuServer = '';
webhookLookup.config.ADD_API_KEY_TO_URL = true;
webhookLookup.config.URL_ELEMENT_ID = '';
webhookLookup.host = '';
webhookLookup.url = '';
//webhookLookup.responseUrl = '';
webhookLookup.webhookLookup.currentUrl = '';

//LABELS
webhookLookup.config.VIEW_DOCUMENTATION = 'View Documentation';
webhookLookup.config.NAME = 'Name';
webhookLookup.config.DESCRIPTION = 'Description';


webhookLookup.onSuccessCB = function(){};


/* WEBHOOK LOOKUP */
webhookLookup.templateRow = function(i, row){
    var _row = '<tr class="dataRow">'+
        '<td>'+
            '<a id="whn-'+i+'" href="javascript:void(0)" onclick="webhookLookup.showLookupField(\''+row.referTo+'\', \''+row.url+'\');">'+row.name+'</a>'+
        '</td>'+
        '<td style="white-space: pre-wrap;"><span id="whd-'+i+'">'+row.description+'</span></td>'+
        '<td><a id="whdl-'+i+'" href="'+row.documentationLink+'" data-ref="webhookNameLink" target="_blank">'+webhookLookup.config.VIEW_DOCUMENTATION+'</a></td>'+
    '</tr>';
    return _row;
};
webhookLookup.showSpecificLookup = function(referTo){
	$copado('[data-type="lookupDiv"]').hide();
	$copado('#js-'+referTo.toLowerCase()).show();
};
webhookLookup.showLookupField = function(referTo, url){
	webhookLookup.currentUrl = url;
	$copado('#divWebhooksTable').hide();
	webhookLookup.showSpecificLookup(referTo);
	$copado('#webhookLookupFields').show();
};
webhookLookup.show = function(){
	webhookLookup.currentUrl = '';
	$copado('#whl-popup').show();
    webhookLookup.getWebhooks();
};
webhookLookup.hide = function(){
	$copado('#whl-popup').hide();
	$copado('#divWebhooksTable').show();
	$copado('#webhooksTable').hide();
	$copado('#divWebhooksLoading').show();
	$copado('#webhookLookupFields').hide();
	webhookLookup.currentUrl = '';
	$copado('#webhooksTable tbody').html('');
};
webhookLookup.renderWebhooksTable = function(response){
    if(response!=null){
	    try{
	        var $table = $copado('#webhooksTable tbody');
	        var obj = JSON.parse(response);
	        var rows = '';
	        for(var i=0; i<obj.length; i++){
	            var row = webhookLookup.templateRow(i, obj[i]);
	            rows = rows+row;
	        }
	        $copado(rows).appendTo($table);
			$copado('#webhooksTable').show();
			$copado('#divWebhooksLoading').hide();
		}
		catch(e){
			$copado('#webhooksTable').hide();
			$copado('#divWebhooksLoading').hide();
			$copado('#divWebhooksLoading').html(e.message);
		}
    }
};
webhookLookup.getWebhooks = function(){
    var url = webhookLookup.config.herokuServer+'/json/v1/describeWebhooks';
    console.log('Calling Heroku to get webhook urls', url);
    utilsV2.method = 'GET';
    utilsV2.onFailureCB = function(res){
    	webhookLookup.hide();
        alert(res);
    };
    utilsV2.onSuccessCB = function(res){
        webhookLookup.renderWebhooksTable(res);
    };
    utilsV2.getRemote(url);
};
webhookLookup.setUrl = function(templateUrl, recordId){
	var ns = webhookLookup.config.ns;
	if(webhookLookup.config.ADD_API_KEY_TO_URL==true){
		JsRemoting.apiKey.createKey(ns,
	        function(result){
	            var url = webhookLookup.config.herokuServer+templateUrl.replace('__RECORDID__', recordId).replace('__APIKEY__', result);
	            webhookLookup.setValue(url);
	            webhookLookup.onSuccessCB();
	            webhookLookup.hide();
	        }, function(event){
	            webhookLookup.hide();
	            alert('Exception: '+event.message);
	        }, function(event){
	            webhookLookup.hide();
	            alert('Error: '+event.message);
	        }
	    );
	}
	else{
		var url = webhookLookup.config.herokuServer+templateUrl.replace('__RECORDID__', recordId).replace('?api_key=__APIKEY__', '');
		webhookLookup.setValue(url);
		webhookLookup.onSuccessCB();
        webhookLookup.hide();
	}
	    
};
webhookLookup.getLookupRecordId = function(id){
	var recordId = $copado('[id$="'+id+'_lkid"]').val();
	if(recordId!='000000000000000'){
		webhookLookup.setUrl(webhookLookup.currentUrl, recordId);
	}
};
webhookLookup.setValue = function(url){
	try{
	    $copado('[id$='+webhookLookup.config.URL_ELEMENT_ID+']').val(url);
	}
	catch(e){
		console.error(e.message);
	}
};