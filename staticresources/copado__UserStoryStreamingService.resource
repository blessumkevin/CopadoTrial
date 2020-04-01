var ccdStoryStream = ccdStoryStream || {};

((userStoryStreamingService) => {
     var userStoryStreamingService = userStoryStreamingService || {};

     userStoryStreamingService.ns = '';
     userStoryStreamingService.timeout = 0;
     userStoryStreamingService.duration = 0;
     userStoryStreamingService.sobjectAccessError = '';
     userStoryStreamingService.pushTopicName = 'CopadoStories';
     userStoryStreamingService.streamCallback = {};
     userStoryStreamingService.pipelineId = '';
     userStoryStreamingService.sourceIds = '';
     userStoryStreamingService.destinationIds = '';
     userStoryStreamingService.filterJSON = '';
     userStoryStreamingService.flowStepToEnvJSON = '';
     userStoryStreamingService.allEnvironmentKeyJSON = '';
     userStoryStreamingService.allEnvironmentToStageJSON = '';
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
        console.error(e.faultstring);
        var msg = userStoryStreamingService.sobjectAccessError + (e.faultstring || e);
        msg = msg.replace('{SOBJECT}', sobjectType);
        return alert(msg);
    };

     var _getPushTopics = () => {
        var me = userStoryStreamingService;
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
         var me = userStoryStreamingService;
         var pt = new sforce.SObject('PushTopic');
         pt.Name = name;
         pt.Query = query;
         pt.ApiVersion = 46.0;
         pt.NotifyForOperationCreate = false;
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

     userStoryStreamingService.initStreaming = () => {
         var query = 'SELECT Id, Name FROM PushTopic LIMIT 10';
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
        var me = userStoryStreamingService;
        if(me.alreadyInitialized) {
            return;
        }
        me.alreadyInitialized = true;
        try {
            var query = 'Select Id, ' + me.ns + 'Promote_Change__c,' + me.ns + 'Environment__c FROM ' + me.ns + 'User_Story__c';
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
         console.info('[' + userStoryStreamingService.pushTopicName + '] connecting to streaming... retry attempts left: ' + retryTimes);
         setTimeout(function() {
             var status = $copado.cometd.getStatus();
             console.log('[' + userStoryStreamingService.pushTopicName + '] status: ' + status);
             switch(status) {
                 case cometd_statuses.CONNECTED:
                    subscriptionRef = $copado.cometd.subscribe('/topic/' + userStoryStreamingService.pushTopicName, function(message) {
                        _readStream(message);
                    });
                    if(userStoryStreamingService.duration) {
                        _startTimer();
                    }
                    break;
                 case cometd_statuses.HANDSHAKING:
                 case cometd_statuses.HANDSHAKEN:
                 case cometd_statuses.CONNECTING:
                 case cometd_statuses.REHANDSHAKING:
                 case cometd_statuses.DISCONNECTED:
                    userStoryStreamingService.c = $copado.cometd.init({
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
            userStoryStreamingService.timeout = userStoryStreamingService.duration;
         });
     };

     var _runCountdown = () => {
          if(userStoryStreamingService.timeout == 0) {
              if(subscriptionRef) {
                  $copado.cometd.unsubscribe(subscriptionRef);
                  console.info('Subscription to ' + userStoryStreamingService.pushTopicName + ' ended.');
              }
              clearInterval(timeoutInterval);
              return;
          }
          setTimeout(function() {
              userStoryStreamingService.timeout -= 1000;
              _runCountdown();
          }, 1000);
      };

     userStoryStreamingService.disconnect = () => {
          $copado.cometd.disconnect();
     };

     var _readStream = (message) => {
         console.info('Push message: ', message);
         if(message.channel == '/topic/' + userStoryStreamingService.pushTopicName) {
             _recalculateUserStoryCounts();
         }
     };

     var _recalculateUserStoryCounts = () => {
         var me = userStoryStreamingService;
         var core = me.ns ? window[me.ns.split('__')[0]] : window;
         (core).PipelineManagerExtension.promotableStoriesForRemoteAction(me.pipelineId, me.sourceIds, me.filterJSON, function(userStoryCountMap, event) {
             if(event.status) {
                 var environmentBoxes = document.querySelectorAll("[id^='wrapper_'");
                 if(environmentBoxes) {
                     for(var i = 0; i < environmentBoxes.length; i++) {
                         var environmentId = environmentBoxes[i].id.split('wrapper_')[1];
                         var storyCountAhead = environmentBoxes[i].querySelector(".storyCountAhead");
                         if(storyCountAhead && environmentId && (environmentId in userStoryCountMap)) {
                             var count = userStoryCountMap[environmentId];
                             if(count == 0) {
                                $copado(storyCountAhead).addClass('disabled');
                             } else {
                                $copado(storyCountAhead).removeClass('disabled');
                             }
                             var storyCountAheadBtn = storyCountAhead.querySelector('.storyCountAheadBtn');
                             if(storyCountAheadBtn) {
                                 storyCountAheadBtn.innerHTML = count;
                             }
                         }
                     }
                 }
             }
         }, { escape : false });
         (core).PipelineManagerExtension.backPromotableStoriesForRemoteAction(me.pipelineId, me.destinationIds, me.filterJSON, me.flowStepToEnvJSON, me.allEnvironmentToStageJSON, me.allEnvironmentKeyJSON, function(userStoryCountMap, event) {
             if(event.status) {
                 var environmentBoxes = document.querySelectorAll("[id^='wrapper_'");
                 if(environmentBoxes) {
                     for(var i = 0; i < environmentBoxes.length; i++) {
                         var environmentId = environmentBoxes[i].id.split('wrapper_')[1];
                         var storyCountBehind = environmentBoxes[i].querySelector(".storyCountBehind");
                         if(storyCountBehind && environmentId && (environmentId in userStoryCountMap)) {
                             var count = userStoryCountMap[environmentId];
                             if(count == 0) {
                                $copado(storyCountBehind).addClass('disabled');
                             } else {
                                $copado(storyCountBehind).removeClass('disabled');
                             }
                             var storyCountBehindBtn = storyCountBehind.querySelector('.storyCountBehindBtn');
                             if(storyCountBehindBtn) {
                                 storyCountBehindBtn.innerHTML = count;
                             }
                         }
                     }
                 }
             }
         }, { escape : false });
     };
})(ccdStoryStream);