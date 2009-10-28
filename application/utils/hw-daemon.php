<?php
declare(ticks=1);

class HwDaemon
{

    const ERROR_INTERNAL = 60;
    const ERROR_WRONG_PARAM = 61;
    const ERROR_PHP = 62;
    const ERROR_EXCEPTION   = 63;
    const ERROR_ENVIRONMENT = 64;

    const VERSION = '0.1';

    const PID_FILE_NAME = 'hw-daemon.pid';
    const CONFIG_FILE_NAME = 'hw-daemon.ini';

    private $_socketAddress = 0;
    private $_socketPort = 7766;
    private $_maxClients = 10;
    private $_authKey = '';
    private $_logFile = 'hw-daemon.log';
    private $_debug = false;

    /**
     * Create OpenVZ HW-node daemon
     *
     */
    public function __construct()
    {
        chdir(dirname(__FILE__));

        $this->_readConfig();
    }

    /**
     * PHP errors handler
     *
     * @param int $code
     * @param string $message
     * @param string $file
     * @param int $line
     * @param array $context
     */
    public function errorHandler($code, $message, $file, $line, $context)
    {
        // don't handle errors suppressed with @-operator and E_STRICT notices
        if ((0 == ini_get('error_reporting')) || (E_STRICT == $code)) {
            return;
        }

        $fullMessage = "$message\n"
            . "file: $file\n"
            . "line: $line\n"
            . "code: $code";

        $this->_fatalError($fullMessage, self::ERROR_PHP);
    }

    /**
     * Exceptions handler
     *
     * @param Exception $exception
     */
    public function exceptionHandler($exception)
    {
        $fullMessage = (get_class($exception) . " - {$exception->getMessage()}\n"
            . "file: {$exception->getFile()}\n"
            . "line: {$exception->getLine()}\n"
            . "code: {$exception->getCode()}"
        );

        $level = ($exception instanceof SoapFault)
            ? self::ERROR_SOAP
            : self::ERROR_EXCEPTION;

        $this->_fatalError($fullMessage, $level);
    }

    /**
     * Raise fatal error
     *
     * @param string $message
     */
    private function _fatalError($message, $level = self::ERROR_INTERNAL)
    {
        $this->_log("Error ($level): $message", true);
        exit($level);
    }

    /**
     * Log message
     *
     * @param string $message
     * @param bool $output
     */
    private function _log($message, $output = false)
    {
        if (!$this->_logFile) {
            echo "$message\n";
        } else {
            if ($output) {
                echo "$message\n";
            }

            $handle = fopen($this->_logFile, 'a+');
            $date = date("M j H:i:s");
            fwrite($handle, "$date $message\n");
            fclose($handle);
        }
    }

    /**
     * Run daemon
     *
     */
    public function run()
    {
        set_time_limit(0);

        $command = @$_SERVER['argv'][1];

        if (('' == $command) || ('help' == $command)) {
            $this->_commandHelp();
        } else if ('start' == $command) {
            $this->_commandStart();
        } else if ('stop' == $command) {
            $this->_commandStop();
        } else if ('restart' == $command) {
            $this->_commandStop(true);
            $this->_commandStart();
        } else if ('status' == $command) {
            $this->_commandStatus();
        } else {
            $this->_fatalError("Unknown command '$command'.");
        }
    }

    /**
     * Handle process signals
     *
     * @param int $signal
     */
    public function signalHandler($signal)
    {
        if ((SIGTERM == $signal) || (SIGINT == $signal)) {
            @unlink(self::PID_FILE_NAME);
            exit(0);
        } else if (SIGCHLD == $signal) {
            pcntl_waitpid(-1, $status);
        } else if (SIGHUP == $signal) {

        }
    }

    /**
     * Read config file data
     *
     */
    private function _readConfig()
    {
        $config = @parse_ini_file(self::CONFIG_FILE_NAME);

        $this->_authKey = @$config['key'];

        if (!$this->_authKey) {
            $this->_fatalError("Auth key isn't defined.");
        }

        if (isset($config['address'])) {
            $this->_socketAddress = $config['address'];
        }

        if (isset($config['port'])) {
            $this->_socketPort = $config['port'];
        }

        if (isset($config['maxClients'])) {
            $this->_maxClients = $config['maxClients'];
        }

        if (isset($config['log'])) {
            $this->_logFile = $config['log'];
        }

        if (isset($config['debug'])) {
            $this->_debug = $config['debug'];
        }
    }

    /**
     * Check requirements
     *
     */
    private function _checkEnvironment()
    {
        if ('cli' != php_sapi_name()) {
            $this->_fatalError('Daemon can be runned only under PHP CLI.');
        }

        if (0 != posix_getuid()) {
            $this->_fatalError('Daemon must be started under root account.');
        }
    }

    /**
     * Show help screen
     *
     */
    private function _commandHelp()
    {
        $scriptName = $_SERVER['argv'][0];
        echo "Usage: php $scriptName (start stop restart status help)\n";
    }

    /**
     * Start daemon
     *
     */
    private function _commandStart()
    {
        $this->_checkEnvironment();

        if ($this->_isDaemonStarted()) {
            $this->_fatalError('Daemon is already running.');
        }

        $pid = pcntl_fork();

        if ($pid == -1) {
            $this->_fatalError('Unable to create daemon.');
        } else if ($pid) {
            // terminate parent
            exit();
        } else {
            // child process
            $this->_log('OpenVZ HW-node daemon v.' . self::VERSION . ' started.', true);
        }

        if (!posix_setsid()) {
            $this->_fatalError('Unable to detach daemon from controlling terminal.');
        }

        pcntl_signal(SIGTERM, array($this, 'signalHandler'));
        pcntl_signal(SIGHUP, array($this, 'signalHandler'));
        pcntl_signal(SIGCHLD, array($this, 'signalHandler'));
        pcntl_signal(SIGINT, array($this, 'signalHandler'));

        file_put_contents(self::PID_FILE_NAME, posix_getpid());
        chmod(self::PID_FILE_NAME, 0600);

        $clients = array();
        $socket = $this->_createSocket();

        while (true) {
            $read = array($socket);

            for ($i = 0; $i < $this->_maxClients; $i++) {
                if (isset($clients[$i]) && (null != $clients[$i])) {
                    $read[$i + 1] = $clients[$i];
                }
            }

            $ready = @socket_select($read, $write = null, $except = null, null);

            if (in_array($socket, $read)) {
                for ($i = 0; $i < $this->_maxClients; $i++) {
                    if (!isset($clients[$i])) {
                        $clients[$i] = @socket_accept($socket);

                        if ($clients[$i] <= 0) {
                            $this->_fatalError('Function socket_accept failed - reason: ' . socket_strerror($clients[$i]));
                        }

                        break;
                    } elseif ($i == $this->_maxClients - 1) {
                        $this->_log('Max clients limit reached.');
                    }
                }

                if (--$ready <= 0) {
                    continue;
                }
            }

            for ($i = 0; $i < $this->_maxClients; $i++) {
                if (isset($clients[$i]) && in_array($clients[$i], $read)) {
                    $this->_runRequestHandler($socket, $clients[$i]);
                    socket_close($clients[$i]);
                }

                unset($clients[$i]);
            }
        }
    }

    /**
     * Run request handler
     *
     * @param resource $socket
     * @param resource $connection
     */
    private function _runRequestHandler($socket, $connection)
    {
        $request = '';

        while (true) {
            $buffer = @socket_read($connection, 4096, PHP_NORMAL_READ);

            if (false === $buffer) {
                $this->_log("Socket read error: " . socket_strerror(socket_last_error()));
                return;
            }

            $request .= $buffer;

            if (false !== strpos($request, "\n\n")) {
                break;
            }
        }

        $response = $this->_getResonse($request);
        socket_write($connection, $response, strlen($response));
    }

    /**
     * Ger response on request
     *
     * @param string $request
     * @return string
     */
    private function _getResonse($request)
    {
        $responseXml = simplexml_load_string('<?xml version="1.0" encoding="UTF-8"?><response/>');

        $requestXml = @simplexml_load_string(trim($request));

        if (!$requestXml) {
            if ($this->_debug) {
                $this->_log("Wrong request: $request");
            }

            $responseXml->fault = 'Unable to parse request XML.';
            $responseXml->code = 255;
            return $responseXml->asXml();
        }

        if ($this->_authKey != $requestXml->authKey) {
            $responseXml->fault = 'Invalid auth key.';
            $responseXml->code = 255;
            return $responseXml->asXml();
        }

        $this->_log("Executing command: $requestXml->command");

        exec($requestXml->command, $output, $resultCode);

        $this->_log("Return code of '$requestXml->command' command: $resultCode");

        if ($this->_debug) {
            $this->_log("Output of '$requestXml->command' command:\n" . join("\n", $output));
        }

        if (0 != $resultCode) {
            $responseXml->fault = 'Unable to execute requested command.';
            $responseXml->code = $resultCode;
            return $responseXml->asXml();
        }

        $responseXml->output = implode("\n", $output);

        return $responseXml->asXml();
    }

    /**
     * Create socket and bind it
     *
     * @return resource
     */
    private function _createSocket()
    {
        if (($socket = socket_create(AF_INET, SOCK_STREAM, 0)) < 0) {
            $this->_fatalError("Function socket_create() failed - reason: " . socket_strerror($socket));
        }

        if (($result = socket_bind($socket, $this->_socketAddress, $this->_socketPort)) < 0) {
            $this->_fatalError("Function socket_bind() failed - reason: " . socket_strerror($result));
        }

        if (($result = socket_listen($socket, 0)) < 0) {
            $this->_fatalError("Function socket_listen() failed - reason: " . socket_strerror($result));
        }

        socket_set_nonblock($socket);

        return $socket;
    }

    /**
     * Check if daemon is started
     *
     * @return bool
     */
    private function _isDaemonStarted()
    {
        $pid = @file_get_contents(self::PID_FILE_NAME);

        if (!$pid) {
            return false;
        }

        return posix_kill($pid, 0);
    }

    /**
     * Stop daemon
     *
     * @param bool $silent
     */
    private function _commandStop($silent = false)
    {
        $pid = @file_get_contents(self::PID_FILE_NAME);

        if (!$pid) {
            if ($silent) {
                echo "Daemon not running (PID file not found).\n";
                return ;
            }

            $this->_fatalError('Daemon not running.');
        }

        if (posix_kill($pid, SIGTERM)) {
            $this->_log('Daemon was stopped.', true);
        } else {
            $this->_fatalError('Unable to stop daemon.');
        }
    }

    /**
     * Display daemon status
     *
     */
    private function _commandStatus()
    {
        if ($this->_isDaemonStarted()) {
            echo "Daemon is running.\n";
        } else {
            echo "Daemon is stopped.\n";
        }
    }

}

$hwDaemon = new HwDaemon();
set_error_handler(array($hwDaemon, 'errorHandler'));
set_exception_handler(array($hwDaemon, 'exceptionHandler'));
$hwDaemon->run();
