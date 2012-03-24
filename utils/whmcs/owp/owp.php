<?php
/**
 * Description: Module for OpenVZ Web Panel integration. 
 * Site: http://code.google.com/p/ovz-web-panel/
 */

/**
 * Module public methods
 */

function owp_ConfigOptions()
{
    $nodes = array();
    $serverTemplates = array();
    $osTempates = array();
    $result = _owp_apiCall('hardware_servers/list');
    foreach ($result->hardware_server as $hardwareServer) {
        $nodes[] = $hardwareServer->host;
        $serverTemplatesResult = _owp_apiCall('hardware_servers/server_templates', array('id' => (int)$hardwareServer->id));
        foreach ($serverTemplatesResult as $serverTemplate) {
            $serverTemplates[] = (string)$serverTemplate->name;
        }
        $osTemplatesResult = _owp_apiCall('hardware_servers/os_templates', array('id' => (int)$hardwareServer->id));
        foreach ($osTemplatesResult as $osTemplate) {
            $osTemplates[] = (string)$osTemplate->name;
        }
    }

    $serverTemplates = array_unique($serverTemplates);
    $osTemplates = array_unique($osTemplates);

    $userRoles = array();
    $result = _owp_apiCall('roles/list');
    foreach ($result->role as $role) {
        $userRoles[] = $role->name;
    }

    $configarray = array(
        "Node" => array("Type" => "dropdown", "Options" => join(',', $nodes)),
        "Server Template" => array("Type" => "dropdown", "Options" => join(',', $serverTemplates)),
        "OS" => array("Type" => "dropdown", "Options" => join(',', $osTemplates)),
        "User Role" => array("Type" => "dropdown", "Options" => join(',', $userRoles)),
    );
    
    return $configarray;
}

function owp_CreateAccount($params)
{
    # ** The variables listed below are passed into all module functions **

    $serviceid = $params["serviceid"]; # Unique ID of the product/service in the WHMCS Database
    $pid = $params["pid"]; # Product/Service ID
    $producttype = $params["producttype"]; # Product Type: hostingaccount, reselleraccount, server or other
    $domain = $params["domain"];
    $username = $params["username"];
    $password = $params["password"];
    $clientsdetails = $params["clientsdetails"]; # Array of clients details - firstname, lastname, email, country, etc...
    $customfields = $params["customfields"]; # Array of custom field values for the product
    $configoptions = $params["configoptions"]; # Array of configurable option values for the product

    # Product module option settings from ConfigOptions array above
    $node = $params["configoption1"];
    $result = _owp_apiCall('hardware_servers/get_by_host', array('host' => $node));
    $hardwareServerId = (int)$result->id;

    $osTemplate = $params["configoption3"];
    $serverTemplate = $params["configoption2"];

    $userRole = $params["configoption4"];
    $result = _owp_apiCall('roles/get_by_name', array('name' => $userRole));
    $userRoleId = (int)$result->id;

    # Additional variables if the product/service is linked to a server
    $server = $params["server"]; # True if linked to a server
    $serverid = $params["serverid"];
    $serverip = $params["serverip"];
    $serverusername = $params["serverusername"];
    $serverpassword = $params["serverpassword"];
    $serveraccesshash = $params["serveraccesshash"];
    $serversecure = $params["serversecure"]; # If set, SSL Mode is enabled in the server config

    $query = mysql_query("SELECT dedicatedip FROM `tblhosting` WHERE `id` = '$serviceid'");
    $result = mysql_fetch_array($query);
    $ipAddress = $result['dedicatedip'];

    $result = _owp_apiCall('users/create', array(
        'login' => $username,
        'password' => $password,
        'role_id' => $userRoleId,
        'contact_name' => $clientsdetails['firstname'] . ' ' . $clientsdetails['lastname'],
        'email' => $clientsdetails['email'],
    ));

    if ('error' == $result->getName()) {
        return (string)$result->message;
    }

    $userId = (int)$result->details->id;

    $result = _owp_apiCall('virtual_servers/create', array(
        'hardware_server_id' => $hardwareServerId,
        'orig_os_template' => $osTemplate,
        'orig_server_template' => $serverTemplate,
        'host_name' => $domain,
        'ip_address' => $ipAddress,
        'password' => $password,
        'user_id' => $userId,
    ));

    if ('error' == $result->getName()) {
        return (string)$result->message;
    }

    $virtualServerId = (int)$result->details->id;

    $result = _owp_apiCall('virtual_servers/start', array('id' => $virtualServerId));

    if ('error' == $result->getName()) {
        return (string)$result->message;
    }

    return "success";
}

function owp_TerminateAccount($params) 
{
    $username = $params["username"];
    $result = _owp_apiCall('users/get_by_login', array('login' => $username));
    $userId = (int)$result->id;
    
    $result = _owp_apiCall('users/delete', array('id' => $userId));

    if ('error' == $result->getName()) {
        return (string)$result->message;
    }

    $domain = $params["domain"];
    $result = _owp_apiCall('virtual_servers/get_by_host', array('host' => $domain));
    $serverId = (int)$result->id;

    $result = _owp_apiCall('virtual_servers/delete', array('id' => $serverId));   
 
    if ('error' == $result->getName()) {
        return (string)$result->message;
    }

    return "success";
}

function owp_SuspendAccount($params) 
{
    $username = $params["username"];
    $result = _owp_apiCall('users/get_by_login', array('login' => $username));
    $userId = (int)$result->id;

    $result = _owp_apiCall('users/disable', array('id' => $userId));

    if ('error' == $result->getName()) {
        return (string)$result->message;
    }

    $domain = $params["domain"];
    $result = _owp_apiCall('virtual_servers/get_by_host', array('host' => $domain));
    $serverId = (int)$result->id;

    $result = _owp_apiCall('virtual_servers/stop', array('id' => $serverId));

    if ('error' == $result->getName()) {
        return (string)$result->message;
    }

    return "success";
}

function owp_UnsuspendAccount($params) 
{
    $username = $params["username"];
    $result = _owp_apiCall('users/get_by_login', array('login' => $username));
    $userId = (int)$result->id;

    $result = _owp_apiCall('users/enable', array('id' => $userId));

    if ('error' == $result->getName()) {
        return (string)$result->message;
    }
    
    $domain = $params["domain"];
    $result = _owp_apiCall('virtual_servers/get_by_host', array('host' => $domain));
    $serverId = (int)$result->id;

    $result = _owp_apiCall('virtual_servers/start', array('id' => $serverId));

    if ('error' == $result->getName()) {
        return (string)$result->message;
    }

    return "success";
}

function owp_ClientArea($params) 
{
    $code = '<form action="http://' . _owp_getHost($params) . '/login" method="post" target="_blank">
<input type="hidden" name="login" value="'.$params["username"].'" />
<input type="hidden" name="password" value="'.$params["password"].'" />
<input type="hidden" name="plain_post" value="1" />
<input type="submit" value="Login to Control Panel" />
</form>';
    return $code;
}

function owp_AdminLink($params) 
{
    $code = '<form action="http://' . _owp_getHost($params) . '/login" method="post" target="_blank">
<input type="hidden" name="login" value="'.$params["serverusername"].'" />
<input type="hidden" name="password" value="'.$params["serverpassword"].'" />
<input type="hidden" name="plain_post" value="1" />
<input type="submit" value="Login to Control Panel" />
</form>';
    return $code;
}

function owp_LoginLink($params) 
{
    echo "<a href=\"http://" . _owp_getHost($params) . "/login?login=".$params["username"]."\" target=\"_blank\" style=\"color:#cc0000\">login to control panel</a>";
}

/**
 * Module private methods
 */

function _owp_getHost($params) 
{
    return ('' != $params['serverhostname']) ? $params['serverhostname'] : $params['serverip'];
}

function _owp_apiCall($method, $params = '') 
{
    $queryResult = mysql_query("SELECT * FROM `tblservers` WHERE `type` = 'owp' LIMIT 1");
    $serverInfo = mysql_fetch_array($queryResult);

    $host = $serverInfo['hostname'];
    $user = $serverInfo['username'];
    $password = decrypt($serverInfo['password']);
    
    if (is_array($params)) {
        $params = http_build_query($params);
    }
    # Check if CURL is compiled with PHP, fall back to fopen if not.
    if (extension_loaded('curl')) {    
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, "http://$host/api/$method?$params");
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        # CURL provides the same base64 encoding as fopen below
        curl_setopt($ch, CURLOPT_USERPWD, "$user:$password");
        curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
        $result = curl_exec($ch);
        curl_close($ch);
    } else {  
    $context = stream_context_create(array(
        'http' => array(
            'header'  => "Authorization: Basic " . base64_encode("$user:$password")
        )
    ));

    $result = file_get_contents("http://$host/api/$method?$params", false, $context);
    }
    $doc = simplexml_load_string($result);

    return $doc;
}
