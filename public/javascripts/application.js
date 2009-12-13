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
  
  // show overall status message
  if ('undefined' != typeof action.result.message) {
    Ext.MessageBox.show({
      msg: action.result.message,
      buttons: Ext.MessageBox.OK,
      icon: Ext.MessageBox.ERROR,
      fn: params['fn']
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

Owp.form.BasicFormWindow = Ext.extend(Ext.Window, {
  findFirst: function(item) {
    if (item instanceof Ext.form.Field && !(item instanceof Ext.form.DisplayField)
      && !item.hidden && !item.disabled
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
  
  function showError() {
    Ext.MessageBox.show({
      title: config.failure.title,
      msg: config.failure.msg,
      buttons: Ext.Msg.OK,
      icon: Ext.MessageBox.ERROR
    });
  }  
  
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
        Ext.getCmp(config.gridName).store.reload();
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
