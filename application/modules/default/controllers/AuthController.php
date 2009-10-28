<?php
/**
 * Auth controller actions
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru>
 */
class AuthController extends Owp_Controller_Action_Simple
{

    /**
     * Login action
     *
     */
    public function loginAction()
    {
        if ($this->_auth->hasIdentity()) {
            $this->_redirect('/admin/dashboard');
        }

        if ($this->_request->isPost()) {
            $userName = $this->_getParam('userName', '*');
            $userPassword = $this->_getParam('userPassword');

            $this->_authAdapter
                ->setIdentity($userName)
                ->setCredential(md5($userPassword));

            $result = $this->_auth->authenticate($this->_authAdapter);

            if ($result->isValid()) {
                $storage = $this->_auth->getStorage();
                $storage->write($this->_authAdapter->getResultRowObject(array(
                    'userName',
                    'roleId',
                )));

                $this->_helper->json(array('success' => true));
            } else {
                $this->_helper->json(array(
                    'success' => false,
                    'errors' => array(
                        'message' => implode(' ', $result->getMessages())
                    )
                ));
            }
        }

        $this->view->pageTitle = "Login";
    }

    /**
     * Logout action
     *
     */
    public function logoutAction()
    {
        $this->_auth->clearIdentity();
        $this->_redirect('/login');
    }

}
