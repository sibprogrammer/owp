<?php
/**
 * OS templates manipulations controller
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru>
 */
class Admin_OsTemplateController extends Owp_Controller_Action_Admin
{

    /**
     * Json data of list of OS templates
     *
     */
    public function listDataAction()
    {
        $hwServerId = (int) $this->_request->getParam('hw-server-id');

        $osTemplates = new Owp_Table_OsTemplates();

        $select = $osTemplates->select()->where('hwServerId = ?', $hwServerId);
        $osTemplatesData = $osTemplates->fetchAll($select);

        $osTemplatesJsonData = array();

        foreach ($osTemplatesData as $osTemplateData) {
            $osTemplatesJsonData[] = array(
                'id' => $osTemplateData->id,
                'name' => $osTemplateData->name,
            );
        }

        $this->_helper->json($osTemplatesJsonData);
    }

}