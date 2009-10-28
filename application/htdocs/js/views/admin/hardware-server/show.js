Owp.Views.Admin.HardwareServer.Show.windowChangeVirtualServerState = null;
Owp.Views.Admin.HardwareServer.Show.gridVirtualServers = null;

Owp.Views.Admin.HardwareServer.Show.changeVirtualServerStateRequest = function(veKeyId, command) {
    Ext.Ajax.request({
        url: '/admin/virtual-server/' + command + '/id/' + veKeyId,
        success: function(response) {
            var result = Ext.util.JSON.decode(response.responseText);
            
            if (!result.success) {
                Ext.MessageBox.show({
                    title: 'Error',
                    msg: 'Change virtual server state request failed.',
                    buttons: Ext.Msg.OK,
                    icon: Ext.MessageBox.ERROR
                });
            
                return ;
            }
            
            Owp.Views.Admin.HardwareServer.Show.gridVirtualServers.store.reload();
            Owp.Views.Admin.HardwareServer.Show.windowChangeVirtualServerState.close();
        }
    });
}

Owp.Views.Admin.HardwareServer.Show.changeVirtualServerState = function(veKeyId, veId) {
    Owp.Views.Admin.HardwareServer.Show.windowChangeVirtualServerState = new Ext.Window({
        title: 'Virtual server #' + veId,
        modal: true,
        plain: true,
        resizable: false,
        bodyStyle: 'padding:5px;',
        html: 'You can change virtual server #' + veId + ' state.',
        
        buttons: [{
            text: 'Start',
            handler: function() {
                Owp.Views.Admin.HardwareServer.Show.changeVirtualServerStateRequest(veKeyId, 'start');
            }
        }, {
            text: 'Stop',
            handler: function() {
                Owp.Views.Admin.HardwareServer.Show.changeVirtualServerStateRequest(veKeyId, 'stop');
            }
        }, {
            text: 'Restart',
            handler: function() {
                Owp.Views.Admin.HardwareServer.Show.changeVirtualServerStateRequest(veKeyId, 'restart');
            }
        }]
    });
    
    Owp.Views.Admin.HardwareServer.Show.windowChangeVirtualServerState.show();
}

Ext.onReady(function(){

    var osTemapltesStore = new Ext.data.JsonStore({
        url: '/admin/os-template/list-data/hw-server-id/' + Owp.Views.Admin.HardwareServer.Show.hwServerId,
        fields: [
            { name: 'id' },
            { name: 'name' }
        ]
    });
    
    osTemapltesStore.load();
    
    function columnVeStateRenderer(veState, metadata, record) {
        var stateImage;
        
        if (1 == veState) {
            stateImage = 'on.gif';
        } else {
            stateImage = 'off.gif';
        }
        
        return '<a href="#" onclick="Owp.Views.Admin.HardwareServer.Show.changeVirtualServerState(' + 
            record.data.id + ', ' + record.data.veId + ');"><img border="0" src="/skins/win_xp/images/' + stateImage + '"/></a>';
    }
    
    var windowAddVirtualServer;
    
    function addVirtualServer() {
        if (!windowAddVirtualServer) {
            var formAddVirtualServer = new Ext.form.FormPanel({
                baseCls: 'x-plain',
                labelWidth: 100,
                url: '/admin/virtual-server/add/hw-server-id/' + Owp.Views.Admin.HardwareServer.Show.hwServerId,
                defaultType: 'textfield',
                waitMsgTarget: true,
                
                items: [{
                    fieldLabel: 'VE ID',
                    name: 'veId',
                    allowBlank: false,
                    anchor: '100%'
                }, {
                    fieldLabel: 'IP Address',
                    name: 'ipAddress',
                    anchor: '100%'
                }, {
                    fieldLabel: 'Host Name',
                    name: 'hostName',
                    anchor: '100%'
                }, {
                    fieldLabel: 'OS Template',
                    xtype: 'combo',
                    hiddenName: 'osTemplateId',
                    valueField: 'id',
                    displayField: 'name',
                    name: 'osTemplateId',
                    forceSelection: true,
                    triggerAction: 'all',
                    emptyText: 'Select OS template',
                    mode: 'local',
                    allowBlank: false,
                    editable: false,
                    store: osTemapltesStore,
                    anchor: '100%'
                }]
            });
            
            windowAddVirtualServer = new Ext.Window({
                title: 'Create new virtual server',
                width: 400,
                height: 180,
                modal: true,
                layout: 'fit',
                plain: true,
                bodyStyle: 'padding: 5px;',
                resizable: false,
                items: formAddVirtualServer,
                closeAction: 'hide',
                
                buttons: [{
                    text: 'Create',
                    handler: function() {
                        formAddVirtualServer.form.submit({
                            waitMsg: 'Loading...',
                            success: function() {
                                Owp.Views.Admin.HardwareServer.Show.gridVirtualServers.store.reload();
                                windowAddVirtualServer.hide();
                            },
                            failure: function(form, action) {
                                var resultMessage = ('client' == action.failureType)
                                    ? 'Please, fill the form.'
                                    : action.result.errors.message;
                                
                                Ext.MessageBox.show({
                                    title: 'Error',
                                    msg: resultMessage,
                                    buttons: Ext.MessageBox.OK,
                                    icon: Ext.MessageBox.ERROR
                                });
                            }
                        });
                    }
                },{
                    text: 'Cancel',
                    handler: function() {
                        windowAddVirtualServer.hide();
                    }
                }]
            });
            
            windowAddVirtualServer.on('show', function() {
                formAddVirtualServer.getForm().reset();
            });
        }
        
        windowAddVirtualServer.show();        
    }
            
    function removeVirtualServer() {
        var selectedItem = Ext.getCmp('virtualServersGrid').getSelectionModel().getSelected();
        
        if (!selectedItem) {
            Ext.MessageBox.show({
                title: 'Error',
                msg: 'Please select a virtual server.',
                buttons: Ext.Msg.OK,
                icon: Ext.MessageBox.ERROR
            });
            
            return ;
        }
        
        Ext.MessageBox.confirm('Confirm', 'Are you sure you want to remove virtual server with id <b>' + selectedItem.get('veId') + '</b>?', function(button, text) {
            if ('yes' == button) {                
                Ext.Ajax.request({
                    url: '/admin/virtual-server/delete',
                    success: function(response) {
                        var result = Ext.util.JSON.decode(response.responseText);
                        
                        if (!result.success) {
                            Ext.MessageBox.show({
                                title: 'Error',
                                msg: 'Server deletion request failed.',
                                buttons: Ext.Msg.OK,
                                icon: Ext.MessageBox.ERROR
                            });
                        
                            return ;
                        }
                        
                        Owp.Views.Admin.HardwareServer.Show.gridVirtualServers.store.reload();
                    },
                    params: { 
                        id: selectedItem.get('id')
                    }
                });
            }
        });
    }
    
    var store = new Ext.data.JsonStore({
        url: '/admin/virtual-server/list-data/hw-server-id/' + Owp.Views.Admin.HardwareServer.Show.hwServerId,
        fields: [
            { name: 'id' },
            { name: 'veId' },
            { name: 'ipAddress' },
            { name: 'hostName' },
            { name: 'veState' },
            { name: 'osTemplateName' }
        ]
    });

    store.load();
    
    var selectionModel = new Ext.grid.CheckboxSelectionModel({ singleSelect: true });

    Owp.Views.Admin.HardwareServer.Show.gridVirtualServers = new Ext.grid.GridPanel({
        id: 'virtualServersGrid',
        title: 'Virtual servers list',
        store: store,
        cm: new Ext.grid.ColumnModel([
            selectionModel, 
            { id: 'veState', header: "State", renderer: columnVeStateRenderer, width: 60, align: 'center', sortable: true, dataIndex: 'veState' },
            { id: 'veId', header: "Virtual Server ID", sortable: true, dataIndex: 'veId' },
            { id: 'ipAddress', header: "IP Address", sortable: true, dataIndex: 'ipAddress' },
            { id: 'hostName', header: "Host Name", sortable: true, dataIndex: 'hostName' },
            { id: 'osTemplateName', header: "OS Template", sortable: true, dataIndex: 'osTemplateName' }
        ]),
        sm: selectionModel,
        stripeRows: true,
        autoExpandColumn: 'osTemplateName',
        autoHeight: true,
        autoWidth: true,
        stripeRows: true,
        frame: true,
        tbar: [{
            text: 'Create virtual server',
            handler: addVirtualServer,
            cls: 'x-btn-text-icon addServer'
        }, {
            text: 'Remove virtual server',
            handler: removeVirtualServer,
            cls: 'x-btn-text-icon removeServer'
        }]
    });
    
    Owp.Views.Admin.HardwareServer.Show.gridVirtualServers.render('virtualServersList');
});
