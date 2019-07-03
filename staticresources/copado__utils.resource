var Base64 = {
    _keyStr: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
    _MINSIZEFORBTOA: 10485760, // minimum size to siwtch to BOTA/ATOB native functions ( 200x faster, but not unicode-friendly )
    encode: function(c) {
        console.debug('Base64.encode.length', c.length, c.length > Base64._MINSIZEFORBTOA ? 'using btoa' : 'using unicode-safe');
        // Comment for Changes.
        // NR: there is  issue in btoa/atob: https://developer.mozilla.org/en/docs/Web/API/WindowBase64/Base64_encoding_and_decoding
        // the std solution is too slow, so the fallback is the original code.
        // NR: btoa/atob sometimes fails, but silently, so, we get mangled characters... so, alternative: over 10mb of attachment, switch to native, otherwise, local
        try {
            if (c.length > Base64._MINSIZEFORBTOA)
                return window.btoa(c);
        } catch (e) {
            console.debug('btoa did not work. Falling back to Base64.encode because', e);
        }

        var a = "",
            d, b, f, g, h, e, j = 0;
        for (c = Base64._utf8_encode(c); j < c.length;) d = c.charCodeAt(j++), b = c.charCodeAt(j++), f = c.charCodeAt(j++), g = d >> 2, d = (d & 3) << 4 | b >> 4, h = (b & 15) << 2 | f >> 6, e = f & 63, isNaN(b) ? h = e = 64 : isNaN(f) && (e = 64), a = a + this._keyStr.charAt(g) + this._keyStr.charAt(d) + this._keyStr.charAt(h) + this._keyStr.charAt(e);
        return a
    },
    decode: function(c) {
        console.debug('Base64.decode.length', c.length, c.length > Base64._MINSIZEFORBTOA ? 'using atob' : 'using unicode-safe');

        // NR: there is  issue in btoa/atob: https://developer.mozilla.org/en/docs/Web/API/WindowBase64/Base64_encoding_and_decoding
        // the std solution is too slow, so the fallback is the original code.
        // NR: btoa/atob sometimes fails, but silently, so, we get mangled characters... so, alternative: over 10mb of attachment, switch to native, otherwise, local
        try {
            if (c.length > Base64._MINSIZEFORBTOA)
                return window.atob(c);
        } catch (e) {
            console.debug('atob did not work. Falling back to Base64.encode because', e);
        }

        var a = "",
            d, b, f, g, h, e = 0;
        for (c = c.replace(/[^A-Za-z0-9\+\/\=]/g, ""); e < c.length;) d = this._keyStr.indexOf(c.charAt(e++)), b = this._keyStr.indexOf(c.charAt(e++)), g = this._keyStr.indexOf(c.charAt(e++)), h = this._keyStr.indexOf(c.charAt(e++)), d = d << 2 | b >> 4, b = (b & 15) << 4 | g >> 2, f = (g & 3) << 6 | h, a += String.fromCharCode(d), 64 != g && (a += String.fromCharCode(b)), 64 != h && (a += String.fromCharCode(f));
        a = Base64._utf8_decode(a);
        return a;
    },
    _utf8_encode: function(c) {
        c = c.replace(/\r\n/g, "\n");
        for (var a = "", d = 0; d < c.length; d++) {
            var b = c.charCodeAt(d);
            128 > b ? a += String.fromCharCode(b) : (127 < b && 2048 > b ? a += String.fromCharCode(b >> 6 | 192) : (a += String.fromCharCode(b >> 12 | 224), a += String.fromCharCode(b >> 6 & 63 | 128)), a += String.fromCharCode(b & 63 | 128))
        }
        return a
    },
    _utf8_decode: function(c) {
        for (var a = "", d = 0, b = c1 = c2 = 0; d < c.length;) b = c.charCodeAt(d), 128 > b ? (a += String.fromCharCode(b), d++) : 191 < b && 224 > b ? (c2 = c.charCodeAt(d + 1), a += String.fromCharCode((b & 31) << 6 | c2 & 63), d += 2) : (c2 = c.charCodeAt(d + 1), c3 = c.charCodeAt(d + 2), a += String.fromCharCode((b & 15) << 12 | (c2 & 63) << 6 | c3 & 63), d += 3);
        return a
    }
};

//IE helper
!window.console && (window.console = {
    log: function() {},
    error: function() {}
});

// parses an ISO date only (ignores ms and tz) "2018-04-25T13:24:39.000Z" and returns a LOCAL date.
Date.fromISOString = function(input) {
  return new Date(Date.UTC(
    parseInt(input.slice(0, 4), 10),
    parseInt(input.slice(5, 7), 10) - 1,
    parseInt(input.slice(8, 10), 10),
    parseInt(input.slice(11, 13), 10),
    parseInt(input.slice(14, 16), 10),
    parseInt(input.slice(17,19), 10)
  ));
};



//namespace
var dw = dw || {};
dw.u = {
    conf: {
        retryLimit: 300,
        retryUISelector: '#retry-label',
        fields2prevent: '==SetupOwnerId==, ==s==, ==Name==, ==type==, ==LastModifiedDate==, ==SystemModstamp==, ==IsDeleted==, ==CreatedById==, ==CreatedDate==, ==Id==, ==LastModifiedById=='
    }
};

dw.u.retry = function(url, cb, postData, avoidRetry, onError) {
    if (dw.u.getRemote.attempts < dw.u.conf.retryLimit) {
        dw.u.getRemote(url, cb, postData, avoidRetry, onError);
        //ﬁdw.u.conf.retryUISelector).append('...');
    } else {
        console.log('retry fail', dw.u.getRemote.attempts, dw.u.conf.retryLimit)
        alert(copadoLabels.OOPS_SOMETHING_WENT_WRONG_GETTING_ORG_REMOTE_DATA);
        return false;
    }
};

dw.u.getRemote = function(url, cb, postData, avoidRetry, onError, cbOnOk) {
    if(Copado_Licenses.hasMultiLicense && !(Copado_Licenses.hasCopado ||Copado_Licenses.hasCCM ||Copado_Licenses.hasCST || Copado_Licenses.hasCCH) ) {
        var errorMsgs = 'Your current license does not allow performing this action.';
        alert(errorMsgs);
        return;
    }

    dw.u.getRemote.attempts++;
    sforce.connection.remoteFunction({
        url: url,
        requestHeaders: {
            "Content-Type": "text/json",
            "userId": _temp_conf.userId,
            "orgId": _temp_conf.orgId,
            "sessionId": _temp_conf.sessionId,
            "token": _temp_conf.token
        },
        method: postData ? 'POST' : "GET",
        requestData: postData ? postData : {},
        onSuccess: function(res) {
            //check response
            try {
                !res && console.log('No response');


                var obj = $copado.parseJSON(res.replace(/(\r\n|\n|\r)/gm, ' '));
                console.log('obj utils ===> ',obj);
                if(obj && typeof obj === 'object' && obj.length>0){
                    obj = preventXSSonJQXGrid(obj);
                }
                console.log('object:::',obj);


                //FIXME: understand why parse is giving an string
                if (typeof obj === 'string') {
                    obj = $copado.parseJSON(obj.replace(/(\r\n|\n|\r)/gm, ' '));
                }

                if (obj.ok && !avoidRetry) {
                    console.log('calling api in two secs...');
                    setTimeout(function() {
                        dw.u.retry(url, cb, postData, avoidRetry, onError);
                    }, 2000);
                    if(cbOnOk){
                        cb && cb(obj);
                    }
                    return;
                }

                if (obj.error) {
                    console.error('Remote Error: ', obj.error);
                    avoidRetry = true;
                    alert(obj.error);
                    throw obj.error;
                }
                console.log('obj.messages utils ===> ',obj.messages);
                if (obj.messages && obj.messages.length > 0) {
                    var errorMsgs = obj.messages.join('\n');
                    alert(errorMsgs);
                    console.error('Error Messages: ', errorMsgs);
                    throw errorMsgs;
                }
                console.log('cb in utilss....',cb);
                cb && cb(obj);

            } catch (e) {
                console.log('dw.u.getRemote() remote error', e);
                if (avoidRetry) {
                    var loadingPanels =  $copado('#loading,#screenLocker');
                    if(loadingPanels.length){
                        loadingPanels.hide();
                    }
                    var gridCheck =  $copado('#jqxgrid');
                    if(gridCheck.length){
                        gridCheck.html(e);
                    }
                }

                if (onError) {
                    onError(res);
                    return;
                }

                if(avoidRetry) {
                    // there was no error handler, and there is no retry. Notify the customer
                    var errMsg = ''+res;
                    try {
                        errMsg = JSON.stringify(e);
                    } catch(e1) {
                        console.error('Couldnt parse error json'+e1);
                    }
                    alert('There was an exception trying to contact Copado API: '+errMsg);
                }else{
                    setTimeout(function() {
                        dw.u.retry(url, cb, postData, avoidRetry, onError);
                    }, 2000);
                }
            }
        },
        onFailure: function(response) {
            console.log('dw.u.getRemote() onFailure', onError, response);
            if (onError) {
                onError(response);
                return;
            }
            if(avoidRetry) {
                // there was no error handler, and there is no retry. Notify the customer
                var errMsg = ''+response;
                if(!errMsg)
                alert('There was an error trying to contact Copado API: '+errMsg);
            }else{
                setTimeout(function() {
                    dw.u.retry(url, cb, postData, avoidRetry, onError);
                }, 2000);
            }
        },
        timeout: 250000
    });

};
dw.u.getRemote.attempts = 0;

dw.u.deleteAttach = function(parentId, name) {
    console.info('deleting attachments from '+parentId+'...');
    var result = sforce.connection.query("Select Id From Attachment where Name='" + name + "' and parentId = '" + parentId + "'");
    var rv = {};
    if(result.size > 0){
        try{
            var records = result.getArray("records");            
            var idsForDeletion = [];
            for(var i=0; i<records.length; i++){
                idsForDeletion.push(records[i].Id);                
            }
            var delRes = sforce.connection.deleteIds(idsForDeletion);

            for(var i = 0; i<delRes.length; i++){
                
                if(delRes[i].success == "false"){                    
                    throw delRes[i].errors.message;
                    break;
                }
            }
            rv.success = true;
            rv.id = parentId;
            return rv;
        }catch(e){
            rv.success = false;
            rv.id = parentId;
            rv.message = 'Exception while deleting metadata attachment : '+e;
            console.warn('Exception while deleting metadata attachment : '+e);
            return rv;
        }
    }else{
        rv.success = false;
        rv.id = parentId;
        rv.message = 'No attachment found to delete';
        console.warn('no attachment found');
        return rv;
    }
    
}

function htmlEntities(str) {
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

dw.u.getAttach = function(parentId, name) {

    var q = "Select Id, Body, LastModifiedDate, Name, ParentId From Attachment where Name='" + name + "' and parentId = '" + parentId + "' order by LastModifiedDate DESC limit 1",
        result = sforce.connection.query(q),
        records = result.getArray("records");
    return records;
};

dw.u.getAttachById = function(attachmentId) {
    var q = "Select Id, Body, LastModifiedDate, Name, ParentId From Attachment where Id='" + attachmentId + "'",
        result = sforce.connection.query(q),
        records = result.getArray("records");
    return records;
};

dw.u.getDecodedAttach = function(parentId, name) {
    var a = dw.u.getAttach(parentId, name);
    if (!a.length) return null;
    a.Body = Base64.decode(a[0].Body);
    //below replaces opening and closing tags based on xss concerns
    while(a.Body.indexOf('<') > -1 || a.Body.indexOf('>') > -1){
             a.Body = a.Body.replace('<','').replace('>','');
         }
    return a;
};


//upsert
dw.u.upsertAttach = function(parentId, name, body, alreadyCheck, newName) {


    var Id = false;
    if (!alreadyCheck) {
        var attach = dw.u.getAttach(parentId, name);
        if (attach.length) {
            Id = attach[0].Id;
        }

    }
    var att = new sforce.SObject("Attachment");
    att.parentId = parentId;
    if(newName) {
        att.name = newName;
    } else {
        att.name = name;
    }
    
    att.body = Base64.encode(body);

    if (Id) {
        att.Id = Id;
    }

    var result = sforce.connection.upsert("Id", [att]);


};
//added this function to be able to prevent Stored XSS Vulnerability based on Salesforce security report - UCU
preventXSSonJQXGrid = function(objectArray){
    //below return all fields of the current object to check on the loop
    if(typeof objectArray == undefined || objectArray.length === 0) return; // added this condition, because it was throwing error if the objectArray was null or undefined

    var fields = Object.keys(objectArray[0]);
    for(var i=0;i<objectArray.length;i++){
            for(var c=0;c<fields.length;c++){
                var currentValue = objectArray[i][fields[c]];
                if(currentValue && typeof currentValue === 'string'){
                    while(currentValue.indexOf('<') > -1 || currentValue.indexOf('>') > -1){
                        currentValue = currentValue.replace('<','').replace('>','');
                    }
                    objectArray[i][fields[c]] = currentValue;
                }
            }
        }

    return objectArray;
};

//this function try to recover the data from cached attach
//if is not cached it get from remote source and save it in attach
dw.u.getCachedRemote = function(opt) {
    /*
    opt sample
    {
        url: remoteUrl,
        parentId: ':)',
        name: 'Metadata' ,
        postData:data
        success:function(){},
        error:function(){},

    };*/

    var attach = dw.u.getAttach(opt.parentId, opt.name);
    console.log('attach=1==> ',attach);
    if (opt.force || attach.length != 1) {

        //get remote and save
        dw.u.getRemote.attempts = 0;

        dw.u.getRemote(opt.url, function(res) {
                console.log('getRemote ok', res);

                //save as attach
                dw.u.upsertAttach(opt.parentId, opt.name, JSON.stringify(res), !opt.force);
                var attachLocal = dw.u.getAttach(opt.parentId, opt.name);
                console.log('attachLocal===> ',attachLocal);
                //format date
                var date = Date.fromISOString(attachLocal[0].LastModifiedDate);
                //added by UCU to be able update Refresh Cache date-time for the new attachments on Grid
                opt.success(preventXSSonJQXGrid(res),  date.toLocaleString());
            },
            opt.postData ? opt.postData : null
        );

    } else {
         try{
            //decode the attach body
            console.log('attach==2=> ',attach);
            var res = Base64.decode(attach[0].Body);


            //format date
            var date = Date.fromISOString(attach[0].LastModifiedDate);
            //parse json
            opt.success(preventXSSonJQXGrid($copado.parseJSON(res)), date.toLocaleString());

        }catch(e){
            //console.log(Base64.decode(attach[0].Body));
            console.error('Exception on saved data:',e);
            opt.error();
            throw e;
        }
    }

};

dw.u.getSavedStepData = function(type, isNotJSON) {
    if (!rock.stepId) return false;
    return dw.u.getSavedData(rock.stepId, type, isNotJSON);
};


dw.u.getSavedData = function(id, type, isNotJSON) {
    var attach = dw.u.getAttach(id, type);
    if (attach.length > 0) {
        try {
            // Save the last modified date of this attachment in case the caller needs it ( scratch org.resource needs it )
            dw.u.getSavedData_AttachmentLastModifiedDate = attach[0].LastModifiedDate;
            //decode the attach body
            var res = Base64.decode(attach[0].Body);
            //parse json
            return isNotJSON ? res : $copado.parseJSON(res);

        } catch (e) {
            console.log('Exception on saved data:', e);
        }
    }
    return false;
};

// JS Upload files
var coUploadAttachment = {
     maxStringSize: 6000000,    //Maximum String size is 6,000,000 characters
     maxFileSize : 4350000,    //After Base64 Encoding, this is the max file size
     chunkSize : 950000,       //Maximum Javascript Remoting message size is 1,000,000 characters
     attachment : {},
     attachmentName : '',
     attachmentBody : '',
     fileSize : 0,
     positionIndex : 0,
     doneUploading : false,
     parentId : '', // If doDML is enabled this should not be empty
     doDML : false,
    //Method to prepare a file to be attached to the Account bound to the page by the standardController
    uploadFile : function(inputName, callback){

        var that = this;
        console.log(that);
        if(!document.getElementById(inputName)) {
            alert("You must choose a file before trying to upload it");
            return; // TODO: add error message
        }
        var file = document.getElementById(inputName).files[0];
              if(file) {
                 console.log('coUploadAttachment:::uploadFile',file);
                 if(file.size <= that.maxFileSize) {
                    if(that.attachmentName.length <= 0)that.attachmentName = file.name;
                    var fileReader = new FileReader();
                    fileReader.onloadend = function(e) {
                        that.attachment = window.btoa(this.result);  //Base 64 encode the file before sending it
                        that.positionIndex=0;
                        that.fileSize = that.attachment.length;
                        console.log("coUploadAttachment:::uploadFile Total Attachment Length: " + that.fileSize);
                        that.doneUploading = false;
                        if(that.fileSize < that.maxStringSize) {
                          that.uploadAttachment(null,that.doDML,callback); // null param is for fileId this may change
                        } else {
                          alert("Base 64 Encoded file is too large.  Maximum size is " + that.maxStringSize + " your file is " + that.fileSize + ".");
                        }
                    }
                    fileReader.onerror = function(e) {
                        alert("There was an error reading the file.  Please try again.");
                    }
                    fileReader.onabort = function(e) {
                        alert("There was an error reading the file.  Please try again.");
                    }
                    fileReader.readAsBinaryString(file);  //Read the body of the file

              }else {
                alert("File must be under 4.3 MB in size.  Your file is too large.  Please try again.");
              }
        }else {
          alert("You must choose a file before trying to upload it");
        }
    },
    //Method to send a file to be attached to the Account bound to the page by the standardController
    //Sends parameters: Account Id, Attachment (body), Attachment Name, and the Id of the Attachment if it exists to the controller
    uploadAttachment : function(fileId, doDML,callback) {
        var that = this;
        if(that.fileSize <= that.positionIndex + that.chunkSize) {
          that.attachmentBody = that.attachment.substring(that.positionIndex);
          console.log('attachmentBody = that.attachment.substring(that.positionIndex) ===>',Base64.decode(that.attachment.substring(that.positionIndex)));
          that.doneUploading = true;
        } else {
          that.attachmentBody = that.attachment.substring(that.positionIndex, that.positionIndex + that.chunkSize);
        }
        console.log("coUploadAttachment:::uploadAttachment Uploading " + that.attachmentBody.length + " chars of " + that.fileSize);
        //TODO : Replace with dynamic one without standard controller

        if(doDML && doDML === true) {
        if(!JsRemotingController) return; // TODO: add error message
            JsRemotingController.doUploadAttachment(
                that.parentId, that.attachmentBody, that.attachmentName, fileId,
                function(result, event) {
                    console.log(result);
                    if(event.type === 'exception') {
                        console.log("exception");
                        console.log(event);
                    } else if(event.status) {
                        if(result.substring(0,3) == '00P') {
                            if(that.doneUploading == true) {
                                console.log('coUploadAttachment:::uploadAttachment UPLOAD COMPLETED');
                            } else {
                                that.positionIndex += that.chunkSize;
                                uploadAttachment(result);
                            }
                        }
                    } else {
                        console.log(event.message);
                    }
                },
                {buffer: true, escape: true, timeout: 120000}
            );
        }
        if(callback) callback();
    }
};


function reformatMilliseconds(milliseconds) {

    var d = parseInt(milliseconds) / 1000;
    x = d
    seconds = x % 60
    x /= 60
    minutes = x % 60
    x /= 60
    hours = x % 24
    x /= 24
    days = x

    var output = (Math.floor(hours) > 0) ? Math.floor(hours) + ' ' + copadoLabels.HOURS + ' ' : '';
    output += (Math.floor(minutes) > 0) ? Math.floor(minutes) + ' ' + copadoLabels.MINUTES + ' ' : '';
    output += (Math.floor(seconds) > 0) ? Math.floor(seconds) + ' ' + copadoLabels.SECONDS + ' ' : '';
    output += (milliseconds > 0 && milliseconds < 1000) ? milliseconds + ' ' + copadoLabels.MILLISECONDS : '';
    return output;
};

/*************************************************
Generic Grid Helper
*************************************************/
var coGridHelper = {
    /**
     * Merge selected items from 2 sources. using the "s" attribute
     * @param  {[type]} metaOrgData [description]
     * @param  {[type]} dataStep    [description]
     * @return {[type]}             [description]
     */
    mergeSavedData: function(metaOrgData, dataStep) {

        var len = dataStep.length;

        while (len--) {
            if (typeof dataStep[len] !== 'object') {
                delete dataStep[len];
            } else {
                dataStep[len].s = true;
            }
        }

        var len2 = dataStep.length;
        for (var i = 0; i < len2; i++) {
            var el = dataStep[i];

            var index = coGridHelper.getIndexByNT(metaOrgData, el.n, (el.t || el.ns));
            if (index > -1) {
                metaOrgData[index].s = true;
            } else {
                if (typeof(window._errNotFoundShown) == 'undefined') {
                    window._errNotFoundShown = true;
                    alert(copadoLabels.missing_element_msg + (el.t || el.ns) + ' - ' + el.n);
                }
            }
        }

        return metaOrgData;
    },

    /**
     * get selected items from the datasource
     * @return {[type]} [description]
     */
    getSelectedObj: function() {
        // NR: when there is no coGridHelper (because it is not a partial selection), we return empty array
        if (!coGridHelper.datasource)
            return [];
        var data = coGridHelper.datasource.localdata,
            len = data.length;

        coGridHelper._selectedNames = [];

        while (len--) {
            var o = {
                n: data[len].n,
                s: true,
                d: data[len].d,
                b: data[len].b,
                cd: data[len].cd,
                cb: data[len].cb,
                ai: data[len].ai,
                vk: data[len].vk,
            };

            if (typeof data[len].r !== 'undefined') {
                o.r = data[len].r;
            } else {
            //MY: When retrieve only is undefined set it as false by default. Backend depends on the parameter so it
            //should never be undefined in the attachment that we create for backend to use
                o.r = false;
            }

            if (typeof data[len].ns != 'undefined') {
                o.ns = data[len].ns;
            } else {
                o.t = data[len].t;
            }

            data[len].s && coGridHelper._selectedNames.push(o);
        }
        return coGridHelper._selectedNames;
    },

    //selected "Names"
    _selectedNames: [],

    /**
     * helper to find index items by name, namespace and type
     * @param  {[type]} arr [description]
     * @param  {[type]} n   [description]
     * @param  {[type]} t   [description]
     * @return {[type]}     [description]
     */
    getIndexByNT: function(arr, n, t) {

        var initialIndex = 0; // todo improve index change >> this.initialIndex || 0,
        len = arr.length;

        for (initialIndex; initialIndex < len; initialIndex++) {
            var el = arr[initialIndex];
            try {
                if (el.n === n && (el.t === t || el.ns === t)) {
                    this.initialIndex = initialIndex;
                    return initialIndex;
                }
            } catch (e) {
                console.error(e);
                return -1;
            }
        }
        return -1;
    },

    /**
     * Save in attachment the selected items of the grid
     * @param  {[type]} id                   parentId
     * @param  {[type]} type                 Attachment Name
     * @param  {[type]} additionalValidation function for additional validations
     * @param  {[type]} allowEmpty           skip length validation
     * @param  {[type]} callcack             
     * @return {[type]}                      false
     */
    saveSelected: function(id, type, additionalValidation, allowEmpty, callback, sel) {
        console.debug('... Saving Attachment');
        var me = coGridHelper;
        //validations
        //check global selected items
        me.getSelectedObj();
        if (!allowEmpty && !me._selectedNames.length) {
            //check if copadoApp showmessage is active
            if (copadoApp.showMessage) {
                copadoApp.showMessage('ERROR', copadoLabels.SPECIFY_AT_LEAST_ONE_ITEM_TO_DEPLOY, 0);
            } else {
                alert(copadoLabels.SPECIFY_AT_LEAST_ONE_ITEM_TO_DEPLOY);
            }
            return false;
        }
        var valid = !additionalValidation ? true : additionalValidation(me._selectedNames);
        valid && me.remoteSaveMeta(id, sel || me._selectedNames, type, callback);

        return false;
    },

    /**
     * save an attachment
     * @param  {[type]} id       parentId
     * @param  {[type]} items    data for stringify
     * @param  {[type]} type     attachment name
     * @param  {[type]} callcack function on callback
     * @return {[type]}          void
     */
    remoteSaveMeta: function(id, items, type, callback) {
        console.log(items);
        dw.u.upsertAttach(id, type, JSON.stringify(items));
        callback && callback();
    }
};