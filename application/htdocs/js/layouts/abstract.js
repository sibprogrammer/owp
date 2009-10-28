Ext.BLANK_IMAGE_URL = '/ext/resources/images/default/s.gif';

Owp.Layouts.Abstract.onCopyrightClick = function() {
    Ext.MessageBox.show({
        title: 'About program',
        icon: Ext.MessageBox.INFO,
        buttons: Ext.Msg.OK,
        animEl: 'layoutCopyrightInner',
        msg: 'Author: <a href="mailto:alex@softunity.com.ru">Alexei Yuzhakov</a><br/>' +
            'Web site: <a href="http://code.google.com/p/ovz-web-panel/" target="_blank">' +
                'http://code.google.com/p/ovz-web-panel/</a><br/><br/>' +
            '&copy; Copyright 2008 SoftUnity.<br/>All Rights Reserved.'
    });
}

Ext.onReady(function() {
    Ext.state.Manager.setProvider(new Ext.state.CookieProvider());
});
