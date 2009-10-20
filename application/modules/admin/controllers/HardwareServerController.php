<?php
/**
 * HW-nodes controller
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru> 
 */
class Admin_HardwareServerController extends Owp_Controller_Action_Admin {

	/**
	 * Action init
	 *
	 */
	public function init() {
		parent::init();
		
		$this->view->upLevelLink = '/admin/dashboard';
	}
	
	/**
	 * Default action
	 *
	 */
	public function indexAction() {
		$this->_forward('list');
	}

	/**
	 * List of servers
	 *
	 */
	public function listAction() {
		$this->view->pageTitle = "Hardware servers";
	}
	
	/**
	 * Json data of list of servers
	 *
	 */
	public function listDataAction() {
		$hwServers = new Owp_Table_HwServers();
			
		$select = $hwServers->select();
		$hwServersData = $hwServers->fetchAll($select);
		
		$hwServersJsonData = array();
		
		foreach ($hwServersData as $hwServerData) {
			$hwServersJsonData[] = array(
				'id' => $hwServerData->id, 
				'hostName' => $hwServerData->hostName,
				'description' => $hwServerData->description,
			);
		}
		
		$this->_helper->json($hwServersJsonData);
	}
	
	/**
	 * Disconnect server
	 *
	 */
	public function deleteAction() {
		$id = $this->_request->getParam('id');
		
		$hwServers = new Owp_Table_HwServers();
		$hwServer = $hwServers->fetchRow($hwServers->select()->where('id = ?', $id));
		
		$hwServer->delete();
		
		$this->_helper->json(array('success' => true));
	}
	
	/**
	 * Connect new server
	 *
	 */
	public function addAction() {
		$hwServers = new Owp_Table_HwServers();
		
		$hwServer = $hwServers->createRow();
		$hwServer->hostName = $this->_request->getParam('hostName');
		$hwServer->authKey = $this->_request->getParam('authKey');
		$hwServer->description = $this->_request->getParam('description');
		$hwServer->save();
		
		$osTemplatesRawData = $hwServer->execDaemonRequest('ls', '/vz/template/cache/');
		
		$osTemplates = new Owp_Table_OsTemplates();
		$osTemplatesRawData = $hwServer->execDaemonRequest('ls', '/vz/template/cache/');
		$osTemplatesArray = explode("\n", $osTemplatesRawData);
		
		foreach ($osTemplatesArray as $osTemplateRecord) {
			$osTemplateRecord = str_replace('.tar.gz', '', $osTemplateRecord);
			$osTemplate = $osTemplates->createRow();
			$osTemplate->name = $osTemplateRecord;
			$osTemplate->hwServerId = $hwServer->id;
			$osTemplate->save();
		}
				
		$virtualServers = new Owp_Table_VirtualServers();
		$vzlistRawData = $hwServer->execDaemonRequest('vzlist', '-a -H -o veid,hostname,ip,status');
		$vzlist = explode("\n", $vzlistRawData);
		
		foreach ($vzlist as $vzlistEntry) {
			list($veId, $hostName, $ipAddress, $status) = preg_split("/\s+/", trim($vzlistEntry));
			
			$virtualServerConfigData = $hwServer->execDaemonRequest('cat', "/etc/vz/conf/$veId.conf");			
			$iniParser = new Owp_Config_IniParser($virtualServerConfigData);			
			$osTemplateName = $iniParser->get('OSTEMPLATE');
			
			$osTemplates = new Owp_Table_OsTemplates();
			$osTemplate = $osTemplates->fetchRow($osTemplates->select()->where('name = ?', $osTemplateName));
						
			$virtualServer = $virtualServers->createRow();
			$virtualServer->veId = $veId;
			$virtualServer->ipAddress = $ipAddress;
			$virtualServer->hostName = $hostName;
			$virtualServer->veState = $virtualServer->getVeStateByName($status);
			$virtualServer->hwServerId = $hwServer->id;
			$virtualServer->osTemplateId = $osTemplate->id;
			$virtualServer->save();
		}
		
		$this->_helper->json(array('success' => true));
	}
		
	/**
	 * Show server settings and VPS list
	 *
	 */
	public function showAction() {
		$id = $this->_request->getParam('id');
		
		$hwServers = new Owp_Table_HwServers();
		$hwServer = $hwServers->fetchRow($hwServers->select()->where('id = ?', $id));
		
		$this->view->pageTitle = "Hardware server - $hwServer->hostName";
		$this->view->upLevelLink = '/admin/hardware-server/list';
		$this->view->hwServerId = $id;
	}
	
}