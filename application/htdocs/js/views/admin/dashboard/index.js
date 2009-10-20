Ext.onReady(function() {
	var dashboardIntro = new Ext.Panel({
		title: 'Intro',
		applyTo: 'dashboardIntro',
		collapsible: true
	});
	
	var dashboardFirstSteps = new Ext.Panel({
		title: 'First steps',
		applyTo: 'dashboardFirstSteps',
		collapsible: true
	});
	
	var shortcutsStore = new Ext.data.JsonStore({
		url: '/admin/shortcut/list-data',
		fields: [
			{ name: 'id' },
			{ name: 'name' },
			{ name: 'link' }
		]
	});
	
	shortcutsStore.load();
		
	shortcutsStore.on('load', function() {			
		var dashboardShortcuts = new Ext.Panel({
			title: 'Shortcuts',
			bodyStyle: 'padding-left: 10px; padding-top: 10px;',
			renderTo: 'dashboardShortcuts',
			collapsible: true,
			tbar: [{
				text: 'Add shortcut',
				handler: function() {
					Owp.Layouts.Admin.addShortcut(true);
				},
				cls: 'x-btn-text-icon addShortcut'
			}, {
				text: 'Delete shortcut',
				handler: deleteShortcut,
				disabled: (0 == shortcutsStore.getCount()),
				cls: 'x-btn-text-icon deleteShortcut'
			}]
		});
				
		shortcutsStore.each(function(shortcut) {
			var shortcutButton = new Ext.Button({
				text: shortcut.data.name,
				cls: 'shortcutButton',
				minWidth: 200,
				handler: function() {
					document.location.href = shortcut.data.link;
				}
			});
			
			dashboardShortcuts.add(shortcutButton);
		});
		
		dashboardShortcuts.doLayout();
	});
	
	var windowDeleteShortcut;
	
	deleteShortcut = function() {
		var currentLocation = window.location.pathname;
		
		if (!windowDeleteShortcut) {
			var formDeleteShortcut = new Ext.form.FormPanel({
				baseCls: 'x-plain',
				labelWidth: 100,
				url: '/admin/shortcut/delete',
				waitMsgTarget: true,
				
				items: [{
					fieldLabel: 'Shortcut',
					name: 'id',
					hiddenName: 'id',
					valueField: 'id',
					displayField: 'name',
					xtype: 'combo',
					allowBlank: false,
					anchor: '100%',
					mode: 'local',
					editable: false,
					forceSelection: true,
					triggerAction: 'all',
					emptyText: 'Select shortcut',
					store: shortcutsStore
				}]
			});
			
			windowDeleteShortcut = new Ext.Window({
				title: 'Delete shortcut',
				width: 400,
				height: 105,
				modal: true,
				layout: 'fit',
				plain: true,
				bodyStyle: 'padding: 5px;',
				resizable: false,
				items: formDeleteShortcut,
				closeAction: 'hide',
				
				buttons: [{
					text: 'Delete',
					handler: function() {
						formDeleteShortcut.form.submit({
							waitMsg: 'Loading...',
							success: function() {
								windowDeleteShortcut.hide();
								document.location.reload();
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
						windowDeleteShortcut.hide();
					}
				}]
			});
								
			windowDeleteShortcut.on('show', function() {
				formDeleteShortcut.getForm().reset();
			});
		}
		
		windowDeleteShortcut.show();
	}
});