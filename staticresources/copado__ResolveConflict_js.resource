var conversionFunc = conversionFunc || {},
    jsonValidation = jsonValidation || {},
    parseOperations = parseOperations || {},
    modalOperations = modalOperations || {},
    panelFunctions = panelFunctions || {};
(function(self) {
    var spacing = '  ',

    getType = function(obj) {
        var type = typeof obj;
        if (obj instanceof Array) {
            return 'array';
        } else if (type == 'string') {
            return 'string';
        } else if (type == 'boolean') {
            return 'boolean';
        } else if (type == 'number') {
            return 'number';
        } else if (type == 'undefined' || obj === null) {
            return 'null';
        } else {
            return 'hash';
        }
    },

    convert = function(obj, ret) {
        var type = getType(obj);

        switch (type) {
            case 'array':
                convertArray(obj, ret);
                break;
            case 'hash':
                convertHash(obj, ret);
                break;
            case 'string':
                convertString(obj, ret);
                break;
            case 'null':
                ret.push('null');
                break;
            case 'number':
                ret.push(obj.toString());
                break;
            case 'boolean':
                ret.push(obj ? 'true' : 'false');
                break;
        }
    },

    convertArray = function(obj, ret) {
        if (obj.length === 0) {
            ret.push('[]');
        }
        for (var i = 0; i < obj.length; i++) {

            var ele = obj[i];
            var recurse = [];
            convert(ele, recurse);

            for (var j = 0; j < recurse.length; j++) {
                ret.push((j == 0 ? '- ' : spacing) + recurse[j]);
            }
        }
    },

    convertHash = function(obj, ret) {
        for (var k in obj) {
            var recurse = [];
            if (obj.hasOwnProperty(k)) {
                var ele = obj[k];
                convert(ele, recurse);
                var type = getType(ele);
                if (type == 'string' || type == 'null' || type == 'number' || type == 'boolean') {
                    ret.push(normalizeString(k) + ': ' + recurse[0]);
                } else {
                    ret.push(normalizeString(k) + ': ');
                    for (var i = 0; i < recurse.length; i++) {
                        ret.push(spacing + recurse[i]);
                    }
                }
            }
        }
    },

    normalizeString = function(str) {
        if (str.match(/^[\w]+$/)) {
            return str;
        } else {
            return '"' + escape(str).replace(/%u/g, '\\u').replace(/%U/g, '\\U').replace(/%/g, '\\x') + '"';
        }
    },

    convertString = function(obj, ret) {
        ret.push(normalizeString(obj));
    };

    self.json2yaml = function(obj) {
        if(obj==''){
            return '';
        }
        //yaml parser error fix for empty files
        if (typeof obj == 'string') {
            obj = JSON.parse(obj);
        }

        var ret = [];
        convert(obj, ret);
        return ret.join('\n');
    };
})(conversionFunc);

(function(self) {
    var setGlobalErrorMessage = function(message, lineNo) {
        var elt = $copado('#errorMessage');
        elt.text(message);
        elt.data('line',lineNo);
    },
    addLineError = function(lineNo) {
        config.hasError = true;
        config.errorLines.push(lineNo);
        var line = editor.edit.doc.getLineHandle(lineNo);
        console.log('addLineError :: adding error message ',line);
        if (line) {
            editor.edit.doc.addLineClass(line, 'background', 'line-error');
        }
    },
    removeLineErrors = function(className) {
        config.hasError = false;
        for (var i = 0; i<config.errorLines; i++) {
            var line = editor.edit.doc.getLineHandle(config.errorLines[i]);
            console.log('removeLineErrors :: removing error message ',line);
            if (line) editor.edit.doc.removeLineClass(line, 'background', 'line-error');
        }
        config.errorLines = [];
    }

    self.parseYaml = function() {
        try{
            if(editor.edit.doc.getValue().length > 0) {
                var doc = jsyaml.load(editor.edit.doc.getValue());
                removeLineErrors('line-error');
            }
            setGlobalErrorMessage('' , 0);
            return null;
        } catch(e) {
            removeLineErrors('line-error');
            var lineNo = e.mark.line;
            // console.log('lineNo===> ',lineNo);
            e.message = e.message.replace('line '+lineNo,'line '+(lineNo + 1));
            console.warn('code exception: ',e.message);
            setGlobalErrorMessage('ERROR: ' + e.message , lineNo);
            addLineError(lineNo);
            return true;
        }
    }
})(jsonValidation);

(function(self) {
    self.setPreValue = function(sPane,format) {
        att2Res = $copado('[id$=attHiddenInp]').val();
        // console.log('directly inp hidden ===> ',$copado('[id$=attHiddenInp]').val());
        // console.log('directly att2Res ===> ',att2Res);

        $copado('#xmlJson>button').removeClass('slds-button_brand');
        if (format) {
            $copado(format).addClass('slds-button_brand');
            currentMode = format = $copado(format).attr('cType');
            jsCookies.set('merge.conflict.format',currentMode);
        } else if (!format && currentMode) {
            $copado('[cType="'+currentMode+'"]').addClass('slds-button_brand');
        } else $copado('[cType="xml"]').addClass('slds-button_brand');

        // console.log('att2Res ? ==> ',att2Res);
        if (att2Res || (attSource.length > 0 &&  attTarget.length > 0)) {
            var attach = att2Res.length > 0 ? getAttachmentById(config.parentId, att2Res) : '';
            // console.log('attach===============> ',attach);
            if (!attach && !bundleFlag) {

                bundleSource = unzip_Decode(attSource);
                // console.log('bundleSource===> ',bundleSource);
                bundleTarget = unzip_Decode(attTarget);
                // console.log('bundleTarget===> ',bundleTarget);
                if ((bundleSource[1].length == 2 || (bundleSource[1].length == 3 && bundleSource[1][1].indexOf('meta.xml') > -1)) && !attach) {
                    preSource[0] = Object.keys(bundleSource[0].files)[0] != 'package.xml' ? bundleSource[0].file(Object.keys(bundleSource[0].files)[0]).asText() : '';
                    preSource[1] = bundleSource[1][0];
                    preTarget[0] = Object.keys(bundleTarget[0].files)[0] != 'package.xml' ? bundleTarget[0].file(Object.keys(bundleTarget[0].files)[0]).asText() : '';
                    preTarget[1] = bundleTarget[1][0];
                } else {
                    bundleFlag = true;
                    modalOperations.showFileModal();
                    $copado('.slds-modal__content#modal-content-id-1').prepend('<div id="fs2append"></div>');

                    for (var i = 0; i<bundleSource[1].length; i++) {
                        if (bundleSource[1][i].toLowerCase() != 'package.xml') {
                            /*used single quotes instead of ` since VF acts weird and puts js code directly to the page as visible*/
                            $copado('[id="fs2append"]').append('<div class="slds-card__header slds-grid" style="padding: 0 0 0 0;margin: 0 0 .15rem;"><header style="color:black !important;'+ ( bundleSource[0].file(bundleSource[1][i]).asText() != bundleTarget[0].file(bundleSource[1][i]).asText() ? 'background-color: #f4f7fa !important;' : 'background-color: #FFF !important;') +'" class="rectangle slds-media slds-media_center slds-has-flexi-truncate"><div class="slds-media__body"><h2><span style="margin-left: 1%;" class="slds-text-heading_small aura-bundle-page-template">'+bundleSource[1][i]+'</span></h2></div>'+ (bundleSource[0].file(bundleSource[1][i]).asText() != bundleTarget[0].file(bundleSource[1][i]).asText() ? '<div class="aura-bundle-view-button slds-no-flex"><div class="slds-form-element__control"><div class="slds-radio_button-group"><span class="slds-button slds-radio_button" onclick="modalOperations.renderBundleSelection(\''+bundleSource[1][i]+'\');"><input id="autoResolveButton-'+i+'" name="radio-'+i+'"  type="radio" value="on"><label class="slds-radio_button__label slds-button slds-button_neutral" for="autoResolveButton-'+i+'"><span class="slds-radio_faux" >'+viewDifferences+'</span></label></span></div> </div></div>' : '<a href="#" onclick="modalOperations.renderBundleSelection(\''+bundleSource[1][i]+'\');">'+viewFile+'</a>') +'</header></div><div class="slds-card__body"></div><footer class="slds-card__footer"></footer>');
                        }
                    }
                    returnFlag = true;
                }

                // console.log('preSource ==> ',preSource);
                // console.log('preTarget ==> ',preTarget);
                // console.log('returnFlag==> ',returnFlag);
                preFlag = true;
            }
            if (((attach && attach.Body.length > 0) || preFlag) && !returnFlag) {
                config.attachName = !preFlag ? attach.Name : (preSource[0] > preTarget[0] ? preSource[1] : preTarget[1]);
                config.hasError = false;
                config.alreadyChecked = true;
                // console.log('attach======> ',attach);
                $copado('#toLineDiv,.CodeMirror-simplescroll,.CodeMirror-merge-2pane,.CodeMirror-merge-3pane,#infoOnMerge').remove();

                if (sPane) panes = sPane;

                var offsetAmount = 120;
                attachmentInfo = !preFlag ? attach.Name.replace('AUTO ','').replace('RESOLVED ','').split(' ') : config.attachName.split('/');
                pMode = defineMode();
                usName = attachmentInfo[0];

                //$copado('.slds-modal__header:last').append('<center><span id="infoOnMerge"><strong style="font-size: medium;">'+attachmentInfo[1]+'</strong> ');
                var fileName = preSource && preSource.length ? (preSource[0] > preTarget[0] ? preSource[1] : preTarget[1]) : '';
                $copado('.files-to-compare').text((preSource && preSource.length > 0) ? fileName : attachmentInfo[1]);

                if (panes != 1) {
                    if (pMode.toLowerCase().indexOf('xml') > -1 && (!parseOperations.parseErrorExist(attach ? prapareValue(Base64.decode(attach.Body),format) : preSource[0]) || format)) {
                        $copado('#xmlJson').css('display','');
                        format = currentMode;
                        offsetAmount = 30;
                    } else {
                        $copado('#xmlJson').css('display','none');
                    }

                    directValue = false;
                    $copado('#view').css('display','');
                    $copado('.CodeMirror-simplescroll').css('display','none');

                    var value = attach ? prapareValue(Base64.decode(attach.Body),format) : prapareValue(preSource[0],format);
                    var orig1 = attach ? prepareOrig(Base64.decode(attach.Body),format) : prapareValue(preTarget[0],format);
                    editor = CodeMirror.MergeView(document.getElementById('view'), {
                        value: value,
                        origLeft: panes == 3 ? value : null,
                        orig: orig1,
                        lineNumbers: true,
                        mode: format == 'json' ? 'application/json' : pMode,
                        highlightDifferences: true,
                        connect: 'align',
                        collapseIdentical: false,
                        readOnly: attach ? false : true
                    });
                    $copado('.CodeMirror-merge-editor').prepend('<div class="panel top" style="background-color:white;"><center><span>'+ (attach ? resolution : source +jqxdatatable_config.data.orgName )+'</span></center></div>');
                    $copado('.CodeMirror-merge-pane-rightmost').prepend('<div class="panel top" style="background-color:white;"><center><span>' + (attach ? featureBranch : target +jqxdatatable_config.data.targetOrgName )+'</span></center></div>');
                    if ($copado('.CodeMirror-merge-left').length > 0) {
                        $copado('.CodeMirror-merge-left').prepend('<div class="panel top" style="background-color:white;"><center><span>'+promotionBranch+'</span></center></div>');
                    }

                    if (cssTop = $copado('.CodeMirror-merge-copy').css('top')) {
                        $copado('.CodeMirror-merge-copy').css('top',parseInt(cssTop.slice(0,-2)) + 19);
                    }

                    var gapSize = parseInt($copado('.CodeMirror-merge-gap').css('height').slice(0,-2)) + 19;
                    $copado('.CodeMirror-merge-gap').css('height',gapSize);
                } else {
                    $copado('#xmlJson').css('display','none');
                    CodeMirror.defineMode("highlightSearch", function(config, parserConfig) {
                        var searchOverlay = {
                            token: function(stream, state) {
                                if (stream.match(keyword)) {
                                    return 'highlightSearch';
                                }
                                while (stream.next() != null && !stream.match(keyword, false)) {}
                                return null;
                            }
                        };
                        return CodeMirror.overlayMode(CodeMirror.getMode(config, parserConfig.backdrop || pMode), searchOverlay);
                    });
                    initEditor2();
                    directValue = true;
                    $copado('#view').css('display','none');
                    $copado('.CodeMirror-simplescroll').css('display','');

                    editor2.focus();
                    editor2.setValue(Base64.decode(attach.Body));
                }
                $copado('#errorMessage').text('');
                modalOperations.toogleLocker(false);
                modalOperations.showFileModal();
            }
        }
    };
    self.classSetValue = function(elem) {
        var index = $copado(elem).attr('panel');
        jsCookies.set('merge.conflict.selection',index);
        $copado('#grp>.slds-button_brand').removeClass('slds-button_brand');
        $copado(elem).addClass('slds-button_brand');
        self.setPreValue(index);
    };
    var unzip_Decode = function(elem) {
        zip = new JSZip(elem,{base64:true});
        return [zip,Object.keys(zip.files)];
    },
    defineMode = function() {
        //last clause(after : ) used to be (attachmentInfo.length > 1 ? attachmentInfo[1].split('.')[0].toLowerCase() : attachmentInfo[0])
        var aType = attachmentInfo.length > 2 ? attachmentInfo[2].split('.')[1].toLowerCase() : (preFlag ? attachmentInfo[0] : attachmentInfo[1].split('/')[0].toLowerCase());
        if (aType == 'apexclass' || aType == 'apextrigger' || aType == 'classes' || aType == 'triggers') {
            return 'text/x-java';
        } else if (aType == 'apexpage' || aType == 'apexcomponent' || aType == 'cmp' || aType == 'pages' || aType == 'components') {
            return 'text/html';
        } else if (aType == 'css') {
            return 'text/css';
        } else if (aType == 'staticresource' || aType == 'js' || aType == 'staticresources') {
            return 'text/javascript';
        } else return 'application/xml';   //'text/x-yaml'
    },
    prapareValue = function(val,format) {
        if (pMode == 'application/xml') {
            let firstRowEndsAt = val.indexOf('\n');
            firstRow = val.slice(0,firstRowEndsAt);
        }
        usName = val.slice(val.indexOf('>>>>>>>'),val.indexOf(usName)+usName.length); //'>>>>>>> feature/'+usName;
        while (val.indexOf(usName) > -1 && usName && usName.length > 0) {
            val = (val.slice(0,val.indexOf('=======')) + val.slice(val.indexOf(usName)+usName.length,val.length)).replace('<<<<<<< HEAD','');
        }

        var returnVal = (format == 'json' ?  conversionFunc.json2yaml(parseOperations.convertXml2formattedJSON(val.replace(/(^[ \t]*\n)/gm, ""))) : val.replace(/(^[ \t]*\n)/gm, ""));
        return unicodeReplacer(returnVal);
    },
    prepareOrig = function(val,format) {
        while (val.indexOf(usName) > -1 && val.indexOf('<<<<<<< HEAD') > -1) {
            val = (val.slice(0,val.indexOf('<<<<<<< HEAD')) + val.slice(val.indexOf('=======') + '======='.length, val.length)).replace(usName,'');
        }
        var returnVal = (format == 'json' ? conversionFunc.json2yaml(parseOperations.convertXml2formattedJSON(val.replace(/(^[ \t]*\n)/gm, ""))) : val.replace(/(^[ \t]*\n)/gm, ""));
        return unicodeReplacer(returnVal);
    },
    unicodeReplacer = function(returnVal) {
        while (returnVal.indexOf('\\x0A\\x20\\x20') > -1) {
            returnVal = returnVal.replace('\\x0A\\x20\\x20','\\x0A\\x20');
        }
        while (returnVal.indexOf('"\\x0A\\x20"') > -1) {
            returnVal = returnVal.replace('"\\x0A\\x20"','');
        }
        while (returnVal.indexOf('\\x20') > -1) {
            returnVal = returnVal.replace('\\x20',' ');
        }
        while (returnVal.indexOf('\\x3A') > -1) {
            returnVal = returnVal.replace('\\x3A',':');
        }
        return returnVal;
    }
})(panelFunctions);


(function(self) {
    self.openModal = function(attachmentId) {
        window.setTimeout(self.lock, 5); // to force redrawing.

        panelFunctions.setPreValue();

        return false;
    };
    self.renderBundleSelection = function(optionName) {
        // console.log('optionName ',optionName);
        preSource[0] = bundleSource[0].file(optionName).asText();
        preTarget[1] = preSource[1] = optionName;
        preTarget[0] = bundleTarget[0].file(optionName).asText();

        returnFlag = false;
        $copado('#fs2append').css('display','none');
        $copado('#closeFileModalbtn').css('display','none');
        $copado('#xmlJson').css('display','inline-flex');
        $copado('#backBtn4bundle').css('display','');
        $copado('#view').css('visibility','');
        panelFunctions.setPreValue();
    };
    self.backButtonOperation = function() {
        $copado('#xmlJson').css('display','none');
        $copado('#fs2append').css('display','');
        $copado('#closeFileModalbtn').css('display','');
        $copado('#backBtn4bundle').css('display','none');
        $copado('#view').css('visibility','hidden');
        $copado('[type=radio]:checked').prop('checked',false);
        $copado('.files-to-compare').text(files2Compare);
    };
    self.showModal = function() {
        setTimeout(function() {
            $copado('#backdrop').addClass('slds-backdrop--open');
            $copado('#modal').addClass('slds-fade-in-open');
            self.unlock();
        }, 500);
    };
    self.closeModal = function() {
        $copado('#modal').removeClass('slds-fade-in-open');
        $copado('#backdrop').removeClass('slds-backdrop--open');
        return false;
    };
    self.showFileModal = function() {
        setTimeout(function() {
            $copado('#fileBackdrop').addClass('slds-backdrop--open');
            $copado('#fileModal').addClass('slds-fade-in-open');
            self.unlock();
        }, 500);
    };
    self.closeFileModal = function() {
        bundleFlag = false;
        returnFlag = false;
        $copado('#backBtn4bundle').css('display','none');
        $copado('#fs2append').detach();
        $copado('#fileModal').removeClass('slds-fade-in-open');
        $copado('#fileBackdrop').removeClass('slds-backdrop--open');
        $copado('#screenLockerLightning').hide();
    };
    self.toogleLocker = function(lock) {
        if (lock) {
            $copado('#screenLockerLightning').show();
            return;
        }
        $copado('#screenLockerLightning').hide();
    };
    self.hideLocker = function() {
        setTimeout(function() {
            self.toogleLocker(false);
        }, 500);
    };
    self.unlock = function() {
        $copado('#screenLockerLightning').hide();
    };
    self.lock = function() {
        $copado('#screenLockerLightning').show();
    };
})(modalOperations);


(function(self) {
    var xmlToJson = function(xml) {
        // Changes XML to JSON
        // Modified version from here: http://davidwalsh.name/convert-xml-json
        // Create the return object
        var obj = {};

        if (xml.nodeType == 1) { // element
            // do attributes
            if (xml.attributes.length > 0) {
            obj['@attributes'] = {};
                for (var j = 0; j < xml.attributes.length; j++) {
                    var attribute = xml.attributes.item(j);
                    obj['@attributes'][attribute.nodeName] = attribute.nodeValue;
                }
            }
        } else if (xml.nodeType == 3) { // text
            obj = xml.nodeValue;
        }

        // do children
        // If just one text node inside
        if (xml.hasChildNodes() && xml.childNodes.length === 1 && xml.childNodes[0].nodeType === 3) {
            obj = xml.childNodes[0].nodeValue;

        } else if (xml.hasChildNodes()) {

            for (var i = 0; i < xml.childNodes.length; i++) {
                var item = xml.childNodes.item(i);
                var nodeName = item.nodeName;
                if (typeof(obj[nodeName]) == 'undefined') {
                    // console.log('nodeName==1=> ',nodeName);
                    if(nodeName != '#text') obj[nodeName] = xmlToJson(item);
                } else {
                    if (typeof(obj[nodeName].push) == 'undefined') {
                        var old = obj[nodeName];
                        obj[nodeName] = [];
                        obj[nodeName].push(old);
                    }
                    // console.log('nodeName==2=> ',nodeName);
                    // console.log('obj[nodeName]===> ',obj[nodeName]);
                    obj[nodeName].push(xmlToJson(item));
                }
            }
        }
        return obj;
    },
    json2Xml = function(json, node) {
        /**
         * JSON to XML
         * @param {Object} JSON
        */
        var root = false;
        if (!node) {
            node = document.createElement('root');
            root = true;
        }

        for (var x in json) {
            if (json.hasOwnProperty(x)) {
                if (typeof json == 'string') { // field value char
                    node.appendChild(document.createTextNode(json[x]));
                } else  if (x == '@attributes') { // attributes
                    for (var y in json[x]) {
                        if (json[x].hasOwnProperty(y)) {
                            node.setAttribute(y, json[x][y]);
                        }
                    }
                } else if (x == '#comment') { // comment
                // ignore
                } else { // elements
                    if (json[x] instanceof Array) { // handle arrays
                        // console.log('json[x]==in if==> ',json[x]);
                        for (var i = 0; i < json[x].length; i++) {
                            // console.log('x==array= in for==> ',x);
                            var str = x;
                            var uppercaseLetters = str.replace(/[a-z]/g, '');
                            let exX = x;
                            var arr = [];
                            if (i == 0) {
                                for (var l=0;l<uppercaseLetters.length;l++) {
                                    if (arr.includes(uppercaseLetters[l])) continue;
                                    x = x.replaceAll(uppercaseLetters[l],uppercaseLetters[l]+repWord);
                                    arr.push(uppercaseLetters[l]);
                                }
                                json = JSON.parse(JSON.stringify(json).replace(exX,x));
                            }
                            node.appendChild(json2Xml(json[x][i], document.createElement(x)));
                        }
                    } else {
                        if(x.length == 1) continue;

                        try {
                            var str = x;
                            var uppercaseLetters = str.replace(/[a-z]/g, '');
                            let exX = x;
                            var arr = [];
                            for (var l=0;l<uppercaseLetters.length;l++) {
                                if(arr.includes(uppercaseLetters[l])) continue;
                                x = x.replaceAll(uppercaseLetters[l],uppercaseLetters[l]+repWord);
                                arr.push(uppercaseLetters[l]);
                            }
                            json = JSON.parse(JSON.stringify(json).replace(exX,x));
                            node.appendChild(this.json2Xml((typeof json[x] == 'number' || typeof json[x] == 'boolean') ? json[x]+'' : json[x], document.createElement(x)));
                        } catch(e) {}
                    }
                }
            }
        }

        if (root == true) {
            return node.innerHTML;
        } else {
            return node;
        }

    },
    formatXml = function(xml) {
        var formatted = '';
        var reg = /(>)(<)(\/*)/g; /**/
        xml = xml.replace(reg, '$1\r\n$2$3');
        var pad = 0;
        jQuery.each(xml.split('\r\n'), function(index, node) {
            var indent = 0;
            if (node.match( /.+<\/\w[^>]*>$/ )) {
                indent = 0;
            } else if (node.match( /^<\/\w/ )) {
                if (pad != 0) {
                    pad -= 2;
                }
            } else if (node.match( /^<\w[^>]*[^\/]>.*$/ )) {
                indent = 2;
            } else {
                indent = 0;
            }

            var padding = '';
            for (var i = 0; i < pad; i++) {
                padding += '  ';
            }

            formatted += padding + node + '\r\n';
            pad += indent;
        });
        while (formatted.indexOf(repWord.toLowerCase()) > -1) {
            let matchChar = formatted.indexOf(repWord.toLowerCase()) - 1;
            let char2uppercase = formatted[matchChar];
            formatted = formatted.replace('XXXXX__','xxxxx__').replace(char2uppercase+repWord.toLowerCase(),char2uppercase.toUpperCase());
        }
        //firstRow: is the missing first row of XML which is gone after casting xml to json -- exp:<?xml version="1.0" encoding="UTF-8"?>
        return firstRow + '\n' + formatted;
    };

    parseOperations.parseErrorExist = function(body) {
        var xmlDOM = new DOMParser().parseFromString(body, 'text/xml');
        var oSerializer = new XMLSerializer();
        var sXML = oSerializer.serializeToString(xmlDOM);
        return sXML.indexOf('parsererror') > -1;
    };
    parseOperations.convertXml2formattedJSON = function(param) {
        //yaml parser error fix for empty files
        return param.length != '' ? JSON.stringify(xmlToJson(new DOMParser().parseFromString(param, 'text/xml')), null, '\t') : '';
    };
    parseOperations.convertJSON2formattedXml = function(param) {
        return formatXml(json2Xml(JSON.parse(param)));
    };
})(parseOperations);