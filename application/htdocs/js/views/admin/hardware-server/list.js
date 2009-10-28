Ext.onReady(function(){
        
    function columnHostNameRenderer(hostName, metadata, record) {
        return "<a href='/admin/hardware-server/show/id/" + record.data.id + "'>" + hostName + "</a>";
    }

    var windowAddServer;
    
    function addHwServer() {
        if (!windowAddServer) {
            var formAddServer = new Ext.form.FormPanel({
                baseCls: 'x-plain',
                labelWidth: 100,
                url: '/admin/hardware-server/add',
                defaultType: 'textfield',
                waitMsgTarget: true,
                
                items: [{
                    fieldLabel: 'Host name',
                    name: 'hostName',
                    allowBlank: false,
                    anchor: '100%'
                }, {
                    fieldLabel: 'Auth key',
                    name: 'authKey',
                    allowBlank: false,
                    anchor: '100%'
                }, {
                    fieldLabel: 'Description',
                    name: 'description',
                    anchor: '100%'
                }]
            });
            
            windowAddServer = new Ext.Window({
                title: 'Connect new hardware server',
                width: 400,
                height: 155,
                modal: true,
                layout: 'fit',
                plain: true,
                bodyStyle: 'padding:5px;',
                resizable: false,
                items: formAddServer,
                closeAction: 'hide',
                
                buttons: [{
                    text:'Connect',
                    handler: function() {
                        formAddServer.form.submit({
                            waitMsg: 'Loading...',
                            success: function() {
                                gridHwServers.store.reload();
                                windowAddServer.hide();
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
                        windowAddServer.hide();
                    }
                }]
            });
            
            windowAddServer.on('show', function() {
                formAddServer.getForm().reset();
            });
        }
        
        windowAddServer.show();        
    }
    
    function removeHwServer() {
        var selectedItem = Ext.getCmp('hwServersGrid').getSelectionModel().getSelected();
        
        if (!selectedItem) {
            Ext.MessageBox.show({
                title: 'Error',
                msg: 'Please select a server.',
                buttons: Ext.Msg.OK,
                icon: Ext.MessageBox.ERROR
            });
            
            return ;
        }
        
        Ext.MessageBox.confirm('Confirm', 'Are you sure you want to disconnect server <b>' + selectedItem.get('hostName') + '</b>?', function(button, text) {
            if ('yes' == button) {                
                Ext.Ajax.request({
                    url: '/admin/hardware-server/delete',
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
                        
                        gridHwServers.store.reload();
                    },
                    params: { id: selectedItem.get('id') }
                });
            }
        });
    }
    
    var store = new Ext.data.JsonStore({
        url: '/admin/hardware-server/list-data',
        fields: [
           { name: 'id' },
           { name: 'hostName' },
           { name: 'description' }
        ]
    });
    
    store.load();
    
    var selectionModel = new Ext.grid.CheckboxSelectionModel({ singleSelect: true });
    
    var gridHwServers = new Ext.grid.GridPanel({
        id: 'hwServersGrid',
        title: 'Hardware servers list',
        store: store,
        cm: new Ext.grid.ColumnModel([
            selectionModel, 
            { id: 'hostName', header: "Host name", renderer: columnHostNameRenderer, sortable: true, dataIndex: 'hostName' },
            { id: 'description', header: "Description", sortable: true, dataIndex: 'description' }
        ]),
        sm: selectionModel,
        stripeRows: true,
        autoExpandColumn: 'description',
        autoHeight: true,
        autoWidth: true,
        stripeRows: true,
        frame: true,
        tbar: [{
            text: 'Connect new server',
            handler: addHwServer,
            cls: 'x-btn-text-icon addServer'
        }, {
            text: 'Disconnect server',
            handler: removeHwServer,
            cls: 'x-btn-text-icon removeServer'
        }]
    });
    
    gridHwServers.render('hwServersList');
});
