<?php
/**
 * Virtual servers table gateway
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru>
 */
class Owp_Table_VirtualServers extends Zend_Db_Table_Abstract
{

    protected $_name = 'virtualServers';
    protected $_rowClass = 'Owp_Table_Row_VirtualServer';

    protected $_referenceMap = array(
        'OsTemplate' => array(
            'columns' => 'osTemplateId',
            'refTableClass' => 'Owp_Table_OsTemplates',
            'refColumns' => 'id',
            'onDelete' => self::CASCADE,
        ),
        'HwServer' => array(
            'columns' => 'hwServerId',
            'refTableClass' => 'Owp_Table_HwServers',
            'refColumns' => 'id'
        ),
    );

}