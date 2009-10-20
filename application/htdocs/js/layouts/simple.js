Ext.onReady(function(event) {
	
	var layout = new Ext.Viewport({
		layout:'border',
		items:[
			new Ext.BoxComponent({
				region: 'north',
				el: 'panelHeader',
				cls: 'x-panel-header',
				height: 50
			}), {
				region: 'center',
				contentEl: 'panelContent',
				bodyStyle: 'background: #3D71B8 url(/skins/win_xp/images/desktop.jpg) no-repeat scroll left top'
			}
		]
	});
	
});
