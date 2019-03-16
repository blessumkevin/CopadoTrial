//namespace
var dw = dw || {};

dw.qb = dw.qb || {};

dw.qb.type = 'Data';
console.log('step type ==>',dw.qb.type);
dw.qb.preQuery = '';

dw.qb.createCacheDeleteButton = function(date){
    
    if(!date){
         $copado('[id*=removeCacheContainer]').hide();
    }else{
        var $btn = $copado('[id$=removeCache]');
        console.log($btn);
        console.log($btn.html())
        if($btn && $btn.html())$btn.html($btn.html().replace('__DATE__',date).replace('__METATYPE__','')).show();
    }    
};

dw.qb.removeCached = function(){
    //hide
    
    //reload
    $copado('#loading').show();
    $copado('#queryBuilder').hide(); 

    init(true);
    
    return false;
};

dw.qb.startQueryBuilder = function(data) {
    try{
        //normalize data
        var source = [],
        len = data.length;
        for(var i=0;i<len; i++){
            source[i]= data[i].L+' ('+data[i].N+')' ;
        }

        source.sort();
        
        // Create a jqxDropDownList
        var $objects = $copado("#objects").jqxComboBox({
             source: source,
             autoComplete: true,
             width: '400px', height: '25px',
             selectedIndex: 0
         });

        $objects.bind('select', function (event) {
            var args = event.args;
            if(args && !isNaN(args.index)){
                var item = $objects.jqxComboBox('listBox').visibleItems[args.index];
                dw.qb.objectSelected = item.label.split('(')[1].split(')')[0];
                dw.qb.selectedCompleteObject = item.label;
                dw.qb.onSelectObject();
            }    
            
        });
                
        //start get fields
        dw.qb.ui.getFields = $copado('#getFields');
        dw.qb.ui.testQuery = $copado('#testQuery');
        
        dw.qb.ui.fields =  $copado('#fields-unselected');
        dw.qb.ui.fieldsSelected =  $copado('#fields-selected');

        dw.qb.ui.fieldsEx =  $copado('#fieldsEx').on('change',dw.qb.selectFieldEx);
        
         
        dw.qb.ui.getFields.on('click',function(e){
            if(!dw.qb.objectSelected){return;}
            
            //lock button
            dw.qb.ui.getFields
                .attr('disabled','disabled');

            dw.qb.ui.fields.html(labels.config.loading_label);    
            //call get
            dw.qb.getFields();
            
            return false;
        });
        
        //query label
        dw.qb.ui.query = $copado('.query-label');
        
        dw.qb.ui.$objects = $objects;
        
        //fields build
        
        dw.qb.ui.fieldsSelected.on('change',dw.qb.removeFieldSelection);
        dw.qb.ui.fields.on('change',dw.qb.addFieldSelection);
      
        dw.qb.preQuery && dw.qb.rebuild();       
            
        
        $copado('#testQuery').on('click',dw.qb.testQuery);
        
        $copado('#loading').hide();
        $copado('#queryBuilder').fadeIn();
        
        $objects.jqxComboBox('focus');
        
        //bind query hand edition sync
        dw.qb.ui.query.on('keyup change',function(){
            dw.qb.query = dw.qb.ui.query.val();
            var w = dw.qb.query.split(/ where /i);
            dw.qb.where = w.length > 1 ? ' where '+w[1]:'';
            
        });
    }catch(e){console.log('Error on QB init',e);}
    
};

dw.qb.objectSelected = false;
dw.qb.ui = {};  
dw.qb.selectedFields = [];
dw.qb.queryTemplate = 'Select fields from object clause';
dw.qb.query = false;

dw.qb.rebuild = function(){
    try{
        var preJson = dw.qb.preQuery;
        if(preJson.rb){
            dw.qb.preData = preJson;
            //preselect objects
            var item = dw.qb.ui.$objects.jqxComboBox('getItemByValue', preJson.rb.sco);
            if(item){
                dw.qb.ui.$objects.jqxComboBox('selectItem',item);
                
                //get fields (cache?)
                dw.qb.ui.getFields.click();
                
                
                //getFileds callback
                dw.qb.rebuilding = 1;
            }
            
            dw.qb.where = dw.qb.preData.q.split(/ where /i)[1] || '';
             
        }
    }catch(e){
        console.log('Error: ',e,dw.qb.preQuery ,preJson);
    }

};

dw.qb.addFieldSelection = function(){
    dw.qb.toogleFieldSelection(this,true);
};
dw.qb.removeFieldSelection = function(){
    dw.qb.toogleFieldSelection(this,false);
};

dw.qb.toogleFieldSelection = function(list,sel){
    
                
    var $el = $copado(list).find('option:selected'),
    el = $el.eq(0),
    field = $el.val();
    
    if(!field){return;}
    
    $el.attr('selected',false);
    
    if(!sel){
        //remove 
        //only remove if not is the only one external 
        if($el.is('[ext]') && dw.qb.ui.fieldsSelected.find('option[ext]').length < 2){
            alert(labels.config.req_ext_id_label);
            return;
        }
        var index = dw.qb.selectedFields.indexOf(field);
        dw.qb.selectedFields.splice(index, 1);
        dw.qb.ui.fields.append(el);
    }
    else{
        dw.qb.selectedFields.push(field);
        dw.qb.ui.fieldsSelected.append(el);
    }
    dw.qb.buildQuery();
};

dw.qb.onSelectObject = function(){
    dw.qb.ui.objectLabel = dw.qb.ui.objectLabel || $copado('#selected-obj');
    dw.qb.ui.objectLabel.html(dw.qb.objectSelected);
    dw.qb.ui.query.html('');
    dw.qb.ui.fields.html('');
    dw.qb.ui.getFields.removeAttr('disabled');

};

dw.qb.selectFieldEx = function(){
    var field = dw.qb.ui.fieldsEx.val();
    console.log('change ex', field)
    
    //unselect prev external selected
    var prev = dw.qb.externalId;
    dw.qb.externalId = field;
    
    //select on fields
    //$copado('option[value="'+dw.qb.externalId+'"]',dw.qb.ui.fields).click();
    $copado('option[value="'+dw.qb.externalId+'"]',dw.qb.ui.fields).attr('selected','selected');
    dw.qb.ui.fields.change();
    
    
    if(prev){ 
        //$copado('option[value="'+prev+'"]',dw.qb.ui.fieldsSelected).click();
        $copado('option[value="'+prev+'"]',dw.qb.ui.fieldsSelected).attr('selected','selected');
        dw.qb.ui.fieldsSelected.change();
    }
    
};

dw.qb.buildQuery = function(){

    var query = dw.qb.queryTemplate
        .replace('fields',dw.qb.selectedFields.join(','))
        .replace('object',dw.qb.objectSelected)
        .replace('clause',dw.qb.where?' where '+dw.qb.where:'');
    
    dw.qb.ui.query.val(query);

    dw.qb.query = query;
    dw.qb.queryTested = false;
};

dw.qb.getFields = function(){
    dw.qb.selectedFields = [];
    dw.qb.externalId = false;
    $copado('.query-step-2').hide();
    dw.qb.ui.fieldsSelected.splice(1,dw.qb.ui.fieldsSelected.length);
    dw.qb.ui.getFields
        .attr('disabled','disabled')
        .html(labels.config.loading_label);
    
    var cb = function(data){
        try{
            var len=data.length,
            html ='',exhtml='', exCounter =0;
            
            data = data.sort(function(a,b){
                  if(a.label.toLowerCase() < b.label.toLowerCase())
                        return - 1;
                  if(a.label.toLowerCase() > b.label.toLowerCase())
                        return 1;
            
                return 0;
            });
            
            for(var i=0; i<len; i++){
                var val = data[i].name,
                option = '<option value="'+val+'" '+(data[i].externalId?'ext="1"':'')+' title="'+val+' '+data[i].type+'">'+data[i].label+' ('+val+')</option>';
                html += option;
                
                if(data[i].externalId){
                    exhtml += option;
                    exCounter++;
                }
            }
            //unlock button
            dw.qb.ui.getFields
                .removeAttr('disabled')
                .html('Get fields');
            
            if(!exCounter){
                alert(labels.config.req_ext_id_label);
                return;
            }
            //console.log('html ==>',html);
            
            dw.qb.ui.fields.html(html);
            dw.qb.ui.fieldsEx.html(exhtml); 
            dw.qb.ui.testQuery.removeAttr('disabled');
            dw.qb.ui.testQuery.addClass('slds-button_success');
            $copado('.query-step-2').fadeIn(); 
            
            //preselect first external 
            !dw.qb.rebuilding && dw.qb.selectFieldEx();
            
            //if rebuilding
            if(dw.qb.rebuilding){
                dw.qb.rebuilding = 0;
                var fields = dw.qb.preData.q
                    .replace(/ from /i,' FROM ').replace(/select /i,' SELECT ')
                    .split(' FROM ')[0].split('SELECT ')[1]
                    .split(',');
                
                $copado(fields).each(function(el,val){
                    dw.qb.ui.fields.val(val);
                    dw.qb.ui.fields.change();
                });
                  
                
                //select external Id
                dw.qb.ui.fieldsEx.val(dw.qb.preData.f);
                dw.qb.selectFieldEx();
                //dw.qb.ui.fieldsEx.change();
                
                //paste query
                setTimeout(function(){
                    dw.qb.ui.query.val(dw.qb.preData.q);
                },321); 
                
                
            }
         }
         catch(e){
            console.log('Error on QB Rebuild',e)
         }
    };
    
    //remote call
    dw.u.getRemote(datasetup.config.describe_url.replace('{sobject}',dw.qb.objectSelected),function(res){
        cb(res);
    });
};

dw.qb.getObjectToRebuild = function(){
    var me = dw.qb;
    return {
        sco: me.selectedCompleteObject,
        fs: me.allfields,
        efs: me.allexfields,
        w: dw.qb.where    
    };
};

dw.qb.testQuery = function(e){
    e.preventDefault();
    
    if(!dw.qb.query){return false;}
    
    if(datasetup.type === 'Bulk Data'){
        if(dw.qb.query.match(/\(.*[select].*\)|COUNT\(|SUM\(/i)){
            alert(labels.config.bulk_soql_error);
            return false;
        }
    }
    
    
    var queryFields = dw.qb.query.match(/select (.*) from/i);
    queryFields = queryFields && queryFields.length >1 ? queryFields[1]:false;
    //check query malformed 
    if(!queryFields){
        alert();
        return false;
    }
    var hasExternal = false;
    //check query has at least one external ID
    $copado('#fieldsEx option').each(function(){
        if(queryFields.indexOf(this.value)!==-1){
            hasExternal = true;
            return false;
        }
    });
    
    if(!hasExternal){
        alert(labels.config.soql_hasnotext_error);
        return false;
    }
    
    $copado('#testQuery')
        .attr('disabled','disabled')
        .html(labels.config.testing);
    
    dw.u.getRemote(datasetup.config.testquery_url,function(r){
        console.log('testquery response:',r);
        if(r && r.done){
            dw.qb.queryTested = true;
            showMessage('CONFIRM',labels.config.successful_testing);
        }else{
            dw.qb.queryTested = false;
            showMessage('ERROR',r.error);
            
        }                
        $copado('#testQuery')
            .removeAttr('disabled')
            .html(labels.config.test_query);
        
    },dw.qb.query, true,function(r){
        //TODO: unify this code and response error
        console.log('testquery response error:',r);
        dw.qb.queryTested = false;
        showMessage('ERROR',(r.error||r));
         
        $copado('#testQuery')
            .removeAttr('disabled')
            .html(labels.config.test_query);
    });

    return false;
};

function init(force){
    //start component
   dw.u.getCachedRemote({
       url:datasetup.config.sobjects_url,
       name:'Data',
       force:force,
       parentId: datasetup.org__c,
       success:function(res, date){
            dw.qb.createCacheDeleteButton(date);
            console.warn('rest',res);
            dw.qb.startQueryBuilder(res);
       },
       error: function(r){
         console.log('Error init: ',r);
       }
   });
}

/*function overridePageMessages(){    

    textureEffect = 'slds-theme--alert-texture';

    $copado('.warningM3').addClass('slds-notify slds-notify--toast slds-theme--warning customMessage '+textureEffect);          
    $copado('.confirmM3').addClass('slds-notify slds-notify--alert slds-theme--success  customMessage '+textureEffect);    
    $copado('.errorM3').addClass('slds-notify slds-notify--alert slds-theme--error customMessage '+textureEffect);                  
    $copado('.infoM3').addClass('slds-notify slds-notify--toast customMessage '+textureEffect);    

    $copado('.errorM3').removeClass('errorM3'); 
    $copado('.confirmM3').removeClass('confirmM3'); 
    $copado('.infoM3').removeClass('infoM3');   
    $copado('.warningM3').removeClass('warningM3');  
} */ 

