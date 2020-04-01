/* Minimap */
(function($, pipelineConnector) {
    $.fn.minimap = function($mapSource, elem) {
        var x, y, l, t, w, h;
        var $window = $(window);
        var $minimap = this;
        var minimapWidth = $minimap.width();
        var minimapHeight = $minimap.height();
        var $viewport = $("<div></div>").addClass("minimap-viewport");
        $minimap.append($viewport);
        synchronize();

        $window.on("resize", synchronize);
        $mapSource.on("scroll", synchronize);
        $mapSource.on("drag", init);
        $minimap.on("mousedown touchstart", down);

        function down(e) {
            var moveEvent, upEvent;
            var pos = $minimap.position();

            x = Math.round(pos.left + l + w / 2);
            y = Math.round(pos.top + t + h / 2);
            move(e);

            if (e.type === 'touchstart') {
                moveEvent = 'touchmove.minimapDown';
                upEvent = 'touchend';
            } else {
                moveEvent = 'mousemove.minimapDown';
                upEvent = 'mouseup';
            }
            $window.on(moveEvent, move);
            $window.on(upEvent, up);
        }

        function move(e) {
            e.preventDefault();

            if (e.type.match(/touch/)) {
                if (e.touches.length > 1) {
                    return;
                }
                var event = e.touches[0];
            } else {
                var event = e;
            }

            var dx = event.clientX - x;
            var dy = event.clientY - y;
            if (l + dx < 0) {
                dx = -l;
            }
            if (t + dy < 0) {
                dy = -t;
            }
            if (l + w + dx > minimapWidth) {
                dx = minimapWidth - l - w;
            }
            if (t + h + dy > minimapHeight) {
                dy = minimapHeight - t - h;
            }

            x += dx;
            y += dy;

            l += dx;
            t += dy;

            var coefX = minimapWidth / $mapSource[0].scrollWidth;
            var coefY = minimapHeight / $mapSource[0].scrollHeight;
            var left = l / coefX;
            var top = t / coefY;

            $mapSource[0].scrollLeft = Math.round(left);
            $mapSource[0].scrollTop = Math.round(top);

            redraw();
        }

        function up() {
            $window.off('.minimapDown');
        }

        function synchronize() {
            var dims = [$mapSource.width(), $mapSource.height()];
            var scroll = [$mapSource.scrollLeft(), $mapSource.scrollTop()];
            var scaleX = minimapWidth / $mapSource[0].scrollWidth;
            var scaleY = minimapHeight / $mapSource[0].scrollHeight;

            var lW = dims[0] * scaleX;
            var lH = dims[1] * scaleY;
            var lX = scroll[0] * scaleX;
            var lY = scroll[1] * scaleY;

            w = Math.round(lW);
            h = Math.round(lH);
            l = Math.round(lX);
            t = Math.round(lY);
            //set the mini viewport dimensions
            redraw();
        }

        function redraw() {
            $viewport.css({
                width: w,
                height: h,
                left: l,
                top: t
            });

            // Recalculate SVG
            ccd.connectAll();
        }

        function calculateHeightFactor() {
            var firstColumnEnvNumber = $copado($mapSource.children('.column').get(0)).find(elem).length;
            var secondColumnEnvNumber = $copado($mapSource.children('.column').get(1)).find(elem).length;
            var heightFactor = 0;

            columnsNumber = firstColumnEnvNumber > secondColumnEnvNumber ? firstColumnEnvNumber : secondColumnEnvNumber;

            if (columnsNumber <= 10) {
                heightFactor = 0.5;
            } else if (columnsNumber > 10 && columnsNumber <= 30) {
                heightFactor = 0.6;
            } else if (columnsNumber > 30 && columnsNumber <= 50) {
                heightFactor = 0.7;
            } else if (columnsNumber > 50 && columnsNumber <= 65) {
                heightFactor = 0.8;
            } else if (columnsNumber > 65 && columnsNumber <= 80) {
                heightFactor = 0.9;
            } else if (columnsNumber > 80) {
                heightFactor = 1;
            }

            return heightFactor;
        }

        function init() {
            $minimap.find('.minimap-node').remove();
            //creating mini version of the supplied children

            var heightFactor = calculateHeightFactor();

            $mapSource.find(elem).each(function() {
                var $child = $(this);
                var mini = $('<div></div>').addClass('minimap-node');
                $minimap.append(mini);

                var ratioX = minimapWidth / $mapSource[0].scrollWidth;
                var ratioY = minimapHeight / $mapSource[0].scrollHeight;

                var ratioX = (minimapWidth / $mapSource[0].scrollWidth) * 0.8;
                var ratioY = (minimapHeight / $mapSource[0].scrollHeight) * heightFactor;

                var wM = $child.width() * ratioX;
                var hM = $child.height() * ratioY;
                var xM = ($child.position().left + $mapSource.scrollLeft()) * ratioX;
                var yM = ($child.position().top + $mapSource.scrollTop()) * ratioY;

                mini.css({
                    width: Math.round(wM),
                    height: Math.round(hM),
                    left: Math.round(xM),
                    top: Math.round(yM)
                });
            });



        }

        init();

        return this;
    }
})(jQuery, ccd);


/* It detects collisions between two DOM elements */
var overlaps = (function() {
    function getPositions(elem) {
        var pos, width, height;
        pos = $copado(elem).position();
        width = $copado(elem).width() / 2;
        height = $copado(elem).height();
        return [
            [pos.left, pos.left + width],
            [pos.top, pos.top + height]
        ];
    }

    function comparePositions(p1, p2) {
        var r1, r2;
        r1 = p1[0] < p2[0] ? p1 : p2;
        r2 = p1[0] < p2[0] ? p2 : p1;
        return r1[1] > r2[0] || r1[0] === r2[0];
    }

    return function(a, b) {
        var pos1 = getPositions(a),
            pos2 = getPositions(b);
        return comparePositions(pos1[0], pos2[0]) && comparePositions(pos1[1], pos2[1]);
    };
})();


// Continuous Delivery Javascript
var ccd = ccd || {};
var copadoApp = copadoApp ? copadoApp : {};
var staticResourcesPath = staticResourcesPath ? staticResourcesPath : '';

((pipelineConnector) => {

    var pipelineConnector = pipelineConnector || {};
    var boxClassIdentifier = '.box-container';

    var signum = (x) => {
        return (x < 0) ? -1 : 1;
    };

    var absolute = (x) => {
        return (x < 0) ? -x : x;
    };

    var getConnectionsList = () => {
        if (ccd.data.connections.length > 0) {
            pipelineConnector.data.connectionsList = JSON.parse(ccd.data.connections);
        }
    };

    var drawPath = (svg, path, startX, startY, endX, endY) => {
        var stroke = parseFloat(path.css('stroke-width'));
        var offsetHeight = 20;

        if (endY < startY && startY > 0) {
            svg.attr('height', startY + offsetHeight);

        } else if (svg.attr('height') < endY) {
            svg.attr('height', endY + offsetHeight);
        }

        if (svg.attr('width') < (startX + stroke)) {
            svg.attr('width', (startX + stroke));
        }

        if (svg.attr('width') < (endX + stroke)) {
            svg.attr('width', (endX + stroke));
        }

        var deltaX = (endX - startX) * 0.15;
        var deltaY = (endY - startY) * 0.15;
        var delta = startY !== endY ? 25 : deltaY < absolute(deltaX) ? deltaY : absolute(deltaX);
        var offset = 30;
        var arc1 = 1;
        var arc2 = 0;

        if (startY > endY) {
            arc1 = 0;
            arc2 = 1;
        }

        var belowPoint = startY > endY ? -1 : 1;
        delta = startY > endY ? absolute(delta) : delta;
        if(absolute(startY - endY) > 5 ) {
        path.attr('d', ' M' + startX + ' ' + startY +
            ' H' + (startX + delta + offset) +
            ' A' + delta + ' ' + delta + ' 0 0 ' + arc1 + ' ' + (offset + startX + 2 * delta) + ' ' + (startY + delta * belowPoint * signum(delta)) +
            ' V' + (endY) +
            ' H' + endX);
        } else {

            path.attr('d', ' M' + startX + ' ' + startY +
                        ' H' + endX);
        }
    };

    var connectElements = (svg, path, startElem, endElem) => {
        var svgContainer = $copado('#svgContainer');

        if (Object.keys(startElem).length === 0 || Object.keys(endElem).length === 0) {
            return;
        }

        if (startElem.offset().left > endElem.offset().left) {
            var temp = startElem;
            startElem = endElem;
            endElem = temp;
        }

        var svgTop = svgContainer.offset().top;
        var svgLeft = svgContainer.offset().left;

        var startCoord = startElem.offset();
        var endCoord = endElem.offset();


        var startX = startCoord.left + startElem.outerWidth() - svgLeft;
        var startY = startCoord.top + 0.5 * startElem.outerHeight() - svgTop;
        var endX = endCoord.left - svgLeft;
        var endY = endCoord.top + 0.5 * endElem.outerHeight() - svgTop;

        if (startY > endY && startY - endY < 3) {
            startY = endY;
        }
        if (endY > startY && endY - startY < 3) {
            endY = startY;
        }

        drawPath(svg, path, startX - 10, startY, endX - 5, endY);
    };

    var getLineArrows = () => {
        var svgContainer = document.getElementById('svgContainer');
        var svgs = svgContainer.children;
        var i, j;
        var svgNS = 'http://www.w3.org/2000/svg';
        var id, svg, mainPath, defs, defTags, path, marker;

        for (var i = 0; i < svgs.length; i++) {

            id = svgs[i].getAttribute('id');

            svg = document.getElementById(id);
            defs = document.createElementNS(svgNS, 'defs');

            svg.appendChild(defs);

            defTags = document.getElementsByTagName('defs');

            path = document.createElementNS(svgNS, 'path');
            path.setAttributeNS(null, 'd', 'M0,0 L0,6 L9,3 z');
            path.setAttributeNS(null, 'fill', '#f00');

            marker = document.createElementNS(svgNS, 'marker');

            marker.appendChild(path);

            marker.setAttributeNS(null, 'id', 'arrow');
            marker.setAttributeNS(null, 'markerWidth', 20);
            marker.setAttributeNS(null, 'markerHeight', 20);
            marker.setAttributeNS(null, 'refX', 0);
            marker.setAttributeNS(null, 'refY', 3);
            marker.setAttributeNS(null, 'orient', 'auto');
            marker.setAttributeNS(null, 'markerUnits', 'strokeWidth');
            marker.setAttributeNS(null, 'viewBox', '0 0 20 20');

            for (j = 0; j < defTags.length; j++) {
                defTags[j].appendChild(marker);
            }

            mainPath = svg.getElementsByTagName('path')[0];
            mainPath.setAttributeNS(null, 'marker-end', 'url(#arrow)');
        }
    };

    var adjustSvgDimensions = () => {
        // Expand svg more to see arrows
        var svgContainer = $copado('#svgContainer');
        var svg, svgHeight, svgWidth;

        svgContainer.children().each(function() {
            svg = $copado(this);
            svgHeight = parseFloat(svg.attr('height'));
            svgWidth = parseFloat(svg.attr('width'));

            svg.attr('height', svgHeight + 20);
            svg.attr('width', svgWidth + 10);

        });
    };

    var createSvgs = () => {
        var svgContainer = $copado('#svgContainer');
        var connectionsList = pipelineConnector.data.targetToSourceList;
        if (!connectionsList) {
            return;
        }
        connectionsList.forEach((connection, index) => {

            svgContainer.append(` <svg id="svg${index}" width="0" height="0" >
                <path id="path${index}"/>
            </svg>`);
        });
    };

    pipelineConnector.connectAll = () => {
        var connectionsList = pipelineConnector.data.targetToSourceList;
        if (!connectionsList) {
            return;
        }
        connectionsList.forEach((connection, index) => {

            connectElements($copado(`#svg${index}`), $copado(`#path${index}`), $copado(`#${connection.origin}`), $copado(`#${connection.target}`));

        });
    };

    var setMinimap = () => {
        var myWrapper = $copado('.pipeline');
        var $minimap = $copado('#minimap');

        if (pipelineConnector.data.isSalesforceClassic) {
            $copado('#minimap').css({ 'bottom': '95px', 'right': '80px' });
        }

        if ($copado(boxClassIdentifier).length > 0) {
            $copado('#minimap').minimap(myWrapper, boxClassIdentifier);
            $minimap.show();
        }

    };

    var initLineConnections = () => {

        createSvgs();
        getLineArrows();
        pipelineConnector.connectAll();
        adjustSvgDimensions();

    };


    var formatConnections = (connectionsList) => {
        var convertedList = [];
        var stage, fromEnvId, toEnvId, columnNumber;
        var finalConnectionList = [];
        var connectionData;
        var fromEnvId, toEnvId, columnNumber;
        var fromEnvName, toEnvName;
        var namespace = pipelineConnector.config.ns;

        for (var key in connectionsList) {
            stage = connectionsList[key];

            for (var stageObject in stage) {

                if (stageObject !== 'Final') {

                    for (var j = 0; j < stage[stageObject].length; j++) {
                        fromEnvId = stage[stageObject][j].currentStep[namespace + 'Source_Environment__c'] ? stage[stageObject][j].currentStep[namespace + 'Source_Environment__c'] : stage[stageObject][j].currentStep[namespace + 'Branch__c'];
                        toEnvId = stage[stageObject][j].currentStep[namespace + 'Destination_Environment__c'] ? stage[stageObject][j].currentStep[namespace + 'Destination_Environment__c'] : stage[stageObject][j].currentStep[namespace + 'Destination_Branch__c'];
                        fromEnvName = stage[stageObject][j].currentStep[namespace + 'Source_Environment__r'] ? stage[stageObject][j].currentStep[namespace + 'Source_Environment__r'].Name : '';
                        toEnvName = stage[stageObject][j].currentStep[namespace + 'Destination_Environment__r'] ? stage[stageObject][j].currentStep[namespace + 'Destination_Environment__r'].Name : '';
                        columnNumber = key.replace('Stage ', '');
                        convertedList.push({
                            originName: fromEnvName,
                            targetName: toEnvName,
                            origin: `wrapper_${fromEnvId}`,
                            target: `wrapper_${toEnvId}`,
                            column: columnNumber
                        });
                    }
                }
            }
        }

        pipelineConnector.data.targetToSourceList = convertedList;

        finalConnectionList = [{
            target: convertedList[0].target,
            connections: [convertedList[0].origin],
            column: convertedList[0].column
        }];

        convertedList.forEach((item) => {

            if (item.target === finalConnectionList[finalConnectionList.length - 1].target && item.column === finalConnectionList[finalConnectionList.length - 1].column) {
                finalConnectionList[finalConnectionList.length - 1].connections.push(item.origin);

            } else {

                connectionData = {
                    target: item.target,
                    connections: [item.origin],
                    column: item.column
                };

                finalConnectionList.push(connectionData);

            }
        });

        return finalConnectionList;
    };

    var getConnectedEnvironments = (connectionList, index) => {

        var currentColumn = parseInt(connectionList[index].column, 10);
        var lastColumn;
        var lastColumnElems;
        var connectedEnv = [];
        var data = {};
        var connectionFound;

        if (currentColumn > 1) {

            lastColumn = (currentColumn - 1).toString();

            lastColumnElems = connectionList.filter((connection) => {
                return connection.column === lastColumn;

            });

            connectionList[index].connections.forEach((connection, index) => {

                connectionFound = lastColumnElems.find((item) => {
                    return item.target === connection;
                });

                data = {
                    id: connection,
                    isConnected: connectionFound && connection === connectionFound.target ? true : false
                };

                connectedEnv.push(data);
            });

            connectedEnv = connectedEnv.sort(function(x, y) {
                return (x.isConnected === y.isConnected) ? 0 : x.isConnected ? -1 : 1;
            });
        }

        return connectedEnv;
    };


    var hasPreviousConnection = (connectionList, elemConnection) => {

        var currentColumn = parseInt(elemConnection.column, 10);
        var lastColumn;
        var lastColumnElems;
        var isConnected = [];
        var connectionFound, allConnected = false;

        if (currentColumn > 1) {

            lastColumn = (currentColumn - 1).toString();

            lastColumnElems = connectionList.filter((connection) => {
                return connection.column === lastColumn;
            });

            elemConnection.connections.forEach((connection, index) => {

                connectionFound = lastColumnElems.find((item) => {
                    return item.target === connection;
                });

                isConnected[index] = (connectionFound && connection === connectionFound.target) ? true : false;
            });

            allConnected = isConnected[0];
            isConnected.forEach((item) => {
                allConnected = allConnected && item;
            });

        } else {
            allConnected = true;
        }

        return allConnected;
    };

    var moveBoxes = (displaceHeightValue) => {
        var boxes = $copado(boxClassIdentifier);
        var currentOffset = 0;

        boxes.each(function(index) {

            var $box = $copado(this);
            currentOffset = $box.offset().top;
            $box.offset({ top: currentOffset + displaceHeightValue });
        });
    };


    var moveBoxesInColumn = ($column, offsetTopLimit, id) => {
        var boxHeight = $copado(boxClassIdentifier).height() + 10;

        $column.children().each(function(index) {

            var $box = $copado(this);
            var boxOffsetTop = $box.offset().top;
            var isCollided = true;

            if (boxOffsetTop >= offsetTopLimit && $box.attr('id') === id) {
                $box.offset({ top: boxOffsetTop + boxHeight });
            }
        });
    };

    var handleCollisions = ($column, columnGroups) => {
        var haveCollisions = true;
        while (haveCollisions) {
            $column.children().each(function(index) {
                var box = $copado(this);
                var offsetTop = 0;
                var isCollided = true;
                var collisionedEnv;
                haveCollisions = true;

                var collisions = $column.find(boxClassIdentifier).not(box).map(function(i) {
                    return { id: $column.children()[i].id, collision: overlaps(box, this) };
                });

                collisions = collisions.filter((index, item) => item.collision === true);

                if (collisions.length > 0) {
                    for (var i = 0; i < collisions.length; i++) {
                        // console.log(box.attr('id') + ' has a collision with ' + collisions[i].id);
                        offsetTop = box.offset().top;

                        moveBoxesInColumn($column, offsetTop, box.attr('id'));

                        isCollided = true;
                        collisionedEnv = $copado(`#${collisions[i].id}`);

                        while (isCollided) {

                            collisionedEnv.offset({ top: collisionedEnv.offset().top - 20 });

                            if (!overlaps(collisionedEnv, $copado(`#${box.attr('id')}`)) || collisions[i].id === box.attr('id')) {
                                collisionedEnv.offset({ top: collisionedEnv.offset().top + 15 });
                                isCollided = false;
                            }
                        }
                    }
                } else {
                    haveCollisions = false;
                }
            });
        }
    };

    var calculateSmartPositioning = () => {

        if ($copado(boxClassIdentifier).length > 0) {
            lockScreen();

            var firstItemTop, lastItemTop;
            var totalHeight = 0;
            var boxHeight = $copado(boxClassIdentifier).height() + 10;
            var connectionsList = pipelineConnector.data.connectionsList;
            var formattedConnectionsList = formatConnections(connectionsList);
            var lastBoxPosition = 0;
            var connectedEnv, connections;
            var $columns, $box;
            var lastPositionedBox;
            var classicHeaderHeight = $copado('#AppBodyHeader').height() + 3;
            var connectedElements, noConnectedElements;

            formattedConnectionsList.forEach((item, index) => {

                if (item.connections.length > 1 && !hasPreviousConnection(formattedConnectionsList, item)) {

                    connectedEnv = getConnectedEnvironments(formattedConnectionsList, index);
                    connectedElements = connectedEnv.filter(element => element.isConnected);
                    noConnectedElements = connectedEnv.filter(element => !element.isConnected);
                    connectedEnv = noConnectedElements.concat(connectedElements);
                    item.connections = connectedEnv.map(x => x.id);

                    lastPositionedBox = connectedEnv.find((item) => {
                        return item.isConnected;
                    });

                    if (lastPositionedBox) {

                        connectedEnv.forEach((box, index) => {

                            if (box.isConnected) {

                                firstItemTop = $copado(`#${connectedElements[0].id}`).position().top;
                                lastItemTop = $copado(`#${connectedElements[connectedElements.length - 1].id}`).position().top;
                                totalHeight = Math.floor((lastItemTop + firstItemTop) / 2);
                                $copado(`#${item.target}`).offset({ top: totalHeight });

                            } else {

                                lastItemTop = $copado(`#${lastPositionedBox.id}`).offset().top;
                                totalHeight = lastItemTop - boxHeight;
                                $copado(`#${box.id}`).offset({ top: totalHeight });

                            }

                            lastPositionedBox = box;
                        });

                    } else {

                        firstItemTop = $copado(`#${noConnectedElements[0].id}`).position().top;
                        lastItemTop = $copado(`#${noConnectedElements[noConnectedElements.length - 1].id}`).position().top;
                        totalHeight = Math.floor((lastItemTop + firstItemTop) / 2);
                        $copado(`#${item.target}`).offset({ top: totalHeight });
                    }

                } else {

                    firstItemTop = $copado(`#${item.connections[0]}`).position().top;
                    lastItemTop = $copado(`#${item.connections[item.connections.length - 1]}`).position().top;
                    totalHeight = Math.floor((lastItemTop + firstItemTop) / 2);

                    if (pipelineConnector.data.isSalesforceClassic) {
                        totalHeight += classicHeaderHeight;
                    }

                    $copado(`#${item.target}`).offset({ top: totalHeight });
                }
            });

            // Check if all box position calculations are inside the container and displace it if not
            var boxes = $copado(boxClassIdentifier);
            var filterOffset = $copado('.filter-main-object').offset().top + $copado('.filter-main-object').height();

            boxes.each(function(index) {
                var $box = $copado(this);
                var displaceHeightValue = 0;
                var margin = 20;

                if ($box.offset().top < filterOffset) {
                    displaceHeightValue = filterOffset - $box.offset().top + margin;
                    moveBoxes(displaceHeightValue);
                }
            });

            // Check collisions. If there are one between 2 boxes, put the box immediately bellow the other one, and move the rest of the boxes
            $columns = $copado('.pipeline').children();

            $columns.each(function(index) {
                var $column = $copado(this);
                var columnBoxesNumber = $column.children().length;
                var columnGroups = formattedConnectionsList.filter((connection) => {
                    return parseInt(connection.column, 10) === index + 1;
                });
                if (columnBoxesNumber > 1) {
                    handleCollisions($column, columnGroups);
                }
            });
        }

        unlockScreen();
    };

    var handleDropdownMenus = () => {
        var envDropdowns = document.querySelectorAll('.box-container div.slds-dropdown');
        var diagramDropdown = document.querySelector('.diagramDropwdown');
        var filterDropdown = document.querySelector('.filter-main-object div.slds-dropdown');
        var dropdowns;

        if (document.querySelector('.slds-dropdown-trigger_click.diagramDropwdown')) {
            document.querySelector('.slds-dropdown-trigger_click.diagramDropwdown').addEventListener('click', (event) => {
                var thisMenu = event.target.closest('.slds-dropdown-trigger_click');
                if (thisMenu.className.includes('diagramDropwdown')) {
                    thisMenu.classList.toggle('slds-is-open');
                }
            });
        }

        document.querySelector('.slds-dropdown-trigger_click.filterOptionsMenu').addEventListener('click', (event) => {
            var thisMenu = event.target.closest('.slds-dropdown-trigger_click');
            if (thisMenu.className.includes('filterOptionsMenu')) {
                thisMenu.classList.toggle('slds-is-open');
            }
        });

        if (envDropdowns.length > 0) {

            document.addEventListener('click', (event) => {
                for (var i = 0; i < envDropdowns.length; i++) {
                    var isClickInside = envDropdowns[i].contains(event.target);
                    var button = envDropdowns[i].parentElement.querySelector('.slds-dropdown-trigger > button');
                    var isTriggered = button && button.contains(event.target);

                    if (!isClickInside && !isTriggered) {
                        $copado(envDropdowns[i]).addClass('slds-hide');
                    }
                }

                if (!(event.target.closest('button') && event.target.className.includes('diagramActionButton'))) {
                    $copado(diagramDropdown).removeClass('slds-is-open');
                }

                if (!(event.target.closest('button') && event.target.closest('button').id === 'filterSettings')) {
                    $copado(filterDropdown).parent().removeClass('slds-is-open');
                }
            });
        }
    };

    pipelineConnector.loadPage = () => {
        try {
            getConnectionsList();
            if (!pipelineConnector.data.connectionsList) {
                return;
            }
            calculateSmartPositioning();
            initLineConnections();
            setMinimap();
            handleDropdownMenus();

        } catch (error) {
            console.error(error);
            unlockScreen();
            alert(error);
        }
    };

    pipelineConnector.updateLastDeployment = (envId, deploymentStatus) => {

        var statusMap = {
            'Completed Successfully': copadoApp.icons.success,
            'Completed with Errors': copadoApp.icons.failed,
            'In progress': copadoApp.icons.paused,
            'Outdated': copadoApp.icons.paused
        }
        var idString = '#deploymentStatus_' + envId;
        var environmentStatus = $copado(idString);

        if (environmentStatus) {
            $copado(environmentStatus).attr('src', statusMap[deploymentStatus]);
        }
    };

    pipelineConnector.openDropdownMenu = (currentButton) => {
        var box = currentButton.closest('.env-box');
        var dropdown = box.nextElementSibling;

        if ($copado(dropdown).hasClass('slds-hide')) {
            $copado('.slds-dropdown.envActionDropdown').addClass('slds-hide');
            $copado(dropdown).removeClass('slds-hide');
        } else {
            $copado('.slds-dropdown.envActionDropdown').addClass('slds-hide');
            $copado(dropdown).addClass('slds-hide');
        }
    };

    pipelineConnector.createOrg = (stepId, envId, envName, useStep) => {
        lockScreen();
        createOrgCredentials(stepId, envId, '', '', 'true', useStep);
    };

    pipelineConnector.isManagerRunning = (currentMode) => {
        if (currentMode === 'manager') {
            promotableUserStories();
        } else {
            reRenderPipelineWrapper();
        }
    };

    pipelineConnector.openConnectionBehavior = (connectionBehaviorId) => {
        window.open('/' + connectionBehaviorId, '_blank');
    };

    pipelineConnector.fromAcf2Open = () => {
        $copado('[id$=dependencyUSComponent]').show();
        $copado('[id$=operationModal]').hide();
        $copado('[id$=promotionListModal]').hide();
        applyRenderSVG(undefined, ['chevrondown']);
        unlockScreen();
    };

    pipelineConnector.reRenderFunction = () => {
        ccd.loadPage();
        renderPageMessage();
    };

    pipelineConnector.toggleNewConnectionIcon = (elem) => {

        var box = $copado(elem).find('.connection-behaviour-override');

        if (box.hasClass('hide')) {
            box.removeClass('hide');
            box.addClass('show');

        } else {
            box.addClass('hide');
            box.removeClass('show');
        }
    };


    var definePipelineConnector = () => {
        pipelineConnector.data = pipelineConnector.data || {};
        pipelineConnector.config = pipelineConnector.config || {};
        pipelineConnector.config.ns = copadoApp.ns;
        pipelineConnector.data.flowId = copadoApp.data.flowId;
        pipelineConnector.data.isSalesforceClassic = copadoApp.data.isClassic === "true" ? true : false;

        pipelineConnector.data.connectionsList = [];
    };


    $copado(document).ready(() => {
        definePipelineConnector();

    });

})(ccd);