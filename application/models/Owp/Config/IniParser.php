<?php
/**
 * Ini-formatted config parser
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru> 
 */
class Owp_Config_IniParser {
	
	private $_data = array();
	
	/**
	 * Create config parser
	 *
	 * @param string $rawData
	 */
	public function __construct($rawData = '') {
		if ($rawData) {
			$this->loadFromString($rawData);
		}
	}
	
	/**
	 * Retrive config variable
	 *
	 * @param string $name
	 */
	public function get($name) {
		return $this->_data[$name];
	}
	
	/**
	 * Load config data from string
	 *
	 */
	public function loadFromString($rawData) {
		$dataRecords = explode("\n", $rawData);
				
		foreach ($dataRecords as $dataRecord) {
			if (preg_match('/^#/', $dataRecord)) {
				continue;
			}
			
			if (preg_match('/^(.*)="(.*)"(\s+)?(#.*)?$/', $dataRecord, $matches)) {
				$paramName = $matches[1];
				$paramValue = $matches[2];
						
				$this->_data[$paramName] = $paramValue;
			}
		}
	}
	
}