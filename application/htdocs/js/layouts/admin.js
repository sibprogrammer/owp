Owp.Layouts.Admin.onLogoutLinkClick = function() {
    Ext.MessageBox.confirm('Confirm', 'Are you sure you want to log out?', function(button, text) {
        if ('yes' == button) {
            window.location.href = '/auth/logout';
        }
    });
}

Owp.Layouts.Admin.windowMyProfile = null;

Owp.Layouts.Admin.onMyProfileClick = function() {
    if (!Owp.Layouts.Admin.windowMyProfile) {
        var formMyProfile = new Ext.form.FormPanel({
            baseCls: 'x-plain',
            labelWidth: 100,
            url: '/admin/my-profile/save',
            defaultType: 'textfield',
            waitMsgTarget: true,
            
            items: [{
                fieldLabel: 'User Name',
                name: 'userName',
                value: Owp.Layouts.Admin.loggedUser,
                readOnly: true,
                anchor: '100%'
            }, {
                fieldLabel: 'Current Password',
                name: 'currentPassword',
                inputType: 'password',
                allowBlank: false,
                anchor: '100%'
            }, {
                fieldLabel: 'New Password',
                name: 'newPassword',
                inputType: 'password',
                allowBlank: false,
                anchor: '100%'
            }, {
                fieldLabel: 'Confirm Password',
                name: 'confirmPassword',
                inputType: 'password',
                allowBlank: false,
                anchor: '100%'
            }]
        });
        
        Owp.Layouts.Admin.windowMyProfile = new Ext.Window({
            title: 'My profile',
            width: 400,
            height: 180,
            modal: true,
            layout: 'fit',
            plain: true,
            bodyStyle: 'padding: 5px;',
            resizable: false,
            items: formMyProfile,
            closeAction: 'hide',
            
            buttons: [{
                text: 'Save',
                handler: function() {
                    formMyProfile.form.submit({
                        waitMsg: 'Loading...',
                        success: function() {
                            Owp.Layouts.Admin.windowMyProfile.hide();
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
                    Owp.Layouts.Admin.windowMyProfile.hide();
                }
            }]
        });
        
        Owp.Layouts.Admin.windowMyProfile.on('show', function() {
            formMyProfile.getForm().reset();
        });
    }
    
    Owp.Layouts.Admin.windowMyProfile.show();
}

Owp.Layouts.Admin.windowAddShortcut = null;

Owp.Layouts.Admin.addShortcut = function(reloadNeeded) {
    var currentLocation = window.location.pathname;
    
    if (!Owp.Layouts.Admin.windowAddShortcut) {
        var formAddShortcut = new Ext.form.FormPanel({
            baseCls: 'x-plain',
            labelWidth: 100,
            url: '/admin/shortcut/add',
            defaultType: 'textfield',
            waitMsgTarget: true,
            
            items: [{
                fieldLabel: 'Title',
                name: 'name',
                value: Owp.Layouts.Admin.pageTitle,
                allowBlank: false,
                anchor: '100%'
            }, {
                fieldLabel: 'Link',
                name: 'link',
                value: currentLocation,
                allowBlank: false,
                anchor: '100%'
            }]
        });
        
        Owp.Layouts.Admin.windowAddShortcut = new Ext.Window({
            title: 'Add shortcut to page',
            width: 400,
            height: 130,
            modal: true,
            layout: 'fit',
            plain: true,
            bodyStyle: 'padding:5px;',
            resizable: false,
            items: formAddShortcut,
            closeAction: 'hide',
            
            buttons: [{
                text: 'Add',
                handler: function() {
                    formAddShortcut.form.submit({
                        waitMsg: 'Loading...',
                        success: function() {
                            Owp.Layouts.Admin.windowAddShortcut.hide();
                            
                            if (true == reloadNeeded) {
                                document.location.reload();
                            }
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
                    Owp.Layouts.Admin.windowAddShortcut.hide();
                }
            }]
        });
                            
        Owp.Layouts.Admin.windowAddShortcut.on('show', function() {
            formAddShortcut.getForm().reset();
        });
    }
    
    Owp.Layouts.Admin.windowAddShortcut.show();
}

Ext.onReady(function(event) {    
        
    var topBar = [{
        text: 'Shortcut',
        handler: Owp.Layouts.Admin.addShortcut,
        cls: 'x-btn-text-icon addShortcut'
    }];
    
    if ('' != Owp.Layouts.Admin.upLevelLink) {
        topBar.push({
            text: 'Up Level',
            handler: function() {
                document.location.href = Owp.Layouts.Admin.upLevelLink;
            },
            cls: 'x-btn-text-icon upLevelLink'
        });
    }
    
    var layout = new Ext.Viewport({
        layout:'border',
        items: [
            new Ext.BoxComponent({
                region: 'north',
                el: 'panelHeader',
                cls: 'x-panel-header',
                height: 50
            }), {
                region: 'west',
                title: 'Menu',
                contentEl: 'panelMenu',
                split:true,
                width: 250,
                minSize: 200,
                maxSize: 400,
                collapsible: true,
                margins: '5 0 5 5',
                layout: 'accordion',
                layoutConfig: { animate: true },                
                xtype: 'treepanel',
                loader: new Ext.tree.TreeLoader(),
                rootVisible: false,
                lines: false,
                root: Owp.Layouts.Admin.getMainMenu()
            }, {
                region: 'center',
                margins: '5 5 5 0',
                contentEl: 'panelContent',
                xtype: 'panel',
                autoScroll: true,
                title: Owp.Layouts.Admin.pageTitle,
                id: 'rightPanelHeader',
                tbar: topBar,
                bodyStyle: 'background: #FFFFFF url(/skins/win_xp/images/openvz-big-logo.gif) no-repeat scroll right bottom'
            }
        ]
    });
    
});
