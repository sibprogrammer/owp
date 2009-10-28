<?php
/**
 * View helper for inclusion of JS files
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru>
 */
class Owp_View_Helper_JsFile extends Zend_View_Helper_Abstract
{

    /**
     * Render helper
     *
     * @return string
     */
    public function jsFile($fileName)
    {
        $htdocsPath = ROOT_PATH . '/htdocs/';
        $cacheIdent = filemtime($htdocsPath . $fileName);

        return '<script type="text/javascript" src="' . htmlspecialchars($fileName) . "?$cacheIdent" . '"></script>';
    }

}

