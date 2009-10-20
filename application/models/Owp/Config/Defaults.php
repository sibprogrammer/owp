<?php
/**
 * Config defaults
 *
 * @author Alexei Yuzhakov <alex@softunity.com.ru> 
 */
class Owp_Config_Defaults {
	
	/**
	 * Get config defaults
	 *
	 * @return array
	 */
	public static function getDefaults() {
		$defaults = array(
			'general' => array(
				'productName' => 'OpenVZ Web Panel',
				'productVersion' => '0.3',
			),
			
			'debug' => array(
				'enabled' => false, 
			),

			'routes' => array(							
				'login' => array(
					'type' => 'Zend_Controller_Router_Route_Static',
					'route' => 'login',
					'defaults' => array(
						'controller' => 'auth',
						'action' => 'login',
					),
				),
			),
			
			'hwDaemon' => array(
				'defaultPort' => 7766,
			),
					
			'menu' => array(
				'general' => array(
					'title' => 'General',
					'items' => array(
						array(
							'title' => 'Dashboard',
							'link' => '/admin/dashboard',
							'icon' => 'menu_icon_dashboard.png',
						),
						array(
							'title' => 'Hardware servers',
							'link' => '/admin/hardware-server/list',
							'icon' => 'menu_icon_host.png',
						),
						array(
							'title' => 'My profile',
							'link' => 'javascript: Owp.Layouts.Admin.onMyProfileClick();',
							'icon' => 'menu_icon_profile.png',
						),
						array(
							'title' => 'Logout',
							'link' => 'javascript: Owp.Layouts.Admin.onLogoutLinkClick();',
							'icon' => 'menu_icon_logout.png',
						),
					),
				),
				
				'help' => array(
					'title' => 'Help',
					'items' => array(
						array(
							'title' => 'Documentation',
							'link' => 'http://code.google.com/p/ovz-web-panel/w/list',
							'external' => true,
							'icon' => 'menu_icon_help.png',
						),
						array(
							'title' => 'Support',
							'link' => 'http://code.google.com/p/ovz-web-panel/issues/list',
							'external' => true,
							'icon' => 'menu_icon_docs.png',
						),
					),
				),
			),
		);
		
		return $defaults;
	}
	
}