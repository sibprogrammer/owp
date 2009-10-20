<?php
/**
 * Main application class
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru> 
 */
class Owp_Application {
	
	/**
	 * Run application
	 *
	 */
	public function run() {
		$this->_initConfig();		
		$this->_initDatabase();
		$this->_initSession();
		$this->_initFrontController();
		$this->_initRouter();
		
		Zend_Controller_Front::getInstance()->dispatch();
	}
	
	/**
	 * Init config object
	 *
	 */
	private function _initConfig() {
		$config = new Zend_Config(Owp_Config_Defaults::getDefaults(), true);
		$configFromFile = new Zend_Config_Ini(ROOT_PATH . '/config.ini');
		
		$config->merge($configFromFile);
		$config->setReadOnly();
		
		Zend_Registry::set('config', $config);
	}
	
	/**
	 * Init config object
	 *
	 */
	private function _initDatabase() {
		$db = Zend_Db::factory(
			Zend_Registry::get('config')->database->adapter,
			Zend_Registry::get('config')->database->params->toArray()
		);
		
		Zend_Registry::set('db', $db);
		
		Zend_Db_Table_Abstract::setDefaultAdapter($db);
	}
	
	/**
	 * Init session object
	 *
	 */
	private function _initSession() {
		Zend_Session::start();
		
		Zend_Registry::set('session', new Zend_Session_Namespace('Default'));
	}
	
	/**
	 * Init controller object
	 *
	 */
	private function _initFrontController() {
		Zend_Layout::startMvc(array('layoutPath' => ROOT_PATH . '/modules/default/views/layouts'));

		$frontController = Zend_Controller_Front::getInstance();
		$frontController->addModuleDirectory(ROOT_PATH . '/modules');
	}
	
	/**
	 * Init router
	 *
	 */
	private function _initRouter() {
		$router = Zend_Controller_Front::getInstance()->getRouter();
		$router->addConfig(Zend_Registry::get('config'), 'routes');
	}
	
}