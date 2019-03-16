var metadataGrid2 = null;

var orgMetadata = orgMetadata || {};

orgMetadata.init = function(conf, force, isScalable, type){
    conf.force = force;
    conf.isScalable = isScalable;
    metadataGrid2 = metadataGrid2 || new MetadataGrid2(conf);

    // there is no selection to load, so skip this step
    metadataGrid2.loadSelectedMetaData = function(callbackFinished) {
        if(callbackFinished)
            callbackFinished();
    };

    metadataGrid2.render(function() {
        console.info("MetadataGrid:init grid rendered", conf);
        lockScreen();
        metadataGrid2.loadData(function() {
            console.info("MetadataGrid:init grid data loaded");
            metadataGrid2.render();
            unlockScreen();
        });
    });
}

orgMetadata.refreshCache = function() {
    metadataGrid2.refreshCache();
};
