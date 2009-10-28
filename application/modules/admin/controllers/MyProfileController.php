<?php
/**
 * My profile controller
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru>
 */
class Admin_MyProfileController extends Owp_Controller_Action_Admin
{

    /**
     * Save profile
     *
     */
    public function saveAction()
    {
        $users = new Owp_Table_Users();
        $user = $users->fetchRow($users->select()->where('userName = ?',
            $this->_auth->getIdentity()->userName
        ));

        if (md5($this->_request->getParam('currentPassword')) != $user->userPassword) {
            $this->_helper->json(array('success' => false, 'errors' =>
                array('message' => 'Incorrect current password.'
            )));
        }

        $newPassword = $this->_request->getParam('newPassword');
        $confirmPassword = $this->_request->getParam('confirmPassword');

        if ($newPassword != $confirmPassword) {
            $this->_helper->json(array('success' => false, 'errors' =>
                array('message' => "New password and it's confirmation aren't the same."
            )));
        }

        $user->userPassword = md5($newPassword);
        $user->save();

        $this->_helper->json(array('success' => true));
    }

}