<?php
/**
 * Abstract controller action
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru> 
 */
abstract class Owp_Controller_Action_Abstract extends Zend_Controller_Action {
	
	protected $_config;
	protected $_session;
	protected $_db;
	protected $_auth;
	protected $_authAdapter;
	
	/**
	 * Init controller
	 *
	 */
	public function init() {
		$this->_config = Zend_Registry::get('config');
		$this->_session = Zend_Registry::get('session');
		$this->_db = Zend_Registry::get('db');		
		$this->_auth = Zend_Auth::getInstance();
		$this->_authAdapter = $this->_getAuthAdapter($this->_db);
		
		$this->view->addHelperPath("Owp/View/Helper", "Owp_View_Helper");
		
		$this->view->productName = $this->_config->general->productName;
		$this->view->productVersion = $this->_config->general->productVersion;
	}
	
	/**
	 * Get auth adapter
	 *
	 * @param Zend_Db_Adapter_Abstract $db
	 * @return Zend_Auth_Adapter
	 */
	private function _getAuthAdapter($db) {
		$authAdapter = new Zend_Auth_Adapter_DbTable($db);
		
		$authAdapter->setTableName('users')
			->setIdentityColumn('userName')
			->setCredentialColumn('userPassword');
		
		return $authAdapter;
	}
	
}
