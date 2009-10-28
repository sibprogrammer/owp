Ext.onReady(function(event) {

    var loginFormSubmitAction = function() {
        loginForm.getForm().submit({
            waitMsg: 'Loading...',
            success: function() {
                document.location.href = '/admin/dashboard';
            },
            failure: function(form, action) {
                var resultMessage = ('client' == action.failureType)
                    ? 'Please, fill the form.'
                    : action.result.errors.message;
                
                Ext.MessageBox.show({
                    title: 'Error',
                    msg: resultMessage,
                    buttons: Ext.MessageBox.OK,
                    icon: Ext.MessageBox.ERROR,
                    fn: function() {
                        Ext.get('userName').focus();
                    }
                });
            }
        });
    }
    
    var loginForm = new Ext.FormPanel({
        labelWidth: 75,
        baseCls: 'x-plain',
        url: '/login',
        bodyStyle: 'padding:15px 15px 0',
        width: 350,
        defaults: { width: 230 },
        defaultType: 'textfield',
        waitMsgTarget: true,
        
        keys: [{
            key: Ext.EventObject.ENTER,
            fn: loginFormSubmitAction
        }],
            
        items: [{
                fieldLabel: 'User name',
                name: 'userName',
                id: 'userName',
                allowBlank: false
            },{
                fieldLabel: 'Password',
                name: 'userPassword',
                inputType: 'password',
                allowBlank: false
            }
        ],

        buttons: [{
            text: 'Log in',
            type: 'submit',
            handler: loginFormSubmitAction
        }]
    });
    
    var loginWindow = new Ext.Window({
        applyTo: 'loginWindow',
        width: 350,
        height: 145,
        y: 150,
        closable: false,
        resizable: false,
        draggable: false,
        items: loginForm
    });
    
    loginWindow.show();
});

Ext.EventManager.on(window, 'load', function() {
    Ext.get('userName').focus();
});