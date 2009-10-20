<?php
/**
 * Controller for various checks
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru> 
 */
class CheckController extends Owp_Controller_Action_Simple {
	
	/**
	 * Default action
	 *
	 */
	public function indexAction() {
		$this->_forward('env');
	}
	
	/**
	 * Check environment
	 *
	 */
	public function envAction() {
		$this->view->pageTitle = "Environment checker";
		
		$phpExtensions = array(
			'pdo',
			'pdo_sqlite',
			'session',
			'pcre',
			'SimpleXML',
			'SPL',
		);
		
		$phpExtensionsJsonData = array();
		
		foreach ($phpExtensions as $phpExtension) {
			$phpExtensionsJsonData[] = array(extension_loaded($phpExtension), $phpExtension);
		}
				
		$this->view->phpExtensionsJsonData = Zend_Json::encode($phpExtensionsJsonData);
	}
	
	/**
	 * Display phpinfo information
	 *
	 */
	public function phpinfoAction() {
		if (!$this->_config->debug->enabled) {
			$this->_redirect('/check/env');
		}
		
		$this->_helper->layout->disableLayout();
		$this->_helper->viewRenderer->setNoRender();
		
		phpinfo();
	}
			
}