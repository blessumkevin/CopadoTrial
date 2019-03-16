
var customSetting = customSetting || {};
customSetting.ops = customSetting.ops || {};
customSetting.ui = customSetting.ui || {};





customSetting.data = {
    objSelected: 0,
    completeObjSelected: 0,
    step: false,
    values: []
};

initCS = function(task){
    console.debug("initCS()");

    customSetting.data.step = task;
    customSetting.ops.getObjects(task, customSetting.ops.getObjectsCB);

    customSetting.ui.getCSValues = $copado('#getCSValues');
    customSetting.ui.toogleAll = $copado('#cs-toggle-all');
    customSetting.ui.refreshCache = $copado('#refresh-cache-cs');

    if (customSetting.started) {
        customSetting.ops.reset();
    } else {
        customSetting.started = true;
    }
    customSetting.ui.toogleAll.off('click');
    customSetting.ui.getCSValues.off('click');
    customSetting.ui.refreshCache.off('click');

    customSetting.ui.toogleAll.on('click', customSetting.ops.toggleAll);    
    customSetting.ui.getCSValues.on('click', customSetting.ops.getCSValues);
    customSetting.ui.refreshCache.on('click', customSetting.ops.refreshCache);
    
};

customSetting.ops.reset = function(){
    $copado('#cs-values').html('');
    customSetting.data.objSelected = false;
    customSetting.data.completeObjSelected = false;
};

customSetting.ops.refreshCache = function() {

    if ($copado('#cs-values option:selected').length && !confirm('You have selected values. If continue will lose the current selection.')) {
        return false;
    }

    lock();
    customSetting.data.objects = false;
    customSetting.ops.reset();
    customSetting.ops.getObjects(customSetting.data.step, customSetting.ops.getObjectsCB, true);


};

customSetting.ops.getObjectsCB = function() {
    customSetting.ops.createObjectSelector('#objectsCJ', customSetting.data.objects, customSetting.ops.onSelectObject);
};

customSetting.ops.onSelectObject = function(name, label) {
    console.log('selected: ', name, label)
    customSetting.data.objSelected = name;
    customSetting.data.completeObjSelected = label;
    customSetting.ops.enabledBtn('#getCSValues', 'Get Custom Settings values');
};

customSetting.ops.prepareSource = function(data) {
    //normalize data
    var temp_source = [],
        len = data.length;
    for (var i = 0; i < len; i++) {
        temp_source[i] = data[i].L + ' (' + data[i].N + ')';
    }

    temp_source.sort();
    return temp_source;
};

customSetting.ops.createObjectSelector = function(selector, data, cb) {
    console.log('prepare selector ', selector);
    console.log('prepare data ', data);
    console.log('prepare cb ', cb);
    var $objects = $copado(selector).jqxComboBox({
        source: customSetting.ops.prepareSource(data),
        autoComplete: true,
        width: '400px',
        height: '25px',
        selectedIndex: 0
    });
    if(data.length == 1){
        customSetting.ops.onSelectObject(data[0].N,customSetting.ops.prepareSource(data));
        console.log('what is this item',customSetting.ops.prepareSource(data));
    }
    $objects.bind('select', function(event) {
        var args = event.args;
        if (args && !isNaN(args.index)) {
            var item = $objects.jqxComboBox('listBox').visibleItems[args.index];
            cb && cb(item.label.split('(')[1].split(')')[0], item.label);
        }

    });

    $objects.jqxComboBox('focus');


    return $objects;

};

customSetting.ops.toggleAll = function() {
    var prev = $copado(this).attr('data-all');    
    console.log('prev',prev=="true",$copado(this));
    $copado(this).attr('data-all',prev!="true").val(prev == "true" ? 'Unselect all' : 'Select all');
    console.log('asagsagag',$copado('#cs-toggle-all').attr('data-all'));
    var options = $copado('#cs-values').find('option');    
    var selectVal = prev=="true" ? true : false;
    options.prop('selected', selectVal);        
    return false;
};

customSetting.ops.getObjects = function(step, cb, force) {
    console.log('get objects')
    if (customSetting.data.objects) {
        console.log('get objects is in cache')
        cb();
        
        return;
    }
    
    dw.u.getCachedRemote({
        url: datasetup.config.sobjects_url + '&onlyCustomSettings=true',
        name: 'Custom Settings',
        force: force,
        parentId: datasetup.org__c,
        success: function(res, date) {

            console.log('get data callbacl');
            customSetting.data.objects = res;
            cb && cb();
            unlock();
        },
        error: function(r) {
            console.log('Error: ',r)
            unlock();
        }
    });
};
customSetting.ops.getRemoteCSValues = function() {
    lock();
    dw.u.getRemote(datasetup.config.custom_settings_url.replace('{sobject}', customSetting.data.objSelected), function(res) {
        customSetting.data.values = res.sort(function(a, b) {
            if (a.Name < b.Name)
                return -1;
            if (a.Name > b.Name)
                return 1;
            return 0;
        });
        customSetting.ops.prepareGrid();

    }, false, true, function(res) {
        console.log('res error getRemoteCSValues')
        //res && copadoApp.showMessage('ERROR', res);
        unlock();
    });
};

customSetting.selectedType = false;

customSetting.ops.prepareGrid = function() {
    var res = customSetting.data.values,
        len = res.length,
        options = '';
    customSetting.selectedType = len ? res[0].type : false;

    var typeField = customSetting.selectedType == 'Hierarchy' ? 'SetupOwnerId' : 'Name';

    for (var i = 0; len > i; i++) {
        var item = res[i];
        options += '<option value="' + item[typeField] + '">' + item.Name + '</option>';
    }
    $copado('#cs-values').html(options);
    unlock();
};

customSetting.ops.enabledBtn = function(sel, label) {
    customSetting.ops.setBtn(true, sel, label);
};

customSetting.ops.setBtn = function(action, sel, label) {
    setTimeout(function() {
        var $btn = $copado(sel);

        if (action) {
            $btn
                .attr('disabled', null)
                .removeClass('btnDisabled');
        } else {
            $btn
                .attr('disabled', 'disabled')
                .addClass('btnDisabled');
        }
        $btn.prop('tagName') === 'INPUT' ? $btn.val(label) : $btn.html(label);
    }, 1);

};

customSetting.ops.getCSValues = function() {
    if (!customSetting.data.objSelected) {
        console.log('no selected');
        customSetting.ui.getCSValues.attr('disabled','disabled');
        return false;
    }

    customSetting.ops.getRemoteCSValues();
    return false;

};