Owp.Views.Default.Check.Env.renderCheckEnvWindow = function(phpExtensionsJsonData) {
	function columnStateRenderer(state) {
		return (state)
			? '<img src="/skins/win_xp/images/ok.png">'
			: '<img src="/skins/win_xp/images/off.gif">';
	}
	
	var store = new Ext.data.SimpleStore({
		fields: [
			{ name: 'state' },
			{ name: 'name' }
		]
	});
	
	store.loadData(phpExtensionsJsonData);
	
	var grid = new Ext.grid.GridPanel({
		store: store,
		cm: new Ext.grid.ColumnModel([
			{ id: 'state', header: "State", renderer: columnStateRenderer, width: 65,
				align: 'center', sortable: true, dataIndex: 'state' },
			{ id: 'name', header: "Extension name", sortable: true, dataIndex: 'name' }
		]),
		stripeRows: true,
		autoExpandColumn: 'name',
		autoHeight: true,
		autoWidth: true,
		stripeRows: true,
		frame: true,
		tbar: [{
			text: 'Go to login form',
			cls: 'x-btn-text-icon loginButton',
			handler: function() {
				window.location.href = '/login';
			}
		}]
	});
	
	grid.render('phpExtensionsGrid');
	
	var checkEnvWindow = new Ext.Window({
		applyTo: 'checkEnvWindow',
		width: 650,
		y: 150,
		autoHeight: true,
		closable: false,
		resizable: false,
		draggable: false
	});
	
	checkEnvWindow.show();
}