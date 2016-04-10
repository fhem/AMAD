<h3>AMAD</h3>
<ul>
  <u><b>AMAD - Automagic Android Device</b></u>
  <br>
  Dieses Modul liefert, <b><u>in Verbindung mit der Android APP Automagic</u></b>, diverse Informationen von Android Ger&auml;ten.
  Die AndroidAPP Automagic (welche nicht von mir stammt und 2.90 Euro kostet) funktioniert wie Tasker, ist aber bei weitem User freundlicher.
  <br>
  Mit etwas Einarbeitung k&ouml;nnen jegliche Informationen welche Automagic bereit stellt in FHEM angezeigt werden. Hierzu bedarf es lediglich eines eigenen Flows welcher seine Daten an die AMADCommBridge sendet. Das Modul gibt auch die M&ouml;glichkeit Androidger&auml;te zu steuern.
  <br>
  F&uuml;r all diese Aktionen und Informationen wird auf dem Androidger&auml;t "Automagic" und ein so genannter Flow ben&ouml;tigt. Die App ist &uuml;ber den Google PlayStore zu beziehen. Das ben&ouml;tigte Flowset bekommt man aus dem FHEM Verzeichnis.
  <br><br>
  <b>Wie genau verwendet man nun AMAD?</b>
  <ul>
    <li>man installiert die App "Automagic Premium" aus dem PlayStore oder die Testversion von <a href="https://automagic4android.com/de/testversion">hier</a></li>
    <li>dann installiert man das Flowset 74_AMADautomagicFlowset$VERSION.xml aus dem Ordner $INSTALLFHEM/FHEM/lib/ auf dem Androidger&auml;t. NOCH NICHT die Flows aktivieren</li>
  </ul>
  <br>
  Es mu&szlig; noch ein Device in FHEM anlegt werden.
  <br><br>
  <a name="AMADdefine"></a>
  <b>Define</b>
  <ul><br>
    <code>define &lt;name&gt; AMAD &lt;IP-ADRESSE&gt; &lt;WLANAP-SSID('s)&gt;</code>
    <br><br>
    Beispiel:
    <ul><br>
      <code>define WandTabletWohnzimmer AMAD 192.168.0.23 TuxNetAP,Opa@@Zu@@Hause</code><br>
    </ul>
    <br>
    Diese Anweisung erstellt zwei neues AMAD-Device im Raum AMAD.Der Parameter &lt;IP-ADRESSE&gt; legt die IP Adresse des Android Ger&auml;tes fest und der Parameter WLANAP-SSID die SSID Deines WLAN's. Es k&ouml;nnen mehrere SSID's mit angegeben werden, welche dann durch Komma getrennt sein m&uuml;ssen. Haben die SSID's Leerzeichen im Namen werde die Leerzeichen durch 2 @ aufgef&uuml;llt. Gibt es Androidger&auml;te welche nicht &uuml;ber WLAN sondern USB-Ethernet angeschlossen sind, ist die WLANAP-SSID mit "usb-ethernet" zu benennen<br>
    Das zweite Device ist die AMADCommBridge welche als Kommunikationsbr&uuml;cke vom Androidger&auml;t zu FHEM diehnt. !!!Comming Soon!!! Wer den Port &auml;ndern m&ouml;chte, kann dies &uuml;ber das Attribut "port" tun. Ihr solltet aber wissen was Ihr tut, da dieser Port im HTTP Request Trigger der beiden Flows eingestellt ist. Demzufolge mu&szlig; der Port dort auch ge&auml;ndert werden. Der Port f&uuml;r die Bridge kann ohne Probleme im Bridge Device mittels dem Attribut "port" ver&auml;ndert werden.
    <br>
    Der Port f&uuml;r die Bridge kann ohne Probleme im Bridge Device mittels dem Attribut "port" ver&auml;ndert werden.</b>
  </ul>
  <br><a name="AMADCommBridge"></a>
  <b>AMAD Communication Bridge</b>
  <ul>
    Beim ersten anlegen einer AMAD Deviceinstanz wird automatisch ein Ger&auml;t Namens AMADCommBridge im Raum AMAD mit angelegt. Dieses Ger&auml;t diehnt zur Kommunikation vom Androidger&auml;t zu FHEM ohne das zuvor eine Anfrage von FHEM aus ging. <b>Damit das Androidger&auml;t die IP von FHEM kennt, muss diese sofort nach dem anlegen der Bridge &uuml;ber den set Befehl in ein entsprechendes Reading in die Bridge  geschrieben werden. DAS IST SUPER WICHTIG UND F&Uuml;R DIE FUNKTION DER BRIDGE NOTWENDIG.</b><br>
    Hierf&uuml;r mu&szlig; folgender Befehl ausgef&uuml;hrt werden. <i>set AMADCommBridge fhemServerIP &lt;FHEM-IP&gt;.</i><br>
    Als zweites Reading kann <i>expertMode</i> gesetzen werden. Mit diesem Reading wird eine unmittelbare Komminikation mit FHEM erreicht ohne die Einschr&auml;nkung &uuml;ber ein
    Notify gehen zu m&uuml;ssen und nur reine set Befehle ausf&uuml;hren zu k&ouml;nnen.
  </ul><br>
  <b><u>NUN bitte die Flows AKTIVIEREN!!!</u></b><br>
  <br>
  <b><u>Fertig! Nach anlegen der Ger&auml;teinstanz und dem eintragen der fhemServerIP in der CommBridge sollten nach sp&auml;testens 15 Sekunden bereits die ersten Readings reinkommen. Nun wird alle 15 Sekunden probiert einen Status Request erfolgreich ab zu schlie&szlig;en. Wenn der Status sich &uuml;ber einen l&auml;ngeren Zeitraum nicht auf "activ" &auml;ndert, sollte man im Log nach eventuellen Fehlern suchen.</u></b>
  <br><br><br>
  <a name="AMADreadings"></a>
  <b>Readings</b>
  <ul>
    <li>airplanemode - Status des Flugmodus</li>
    <li>androidVersion - aktuell installierte Androidversion</li>
    <li>automagicState - Statusmeldungen von der AutomagicApp <b>(Voraussetzung Android >4.3). Ist Android gr&ouml;&szlig;er 4.3 vorhanden und im Reading steht "wird nicht unterst&uuml;tzt", mu&szlig; in den Androideinstellungen unter Ton und Benachrichtigungen -> Benachrichtigungszugriff ein Haken f&uuml;r Automagic gesetzt werden</b></li>
    <li>bluetooth - on/off, Bluetooth Status an oder aus</li>
    <li>checkActiveTask - Zustand einer zuvor definierten APP. 0=nicht aktiv oder nicht aktiv im Vordergrund, 1=aktiv im Vordergrund, <b>siehe Hinweis unten</b></li>
    <li>connectedBTdevices - eine Liste der verbundenen Ger&auml;t</li>
    <li>connectedBTdevicesMAC - eine Liste der MAC Adressen aller verbundender BT Ger&auml;te</li>
    <li>currentMusicAlbum - aktuell abgespieltes Musikalbum des verwendeten Mediaplayers</li>
    <li>currentMusicArtist - aktuell abgespielter Musikinterpret des verwendeten Mediaplayers</li>
    <li>currentMusicTrack - aktuell abgespielter Musiktitel des verwendeten Mediaplayers</li>
    <li>daydream - on/off, Daydream gestartet oder nicht</li>
    <li>deviceState - Status des Androidger&auml;tes. !!!Gibt nicht den tats&auml;chlichen Status des Ger&auml;tes wieder!!! deviceState muss von Hand selbst  gesetzt werden. (set DEVICE deviceState) z.B. &uuml;ber die Anwesenheitskontrolle.<br> Ist Offline gesetzt, k&ouml;nnen keine set Befehle abgesetzt werden.</li>
    <li>dockingState - undocked/docked Status ob sich das Ger&auml;t in einer Dockinstation befindet.</li>
    <li>flow_SetCommands - active/inactive, Status des SetCommands Flow</li>
    <li>flow_informations - active/inactive, Status des Informations Flow</li>
    <li>flowsetVersionAtDevice - aktuell installierte Flowsetversion auf dem Device</li>
    <li>intentRadioName - zuletzt gesrreamter Intent Radio Name</li>
    <li>intentRadioState - Status des IntentRadio Players</li>
    <li>keyguardSet - 0/1 Displaysperre gesetzt 0=nein 1=ja, bedeutet nicht das sie gerade aktiv ist</li>
    <li>lastSetCommandError - letzte Fehlermeldung vom set Befehl</li>
    <li>lastSetCommandState - letzter Status vom set Befehl, Befehl erfolgreich/nicht erfolgreich gesendet</li>
    <li>lastStatusRequestError - letzte Fehlermeldung vom statusRequest Befehl</li>
    <li>lastStatusRequestState - letzter Status vom statusRequest Befehl, Befehl erfolgreich/nicht erfolgreich gesendet</li>
    <li>nextAlarmDay - aktiver Alarmtag</li>
    <li>nextAlarmState - aktueller Status des <i>"Androidinternen"</i> Weckers</li>
    <li>nextAlarmTime - aktive Alarmzeit</li>
    <li>powerLevel - Status der Batterie in %</li>
    <li>powerPlugged - Netzteil angeschlossen? 0=NEIN, 1|2=JA</li>
    <li>screen - on locked/unlocked, off locked/unlocked gibt an ob der Bildschirm an oder aus ist und gleichzeitig gesperrt oder nicht gesperrt</li>
    <li>screenBrightness - Bildschirmhelligkeit von 0-255</li>
    <li>screenFullscreen - on/off, Vollbildmodus (An,Aus)</li>
    <li>screenOrientation - Landscape,Portrait, Bildschirmausrichtung (Horizontal,Vertikal)</li>
    <li>screenOrientationMode - auto/manual, Modus f&uuml;r die Ausrichtung (Automatisch, Manuell)</li>
    <li>state - aktueller Status</li>
    <li>volume - Media Lautst&auml;rkewert</li>
    <li>volumeNotification - Benachrichtigungs Lautst&auml;rke</li>
    <br>
    Beim Reading checkActivTask mu&szlig; zuvor der Packagename der zu pr&uuml;fenden App als Attribut <i>checkActiveTask</i> angegeben werden. Beispiel: <i>attr Nexus10Wohnzimmer
    checkActiveTask com.android.chrome</i> f&uuml;r den Chrome Browser.
    <br><br>
  </ul>
  <br><br>
  <a name="AMADset"></a>
  <b>Set</b>
  <ul>
    <li>activateVoiceInput - aktiviert die Spracheingabe</li>
    <li>bluetooth - on/off, aktiviert/deaktiviert Bluetooth</li>
    <li>clearNotificationBar - All,Automagic, l&ouml;scht alle Meldungen oder nur die Automagic Meldungen in der Statusleiste</li>
    <li>currentFlowsetUpdate - f&uuml;rt ein Flowsetupdate auf dem Device durch</li>
    <li>deviceState - online/offline, setzt den Device Status . <b>mehr Info unter Readings</b></li>
    <li>installFlowSource - installiert einen Flow auf dem Device, <u>das XML File muss unter /tmp/ liegen und die Endung xml haben</u>. <b>Bsp:</b> <i>set TabletWohnzimmer installFlowSource WlanUebwerwachen.xml</i></li>
    <li>mediaPlayer - play, stop, next, back  ,steuert den Standard Mediaplayer</li>
    <li>nextAlarmTime - setzt die Alarmzeit. gilt aber nur innerhalb der n&auml;chsten 24Std.</li>
    <li>notifySndFile - spielt die angegebene Mediadatei auf dem Androidger&auml;t ab. <b>Die aufzurufende Mediadatei mu&szlig; sich im Ordner /storage/emulated/0/Notifications/ befinden.</b></li>
    <li>screenBrightness - setzt die Bildschirmhelligkeit, von 0-255.</li>
    <li>screenMsg - versendet eine Bildschirmnachricht</li>
    <li>sendintent - sendet einen Intentstring <u>Bsp:</u><i> set $AMADDEVICE sendIntent org.smblott.intentradio.PLAY url http://stream.klassikradio.de/live/mp3-192/stream.klassikradio.de/play.m3u name Klassikradio</i>, der erste Befehl ist die Aktion und der zweite das Extra. Es k&ouml;nnen immer zwei Extras mitgegeben werden.</li>
    <li>statusRequest - Fordert einen neuen Statusreport beim Device an. Es k&ouml;nnen nicht von allen Readings per statusRequest die Daten geholt werden. Einige wenige geben nur bei Status&auml;nderung ihren Status wieder.</li>
    <li>timer - setzt einen Timer innerhalb der als Standard definierten ClockAPP auf dem Device. Es k&ouml;nnen nur Sekunden angegeben werden.</li>
    <li>ttsMsg - versendet eine Nachricht welche als Sprachnachricht ausgegeben wird</li>
    <li>vibrate - l&auml;sst das Androidger&auml;t vibrieren</li>
    <li>volume - setzt die Medialautst&auml;rke. Entweder die internen Lautsprecher oder sofern angeschlossen die Bluetoothlautsprecher und per Klinkenstecker angeschlossene Lautsprecher</li>
    <li>volumeNotification - setzt die Benachrichtigungslautst&auml;rke.</li>
  </ul>
  <br>
  <b>Set abh&auml;ngig von gesetzten Attributen</b>
  <ul>
    <li>changetoBtDevice - wechselt zu einem anderen Bluetooth Ger&auml;t. <b>Attribut setBluetoothDevice mu&szlig; gesetzt sein. Siehe Hinweis unten!</b></li>
    <li>openApp - &ouml;ffnet eine ausgew&auml;hlte App. <b>Attribut setOpenApp</b></li>
    <li>openURL - &ouml;ffnet eine URL im Standardbrowser, sofern kein anderer Browser &uuml;ber das <b>Attribut setOpenUrlBrowser</b> ausgew&auml;hlt wurde.<b> Bsp:</b><i> attr Tablet setOpenUrlBrowser de.ozerov.fully|de.ozerov.fully.MainActivity, das erste ist der Package Name und das zweite der Class Name</i></li>
    <li>screen - on/off/lock/unlock schaltet den Bildschirm ein/aus oder sperrt/entsperrt ihn, in den Automagic Einstellungen muss "Admin Funktion" gesetzt werden sonst funktioniert "Screen off" nicht. <b>Attribut setScreenOnForTimer</b> &auml;ndert die Zeit wie lange das Display an bleiben soll!</li>
    <li>screenFullscreen - on/off, (aktiviert/deaktiviert) den Vollbildmodus. <b>Attribut setFullscreen</b></li>
    <li>screenLock - Sperrt den Bildschirm mit Pinabfrage. <b>Attribut setScreenlockPIN - hier die Pin daf&uuml;r eingeben. Erlaubt sind nur Zahlen. Es m&uuml;&szlig;en mindestens 4, bis max 16 Zeichen verwendet werden.</b></li>
    <li>screenOrientation - Auto,Landscape,Portait,  aktiviert die Bildschirmausrichtung (Automatisch,Horizontal,Vertikal). <b>Attribut setScreenOrientation</b></li>
    <li>system - setzt Systembefehle ab (nur bei gerootetet Ger&auml;en). reboot,shutdown,airplanemodeON (kann nur aktiviert werden) <b>Attribut root</b>, in den Automagic Einstellungen muss "Root Funktion" gesetzt werden</li>
    <br>
    Um openApp verwenden zu k&ouml;nnen, muss als Attribut der Package Name der App angegeben werden.
    <br><br>
    Um zwischen Bluetoothger&auml;ten wechseln zu k&ouml;nnen, mu&szlig; das Attribut setBluetoothDevice mit folgender Syntax gesetzt werden. <b>attr &lt;DEVICE&gt; BTdeviceName1|MAC,BTDeviceName2|MAC</b> Es muss
    zwingend darauf geachtet werden das beim BTdeviceName kein Leerzeichen vorhanden ist. Am besten zusammen oder mit Unterstrich. Achtet bei der MAC darauf das Ihr wirklich nach jeder zweiten Zahl auch
    einen : drin habt<br>
    Beispiel: <i>attr Nexus10Wohnzimmer setBluetoothDevice Logitech_BT_Adapter|AB:12:CD:34:EF:32,Anker_A3565|GH:56:IJ:78:KL:76</i> 
  </ul>
  <br><br>
  <a name="AMADstate"></a>
  <b>state</b>
  <ul>
    <li>initialized - Ist der Status kurz nach einem define.</li>
    <li>active - die Ger&auml;teinstanz ist im aktiven Status.</li>
    <li>disabled - die Ger&auml;teinstanz wurde &uuml;ber das Attribut disable deaktiviert</li>
  </ul>
  <br><br><br>
  <u><b>Anwendungsbeispiele:</b></u>
  <ul><br>
    <a href="http://www.fhemwiki.de/wiki/AMAD#Anwendungsbeispiele">Hier verweise ich auf den gut gepflegten Wikieintrag</a>
  </ul>
  <br><br><br>
</ul>