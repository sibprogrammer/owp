<?php
/**
 * HW-servers table gateway
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru>
 */
class Owp_Table_HwServers extends Zend_Db_Table_Abstract
{

    protected $_name = 'hwServers';
    protected $_rowClass = 'Owp_Table_Row_HwServer';

    protected $_dependentTables = array(
        'Owp_Table_OsTemplates'
    );

}