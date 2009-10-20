<?php
/**
 * Simple (by layout) controller
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru> 
 */
abstract class Owp_Controller_Action_Simple extends Owp_Controller_Action_Abstract {
	
	/**
	 * Action init
	 *
	 */
	public function init() {
		parent::init();
		
		$this->_helper->layout->setLayout('simple');
	}
		
}
