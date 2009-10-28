Ext.onReady(function(event) {
    
    var errorWindow = new Ext.Window({
        applyTo: 'errorWindow',
        width: 650,
        y: 150,
        autoHeight: true,
        iconCls: 'errorWindowIcon',
        closable: false,
        resizable: false,
        draggable: false
    });
    
    errorWindow.show();
});