<?php
/**
 * Default controller
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru>
 */
class Admin_IndexController extends Owp_Controller_Action_Admin
{

    /**
     * Default action
     *
     */
    public function indexAction()
    {
        $this->_redirect('/admin/dashboard');
    }

}