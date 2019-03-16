var metadataGrid2 = null;

var usTestClasses = usTestClasses || {};

usTestClasses.init = function(conf, force, isScalable, type, callback){
    conf.force = force;
    conf.isScalable = isScalable;
    metadataGrid2 = metadataGrid2 || new MetadataGrid2(conf);

    metadataGrid2.render(function() {
        console.info("usTestClasses::MetadataGrid:init grid rendered", conf);
        lockScreen();
        metadataGrid2.loadData(function() {
            console.info("usTestClasses::MetadataGrid:init grid data loaded");
            metadataGrid2.render();
            unlockScreen();
        });
    });

    if(callback){
        callback();
    }
};
usTestClasses.refreshCache = function() {
    metadataGrid2.refreshCache();
};

usTestClasses.save = function(){
     lockScreen();
     coGridHelper.datasource = metadataGrid2.datasource;
     coGridHelper.saveSelected(_config.data.id, _config.attachmentName, null, true, function(){
         location.href = '/apex/'+metadataGrid2.conf.ns+'userstoryselectedmetadata?id='+metadataGrid2.conf.data.id+'&inline=1'
     });
     window.parent.postMessage({"from":"userStorySelectedMetadata", "hasChanges":true,"change":null}, "*");
     return false;
 };

 usTestClasses.cancel = function(){
      location.href = '/apex/'+metadataGrid2.conf.ns+'userstoryselectedmetadata?id='+metadataGrid2.conf.data.id+'&inline=1'
      return false;
  };