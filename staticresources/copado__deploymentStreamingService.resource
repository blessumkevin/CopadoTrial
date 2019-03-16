var deploymentStreamingService = deploymentStreamingService || {};

deploymentStreamingService.streamingAPI_clientId  = '';
deploymentStreamingService.fileName = 'PROGRESS_STATUS_COPADO';
deploymentStreamingService.ns = '';

deploymentStreamingService.readStream = function(message){
    var me = deploymentStreamingService;
    
    me.streamingAPI_clientId = message.clientId;

    if(message.channel=='/topic/CopadoNotifications'){
        if(me.ParentIdinArray(message.data.sobject[me.ns+'ParentId__c'])){
            if(message.data.sobject.Name==me.fileName){
                copadoApp.updateDeployment();
                copadoApp.statusCheckerCallBack();
                setTimeout(function(){
                    copadoApp.updateDeployment();
                    copadoApp.statusCheckerCallBack();
                }, 5000);
            }
        }
    }
};
deploymentStreamingService.ParentIdinArray = function(parentId){
    for(var i=0; i<copadoApp.data.jobs.length; i++){
        var id1 = parentId;
        var id2 = copadoApp.data.jobs[i].Id;
        console.info(id1, id2, id1 == id2);
        if(id1 == id2)return true;
    }
    return false;
};