Ext.BLANK_IMAGE_URL = '/images/blank.gif';
Ext.state.Manager.setProvider(new Ext.state.CookieProvider());
Ext.QuickTips.init();
Ext.form.Field.prototype.msgTarget = 'side';
Ext.Ajax.timeout = 5 * 60 * 1000;
Ext.form.BasicForm.prototype.timeout = 5 * 60;

Ext.ns('Owp.form');

Owp.form.errorHandler = function(form, action, params) {
  if ('client' == action.failureType) {
    return
  }
  
  if ('undefined' == typeof action.result) {
    Ext.MessageBox.show({
      msg: 'Internal error occured. See logs for details.',
      buttons: Ext.MessageBox.OK,
      icon: Ext.MessageBox.ERROR
    });
    
    return
  }
  
  var params = ('undefined' == typeof params) ? Array() : params;
  var handler = params['fn'] || function() {};
  
  // show overall status message
  if ('undefined' != typeof action.result.message) {
    Ext.MessageBox.show({
      msg: action.result.message,
      buttons: Ext.MessageBox.OK,
      icon: Ext.MessageBox.ERROR,
      fn: handler
    });
    
    return
  }
  
  // highlight fields with errors
  var errorsHash = new Array();  
  
  Ext.each(action.result.form_errors, function(message) {
    messageField = message[0];
    messageContent = message[1];
    
    errorsHash[messageField] = (errorsHash[messageField])
      ? errorsHash[messageField] + '<br/>' + messageContent
      : messageContent;
  });
    
  Ext.each(form.items.items, function(field) {    
    if (('undefined' != field.name) && ('undefined' != typeof errorsHash[field.name])) {
      field.markInvalid(errorsHash[field.name])
    }
  });
}

Owp.form.BasicForm = Ext.extend(Ext.FormPanel, {
  baseCls: 'x-plain',
  defaultType: 'textfield'
});

Owp.form.BasicFormWindow = Ext.extend(Ext.Window, {
  findFirst: function(item) {
    if (item instanceof Ext.form.Field && !(item instanceof Ext.form.DisplayField)
      && (item.inputType != 'hidden') && !item.disabled
    ) {
      item.focus(false, 50); // delayed focus by 50 ms
      return true;
    }
    
    if (item.items && item.items.find) {
      return item.items.find(this.findFirst, this);
    }
    
    return false;
  },
  
  focus: function() {
    this.items.find(this.findFirst, this);
  }
});

Ext.ns('Owp.button');

Owp.button.action = function(config) {
  config = Ext.apply({
    gridName: '',
    url: '',
    command: '',
    waitMsg: '',
    failure: {
      title: '',
      msg: ''
    }
  }, config);
  
  var progressBar = Ext.Msg.wait(config.waitMsg);
  
  Ext.Ajax.request({
    url: config.url,
    success: function(response) {
      progressBar.hide();
         
      var result = Ext.util.JSON.decode(response.responseText);
      
      if (!result.success) {
        Ext.MessageBox.show({
          title: config.failure.title,
          msg: config.failure.msg,
          buttons: Ext.Msg.OK,
          icon: Ext.MessageBox.ERROR
        });
      } else {
        if (config.gridName) {
          var grid = Ext.getCmp(config.gridName);
          grid.store.reload();
          grid.getSelectionModel().clearSelections();
        }
      }      
    },
    failure: function() {
      Ext.MessageBox.show({
        title: config.failure.title,
        msg: 'Internal error occured. See logs for details.',
        buttons: Ext.Msg.OK,
        icon: Ext.MessageBox.ERROR
      });
    },
    params: {
      command: config.command
    },
    scope: this
  });
}

Ext.ns('Owp.list');

Owp.list.getSelectedIds = function(gridName) {
  var selectedItems = Ext.getCmp(gridName).getSelectionModel().getSelections();
    
  var selectedIds = [];    
  Ext.each(selectedItems, function(item) {    
    selectedIds.push(item.data.id);
  });
  
  return selectedIds;
}

Owp.list.groupAction = function(config) {
  config = Ext.apply({
    gridName: '',
    url: '',
    command: '',
    waitMsg: '',
    failure: {
      title: '',
      msg: ''
    }
  }, config);

  var progressBar = Ext.Msg.wait(config.waitMsg);
  
  Ext.Ajax.request({
    url: config.url,
    success: function(response) {
      progressBar.hide();
         
      var result = Ext.util.JSON.decode(response.responseText);
      
      if (!result.success) {
        Ext.MessageBox.show({
          title: config.failure.title,
          msg: config.failure.msg,
          buttons: Ext.Msg.OK,
          icon: Ext.MessageBox.ERROR
        });
      } else {
        var grid = Ext.getCmp(config.gridName);
        grid.store.reload();
        grid.getSelectionModel().clearSelections();
      }      
    },
    failure: function() {
      Ext.MessageBox.show({
        title: config.failure.title,
        msg: 'Internal error occured. See logs for details.',
        buttons: Ext.Msg.OK,
        icon: Ext.MessageBox.ERROR
      });
    },
    params: { 
      ids: [Owp.list.getSelectedIds(config.gridName)],
      command: config.command
    },
    scope: this
  });
}

Ext.ns('Owp.layout');

Owp.layout.addToCenter = function(item) {
  var centerPanel = Ext.getCmp('mainContentCenterPanel');
  centerPanel.add(item);
  centerPanel.doLayout();
}

Owp.Panel = Ext.extend(Ext.Panel, {
  stateEvents: ['collapse', 'expand'],
  
  getState: function() {
    return {
      collapsed: this.collapsed
    };
  }
});

Ext.ns('Owp.grid');

Owp.grid.GridPanel = Ext.extend(Ext.grid.GridPanel, {
  stateEvents: ['collapse', 'expand'],
  
  getState: function() {
    var state = Owp.grid.GridPanel.superclass.getState.call(this);
    return Ext.apply(state, {
      collapsed: this.collapsed
    });
  }
});

Ext.ns('Owp.statusUpdater');

Owp.statusUpdater = {
  task: {
    run: function() {
      Ext.Ajax.request({
        url: '/admin/tasks/status',
        success: function(response) {
          var result = Ext.util.JSON.decode(response.responseText);
          var statusbar = Ext.get('statusbar');
          if (result.message) {
            statusbar.update('<img src="/images/spinner.gif" class="icon-inline"> ' + result.message);
          } else {
            statusbar.update('');
            Ext.TaskMgr.stop(Owp.statusUpdater.task);
          }
        }
      });
    },
    interval: 5000
  },
  
  start: function() {
    Ext.TaskMgr.start(Owp.statusUpdater.task);
  }
}
