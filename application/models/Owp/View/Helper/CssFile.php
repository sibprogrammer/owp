<?php
/**
 * View helper for inclusion of CSS files
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru> 
 */
class Owp_View_Helper_CssFile extends Zend_View_Helper_Abstract {
	
	/**
	 * Render helper
	 *
	 * @return string
	 */
	public function cssFile($fileName) {
		$htdocsPath = ROOT_PATH . '/htdocs/';
		$cacheIdent = filemtime($htdocsPath . $fileName);
		
		return '<link rel="stylesheet" type="text/css" href="' . htmlspecialchars($fileName) . "?$cacheIdent" . '"/>';
	}
	
}

