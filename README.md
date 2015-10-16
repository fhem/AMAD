<h3>AMAD</h3>
<ul>
  <u><b>AMAD - Automagic Android Device</b></u>
  <br>
  Dieses Modul liefert, <b><u>in Verbindung mit der Android APP Automagic</u></b>, diverse Informationen von Android Ger&auml;ten.
  Die AndroidAPP Automagic (welche nicht von mir stammt und 2.90Euro kostet) funktioniert wie Tasker, ist aber bei weitem User freundlicher.
  Im Auslieferungszustand werden folgende Zust&auml;nde dargestellt:
  <ul>
    <li>Zustand von Automagic auf dem Ger&auml;t</li>
    <li>Bluetooth An/Aus</li>
    <li>Zustand einer definierten App (l&auml;uft aktiv im Vordergrund oder nicht?)</li>
    <li>verbundene Bluetoothger&auml;te, inklusive deren MAC Adresse</li>
    <li>aktuell abgespieltes Musikalbum des verwendeten Mediaplayers</li>
    <li>aktuell abgespielter Musikinterpret des verwendeten Mediaplayers</li>
    <li>aktuell abgespielter Musiktitel des verwendeten Mediaplayers</li>
    <li>Status des Androidger&auml;tes - Online/Offline</li>
    <li>n&auml;chster Alarmtag</li>
    <li>n&auml;chste Alarmzeit</li>
    <li>Batteriestatus in %</li>
    <li>Ladestatus - Netztei angeschlossen / nicht angeschlossen</li>
    <li>Bildschirmstatus An/Aus</li>
    <li>Bildschirmhelligkeit</li>
    <li>Vollbildmodus An/Aus</li>
    <li>Bildschirmausrichtung Auto/Landscape/Portrait</li>
    <li>Standardlautst&auml;rke</li>
    <li>Media Lautst&auml;rke des Lautsprechers am Ger&auml;t</li>
    <li>Media Lautst&auml;rke des Bluetooth Lautsprechers</li>
  </ul>
  <br>
  Mit etwas Einarbeitung k&ouml;nnen jegliche Informationen welche Automagic bereit stellt in FHEM angezeigt werden. Hierzu bedarf es lediglich
  einer kleinen Anpassung des "Informations" Flows
  <br><br>
  Das Modul gibt Dir auch die M&ouml;glichkeit Deine Androidger&auml;te zu steuern. So k&ouml;nnen folgende Aktionen durchgef&uuml;hrt werden.
  <ul>
    <li>Bluetooth Ein/Aus schalten</li>
    <li>zu einem bestimmten Bluetoothger&auml;t wechseln/verbinden</li>
    <li>Status des Ger&auml;tes (Online,Offline)</li>
    <li>Mediaplayer steuern (Play, Stop, n&auml;chster Titel, vorheriger Titel)</li>
    <li>n&auml;chste Alarmzeit setzen</li>
    <li>ein Benachrichtigungston abspielen (Notificationsound)</li>
    <li>eine App auf dem Ger&auml;t &ouml;ffnen</li>
    <li>eine URL im Browser &ouml;ffnen</li>
    <li>Bildschirm An/Aus machen</li>
    <li>Bildschirmhelligkeit einstellen</li>
    <li>Vollbildmodus einschalten</li>
    <li>eine Nachricht senden welche am Bildschirm angezeigt wird</li>
    <li>Bildschirmausrichtung einstellen (Auto,Landscape,Portrait)</li>
    <li>neuen Statusreport des Ger&auml;tes anfordern</li>
    <li>Systembefehle setzen (Reboot)</li>
    <li>eine Nachricht senden welche <b>angesagt</b> wird (TTS)</li>
    <li>Medienlautst&auml;rke regeln</li>  
  </ul>
  <br><br> 
  F&uuml;r all diese Aktionen und Informationen wird auf dem Androidger&auml;t Automagic und ein so genannter Flow ben&ouml;tigt. Die App m&uuml;&szlig;t
  Ihr Euch besorgen, die Flows bekommt Ihr von mir zusammen mit dem AMAD Modul.
  <br><br>
  <b>Wie genau verwendet man nun AMAD?</b>
  <ul>
    <li>installiert Euch die App "Automagic Premium" aus dem App Store oder die Testversion von <a href="https://automagic4android.com/de/testversion">hier</a></li>
    <li>installiert das Flowset 74_AMADautomagicFlows$VERSION.xml aus dem Ordner $INSTALLFHEM/FHEM/lib/ auf Eurem Androidger&auml;t und aktiviert erstmal nur den "Informations" Flow.</li>
  </ul>
  <br>
  Nun m&uuml;sst Ihr nur noch ein Device in FHEM anlegen.
  <br><br>
  <a name="AMADdefine"></a>
  <b>Define</b>
  <ul><br>
    <code>define &lt;name&gt; AMAD &lt;IP-ADRESSE&gt;</code>
    <br><br>
    Beispiel:
    <ul><br>
      <code>define WandTabletWohnzimmer AMAD 192.168.0.23</code><br>
    </ul>
    <br>
    Diese Anweisung erstellt ein neues AMAD-Device im Raum AMAD.Der Parameter &lt;IP-ADRESSE&lt; legt die IP Adresse des Android Ger&auml;tes fest.<br>
    Das Standard Abfrageinterval ist 180 Sekunden und kann &uuml;ber das Attribut intervall ge&auml;ndert werden. Wer den Port &auml;ndern m&ouml;chte, kann dies &uuml;ber
    das Attribut port tun. <b>Ihr solltet aber wissen was Ihr tut, da dieser Port im HTTP Response Trigger der beiden Flows eingestellt ist. Demzufolge mu&szlig; dieser dort
    auch ver&auml;dert werden.</b><br>
  </ul>
  <br><br> 
  <b><u>Fertig! Nach anlegen der Ger&auml;teinstanz sollten nach sp&auml;testens 3 Minuten bereits die ersten Readings reinkommen.</u></b>
  <br><br><br>
  <a name="AMADCommBridge"></a>
  <b>AMAD Communication Bridge</b>
  <ul>
    Beim ersten anlegen einer AMAD Deviceinstanz wird automatisch ein Ger&auml;t Namens AMADCommBridge im Raum AMAD angelegt. <b>BITTE NIEMALS DEN NAMEN DER BRIDGE &Auml;NDERN!!!</b> 
    Alle anderen Eigenschaften k&ouml;nnen ge&auml;ndert werden. Dieses Ger&auml;t diehnt zur Kommunikation
    vom Androidger&auml;t zu FHEM ohne das zuvor eine Anfrage von FHEM aus ging. <b>Damit das Androidger&auml;t die IP von FHEM kennt, muss diese sofort nach dem anlegen der Bridge
    &uuml;ber den set Befehl in ein entsprechendes Reading in die Bridge  geschrieben werden. DAS IST SUPER WICHTIG UND F&Uuml;R DIE FUNKTION DER BRIDGE NOTWENDIG.</b><br>
    Bitte f&uuml;hrt hierzu folgenden Befehl aus. <i>set AMADCommBridge fhemServerIP &lt;FHEM-IP&gt;.</i><br>
    Als zweites Reading k&ouml;nnt Ihr <i>expertMode</i>setzen. Mit diesem Reading wird eine unmittelbare Komminikation mit FHEM erreicht ohne die Einschr&auml;nkung &uuml;ber ein
    Notify gehen zu m&uuml;ssen und nur reine set Befehle ausf&uuml;hren zu k&ouml;nnen.
  </ul>
  <br><br>
  <a name="AMADreadings"></a>
  <b>Readings</b>
  <ul>
    <li>automagicState - Statusmeldungen von der AutomagicApp <b>(Voraussetzung Android >4.3). Wer ein Android >4.3 hat und im Reading steht "wird nicht unterst&uuml;tzt", mu&szlig; in den Androideinstellungen unter Ton und Benachrichtigungen -> Benachrichtigungszugriff ein Haken setzen f&uuml;r Automagic</b></li>
    <li>bluetooth on/off - ist auf dem Ger&auml;t Bluetooth an oder aus</li>
    <li>checkActiveTask - Zustand einer zuvor definierten APP. 0=nicht aktiv oder nicht aktiv im Vordergrund, 1=aktiv im Vordergrund, <b>siehe Hinweis unten</b></li>
    <li>connectedBTdevices - eine Liste der verbundenen Ger&auml;t</li>
    <li>connectedBTdevicesMAC - eine Liste der MAC Adressen aller verbundender BT Ger&auml;te</li>
    <li>currentMusicAlbum - aktuell abgespieltes Musikalbum des verwendeten Mediaplayers</li>
    <li>currentMusicArtist - aktuell abgespielter Musikinterpret des verwendeten Mediaplayers</li>
    <li>currentMusicTrack - aktuell abgespielter Musiktitel des verwendeten Mediaplayers</li>
    <li>deviceState - Status des Androidger&auml;tes, muss selbst mit setreading gesetzt werden z.B. &uuml;ber die Anwesenheitskontrolle.<br>
    Ist Offline gesetzt, wird der Intervall zum Informationsabruf aus gesetzt.</li>
    <li>flow_SetCommands active/inactive - gibt den Status des SetCommands Flow wieder</li>
    <li>flow_informations active/inactive - gibt den Status des Informations Flow wieder</li>
    <li>lastSetCommandError - letzte Fehlermeldung vom set Befehl</li>
    <li>lastSetCommandState - letzter Status vom set Befehl, Befehl erfolgreich/nicht erfolgreich gesendet</li>
    <li>lastStatusRequestError - letzte Fehlermeldung vom statusRequest Befehl</li>
    <li>lastStatusRequestState - letzter Status vom statusRequest Befehl, Befehl erfolgreich/nicht erfolgreich gesendet</li>
    <li>nextAlarmDay - aktiver Alarmtag</li>
    <li>nextAlarmTime - aktive Alarmzeit</li>
    <li>powerLevel - Status der Batterie in %</li>
    <li>powerPlugged - Netzteil angeschlossen? 0=NEIN, 1|2=JA</li>
    <li>screen - Bildschirm An oderAus</li>
    <li>screenBrightness - Bildschirmhelligkeit von 0-255</li>
    <li>screenFullscreen - Vollbildmodus (On,Off)</li>
    <li>screenOrientation - Bildschirmausrichtung (Auto,Landscape,Portrait)</li>
    <li>volume - Lautst&auml;rkewert welcher &uuml;ber "set volume" gesetzt wurde.</li>
    <li>volumeMusikBluetooth - Media Lautst&auml;rke von angeschlossenden Bluetooth Lautsprechern</li>
    <li>volumeMusikSpeaker - Media Lautst&auml;rke der internen Lautsprecher</li>
    <br>
    Die Readings volumeMusikBluetooth und volumeMusikSpeaker spiegeln die jeweilige Medialautst&auml;rke der angeschlossenden Bluetoothlautsprecher oder der internen Lautsprecher wieder.
    Sofern man die jeweiligen Lautst&auml;rken ausschlie&szlig;lich &uuml;ber den Set Befehl setzt, wird eine der beiden immer mit dem "volume" Reading &uuml;ber ein stimmen.<br><br>
    Beim Reading checkActivTask mu&szlig; zuvor der Packagename der zu pr&uuml;fenden App als Attribut <i>checkActiveTask</i> angegeben werden. Beispiel: <i>attr Nexus10Wohnzimmer
    checkActiveTask com.android.chrome</i> f&uuml;r den Chrome Browser.
    <br><br>
  </ul>
  <b>Eigene Readings im AMAD-Device erstellen</b>
  <ul>
    Es ist m&ouml;glich, aus beliebigen eigenen Automagic-Flows eigene Readings im AMAD-Device zu erstellen und zu f&uuml;llen. Die &Uuml;bertragung zum FHEM AMAD-Device erfolgt umgehend &uuml;ber die AMADCommBridge - daher sollte auf eine zu h&auml;ufige Aktualisierung verzichtet werden. Die Vorgehensweise in Automagic hierf&uuml;r ist folgende:
    <ul>
    <br>
      <li>zun&auml;chst erstellt man sich, soweit nicht bereits geschehen, einen Automagic-Flow der die Information, die in ein Reading &uuml;bernommen werden soll zur Verf&uuml;gung stellt</li>
      <li>diese Information speichert man nun mittels Automagic Action Script in eine globale Variable namens global_reading_<Readingname> (beim <Readingname> auf Gro&szlig;- und Kleinschreibung achten):</li>
    <br>
    <code>
      Beispiel: Das Reading Touch soll den Wert "ja" erhalten
      Action Script: global_reading_Touch="ja"
    </code>
    <br><br>
      <li>abschlie&szlig;end muss noch die &Uuml;bertragung des Wertes initiiert werden. Dies erfolgt, indem der Wert der Variable global_own_reading auf den Wert <Zeitstempel>_<Readingname> gesetzt wird (auch hier auf Gro&szlig;- und Kleinschreibung achten):</li>
    <br>
      <code>
	Beispiel: Das Reading Touch soll &uuml;bertragen werden<br>
	Action Script: global_own_reading="{getDate()}_Touch"<br>
	Hinweis: man kann auch beide Aktionen in ein Script packen:
	<ul>
	  global_reading_Touch="ja";global_own_reading="{getDate()}_Touch"
	</ul>
      </code>
      <br>
	<li>M&ouml;chte man nun als n&auml;chstes z.B. eine sofortige Benachrichtigung, wenn das Display des Tablets an- oder ausgeschaltet wird, k&ouml;nnte man sich Flows bauen, welche beim De-/Aktivieren des Display ausgef&uuml;hrt werden:</li>
      <br>
	<code>
	  Action Script beim Aktivieren des Displays: global_reading_Display="an";global_own_reading="{getDate()}_Display"
	  Action Script beim Deaktivieren des Displays: global_reading_Display="aus";global_own_reading="{getDate()}_Display"
	</code>
    </ul>
  </ul>
  <br><br>
  <a name="AMADset"></a>
  <b>Set</b>
  <ul>
    <li>bluetooth - Schaltet Bluetooth on/off</li>
    <li>clearNotificationBar - (All,Automagic) l&ouml;scht alle Meldungen oder nur die Automagic Meldungen in der Statusleiste</li>
    <li>deviceState - setzt den Device Status Online/Offline. Siehe Readings</li>
    <li>mediaPlayer - steuert den Standard Mediaplayer. play, stop, Titel z&uuml;r&uuml;ck, Titel vor.</li>
    <li>nextAlarmTime - setzt die Alarmzeit. Geht aber nur innerhalb der n&auml;chsten 24Std.</li>
    <li>notifySndFile - spielt die angegebende Mediadatei auf dem Androidger&auml;t ab. <b>Die aufzurufende Mediadatei mu&szlig; sich im Ordner /storage/emulated/0/Notifications/ befinden.</b></li>
    <li>openURL - &ouml;ffnet eine URL im Standardbrowser</li>
    <li>screen - setzt den Bildschirm on/off mit Sperre, in den Automagic Einstellungen muss "Admin Funktion" gesetzt werden sonst funktioniert "Screen off" nicht.</li>
    <li>screenMsg - versendet eine Bildschirmnachricht</li>
    <li>statusRequest - Fordert einen neuen Statusreport beim Device an</li>
    <li>ttsMsg - versendet eine Nachricht welche als Sprachnachricht ausgegeben wird</li>
    <li>volume - setzt die Medialautst&auml;rke. Entweder die internen Lautsprecher oder sofern angeschlossen die Bluetoothlautsprecher</li>
  </ul>
  <br>
  <b>Set abh&auml;ngig von gesetzten Attributen</b>
  <ul>
    <li>changetoBtDevice - wechselt zu einem anderen Bluetooth Ger&auml;t. <b>Attribut setBluetoothDevice mu&szlig; gesetzt sein. Siehe Hinweis unten!</b></li>
    <li>mediaPlayer - steuert den Standard Mediaplayer. play, stop, Titel z&uuml;r&uuml;ck, Titel vor. <b>Attribut fhemServerIP</b></li>
    <li>openApp - &ouml;ffnet eine ausgew&auml;hlte App. <b>Attribut setOpenApp</b></li>
    <li>screenBrightness - setzt die Bildschirmhelligkeit, von 0-255 <b>Attribut setScreenBrightness</b></li>
    Wenn Ihr das "set screenBrightness" verwenden wollt, muss eine kleine Anpassung im Flow SetCommands vorgenommen werden. &Ouml;ffnet die Aktion (eines der Vierecke ganz ganz unten)
    SetzeSystemeinstellung:System und macht einen Haken bei "Ich habe die Einstellungen &uuml;berpr&uuml;ft, ich weiss was ich tue".
    <li>screenFullscreen - Schaltet den Vollbildmodus on/off. <b>Attribut setFullscreen</b></li>
    <li>screenOrientation - Schaltet die Bildschirmausrichtung Auto/Landscape/Portait. <b>Attribut setScreenOrientation</b></li>
    <li>system - setzt Systembefehle ab (nur bei gerootetet Ger&auml;en). Reboot <b>Attribut root</b>, in den Automagic Einstellungen muss "Root Funktion" gesetzt werden</li>
    <br>
    Um openApp verwenden zu k&ouml;nnen, muss als Attribut ein, oder durch Komma getrennt, mehrere App Namen gesetzt werden. Der App Name ist frei w&auml;hlbar und nur zur Wiedererkennung notwendig.
    Der selbe App Name mu&szlig; im Flow SetCommands auf der linken Seite unterhalb der Raute Expression:"openApp" in einen der 5 Str&auml;nge (eine App pro Strang) in beide Rauten eingetragen werden. Danach wird
    in das Viereck die App ausgew&auml;lt welche durch den Attribut App Namen gestartet werden soll.<br><br>
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
    Ich habe die Ladeger&auml;te f&uuml;r meine Androidger&auml;te an Funkschaltsteckdosen. ein DOIF schaltet bei unter 30% die Steckdose ein und bei &uuml;ber 90% wieder aus. Morgens lasse ich mich
    &uuml;ber mein Tablet im Schlafzimmer mit Musik wecken. Verwendet wird hierzu der wakeuptimer des RESIDENTS Modules. Das abspielen stoppe ich dann von Hand. Danach erfolgt noch eine
    Ansage wie das Wetter gerade ist und wird.<br>
    Mein 10" Tablet im Wohnzimmer ist Mediaplayer f&uuml;r das Wohnzimmer mit Bluetoothlautsprechern. Die Lautst&auml;rke wird automatisch runter gesetzt wenn die Fritzbox einen Anruf auf das
    Wohnzimmer Handger&auml;t signalisiert.
  </ul>
  <br><br><br>
  <b><u>Und zu guter letzt m&ouml;chte ich mich noch bedanken.</u><br>
  Der gr&ouml;&szlig;te Dank geht an meinen Mentor Andre (justme1968), er hat mir mit hilfreichen Tips geholfen Perlcode zu verstehen und Spa&szlig; am programmieren zu haben.<br>
  Auch m&ouml;chte ich mich bei Jens bedanken (jensb) welcher mir ebenfalls mit hilfreichen Tips bei meinen aller ersten Gehversuchen beim Perlcode schreiben unterst&uuml;tzt hat.<br>
  So und nun noch ein besonderer Dank an pah (Prof. Dr. Peter Henning ), ohne seine Aussage "Keine Ahnung hatten wir alle mal, das ist keine Ausrede" h&auml;tte ich bestimmt nicht angefangen Interesse an
  Modulentwicklung zu zeigen :-)<br>
  Danke an J&uuml;rgen(ujaudio) der sich um die &Uuml;bersetzung der Commandref ins Englische gek&uuml;mmert hat und hoffentlich weiter k&uuml;mmern wird :-)<br>
  Danke auch an Ronny(RoBra81) f&uuml;r seine tollte Idee und Umsetzung von eigenen AMAD Readings aus externen Flows.</b>
</ul>