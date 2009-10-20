<?php
/**
 * Errors controller actions
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru> 
 */
class ErrorController extends Owp_Controller_Action_Simple {
		
	/**
	 * Error handling
	 *
	 */
	public function errorAction() {
		$this->view->pageTitle = "Error";
		
		$errors = $this->_getParam('error_handler');
		
		if ((Zend_Controller_Plugin_ErrorHandler::EXCEPTION_NO_CONTROLLER == $errors->type)
			|| (Zend_Controller_Plugin_ErrorHandler::EXCEPTION_NO_ACTION == $errors->type)
		) {
			$this->_redirect('/');
		}
		
		$this->view->exception = $errors->exception;
	}
		
}