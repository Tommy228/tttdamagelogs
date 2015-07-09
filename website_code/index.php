<?php
/* Code by Mohamed RACHID */


header('Content-Type: text/html; charset=UTF-8');


require(dirname(__FILE__).'/config.php');
$db = @new mysqli($db_config['host'], $db_config['username'], $db_config['passwd'], $db_config['dbname'], $db_config['port'], $db_config['socket']);
$db_error = mysqli_connect_errno();
date_default_timezone_set($timezone);


function IsEmptyDateRange ($MinTime, $MaxTime) {
	global $db_config;
	global $check_for_empty;
	global $db;
	if ($check_for_empty) {
		$result = $db->query('SELECT date FROM '.$db_config['table'].' WHERE date >= '.(int) $MinTime.' AND date < '.(int) $MaxTime.' LIMIT 1');
		if ($result->num_rows > 0) {
			$result->free();
			return false;
		}
		else {
			$result->free();
			return true; // empty
		}
	}
	else {
		return false;
	}
}


define('LF', "\x0A");
define('CR', "\x0D");
define('CRLF', "\x0D\x0A");


function escapeHTMLasJSstring ($html) {
	return str_replace('"', '\\"', str_replace('\'', '\\\'', str_replace(CR, '\\r', str_replace(LF, '\\n', str_replace(CRLF, '\\n', str_replace("\t", '\\t', str_replace('\\', '\\\\', $html)))))));
}


define('page_title', 'Trouble in Terrorist Town - Old Damagelogs');


// Player roles
define('ROLE_INNOCENT', 0);
define('ROLE_TRAITOR', 1);
define('ROLE_DETECTIVE', 2);
define('ROLE_NONE', ROLE_INNOCENT);
$ROLES = array(
	ROLE_INNOCENT => 'Innocent',
	ROLE_TRAITOR => 'Traitor',
	ROLE_DETECTIVE => 'Detective'
);
$ROLE_COLORS = array(
	ROLE_INNOCENT => '#00C900',
	ROLE_TRAITOR => '#C90000',
	ROLE_DETECTIVE => '#0000C9'
);


// Weapon names
if (!$db_error) {
	$result = $db->query('SELECT class, name FROM '.$db_config['table_weapons']);
	$WEAPONS = array();
	while ($result_row = $result->fetch_assoc()) {
		$WEAPONS[$result_row['class']] = $result_row['name'];
	}
	$result->free();
	unset($result, $result_row);
}
function GetWeaponDisplayName ($class) {
	global $WEAPONS;
	if (isset($WEAPONS[$class]))
		return $WEAPONS[$class];
	else
		return $class;
}


// Player info fields
define('INFO_Role', 'role');
define('INFO_SteamID', 'steamid');
define('INFO_SteamID64', 'steamid64');


function Complete_Permalink_URL_Params ($url_params, $data = NULL, $year = NULL, $month = NULL, $day = NULL, $round_begin = NULL, $round_end = NULL) {
	preg_match('`^&([a-zA-Z_]+)=`', $url_params, $type);
	$type = $type[1];
	switch ($type) {
		case 'round_list':
			if ($year == NULL)
				$year = (int) date('Y', $data['date']);
			if ($month == NULL)
				$month = (int) date('n', $data['date']);
			if ($day == NULL)
				$day = (int) date('j', $data['date']);
			if ($type != 'round_list')
				$url_params .= '&round_list='.$data['id'];
		case 'map_loaded_list':
			if ($type != 'map_loaded_list')
				$url_params .= '&map_loaded_list='.$round_begin.'_'.$round_end;
		case 'day_list':
			if ($type != 'day_list')
				$url_params .= '&day_list='.date('Y_n_j', mktime(0, 0, 0, $month, $day, $year));
		case 'month_list':
			if ($type != 'month_list')
				$url_params .= '&month_list='.date('Y_n', mktime(0, 0, 0, $month, 1, $year));
		case 'year_list':
			if ($type != 'year_list')
				$url_params .= '&year_list='.$year;
			break;
		default:
			// nothing to do
			break;
	}
	return $url_params;
}


if (!isset($_GET['ajax_update'])) { // for HTML only
?><!DOCTYPE html>
<html>
<!-- Code by Mohamed RACHID -->
<head>
	<title><?php echo page_title; ?></title>
	<style type="text/css">
	<?php readfile(dirname(__FILE__).'/old_damagelog.css'); ?>
	.folder_close {
		background-image: url(data:image/png;base64,<?php echo base64_encode(file_get_contents(dirname(__FILE__).'/folder_close.png')); ?>);
		background-repeat: no-repeat;
		margin-top: 0px;
		margin-bottom: 0px;
		margin-left: 0px;
		margin-right: 0px;
		padding-top: 0px;
		padding-bottom: 0px;
		padding-left: 0px;
		padding-right: 0px;
		width: 16px;
		height: 16px;
		cursor: pointer;
	}
	.folder_open {
		background-image: url(data:image/png;base64,<?php echo base64_encode(file_get_contents(dirname(__FILE__).'/folder_open.png')); ?>);
		background-repeat: no-repeat;
		margin-top: 0px;
		margin-bottom: 0px;
		margin-left: 0px;
		margin-right: 0px;
		padding-top: 0px;
		padding-bottom: 0px;
		padding-left: 0px;
		padding-right: 0px;
		width: 16px;
		height: 16px;
		cursor: pointer;
	}
	</style>
</head>
<body class="content">


<div id="selection" class="selection">
	<?php
		if ($db_error) {
			printf('<b>MySQL connection failed:</b><br />%s</div></body></html>', mysqli_connect_error());
			die();
		}
	?>
	Please select a round to load.
	<?php
		$dates = array();
		$result = $db->query('SELECT MIN(date), MAX(date) FROM '.$db_config['table']);
		$result_row = $result->fetch_row();
		$dates['year_min'] = (int) date('Y', $result_row[0]);
		$dates['year_max'] = (int) date('Y', $result_row[1]);
		$result->free();
		unset($result, $result_row);
		
		for ($year=$dates['year_max']; $year>=$dates['year_min']; $year--) {
			if (IsEmptyDateRange(mktime(0,0,0,1,1,$year), mktime(0,0,0,1,1,$year+1))) {
				continue;
			}
			$url_params = '&year_list='.$year;
			?><table class="year_container">
				<tr>
					<td class="year_open_close" align="center" valign="top"><a class="year_open_close" href="<?php echo $_SERVER['SCRIPT_NAME'].'?static'.Complete_Permalink_URL_Params($url_params, NULL, $year, NULL, NULL, NULL, NULL); ?>" onclick="ChangeVisibleClass('year_open_close_<?php echo $year; ?>', ShowHideElt('year_list_<?php echo $year; ?>', '<?php echo $url_params; ?>'), 'folder_open', 'folder_close'); return false;"><div id="year_open_close_<?php echo $year; ?>" class="folder_close">&nbsp;&nbsp;</div></a></td>
					<td class="year_content">
						<span class="year_number"><?php echo $year; ?></span><br />
						<div class="year_list" id="year_list_<?php echo $year; ?>" style="display: none;">
							<!-- Not loaded yet. -->
						</div>
					</td>
				</tr>
			</table><?php
		}
	?>
</div>


<div id="main_page" class="main_page">
	<div class="roll_catogory" id="roll_catogory_role_list" onclick="ChangeVisibleClass(this, ShowHideElt('damagelog_info_content'), 'roll_catogory', 'rolled_catogory');">Player information</div>
	<div id="damagelog_info" class="damagelog_info"></div>
	<div id="damagelog_data" class="damagelog_data"></div>
</div>


<script type="text/javascript">
	function GetDomElt (EltId) {
		if (typeof(EltId) == "string")
			return document.getElementById(EltId); // arg is an id
		else
			return EltId; // arg is a DOM object
	}
	function EltIsVisible (EltId) {
		var Elt = GetDomElt(EltId);
		if (Elt.style.display == "none") // invisible
			return false;
		else
			return true;
	}
	function ShowHideElt (EltId, update_ajax_arg) {
		var Elt = GetDomElt(EltId);
		if (!EltIsVisible(Elt)) { // invisible
			if (update_ajax_arg != null)
				update_ajax(update_ajax_arg);
			else
				Elt.style.display = ""; // now visible
			return true;
		}
		else { // visible
			Elt.style.display = "none";
			return false; // now invisible
		}
	}
	function ChangeVisibleClass (EltId, IsVisible, VisibleClass, InvisibleClass) {
		// IsVisible can also be from another DOM object!
		var Elt = GetDomElt(EltId);
		if (IsVisible)
			Elt.className = VisibleClass;
		else
			Elt.className = InvisibleClass;
		return IsVisible
	}
</script>


<!-- BEGIN AJAX stuff: -->
<script type="text/javascript">
	<!--
	// http://fr.wikipedia.org/wiki/XMLHttpRequest#Cr.C3.A9ation_d.27un_objet_XMLHttpRequest
	// http://blog.pascal-martin.fr/post/Ajax-un-premier-appel-avec-XMLHttpRequest
	// http://www.siteduzero.com/tutoriel-3-557807-xmlhttprequest.html
	function createXhrObject () {
		if (window.XMLHttpRequest)
			return new XMLHttpRequest();
		if (window.ActiveXObject) {
			var names = [
				"Msxml2.XMLHTTP.6.0",
				"Msxml2.XMLHTTP.3.0",
				"Msxml2.XMLHTTP",
				"Microsoft.XMLHTTP"
			];
			for(var i in names) {
				try{ return new ActiveXObject(names[i]); }
				catch(e){}
			}
		}
		return null; // unsupported
	}
	// -->
</script>
<span style="display: none;" id="received_js_container"><script type="text/javascript" id="received_js"><?php
}


// BEGIN: AJAX answers or permalink autorun:
if (isset($_GET['year_list'])) {
	$year = (int) $_GET['year_list'];
	$dates = array();
	$result = $db->query('SELECT MIN(date), MAX(date) FROM '.$db_config['table'].' WHERE date >= '.mktime(0, 0, 0, 1, 1, $year).' AND date < '.mktime(0, 0, 0, 1, 1, $year+1));
	$result_row = $result->fetch_row();
	$dates['month_min'] = (int) date('n', $result_row[0]);
	$dates['month_max'] = (int) date('n', $result_row[1]);
	$result->free();
	unset($result, $result_row);
	
	$fullJSstring = '';
	for ($month=$dates['month_max']; $month>=$dates['month_min']; $month--) {
		if (IsEmptyDateRange(mktime(0,0,0,$month,1,$year), mktime(0,0,0,$month+1,1,$year))) {
			continue;
		}
		$month_timestamp = mktime(0, 0, 0, $month, 1, $year);
		$month_code = date('Y_n', $month_timestamp);
		$url_params = '&month_list='.$month_code;
		$fullJSstring .= escapeHTMLasJSstring(
		'<table class="month_container">
			<tr>
				<td class="month_open_close" align="center" valign="top"><a class="month_open_close" href="'.$_SERVER['SCRIPT_NAME'].'?static'.Complete_Permalink_URL_Params($url_params, NULL, $year, $month, NULL, NULL, NULL).'" onclick="ChangeVisibleClass(\'month_open_close_'.$month_code.'\', ShowHideElt(\'month_list_'.$month_code.'\', \''.$url_params.'\'), \'folder_open\', \'folder_close\'); return false;"><div id="month_open_close_'.$month_code.'" class="folder_close">&nbsp;&nbsp;</div></a></td>
				<td class="month_content">
					<span class="month_number">'.date('F Y', $month_timestamp).'</span><br />
					<div class="month_list" id="month_list_'.$month_code.'" style="display: none;">
						<!-- Not loaded yet. -->
					</div>
				</td>
			</tr>
		</table>');
	}
	echo 'document.getElementById(\'year_list_'.$year.'\').innerHTML=\''.$fullJSstring.'\';';
	echo 'document.getElementById(\'year_list_'.$year.'\').style.display="";';
	echo 'document.getElementById("year_open_close_'.$year.'").className = "folder_open";';
}
if (isset($_GET['month_list'])) {
	$year = explode('_', $_GET['month_list']);
	$month = (int) $year[1];
	$year = (int) $year[0];
	$dates = array();
	$result = $db->query('SELECT MIN(date), MAX(date) FROM '.$db_config['table'].' WHERE date >= '.mktime(0, 0, 0, $month, 1, $year).' AND date < '.mktime(0, 0, 0, $month+1, 1, $year));
	$result_row = $result->fetch_row();
	$dates['day_min'] = (int) date('j', $result_row[0]);
	$dates['day_max'] = (int) date('j', $result_row[1]);
	$result->free();
	unset($result, $result_row);
	
	$fullJSstring = '';
	for ($day=$dates['day_max']; $day>=$dates['day_min']; $day--) {
		if (IsEmptyDateRange(mktime(0,0,0,$month,$day,$year), mktime(0,0,0,$month,$day+1,$year))) {
			continue;
		}
		$day_timestamp = mktime(0, 0, 0, $month, $day, $year);
		$day_code = date('Y_n_j', $day_timestamp);
		$url_params = '&day_list='.$day_code;
		$fullJSstring .= escapeHTMLasJSstring(
		'<table class="day_container">
			<tr>
				<td class="day_open_close" align="center" valign="top"><a class="day_open_close" href="'.$_SERVER['SCRIPT_NAME'].'?static'.Complete_Permalink_URL_Params($url_params, NULL, $year, $month, $day, NULL, NULL).'" onclick="ChangeVisibleClass(\'day_open_close_'.$day_code.'\', ShowHideElt(\'day_list_'.$day_code.'\', \''.$url_params.'\'), \'folder_open\', \'folder_close\'); return false;"><div id="day_open_close_'.$day_code.'" class="folder_close">&nbsp;&nbsp;</div></a></td>
				<td class="day_content">
					<span class="day_number">'.date('F j Y', $day_timestamp).'</span><br />
					<div class="day_list" id="day_list_'.$day_code.'" style="display: none;">
						<!-- Not loaded yet. -->
					</div>
				</td>
			</tr>
		</table>');
	}
	$month_code = $year.'_'.$month;
	echo 'document.getElementById(\'month_list_'.$month_code.'\').innerHTML=\''.$fullJSstring.'\';';
	echo 'document.getElementById(\'month_list_'.$month_code.'\').style.display="";';
	echo 'document.getElementById("month_open_close_'.$month_code.'").className = "folder_open";';
}
if (isset($_GET['day_list'])) {
	$year = explode('_', $_GET['day_list']);
	$day = (int) $year[2];
	$month = (int) $year[1];
	$year = (int) $year[0];
	$result = $db->query('SELECT id, date, map, round FROM '.$db_config['table'].' WHERE date >= '.mktime(0, 0, 0, $month, $day, $year).' AND date < '.mktime(0, 0, 0, $month, $day+1, $year));
	$day_maps_loaded_all = array();
	while ($result_row = $result->fetch_assoc()) {
		$day_maps_loaded_all[] = $result_row;
	}
	$result->free();
	unset($result, $result_row);
	
	$day_maps_loaded = array();
	$last_map = '';
	$last_round = 0;
	$i = -1;
	$last_id = -1;
	foreach ($day_maps_loaded_all as $map_loaded) {
		if ($last_map != $map_loaded['map'] or $map_loaded['round'] == 1 or $map_loaded['round'] <= $last_round) {
			if ($i > -1) {
				$day_maps_loaded[$i]['id_end'] = $last_id;
			}
			$i++;
			$day_maps_loaded[$i] = array();
			$day_maps_loaded[$i]['map'] = $map_loaded['map'];
			$day_maps_loaded[$i]['date'] = $map_loaded['date'];
			$day_maps_loaded[$i]['id_begin'] = $map_loaded['id'];
		}
		$last_map = $map_loaded['map'];
		$last_round = $map_loaded['round'];
		$last_id = $map_loaded['id'];
	}
	if ($i > -1) {
		$day_maps_loaded[$i]['id_end'] = $last_id;
	}
	
	
	$fullJSstring = '';
	foreach (array_reverse($day_maps_loaded, true) as $map_loaded) {
		$map_loaded_code = $map_loaded['id_begin'].'_'.$map_loaded['id_end'];
		$url_params = '&map_loaded_list='.$map_loaded_code;
		$fullJSstring .= escapeHTMLasJSstring(
		'<table class="map_loaded_container">
			<tr>
				<td class="map_loaded_open_close" align="center" valign="top"><a class="map_loaded_open_close" href="'.$_SERVER['SCRIPT_NAME'].'?static'.Complete_Permalink_URL_Params($url_params, $map_loaded, $year, $month, $day, $map_loaded['id_begin'], $map_loaded['id_end']).'" onclick="ChangeVisibleClass(\'map_loaded_open_close_'.$map_loaded_code.'\', ShowHideElt(\'map_loaded_list_'.$map_loaded_code.'\', \''.$url_params.'\'), \'folder_open\', \'folder_close\'); return false;"><div id="map_loaded_open_close_'.$map_loaded_code.'" class="folder_close">&nbsp;&nbsp;</div></a></td>
				<td class="map_loaded_content">
					<span class="map_loaded_number">'.$map_loaded['map'].' ('.date('h:i A', $map_loaded['date']).')</span><br />
					<div class="map_loaded_list" id="map_loaded_list_'.$map_loaded_code.'" style="display: none;">
						<!-- Not loaded yet. -->
					</div>
				</td>
			</tr>
		</table>');
	}
	$day_code = $year.'_'.$month.'_'.$day;
	echo 'document.getElementById(\'day_list_'.$day_code.'\').innerHTML=\''.$fullJSstring.'\';';
	echo 'document.getElementById(\'day_list_'.$day_code.'\').style.display="";';
	echo 'document.getElementById("day_open_close_'.$day_code.'").className = "folder_open";';
}
if (isset($_GET['map_loaded_list'])) {
	$round_end = explode('_', $_GET['map_loaded_list']);
	$round_begin = (int) $round_end[0];
	$round_end = (int) $round_end[1];
	$result = $db->query('SELECT id, date, round FROM '.$db_config['table'].' WHERE id >= '.$round_begin.' AND id <= '.$round_end);
	$rounds = array();
	while ($result_row = $result->fetch_assoc()) {
		$rounds[] = $result_row;
	}
	$result->free();
	unset($result, $result_row);
	
	$fullJSstring = '';
	foreach (array_reverse($rounds, true) as $round) {
		$url_params = '&round_list='.$round['id'];
		$href = $_SERVER['SCRIPT_NAME'].'?static'.Complete_Permalink_URL_Params($url_params, $round, NULL, NULL, NULL, $round_begin, $round_end);
		$fullJSstring .= escapeHTMLasJSstring(
		'<table class="round_container">
			<tr>
				<td class="round_open_close" align="center" valign="top"></td>
				<td class="round_content">
					<a class="round_number" href="'.$href.'" onclick="update_ajax(\''.$url_params.'\'); history.pushState({},\''.escapeHTMLasJSstring(page_title).'\',\''.escapeHTMLasJSstring($href).'\'); return false;">Round '.$round['round'].' ('.date('h:i A', $round['date']).')</a>
				</td>
			</tr>
		</table>');
	}
	$map_loaded_code = $round_begin.'_'.$round_end;
	echo 'document.getElementById(\'map_loaded_list_'.$map_loaded_code.'\').innerHTML=\''.$fullJSstring.'\';';
	echo 'document.getElementById(\'map_loaded_list_'.$map_loaded_code.'\').style.display="";';
	echo 'document.getElementById("map_loaded_open_close_'.$map_loaded_code.'").className = "folder_open";';
	
}
if (isset($_GET['round_list'])) {
	$round = (int) $_GET['round_list'];
	$result = $db->query('SELECT date, map, round, UNCOMPRESS(damagelog) AS damagelog FROM '.$db_config['table'].' WHERE id = '.$round.' LIMIT 1');
	$round_info = $result->fetch_assoc();
	$result->free();
	unset($result);
	$round_info['damagelog'] = json_decode($round_info['damagelog'], true);
	
	function DisplayDamageEvent ($logrow, &$display_text) {
		global $ROLES;
		$text_color = 'black';
		switch ($logrow['type']) {
			case 'DMG':
				$display_text = sprintf('%s [%s] has damaged %s [%s] for %d HP with %s', htmlspecialchars($logrow['infos'][3], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][4]]), htmlspecialchars($logrow['infos'][1], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][2]]), $logrow['infos'][5], GetWeaponDisplayName($logrow['infos'][6]));
				if ($logrow['infos'][4] != $logrow['infos'][2]) {
					$text_color = '#000000';
				}
				else {
					$text_color = '#FF2323';
				}
				break;
			case 'KILL':
				if (isset($logrow['infos'][5])) {
					$display_text = sprintf('%s [%s] has killed %s [%s] with %s', htmlspecialchars($logrow['infos'][1], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][2]]), htmlspecialchars($logrow['infos'][3], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][4]]), GetWeaponDisplayName($logrow['infos'][5]));
					if ($logrow['infos'][4] != $logrow['infos'][2]) {
						$text_color = '#FF8100';
					}
					else {
						$text_color = '#FF2323';
					}
				}
				else { // suicide
					$display_text = sprintf('&lt;something/world&gt; has killed %s [%s]', htmlspecialchars($logrow['infos'][1], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][2]]));
					$text_color = '#1212DD';
				}
				break;
			case 'FD':
				if (isset($logrow['infos'][5])) {
					$display_text = sprintf('%s [%s] fell and lost %d HP', htmlspecialchars($logrow['infos'][1], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][2]]), htmlspecialchars($logrow['infos'][3], ENT_COMPAT | ENT_HTML401, 'UTF-8'));
					$text_color = '#000000';
				}
				else {
					$display_text = sprintf('%s [%s] fell and lost %d HP after being pushed by %s [%s]', htmlspecialchars($logrow['infos'][1], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][2]]), $logrow['infos'][3], htmlspecialchars($logrow['infos'][5], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][5]]));
					if ($logrow['infos'][5] != $logrow['infos'][2]) {
						$text_color = '#000000';
					}
					else {
						$text_color = '#FF2323';
					}
				}
				break;
			case 'DNA':
				$display_text = sprintf('%s [%s] has retrieved the DNA of %s [%s] from the body of %s', htmlspecialchars($logrow['infos'][1], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][2]]), htmlspecialchars($logrow['infos'][4], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][5]]), $logrow['infos'][7]);
				$text_color = '#00FF00';
				break;
			case 'WEP':
				$display_text = sprintf('%s [%s] bought %s', htmlspecialchars($logrow['infos'][1], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][2]]), GetWeaponDisplayName($logrow['infos'][5]));
				$text_color = '#810081';
				break;
			case 'NADE':
				$display_text = sprintf('%s [%s] threw %s', htmlspecialchars($logrow['infos'][1], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][2]]), GetWeaponDisplayName($logrow['infos'][3]));
				$text_color = '#008100';
				break;
			case 'MISC':
				switch ($logrow['infos'][1]) {
					case 1:
						if ($logrow['infos'][5]) {
							$status = 'enabled';
						}
						else {
							$status = 'disabled';
						}
						$display_text = sprintf('%s [%s] has %s his disguiser', htmlspecialchars($logrow['infos'][2], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][3]]), $status);
						break;
					case 2:
						$display_text = sprintf('%s [%s] has teleported', htmlspecialchars($logrow['infos'][2], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][3]]));
						break;
					case 3:
						$display_text = sprintf('%s [%s] is spamming their disguiser', htmlspecialchars($logrow['infos'][2], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][3]]));
						break;
					case 4:
						if ($logrow['infos'][6]) {
							$status = 'with';
						}
						else {
							$status = 'without';
						}
						$display_text = sprintf('%s [%s] has disarmed the C4 of %s %s success', htmlspecialchars($logrow['infos'][2], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][3]]), htmlspecialchars($logrow['infos'][5], ENT_COMPAT | ENT_HTML401, 'UTF-8'), $status);
						break;
					case 5:
						$display_text = sprintf('%s [%s] has destroyed the C4 of %s', htmlspecialchars($logrow['infos'][2], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][3]]), htmlspecialchars($logrow['infos'][5], ENT_COMPAT | ENT_HTML401, 'UTF-8'));
						break;
					case 6:
						$display_text = sprintf('%s [%s] has picked up the C4 of %s', htmlspecialchars($logrow['infos'][2], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][3]]), htmlspecialchars($logrow['infos'][5], ENT_COMPAT | ENT_HTML401, 'UTF-8'));
						break;
					case 7:
						$display_text = sprintf('%s [%s] planted or dropped a C4', htmlspecialchars($logrow['infos'][2], ENT_COMPAT | ENT_HTML401, 'UTF-8'), strtolower($ROLES[$logrow['infos'][3]]));
						break;
					default:
						$display_text = '[Unknown event]';
				}
				$text_color = '#00B5B5';
				break;
			default:
				$display_text = '<pre>'.htmlspecialchars(var_export($logrow['infos'], true), ENT_COMPAT | ENT_HTML401, 'UTF-8').'</pre>';
				break;
		}
		return $text_color;
	}
	
	$fullJSstring = escapeHTMLasJSstring(
	'<table width="100%" class="damagelog_data_header">
		<tr>
			<th class="damagelog_data_header" align="right">Date:</th>
			<td class="damagelog_data_header">'.date('l, F j Y', $round_info['date']).'</td>
			<th class="damagelog_data_header" align="right">Map:</th>
			<td class="damagelog_data_header">'.$round_info['map'].'</td>
			<th class="damagelog_data_header" align="right">Round:</th>
			<td class="damagelog_data_header">#'.$round_info['round'].', began at '.date('h:i:s A', $round_info['date']).'</td>
		</tr>
	</table>
	<table width="100%" class="damagelog_data_content">
		<tr>
			<th class="damagelog_data_content">Time</th>
			<th class="damagelog_data_content">Type</th>
			<th class="damagelog_data_content">Event</th>
		</tr>');
		foreach ($round_info['damagelog']['DamageTable'] as $logrow) {
			if (!is_array($logrow)) {
				if (is_string($logrow) and $logrow == 'empty')
					$logrow = 'Nothing happened during this round.';
				$fullJSstring .= escapeHTMLasJSstring(
				'<tr class="damagelog_data_content">
					<td class="damagelog_data_content" style="text-align: center;" colspan="3">'.$logrow.'</td>
				</tr>');
				break;
			}
			if ($logrow['time'] < 3600)
				$time_display = date('i:s', (int) $logrow['time']);
			else
				$time_display = date('G:i:s', (int) $logrow['time']);
			$text_color = DisplayDamageEvent($logrow, $display_text);
			$fullJSstring .= escapeHTMLasJSstring(
			'<tr class="damagelog_data_content" style="color: '.$text_color.';">
				<td class="damagelog_data_content" valign="top">'.$time_display.'</td>
				<td class="damagelog_data_content" valign="top">'.$logrow['type'].'</td>
				<td class="damagelog_data_content">'.$display_text.'</td>
			</tr>');
		}
		$fullJSstring .= escapeHTMLasJSstring(
	'</table>');
	// $fullJSstring .= escapeHTMLasJSstring('<pre>'.htmlspecialchars(var_export($round_info['damagelog'], true), ENT_COMPAT | ENT_HTML401, 'UTF-8').'</pre>');
	echo 'document.getElementById(\'damagelog_data\').innerHTML=\''.$fullJSstring.'\';';
	echo 'document.getElementById(\'damagelog_data\').style.display="";';
	
	$fullJSstring = escapeHTMLasJSstring(
	'<table width="100%" class="damagelog_info_content" id="damagelog_info_content">
		<tr>
			<th class="damagelog_info_content">Player</th>
			<th class="damagelog_info_content">SteamID</th>
			<th class="damagelog_info_content">Role</th>
		</tr>');
		foreach ($round_info['damagelog']['Infos'] as $nickname => $logrow) {
			$line_color = $ROLE_COLORS[$logrow[INFO_Role]];
			$fullJSstring .= escapeHTMLasJSstring(
			'<tr class="damagelog_info_content">
				<td class="damagelog_info_content">');
				if ($logrow[INFO_SteamID] != 'BOT')
					$fullJSstring .= escapeHTMLasJSstring('<a href="https://steamcommunity.com/profiles/'.$logrow[INFO_SteamID64].'/" target="_blank" class="info_profile_link">');
				else
					$fullJSstring .= escapeHTMLasJSstring('<a>');
				$fullJSstring .= escapeHTMLasJSstring('<font color="'.$line_color.'">'.htmlspecialchars($nickname, ENT_COMPAT | ENT_HTML401, 'UTF-8').'</font></a></td>
				<td class="damagelog_info_content"><font color="'.$line_color.'">'.$logrow[INFO_SteamID].'</font></td>
				<td class="damagelog_info_content"><font color="'.$line_color.'">'.$ROLES[$logrow[INFO_Role]].'</font></td>
			</tr>');
		}
		$fullJSstring .= escapeHTMLasJSstring(
	'</table>');
	echo 'document.getElementById(\'damagelog_info\').innerHTML=\''.$fullJSstring.'\';';
	echo 'document.getElementById(\'damagelog_info\').style.display="";';
	echo 'document.getElementById(\'roll_catogory_role_list\').className="roll_catogory";';
}
if (isset($_GET['ajax_update'])) {
	exit();
}
// END: AJAX answers or permalink autorun


$db->close();


?></script></span>
<script type="text/javascript">
	<!--
	function update_ajax (url_params) {
		var xhr = createXhrObject();
		if (xhr != null) {
			function update_req () {
				xhr.open('GET', './index.php?ajax_update=1'+url_params, true); // encodeURIComponent()
				xhr.onreadystatechange = function () {
					if (xhr.readyState == 4) {
						if (xhr.status == 200) {
							if (xhr.responseText != '') {
								var toremove = document.getElementById('received_js');
								toremove.parentNode.removeChild(toremove);
								var received_js = document.createElement('script');
								received_js.type = 'text/javascript';
								received_js.id = 'received_js';
								received_js.text = xhr.responseText;
								document.getElementById('received_js_container').appendChild(received_js);
							}
						}
					}
				};
				xhr.send(null);
			}
			update_req();
		}
	}
	// -->
</script>
<!-- END AJAX stuff -->


</body>
</html>