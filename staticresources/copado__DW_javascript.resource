// DW_javascript
var dw = dw || {};
var globalSldsResourcePath = globalSldsResourcePath ? globalSldsResourcePath : undefined;
var currentStepValue = currentStepValue ? currentStepValue : 0;
var dataTableId = dataTableId ? dataTableId : undefined;
var selectedSourceType = selectedSourceType ? selectedSourceType : undefined;
var dId = dId ? dId : undefined;
var stepId = stepId ? stepId : undefined;
var namespace = namespace ? namespace : undefined;

((app) => {
    'use strict';

    var iconsList = [{
            svgButtonsClass: 'stepCompleted',
            name: 'success'
        },
        {
            svgButtonsClass: 'search',
            name: 'search'
        },
        {
            svgButtonsClass: 'down',
            name: 'down'
        },
        {
            svgButtonsClass: 'chevronright',
            name: 'chevronright'
        },
        {
            svgButtonsClass: 'warningToastIcon',
            name: 'warning'
        },
        {
            svgButtonsClass: 'successToastIcon',
            name: 'success'
        },
        {
            svgButtonsClass: 'errorToastIcon',
            name: 'error'
        },
        {
            svgButtonsClass: 'closeToastIcon',
            name: 'close'
        },
        {
            svgButtonsClass: 'infoToastIcon',
            name: 'check'
        },
        {
            svgButtonsClass: 'pinIcon',
            name: 'check'
        }
    ];
    var svgStruct = [];

    app.setDataTableId = (value) => {
        dataTableId = `${value}Table`;
    };

    app.buttonOnComplete = () => {
        app.applyRenderSVG();
        app.getTooltipPosition();
    };

    app.changeValue = (input, textid) => {
        app.selection = '';
        app.setDataTableId(input.value);
        document.getElementById(textid).value = input.value;
    };

    app.getTooltipPosition = () => {

        if (currentStepValue) {
            var stepNumber = currentStepValue;
            var offset = 30;
            var position = $copado($copado('.slds-progress__list>li')[stepNumber]).position().left;
            var leftPosition = ($copado($copado('.slds-progress__list>li')[stepNumber]).position().left - offset) + 'px';

            $copado(`#step-${currentStepValue}-tooltip`).css({
                'left': leftPosition
            });
            $copado(`#step-${currentStepValue}-tooltip`).css({
                'display': 'block'
            });
        }
    };

    app.selection = '';

    var checkDataTableRow = (tr, tableId, rows, currentPage) => {
        var table = $copado(`#${tableId}`).DataTable();

        if ($copado(tr).find('td:first').find('input[type="checkbox"]')[0]) {

            // remove the previous selection mark
            rows.each((index, row) => {
                if ($copado(row).find('td:first').find('input[type="checkbox"]').length > 0) {
                    $copado(row).find('td:first').find('input[type="checkbox"]')[0].checked = false;
                }
            });

            // mark the picked row
            $copado(tr).find('td:first').find('input[type="checkbox"]')[0].checked = true;
            app.selection = $copado(tr).find('td:first').find('input[type="checkbox"]').attr('recordId');
            if ($copado('.disabled').length > 0) {
                $copado('.disabled').prop('disabled', false);
                $copado('.disabled').removeClass('disabled');
            }
            table.page(currentPage).draw(false);
        }
    };

    app.handleTabs = (elem) => {
        var open = $copado(elem.target).data('open');
        if (open === true) {
            $copado('#tabbingUl li').removeClass('slds-is-active');
            $copado(elem.target).closest('li').addClass('slds-is-active');
            var targetId = $copado(elem.target).attr('aria-controls');
            $copado('div.slds-show').removeClass('slds-show').addClass('slds-hide');
            $copado(`#${targetId}`).removeClass('slds-hide').addClass('slds-show');
        }
    }

    app.clickDatatableHandler = () => {

        var tableId = dataTableId;
        var rows, activePaginationSelected, table;
        var info = {};
        var currentPage = 0;

        if (tableId) {
            activePaginationSelected = $copado(`#${tableId}_length`).find('select').val(); // get the pagination row count
            table = $copado(`#${tableId}`).DataTable();

            // get page number
            $copado(`#${tableId}`).on('page.dt', () => {
                info = table.page.info();
                currentPage = info.page;
            });

            // show all rows
            $copado(`#${tableId}_length`).find('select').val(-1).trigger('change');
            rows = $copado(`#${tableId}`).find('tr');

            // click event
            rows.click((event) => {
                checkDataTableRow(event.currentTarget, tableId, rows, currentPage);
            });

            // return the pagination to first situation
            $copado(`#${tableId}_length`).find('select').val(activePaginationSelected).trigger('change');

            $copado(`#${tableId}`).removeClass('slds-hidden');

        }
    };

    app.resizeHandler = () => {

        $copado(window).resize(() => {
            app.getTooltipPosition();
        });
    };

    app.startDataTables = () => {

        var tablesList = ['orgTable', 'gitTable', 'targetTable', 'dataTemplateTable'];
        var isTableFound = tablesList.find((table) => {
            return table === dataTableId;
        });

        if (isTableFound && $copado(`#${dataTableId}`).dataTable) {
            $copado(`#${dataTableId}`).dataTable({
                'language': {
                    search: '',
                    searchPlaceholder: "Search..."
                },
                'paging': true,
                'scrollCollapse': true,
                'ordering': true,
                columnDefs: [{
                    orderable: false,
                    targets: "no-sort"
                }],
                'lengthMenu': [
                    [5, 10, 25, 50, -1],
                    [5, 10, 25, 50, 'All']
                ],
                'fnPreDrawCallback': () => {
                    $copado('#progress').show();
                },
                'fnInitComplete': () => {
                    $copado(`#${dataTableId}`).show();
                    $copado(`#${dataTableId}`).find('th').first().removeClass('sorting_asc');
                    $copado('#progress').hide();
                },
                'dom': '<"top"f>rt<"bottom"ilp><"clear">'
            });
        }

    };

    app.renderSVG = (elemId) => {
        var elem = $copado(elemId);
        var struct = svgStruct[elemId];
        var imageURL, SVG, SVGUse;

        if (struct) {
            imageURL = struct.imageURL;
            SVG = $copado('<svg/>', {
                class: struct.class,
            });
            SVGUse = $copado('<use/>');

            SVGUse.attr('xlink:href', imageURL);
            elem.prepend(SVG.append(SVGUse));
            elem.html(elem.html());
        }
    };

    app.applyRenderSVG = () => {
        if (iconsList) {
            iconsList.forEach((element) => {
                app.renderSVG('.' + element.svgButtonsClass);
            });
        }
    };

    app.setSVGStruct = () => {
        var className;

        if (globalSldsResourcePath) {

            iconsList.forEach((item) => {
                className = item.styleClass ? `slds-button__icon ${item.styleClass}` : 'slds-button__icon';
                svgStruct['.' + item.svgButtonsClass] = {
                    imageURL: `${globalSldsResourcePath}/icons/utility-sprite/svg/symbols.svg#${item.name}`,
                    class: className
                };
            });
        }
    };

    /* JQX datatable modals */
    app.checkIfRefreshCacheCompleted = (modalId) => {
        dw.closeModals(modalId);
    };

    app.createStep = (justSaveAndClose) => {
        getMetadataGridConfig();
        app.conf.jsonData.selectedMetadata = app.grid.selectedMetadata;
        var noMetadataSelected = !app.conf.jsonData.selectedMetadata || !app.conf.jsonData.selectedMetadata.length;
        // if no metadata is selected and just save and close button is clicked no need to show a warning. In this case no need to create a steps.
        if (noMetadataSelected && !justSaveAndClose) {
            alert('You need to select at least one item to commit');
            return unlockScreen();
        }
        // if there is no metadata selected and clicked on save and close button, call the action function to save and close deployment.
        if (noMetadataSelected && justSaveAndClose) {
            saveAndClose();
        }

        if (!noMetadataSelected && (justSaveAndClose || !justSaveAndClose)) {
            var core = app.conf.ns ? window[app.conf.ns.split('__')[0]] : window;
            (core).DW_SelectChangesExtension.insertStep(
                app.conf.data.deploymentId,
                function(result, event) {
                    if (result && event.status) {
                        app.redirectToOperation(result, justSaveAndClose);
                    }
                }
            );
        }
    };

    app.redirectToOperation = (stepId, justSaveAndClose, sel) => {
        getMetadataGridConfig();
        app.conf.data.stepId = stepId || null;
        // get selected
        coGridHelper.datasource = app.grid.datasource;
        sel = sel || coGridHelper.getSelectedObj();

        // Attachment Name
        var attachmentName = app.conf.attachmentName || 'MetaData';
        app.conf.data.stepId && coGridHelper.saveSelected(app.conf.data.stepId, attachmentName, null, true, function() {
            if (!justSaveAndClose) {
                goToNextPage();
            } else {
                saveAndClose();
            }
            return;
        }, sel);
    };

    // Errors grid
    app.errorGridsource = {
        localdata: [],
        datafields: [{
            name: 'l',
            type: 'string'
        }, {
            name: 'm',
            type: 'string'
        }, {
            name: 't',
            type: 'string'
        }],
        datatype: "array"
    };

    // Data template summary grid
    app.dataTemplateSummaryGridSource = {
        localdata: [],
        datafields: [{
            name: 'totalRecords',
            type: 'integer'
        }, {
            name: 'deployedRecords',
            type: 'integer'
        }, {
            name: 'failedRecords',
            type: 'integer'
        }, {
            name: 'objectName',
            type: 'string'
        }, {
            name: 'templateId',
            type: 'string'
        }, {
            name: 'templateName',
            type: 'string'
        }, {
            name: 'attachmentSize',
            type: 'integer'
        }],
        datatype: "array"
    };

    app.prepareErrorGrid = (jobId) => {
        var result = sforce.connection.query("SELECT Id, Body, BodyLength, ContentType, Name, ParentId FROM Attachment WHERE Name = '" + jobId + ".json' ORDER BY CreatedDate DESC LIMIT 1", {
            onSuccess: (res) => {
                // adapter wrapper
                if (res.records) {
                    res = Base64.decode(res.records.Body);
                    res = $copado.parseJSON(res);

                    var dataTemplateSummary = false;
                    if (res[0] && res[0].m && (res[0].m.templateId || res[0].m.exception)) {
                        if (!res[0].m.exception) {
                            var newResultArray = [];
                            res.forEach(function(element) {
                                var newResult = {
                                    'deployedRecords': element.m.deployedRecords,
                                    'failedRecords': element.m.failedRecords,
                                    'objectName': element.m.objectName,
                                    'templateId': element.m.templateId,
                                    'templateName': element.m.templateName,
                                    'attachmentSize': element.m.attachmentSize,
                                };
                                newResultArray.push(newResult);
                            });
                            app.dataTemplateSummaryGridSource.localdata = newResultArray;
                            dataTemplateSummary = true;
                        } else {
                            var newResult = [{
                                'l': res[0].l,
                                'm': res[0].m.exception,
                                't': res[0].t
                            }];
                            app.errorGridsource.localdata = newResult;
                        }
                    } else {
                        app.errorGridsource.localdata = res;
                    }
                    var errorDataAdapter = dataTemplateSummary ? new $copado.jqx.dataAdapter(app.dataTemplateSummaryGridSource) : new $copado.jqx.dataAdapter(app.errorGridsource);
                    var errorContainer = $copado('#stepResult');
                    // keep jquery pointer for performance query
                    var errorGrid2 = $copado('<div>');
                    errorContainer.append(errorGrid2);

                    errorGrid2.jqxGrid({
                        width: '100%',
                        source: errorDataAdapter,
                        showfilterrow: true,
                        filterable: true,
                        theme: 'base',
                        editable: false,
                        scrollmode: 'logical',
                        selectionmode: 'none',
                        enablebrowserselection: true,
                        pageable: true,
                        pagesizeoptions: ['5', '20', '50', '100', '200', '500', '1000', '2000', '5000'],
                        pagesize: 5,
                        sortable: true,
                        columnsresize: true,
                        autorowheight: true,
                        autoheight: true,
                        altrows: true,
                        columns: dataTemplateSummary ? app.getDataTemplateSummaryColumns() : app.getErrorColumns()
                    });

                    $copado('#tab-default-2__item').data('open', true);
                    $copado('#tab-default-2__item').attr('title', '');
                    $copado('#tab-default-2__item').removeClass('disabled-tab');
                    $copado('#tab-default-2__item').addClass('enabled-tab');
                }
            },
            onFailure: (res) => {
                console.error(res);
            }
        });
    };

    app.getErrorColumns = () => {
        var preRender = (row, column, value) => {
            return '<span class="co-preCell">' + value + '</span>';
        };

        return [{
            text: 'Level',
            columntype: 'textbox',
            filtertype: 'input',
            datafield: 'l',
            width: '7%'
        }, {
            text: 'Message',
            filtertype: 'input',
            datafield: 'm',
            cellsrenderer: preRender,
            width: '73%'
        }, {
            text: 'Copado Tip',
            datafield: 't',
            filtertype: 'input',
            columntype: 'textbox',
            cellsrenderer: preRender,
            width: '20%'
        }];
    };

    app.getDataTemplateSummaryColumns = () => {
        return [{
            text: 'Object Name',
            columntype: 'textbox',
            filtertype: 'input',
            datafield: 'objectName',
            width: '25%'
        }, {
            text: 'Template Id',
            filtertype: 'input',
            columntype: 'textbox',
            datafield: 'templateId',
            hidden: true
        }, {
            text: 'Template Name',
            filtertype: 'input',
            columntype: 'textbox',
            datafield: 'templateName',
            width: '25%',
        }, {
            text: 'Total Record Count',
            datafield: 'totalRecords',
            filtertype: 'input',
            columntype: 'textbox',
            width: '10%',
            cellsrenderer: sumSuccessAndFailRecords
        }, {
            text: 'Success Record Count',
            datafield: 'deployedRecords',
            filtertype: 'input',
            columntype: 'textbox',
            width: '10%'
        }, {
            text: 'Failed Record Count',
            datafield: 'failedRecords',
            filtertype: 'input',
            columntype: 'textbox',
            width: '10%'
        }, {
            text: 'Attachments (mb)',
            datafield: 'attachmentSize',
            filtertype: 'input',
            columntype: 'textbox',
            width: '10%'
        }, {
            text: 'Actions',
            datafield: 'viewResult',
            columntype: 'textbox',
            width: '10%',
            cellsrenderer: viewResultLink
        }];
    };

    var viewResultLink = (row, column, value, defaultHtml) => {
        var templateId = $copado('.jqx-grid').jqxGrid('getCell', row, 'templateId').value;
        var templateName = $copado('.jqx-grid').jqxGrid('getCell', row, 'templateName').value;
        var element = $copado(defaultHtml);
        var resultPageUrl = '/apex/' + namespace + 'DataTemplateObjectResult?templateId=' + templateId + '&templateName=' + templateName + '&deploymentId=' + dId + '&stepId=' + stepId;
        element.html('<a href="#" onClick="window.open(\'' + resultPageUrl + '\');">View Results</a>');
        return element[0].outerHTML;
    };

    var sumSuccessAndFailRecords = (row, column, value, defaultHtml) => {
        value = $copado('.jqx-grid').jqxGrid('getCell', row, 'deployedRecords').value + $copado('.jqx-grid').jqxGrid('getCell', row, 'failedRecords').value;
        var element = $copado(defaultHtml);
        element.html(value);
        return element[0].outerHTML;
    };

    app.openModals = (param) => {
        $copado('[id=notificationModal' + param + ']').show();
        $copado('[id=backDrop' + param + ']').show();
    };

    app.closeModals = (param) => {
        $copado('[id=notificationModal' + param + ']').hide();
        $copado('[id=backDrop' + param + ']').hide();
    };

    app.checkError = () => {
        if ($copado('.slds-theme_warning').length > 0) {
            window.scrollTo(0, 0);
        }
        unlockScreen();
    }

    app.checkDisable = (isSource) => {
        var flag = false;
        if (isSource) {
            if (deploymentId.length == 0) {
                $copado('input.disabled').prop('disabled', true);
            } else {
                $copado('input.disabled').removeClass('disabled');
            }
        } else {
            flag = false;
            $copado('input[type="checkbox"]').each(function() {
                if ($copado(this).prop('checked') == true) {
                    flag = true;
                    $copado('input.disabled').removeClass('disabled');
                }
            });
            if (!flag) {
                $copado('input.disabled').prop('disabled', true);
            }
        }
    }

    var getMetadataGridConfig = () => {
        app.conf = jqx.conf;
        app.grid = jqx.grid;
    };

    $(document).ready(() => {
        if (selectedSourceType) {
            app.setDataTableId(selectedSourceType);
        }
        app.setSVGStruct();
        app.applyRenderSVG();
        app.startDataTables();
        app.resizeHandler();
        app.clickDatatableHandler();
        app.getTooltipPosition();
    });

})(dw);