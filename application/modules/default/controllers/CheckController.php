<?php
/**
 * Controller for various checks
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru>
 */
class CheckController extends Owp_Controller_Action_Simple
{

    /**
     * Controller init routines
     *
     */
    public function init()
    {
        parent::init();

        if (!$this->_config->debug->enabled) {
            $this->_redirect('/login');
        }
    }

    /**
     * Default action
     *
     */
    public function indexAction()
    {
        $this->_redirect('/check/env');
    }

    /**
     * Check environment
     *
     */
    public function envAction()
    {
        $this->view->pageTitle = "Environment checker";

        $phpExtensions = array('pdo', 'pdo_sqlite', 'session', 'pcre', 'SimpleXML', 'SPL');

        $checksData = array();

        foreach ($phpExtensions as $phpExtension) {
            $checksData[] = array(extension_loaded($phpExtension), "Extension: $phpExtension");
        }

        $phpParameters = array('safe_mode' => false, 'register_globals' => false);

        foreach ($phpParameters as $phpParameter => $value) {
            $checksData[] = array($value == ini_get($phpParameter), "PHP parameter: $phpParameter");
        }

        $checksData[] = array($this->_checkDbConnection(), "Database connection and state");

        $this->view->checksData = Zend_Json::encode($checksData);
    }

    /**
     * Display phpinfo information
     *
     */
    public function phpinfoAction()
    {
        $this->_helper->layout->disableLayout();
        $this->_helper->viewRenderer->setNoRender();

        phpinfo();
    }

    /**
     * Check database connection and state
     *
     * @return bool
     */
    private function _checkDbConnection()
    {
        try {
            $db = Zend_Registry::get('db');
            $db->fetchAll('SELECT * FROM users LIMIT 1');
            return true;
        } catch (Zend_Db_Exception $exception) {
            return false;
        }
    }

}