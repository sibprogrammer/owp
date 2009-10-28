<?php
/**
 * HW-server table row gateway
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru>
 */
class Owp_Table_Row_HwServer extends Zend_Db_Table_Row_Abstract
{

    /**
     * Execute command on HW server via daemon
     *
     * @param string $command
     * @param string $arguments
     */
    public function execDaemonRequest($command, $arguments = '')
    {
        $port = Zend_Registry::get('config')->hwDaemon->defaultPort;

        $handler = fsockopen($this->hostName, $port, $errorCode, $errorString, 30);

        if (!$handler) {
            echo "$errorString ($errorCode)<br />\n";
        } else {
            $requestXml = simplexml_load_string('<?xml version="1.0" encoding="UTF-8"?><request/>');
            $requestXml->authKey = $this->authKey;
            $requestXml->command = "$command $arguments";

            fwrite($handler, $requestXml->asXml() . "\n\n");

            $response = '';

            while (!feof($handler)) {
                $response .= fgets($handler, 128);
            }

            fclose($handler);
        }

        $responseXml = simplexml_load_string($response);

        if (!$responseXml) {
            throw new Owp_Exception('Unable to parse response XML.');
        }

        if ($responseXml->fault) {
            throw new Owp_Exception("Request failed. $responseXml->fault Code: $responseXml->code");
        }

        return (string) $responseXml->output;
    }

}