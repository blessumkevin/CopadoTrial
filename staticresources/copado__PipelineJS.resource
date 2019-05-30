
(function ( $ ) {
    $.fn.connectSVG = function(param){

        var _canvas;
        var _ctx;
        var _lines = new Array();
        var _me = this;
        var _parent = param || document;

        //Initialize Canvas object
        _canvas = $('<canvas/>')
                    .attr('width',$(_parent).width())
                    .attr('height',$(_parent).height());
        if($('#boxCanvas canvas').length==0)$('#boxCanvas').append(_canvas);

        this.drawLine = function(option){
            //It will push line to array.
            _lines.push(option);
            this.connect(option);
        };
        this.drawAllLine=function(option){
            if(option.left_selector != '' && typeof option.left_selector !== 'undefined' && $(option.left_selector).length>0){
                $(option.left_selector).each(function(index){
                    var option2 = new Object();
                    $.extend(option2, option);
                    option2.left_node = $(this).attr('id');
                    option2.right_node = $(this).data(option.data_attribute);
                    if(option2.right_node != '' && typeof option2.right_node !== 'undefined'){
                        _me.drawLine(option2);
                    }
                });
            }
        };

        //This Function is used to connect two different div with a dotted line.
        this.connect = function(option) {
            _ctx=_canvas[0].getContext('2d');
            _ctx.beginPath();

            try{
                var _destinationBox = new Object();
                var _color;
                var _dash;
                var _left = new Object();
                var _right = new Object();
                var _error = (option.error == 'show') || false;
                var headerHeight = option.headerHeight || 0;

                if(option.left_node != '' && typeof option.left_node !== 'undefined' && option.right_node != '' && typeof option.right_node !== 'undefined' && $(option.left_node).length>0 && $(option.right_node).length>0){

                    //To decide colour of the line
                    switch (option.color){
                        case 'copado-blue':
                            _color = '#3593c6';
                            break;
                    }

                    //To decide style of the line. dotted or solid
                    switch (option.style){
                        case 'solid':
                            _dash = [0,0];
                            break;
                    }

                    //If left_node is actually right side, following code will switch elements.
                    $(option.right_node).each(function(index,value){
                        _left_node = $(option.left_node);
                        _right_node = $(value);
                        _dest_node = ( _left_node==$(option.destinationNode) )?_left_node:_right_node;

                        var drawArrowWhere = 'left-side';

                        if(_left_node.left >= _right_node.left){
                            _tmp = _left_node
                            _left_node = _right_node
                            _right_node =_tmp;
                            if(_dest_node==_left_node)drawArrowWhere='right-side';
                        }
                        var scope_Padding = parseInt($copado('.slds-scope').css('padding'));
                        //Get Left point and Right Point
                        _left.x =parseInt(_left_node.css('left')) + _left_node.outerWidth() -scope_Padding;
                        _left.y = parseInt(_left_node.css('top')) - headerHeight + (_left_node.outerHeight()/2) ;
                        _right.x = parseInt(_right_node.css('left')) -scope_Padding;
                        _right.y = parseInt(_right_node.css('top')) - headerHeight + ( _right_node.outerHeight()/2);

                        //Draw Line
                        var _gap = option.horizantal_gap || 0 ;

                        _destinationBox.x = parseInt(_dest_node.css('left')) + _dest_node.outerWidth() -scope_Padding;
                        _destinationBox.y = parseInt(_dest_node.css('top')) - headerHeight + (_dest_node.outerHeight()
                        /2);

                        //Draw arrow either on the left or the rigth
                        if(drawArrowWhere=='left-side'){
                            _ctx.moveTo(_destinationBox.x-205, _destinationBox.y+0);
                            _ctx.lineTo(_destinationBox.x-218, _destinationBox.y-7);
                            _ctx.lineTo(_destinationBox.x-215, _destinationBox.y+0);
                            _ctx.lineTo(_destinationBox.x-218, _destinationBox.y+7);
                            _ctx.lineTo(_destinationBox.x-205, _destinationBox.y+0);
                            _ctx.fillStyle=_color;
                            _ctx.fill();
                        }
                        else{
                            _ctx.moveTo(_destinationBox.x-0, _destinationBox.y+0);
                            _ctx.lineTo(_destinationBox.x+13, _destinationBox.y-7);
                            _ctx.lineTo(_destinationBox.x+10, _destinationBox.y+0);
                            _ctx.lineTo(_destinationBox.x+13, _destinationBox.y+7);
                            _ctx.lineTo(_destinationBox.x-0, _destinationBox.y+0);
                            _ctx.fillStyle=_color;
                            _ctx.fill();
                        }

                        _ctx.moveTo(_left.x+0, _left.y+0);
                        if(_gap != 0){
                            _ctx.lineTo(_left.x + _gap, _left.y);
                            _ctx.lineTo(_right.x - _gap, _right.y);
                        }
                        _ctx.lineTo(_right.x, _right.y);
                        _ctx.lineWidth=option.width||2;
                        _ctx.strokeStyle = _color;
                        _ctx.stroke();
                    });
                }
                else{
                    if(_error) alert('Mandatory Fields are missing or incorrect');
                }
            }
            catch(err){
                if(_error) alert('Mandatory Fields are missing or incorrect');
            }
        };

        //It will redraw all line when screen resizes
        $(window).resize(function(){
            _me.redrawLines();
        });
        this.redrawLines = function(){
            if(!_ctx)_ctx=_canvas[0].getContext('2d');
            _ctx.clearRect(0,0,$(_parent).width(),$(_parent).height());
            _lines.forEach(function(entry){
                entry.resize=true;
                _me.connect(entry);
            });
        };
        return this;
    };
}( jQuery ));

var pipelineConnector = pipelineConnector || {};
pipelineConnector.data = pipelineConnector.data || {};
pipelineConnector.config = pipelineConnector.config || {};
pipelineConnector.branch = pipelineConnector.branch || {};
pipelineConnector.floater = pipelineConnector.floater || {};
pipelineConnector.labels = pipelineConnector.labels || {};

pipelineConnector.config.ns = copadoApp.ns;
pipelineConnector.config.currentUserId = '';
pipelineConnector.config.canvas = $copado('#boxCanvas').connectSVG($copado("html"));
pipelineConnector.data.flowId = copadoApp.data.flowId;
pipelineConnector.data.mapStepIdEnvironments = [];
pipelineConnector.data.mapStepEnvConnections = new Map();
pipelineConnector.data.mapBoxIdToStepId = [];
pipelineConnector.data.stepIds = [];
pipelineConnector.data.env2branchMap = [];
pipelineConnector.data.permissions = [];
pipelineConnector.data.positionArray = [];
pipelineConnector.data.prodBox = '';
pipelineConnector.data.targetToSource = new Map();
pipelineConnector.labels.LOADING = 'Loading';


pipelineConnector.logMapElements = function(value, key, map) {
  !pipelineConnector.data.mapStepEnvConnections.has(value) ? pipelineConnector.data.prodBox = value : '';
  if(!pipelineConnector.data.targetToSource.has('wrapper_'+value)){
  	pipelineConnector.data.targetToSource.put('wrapper_'+value,'wrapper_'+key);
  } else {
  	var innerArray = new Array();
  	innerArray = innerArray.concat(pipelineConnector.data.targetToSource.get('wrapper_'+value));
  	innerArray.push('wrapper_'+key);
  	pipelineConnector.data.targetToSource.put('wrapper_'+value,innerArray);
  }
}

pipelineConnector.fixInCanvas = function(flowWidth){
    var $win = $copado(window);
    var $doc = $copado(document);
    $copado('#boxCanvas').css('width',flowWidth);
    $canvas = $copado("#boxCanvas canvas");
    if(flowWidth <=  $win.width()){
        $canvas.prop('width',  $win.width());
        $copado('#boxCanvas').css('width',flowWidth);
        //$doc.css('width',$win.width());
    }else{
        $canvas.prop('width',  flowWidth);
        $copado('#boxCanvas').css('width',flowWidth);
        //$doc.css('width',flowWidth);
    }
    if(callHeaderMode){
        var mode = callHeaderMode();
        if(mode === 'diagram'){
            $copado('#boxCanvas').css('padding-top',$copado("[id$='headerPanel']").height()+20);
            $copado('div.bodyDiv.brdPalette.brandPrimaryBrd').css('position','fixed');
        }
    }
}
var stageWidth;
var minLeft;
var maxTop = 0;
pipelineConnector.positionEnvBoxes= function(){

    pipelineConnector.data.prodBox = '';
    pipelineConnector.data.targetToSource = new Map();
    pipelineConnector.data.positionArray = [];
	pipelineConnector.data.mapStepEnvConnections.forEach(pipelineConnector.logMapElements)
	var totalWidth = $copado('#boxCanvas').width();
	var totalStage = pipelineConnector.data.targetToSource.size+1; // steps + prod
	var calculatedCol = totalWidth / totalStage;
	stageWidth =  calculatedCol < 245 ? 245 : calculatedCol;
	var boxWidth = $copado('.jsEnvBoxWrapper').first().width();
	var bufferWidth = stageWidth - boxWidth;
	var calculatedTotalWidth = (stageWidth * totalStage);
    if(calculatedTotalWidth > totalWidth){
        pipelineConnector.fixInCanvas(calculatedTotalWidth);
        setTimeout(function() {pipelineConnector.positionEnvBoxes();},100);
        return;
    } else {
        pipelineConnector.fixInCanvas();
    }
	var wrapperId = 'wrapper_' + pipelineConnector.data.prodBox;
	var leftSpace = totalWidth -boxWidth - 20;
	var topSpace = $copado("[id$='headerPanel']").height() + 40;
	pipelineConnector.setCoordinates(wrapperId,leftSpace,topSpace,bufferWidth,boxWidth);
    setTimeout(function() {
        $copado('.jsEnvBoxWrapper').each(function(){
            var current = $copado(this).css('left');
            $copado(this).css('left',parseInt(current)-minLeft+20);
        });
        var canvasWidth = parseInt($canvas.prop('width'));
        $canvas.prop('width',  canvasWidth - minLeft + 100);
        $copado(document).css('width',canvasWidth - minLeft + 100);
        $copado('#boxCanvas').css('width',$copado('body').width());

        $canvas.prop('height', maxTop+75);
    pipelineConnector.config.canvas.redrawLines();
    unlockScreen();
    },100);
}

pipelineConnector.setCoordinates = function(wrapperId,leftSpace,topSpace,bufferWidth,boxWidth,order){
	var innerTop = order ? topSpace + (100 * order) : topSpace;
	maxTop = maxTop < innerTop ? innerTop : maxTop;
	var box = document.getElementById(wrapperId);
	if(pipelineConnector.data.positionArray.indexOf(leftSpace+'_'+innerTop) >= 0 ){
	    pipelineConnector.setCoordinates(wrapperId,leftSpace,topSpace,bufferWidth,boxWidth,order+1);
	    return;
    } else {
        pipelineConnector.data.positionArray.push(leftSpace+'_'+innerTop);
    }
    if (box != null) {
        box.style.left = leftSpace+'px';
        box.style.top = innerTop+'px'
        if(!minLeft || minLeft > leftSpace){
            minLeft = leftSpace;
        }
    }
    var inner = pipelineConnector.data.targetToSource.has(wrapperId) ? pipelineConnector.data.targetToSource.get(wrapperId) : new Array();
    var depth = Array.isArray(inner) ? inner.length : 1;

    if(depth > 0){
        var positioner = 0;
        var calc = (stageWidth - boxWidth - 90);
        if(calc > 0){
            positioner = calc;
        }
    	leftSpace = leftSpace - positioner - boxWidth-90;
    	for (var x = 0; x < depth; x++) {
			var key = Array.isArray(inner) ? inner[x] : inner;
    		pipelineConnector.setCoordinates(key,leftSpace,topSpace,bufferWidth,boxWidth,x);
    	}
    }
}

pipelineConnector.drawSVGlines = function(leftNode, rightNode, destinationNode, envConnection) {
    pipelineConnector.config.canvas.drawLine({
        left_node: leftNode,
        right_node: rightNode,
        destinationNode: destinationNode,
        horizantal_gap: 25,
        error: true,
        style: 'solid',
        color: 'copado-blue',
        width: 2,
        headerHeight: $copado("[id$='headerPanel']").height() + 20
    });
};
pipelineConnector.drawEnvironmentConnections = function() {
    for (i = 0; i < copadoApp.envConnections.length; i++) {
        pipelineConnector.drawEnvironmentConnection(copadoApp.envConnections[i].fromEnvId, copadoApp.envConnections[i].toEnvId, copadoApp.envConnections[i]);
    }
};

pipelineConnector.drawEnvironmentConnection = function(fromEnvId, toEnvId, envConnection) {
    pipelineConnector.setDestinatonEnvName(fromEnvId, toEnvId);
    var fromEnvBox = '#wrapper_' + fromEnvId;
    var toEnvBox = '#wrapper_' + toEnvId;
    pipelineConnector.drawSVGlines(fromEnvBox, toEnvBox, toEnvBox, envConnection);
};
pipelineConnector.drawEnvironmentBoxes = function() {
    console.info('Drawing Environment Boxes...');
    if(copadoApp.environments.length > 0){
        for (var i = 0; i < copadoApp.environments.length; i++) {
                pipelineConnector.addEnvBox(copadoApp.environments[i].envName, copadoApp.environments[i].envId, copadoApp.environments[i].flowStepId, copadoApp.environments[i].branch, copadoApp.environments[i], copadoApp.environments[i].needsOauth, copadoApp.environments[i].fromEnvId, copadoApp.environments[i].toEnvId);
        }
    }

    // Give the browser a few ms to stabilize the DOM
    /*window.setTimeout(function() {
        pipelineConnector.getsetCoordinates();
        pipelineConnector.initialiseDraggable();
    },100);*/
};
pipelineConnector.setDestinatonEnvName = function(fromEnvId, toEnvId) {
    var toEnvName = $copado('#' + toEnvId + '_title').text();
    $copado('#nextDestEnvBody_' + fromEnvId).text(toEnvName);
    if (toEnvName.length > 0) $copado('#detailModeBody_' + fromEnvId).show();
};
pipelineConnector.setEnvironmentValues = function(envId, destEnvName, destEnvId, flowStepId) {
    console.info('Setting Environment values...');
    pipelineConnector.setDestinatonEnvName(envId, destEnvId);
    $copado('#wrapper_' + envId).attr('data-flowStepId', flowStepId);
};
pipelineConnector.buildEnvBox = function(envName, envId, style, branch, env, flowStepId, needsOauth, fromEnvId, toEnvId) {
    style = (style == '' || style == null || typeof style == 'undefined') ? '' : style;
    branch = (typeof branch == 'undefined' || branch == null) ? '' : htmlEntities(branch);
    envId = envId || branch;
    var s = "<div style='" + style + "' class='jsEnvBoxWrapper' id='wrapper_" + envId + "' data-flowStepId='"+flowStepId+"' data-floaters='' data-branch='" + branch + "'>" +
        "<div id='box_" + envId + "' data-branch='" + branch + "' data-boxId='' class='envBox' style='background-color:white !important; border-color:#3593c6;margin-left:5px !important;border-radius:5px'>";

    if((env.orgType != 'Scratch Org') && ((fromEnvId && fromEnvId != envName) || !fromEnvId)) {
        s+= "<div style='float: left;height: 100%;text-align: center;background-color:#3593c6;'>" +
        "<input type='button' onclick='createOrg(\"" + flowStepId + "\",\"" + envId + "\",\"" + envName + "\",\"" +  !fromEnvId + "\");' data-branch='" + branch + "' data-parentSelector='box_" + envId + "' class='createEnv' value='+' title='Create new Environment Connection' /></div>"
    }

    s+= "<div style='width:100%;height:100%;";
    if(!needsOauth) {
        s+= "padding-top: 15px;";
    }

    s+="'><div  style='text-overflow: ellipsis; white-space: nowrap; overflow: hidden;margin-top:2px;'>" +
        "<b><span id='" + envId + "_title' class='title' style='color:#16325c;' target='_blank' title='" + envName + "'>";
    if(!needsOauth){
        s+= '&#x2714;';
    }
    s+= htmlEntities(envName) + "</span></b></br>" +
        "<div class='title' style='color:#d0d9e2;font-size:12px;padding:0;' title='"+branch+"'>branch : "+htmlEntities(branch)+"</div></div>";
        
    if(needsOauth) {
        s+="<div><a href='#' onclick='doOauth(\"" + flowStepId + "\",\"" + envId + "\",\"" + envName + "\",\"" + branch + "\");' value='Authenticate' title='Authenticate' class='btn slds-button' target='_parent' style='color:#3593c6;'>Authenticate</a></div>";
    }
    s+= "</div></div></div>"

    return s;
};
pipelineConnector.environmentboxOnCanvas = function(envId) {
    if ($copado('#box_' + envId).length) return true;
    return false;
};
pipelineConnector.counter = 0;
pipelineConnector.addEnvBox = function(envName, envId, flowStepId, branch, environment, needsOauth, fromEnvId, toEnvId) {
    var style = '';
    if(!envId) return;
    envId = envId || branch;

    if (pipelineConnector.environmentboxOnCanvas(envId) == false) {
        $copado("#boxCanvas").append(pipelineConnector.buildEnvBox(envName, envId, style, branch, environment, flowStepId, needsOauth, fromEnvId, toEnvId));
        $copado('#wrapper_' + envId).attr('data-flowStepId', flowStepId);
        var box = document.getElementById('wrapper_' + envId);
        if(box) {
            box.style.left = '30px';
            box.style.top = '30px';
        }
        $copado('#box_' + envId).attr('data-boxId', flowStepId);
        $copado("#box_" + envId + "_content").attr('data-stepContent', flowStepId);
    }
    pipelineConnector.counter++;
};
pipelineConnector.splitCoordinates = function(s) {
    var data = s.split(',');
    return data;
};
pipelineConnector.queryFlowSteps = function() {
    var NS = pipelineConnector.config.ns;
    copadoApp.envConnections = [];
    copadoApp.finalDestination = '';
    var fromIds = [];
    var toIds = [];
    pipelineConnector.data.env2branchMap = [];
    pipelineConnector.data.stepIds = [];
    var records = JsRemoting.deploymentFlows.queryFlowSteps(pipelineConnector.config.ns, pipelineConnector.data.flowId);
    for (var i = 0; i < records.length; i++) {
        var r = records[i];
        var key = r[NS + 'Source_Environment__c'] ? r[NS + 'Source_Environment__c'] : r[NS + 'Branch__c'];
        var destinationBranch = r[NS + 'Destination_Environment__c'] ? r[NS + 'Destination_Environment__c'] : r[NS + 'Destination_Branch__c'];
        pipelineConnector.data.env2branchMap[key] = r[NS + 'Branch__c'];

        copadoApp.envConnections.push({
            flowStepId: r.Id,
            fromEnvId:  r[NS + 'Source_Environment__c'] ? r[NS + 'Source_Environment__c'] : r[NS + 'Branch__c'],
            fromEnvName: r[NS + 'Source_Environment__r'] ? r[NS + 'Source_Environment__r'].Name : r[NS + 'Branch__c'],
            toEnvId: r[NS + 'Destination_Environment__c'] ? r[NS + 'Destination_Environment__c'] : r[NS + 'Destination_Branch__c'],
            toEnvName: r[NS + 'Destination_Environment__r'] ? r[NS + 'Destination_Environment__r'].Name : r[NS + 'Destination_Branch__c'],
            branch: r[NS + 'Branch__c'],
            orgType : r[NS + 'Source_Environment__r'] ? r[NS + 'Source_Environment__r'][NS+'Type__c'] : '',
            needsOauth : pipelineConnector.stepNeedsOauth(r)
        });

        fromIds.push(key);
        pipelineConnector.data.mapStepEnvConnections.put(key,destinationBranch);
        toIds.push(destinationBranch);
        pipelineConnector.data.mapStepIdEnvironments[r.Id] = key + '-' + destinationBranch;
        // we add both forward src->dest and the reverse (backdeploy)
        pipelineConnector.data.mapBoxIdToStepId[key + '-' + destinationBranch] = r.Id;
        pipelineConnector.data.mapBoxIdToStepId[destinationBranch + '-' + key] = r.Id;
        pipelineConnector.data.stepIds.push(r.Id);
    }

    for (var j = 0; j < toIds.length; j++) {
        if (fromIds.indexOf(toIds[j]) < 0) {
            copadoApp.finalDestination = toIds[j];
        }
    }
};
pipelineConnector.stepNeedsOauth = function(step){
    var NS = pipelineConnector.config.ns;
    var stepSource = step[NS + 'Source_Environment__c'];
    if(stepSource){
        var q = 'SELECT Id FROM '+NS +'Org__c WHERE '+NS +'Environment__c = \''+stepSource+'\' AND ('+NS +'Default_Credential__c = true OR CreatedById = \''+pipelineConnector.config.currentUserId+'\'' +')';
        var result =  sforce.connection.query(q);
        var records = result.getArray('records');
        if(!records || records.length <= 0) {
            return true;
        }
    } else {
        return true;
    }
    return false;
}

pipelineConnector.getFlowSteps = function() {
    console.info('Get Flow Steps...');
    pipelineConnector.queryFlowSteps();
    copadoApp.environments = pipelineConnector.createEnvironmentArray(copadoApp.envConnections);
};
pipelineConnector.addToEnvironmentArray = function(envConns) {
    var map = new Object();
    for (var i = 0; i < envConns.length; i++) {
        var conn = envConns[i];
        pipelineConnector.data.env2branchMap[conn.fromEnvId] = conn.branch;
        var tmpFrom = {
            envName: conn.fromEnvName || conn.branch,
            envId: conn.fromEnvId || conn.branch,
            flowStepId: conn.flowStepId,
            branch: conn.branch,
            orgType: conn.orgType,
            needsOauth: conn.needsOauth,
            fromEnvId: conn.fromEnvId,
            toEnvId: conn.toEnvId
        };
        var tmpTo = null;
        if (tmpFrom.toEnvId && tmpFrom.toEnvId !== null || tmpFrom.toEnvId !== '') {
            tmpTo = {
                envName: conn.toEnvName,
                envId: conn.toEnvId,
                flowStepId: conn.flowStepId,
                fromEnvId: conn.fromEnvId,
                branch: ''
            };
            // never overwrite an existing env.
            if(!map[conn.toEnvId])
                map[conn.toEnvId] = tmpTo;
        }
        map[conn.fromEnvId] = tmpFrom;
    }
    for (var v in map) {
        var branch = (typeof pipelineConnector.data.env2branchMap[map[v].envId] != 'undefined') ? pipelineConnector.data.env2branchMap[map[v].envId] : copadoApp.data.mainBranch;
        copadoApp.environments.push({
            envName: map[v].envName,
            envId: map[v].envId,
            flowStepId: map[v].flowStepId,
            branch: branch,
            _tto: map[v]._tto,
            orgType: map[v].orgType,
            needsOauth: map[v].needsOauth,
            fromEnvId: map[v].fromEnvId,
            toEnvId: map[v].toEnvId
        });
    }
    return copadoApp.environments;
};
pipelineConnector.createEnvironmentArray = function(envConnections) {
    copadoApp.environments = [];
    return pipelineConnector.addToEnvironmentArray(envConnections);
};
pipelineConnector.getPermissions = function() {
    pipelineConnector.data.permissions = JsRemoting.backDeploy.getPermissionsForUser(pipelineConnector.config.ns, pipelineConnector.config.currentUserId);
};
pipelineConnector.loadPage = function() {
    try {
        lockScreen();
        pipelineConnector.getPermissions();
        //pipelineConnector.getFlowStepCoordinates();
        pipelineConnector.getFlowSteps();
        pipelineConnector.drawEnvironmentBoxes();
        pipelineConnector.positionEnvBoxes();
        window.setTimeout(function() {
            pipelineConnector.drawEnvironmentConnections();
        },100);
        $copado('#boxCanvas canvas').css('margin-top',$copado('#headerPanel').outerHeight()+20);
    } catch (error) {
        console.error(error);
        unlockScreen();
        alert(error);
    }
};

