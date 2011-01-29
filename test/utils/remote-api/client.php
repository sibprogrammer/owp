#!/usr/bin/env php
<?php

$host = 'host';
$port = 3000;
$user = 'admin';
$password = 'password';
$api_method = '/api/hardware_servers/list';

$context = stream_context_create(array(
    'http' => array(
        'header'  => "Authorization: Basic " . base64_encode("$user:$password")
    )
));

$result = file_get_contents("http://$host:$port$api_method", false, $context);

echo $result;

$doc = simplexml_load_string($result);

foreach($doc->xpath('//hardware_server/host') as $node) {
    echo "server: $node\n";
}
