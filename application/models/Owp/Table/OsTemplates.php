<?php
/**
 * OS templates table gateway
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru> 
 */
class Owp_Table_OsTemplates extends Zend_Db_Table_Abstract {
		
	protected $_name = 'osTemplates';
	protected $_dependentTables = array('Owp_Table_VirtualServers');
	
	protected $_referenceMap = array(
		'HwServer' => array(
			'columns' => 'hwServerId',
			'refTableClass' => 'Owp_Table_HwServers',
			'refColumns' => 'id',
			'onDelete' => self::CASCADE,
		),
	);
		
}