<?php
/**
 * Admin controller
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru>
 */
abstract class Owp_Controller_Action_Admin extends Owp_Controller_Action_Abstract
{

    /**
     * Action init
     *
     */
    public function init()
    {
        parent::init();

        if (!$this->_auth->hasIdentity()) {
            $this->_redirect('/login');
        }

        $this->view->loggedUser = $this->_auth->getIdentity()->userName;

        $this->_helper->layout->setLayout('admin');
    }

    /**
     * Post dispatch routines
     *
     */
    public function postDispatch()
    {
        if ($this->_helper->layout->isEnabled()) {
            $this->_generateMenu();
        }
    }

    /**
     * Generate menu
     *
     */
    private function _generateMenu()
    {
        $this->view->menus = Zend_Registry::get('config')->menu->toArray();

        // render menu
        $response = $this->getResponse();
        $response->insert('menu', $this->view->render('_partials/menu.phtml'));
    }

    /**
     * Add paginator for list
     *
     * @param object $select
     */
    protected function _addPaginator($select)
    {
        $paginator = new Zend_Paginator(new Zend_Paginator_Adapter_DbSelect($select));
        $paginator->setCurrentPageNumber($this->_getParam('page'));
        $this->view->paginator = $paginator;
    }

}
