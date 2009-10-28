<?php
/**
 * Virtual server table row gateway
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru>
 */
class Owp_Table_Row_VirtualServer extends Zend_Db_Table_Row_Abstract
{

    const STATE_RUNNING = 1;
    const STATE_STOPPED = 2;
    const STATE_UNKNOWN = 3;

    /**
     * Get virtual server state by state name
     *
     * @param string $stateName
     * @return int
     */
    public function getVeStateByName($stateName)
    {
        if ('running' == $stateName) {
            return self::STATE_RUNNING;
        }

        if ('stopped' == $stateName) {
            return self::STATE_STOPPED;
        }

        return self::STATE_UNKNOWN;
    }

    /**
     * Remove virtual server physically
     *
     */
    public function removePhysically()
    {
        $hwServer = $this->findParentRow('Owp_Table_HwServers', 'HwServer');

        if (self::STATE_STOPPED != $this->veState) {
            $hwServer->execDaemonRequest('vzctl', "stop $this->veId");
        }

        $hwServer->execDaemonRequest('vzctl', "destroy $this->veId");
    }

    /**
     * Create virtual server physically
     *
     */
    public function createPhysically()
    {
        $osTemplate = $this->findParentRow('Owp_Table_OsTemplates', 'OsTemplate');

        $hwServers = new Owp_Table_HwServers();
        $hwServer = $hwServers->find($this->hwServerId)->current();

        $hwServer->execDaemonRequest('vzctl', "create $this->veId --ostemplate $osTemplate->name");

        if ($this->ipAddress) {
            $hwServer->execDaemonRequest('vzctl', "set $this->veId --ipadd $this->ipAddress --save");
        }

        if ($this->hostName) {
            $hwServer->execDaemonRequest('vzctl', "set $this->veId --hostname $this->hostName --save");
        }

        $hwServer->execDaemonRequest('vzctl', "start $this->veId");
    }

}
