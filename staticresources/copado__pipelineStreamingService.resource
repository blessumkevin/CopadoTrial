var ccdStream = ccdStream || {};

((pipelineStreamingService) => {
    var pipelineStreamingService = pipelineStreamingService || {};

    pipelineStreamingService.ns = '';
    pipelineStreamingService.timeout = 0;
    pipelineStreamingService.duration = 0;
    pipelineStreamingService.sobjectAccessError = '';
    pipelineStreamingService.pushTopicName = 'CopadoEnvironments';
    pipelineStreamingService.streamCallback = {};
    var subscriptionRef;
    var hasPushTopic = false;
    var alreadyInitialized = false;
    var retryTimes = 20;
    var timeoutInterval;
    const cometd_statuses = {
       CONNECTED : 'connected',         // State assumed when this BayeuxClient is connected to the Bayeux server
       CONNECTING : 'connecting',       // State assumed when the connect is being sent for the first time
       DISCONNECTED : 'disconnected',   // State assumed before the handshake and when the disconnect is completed
       DISCONNECTING : 'disconnecting', // State assumed when the disconnect is being sent
       HANDSHAKEN : 'handshaken',       // State assumed when the handshake is received, but before connecting
       HANDSHAKING : 'handshaking',     // State assumed when the handshake is being sent
       REHANDSHAKING : 'rehandshaking', // State assumed when a first handshake failed and the handshake is retried, or when the Bayeux server requests a re-handshake
       TERMINATING : 'terminating',     // State assumed when the disconnect is received but terminal actions must be performed
       UNCONNECTED : 'unconnected'      // State assumed after the handshake when the connection is broken
    }

    var _errorOnAccessingSobject = (e, sobjectType) => {
        console.error(e, e.faultstring);
        var msg = pipelineStreamingService.sobjectAccessError + (e.faultstring || e);
        msg = msg.replace('{SOBJECT}', sobjectType);
        return alert(msg);
    };

    var _getPushTopics = () => {
        var me = pipelineStreamingService;
        try {
            var result = sforce.connection.query('SELECT Id, Name, Query, ApiVersion, IsActive, NotifyForFields, NotifyForOperations, '
                                               + 'Description, NotifyForOperationCreate, NotifyForOperationUpdate, NotifyForOperationDelete, '
                                               + 'NotifyForOperationUndelete FROM PushTopic WHERE Name = \'' + me.pushTopicName + '\'');
        } catch(e) {
            return _errorOnAccessingSobject(e,'PushTopic');
        }
        var records = result.getArray('records');
        if(records.length > 0) {
            for(var i = 0; i < records.length; i++) {
                if(records[i].Name == me.pushTopicName) {
                    console.info('Push topic for ' + me.pushTopicName + ' already exists.');
                    me.hasPushTopic = true;
                }
            }
        }
    };

     var _createPushTopic = (name, query) => {
         var me = pipelineStreamingService;
         var pt = new sforce.SObject('PushTopic');
         pt.Name = name;
         pt.Query = query;
         pt.ApiVersion = 46.0;
         pt.NotifyForOperationCreate = true;
         pt.NotifyForOperationUpdate = true;
         pt.NotifyForOperationDelete = false;
         pt.NotifyForOperationUndelete = false;
         pt.NotifyForFields = 'Select';

         try {
             var result = sforce.connection.create([pt]);
         } catch(e) {
             return _errorOnAccessingSobject(e, 'PushTopic');
         }
         if(result[0].getBoolean('success')) {
             console.info(me.pushTopicName + ' PushTopic not found and a new one is created');
         } else {
             console.error('Problem creating ' + me.pushTopicName + ' PushTopic: ', result[0]);
             return _errorOnAccessingSobject(result[0], 'PushTopic');
         }
     };

     pipelineStreamingService.initStreaming = () => {
         var query = 'SELECT Id, Name FROM PushTopic limit 10';
         var result = sforce.connection.query(query, {
             onSuccess: function(res) {
                 _init();
             },
             onFailure: function(res) {
                 console.error(res);
             }
         });
     };

     var _init = () => {
        var me = pipelineStreamingService;
        if(me.alreadyInitialized) {
            return;
        }
        me.alreadyInitialized = true;
        try {
            var query = 'Select Id, Name, ' + me.ns + 'Latest_Deployment__c, ' + me.ns + 'Latest_Deployment_Status__c FROM ' + me.ns + 'Environment__c';
            _getPushTopics();
            if(!me.hasPushTopic) {
                _createPushTopic(me.pushTopicName, query);
            }
        } catch(e) {
            console.error(e);
            return _errorOnAccessingSobject(e, me.ns + 'Environment__c');
        }
        var status = $copado.cometd.getStatus();
        if(status !== cometd_statuses.CONNECTED) {
            var asyncConnect = new Promise(function(resolve, reject) {
                _connectToStreaming();
            });
        }
     };

     var _connectToStreaming = () => {
         if(retryTimes == 0) {
             return;
         }
         retryTimes--;
         console.info('[' + pipelineStreamingService.pushTopicName + '] connecting to streaming... retry attempts left: ' + retryTimes);
         setTimeout(function() {
             var status = $copado.cometd.getStatus();
             console.log('[' + pipelineStreamingService.pushTopicName + '] status: ' + status);
             switch(status) {
                 case cometd_statuses.CONNECTED:
                    subscriptionRef = $copado.cometd.subscribe('/topic/' + pipelineStreamingService.pushTopicName, function(message) {
                        _readStream(message);
                    });
                    if(pipelineStreamingService.duration) {
                        _startTimer();
                    }
                    break;
                 case cometd_statuses.HANDSHAKING:
                 case cometd_statuses.HANDSHAKEN:
                 case cometd_statuses.CONNECTING:
                 case cometd_statuses.REHANDSHAKING:
                 case cometd_statuses.DISCONNECTED:
                    pipelineStreamingService.c = $copado.cometd.init({
                          url: window.location.protocol + '//' + window.location.hostname + '/cometd/37.0/',
                          requestHeaders: { Authorization: 'OAuth ' + __sfdcSessionId }
                     });
                    _connectToStreaming();
                    break;
                 default:
                    break;
             }
         }, 1000);
     };

     var _startTimer = () => {
         setTimeout(function() {
            timeoutInterval = setInterval(_runCountdown(), 1000);
         }, 10000);
         document.addEventListener('click', function() {
            pipelineStreamingService.timeout = pipelineStreamingService.duration;
         });
     };

     var _runCountdown = () => {
          if(pipelineStreamingService.timeout == 0) {
              if(subscriptionRef) {
                  $copado.cometd.unsubscribe(subscriptionRef);
                  console.info('Subscription to ' + pipelineStreamingService.pushTopicName + ' ended.');
              }
              clearInterval(timeoutInterval);
              return;
          }
          setTimeout(function() {
              pipelineStreamingService.timeout -= 1000;
              _runCountdown();
          }, 1000);
     };

     pipelineStreamingService.disconnect = () => {
          $copado.cometd.disconnect();
     };

     var _readStream = (message) => {
         var me = pipelineStreamingService;
         console.info('Push message: ', message);
         var statusMap = pipelineStreamingService.statusMap;
         if(message.channel == '/topic/' + pipelineStreamingService.pushTopicName) {
             var newStatus = message.data.sobject[me.ns + 'Latest_Deployment_Status__c'];
             var idString = '#deploymentStatus_' + message.data.sobject.Id;
             var idStringNoStatus = '#noDeploymentStatus_' + message.data.sobject.Id;
             var noDeploymentStatus = $copado(idStringNoStatus);
             if(noDeploymentStatus.length > 0) {
                var container = $copado(idStringNoStatus).parent();
                $copado(idStringNoStatus).remove();
                container.append('<img id="' + idString + '" src="" />');
             }
             var environmentStatus = $copado(idString);
             var elementType = environmentStatus.prop('nodeName');
             if(elementType === 'DIV' && newStatus !== 'In progress') {
                 _replaceSpinner(idString);
             } else if (elementType === 'IMG' && newStatus === 'In progress') {
                 _replaceImg(idString);
                 return;
             }
             var statusElem = $copado(idString);
             if(statusElem && statusMap !== undefined && statusMap !== null && (newStatus in statusMap)) {
                 $copado(statusElem).attr('src', statusMap[newStatus]);
             }
         }
     };
     var _replaceSpinner = (elemId) => {
        var container = $copado(elemId).parent();
        $copado(elemId).remove();
        container.append('<img id="' + elemId.replace('#','') + '" src="" />')
     };

     var _replaceImg = (elemId) => {
         var container = $copado(elemId).parent();
         $copado(elemId).remove();
         var spinner = '<div id="' + elemId.replace('#','') + '" class="spinner">'
                       + '<div role="status" class="slds-spinner slds-spinner_xx-small slds-spinner_brand">'
                       + '<span class="slds-assistive-text">Loading</span>'
                       + '<div class="slds-spinner__dot-a"></div>'
                       + '<div class="slds-spinner__dot-b"></div>'
                       + '</div></div>'
         container.append(spinner);
      }
})(ccdStream);