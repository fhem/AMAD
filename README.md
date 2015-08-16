#AMADD - Automagic Android Device

Dieses Modul liefert, in Verbindung mit der Android APP Automagic, diverse Informationen von Android Geräten. Die AndroidAPP Automagic (welche nicht von mir stammt und 2.90Euro kostet) funktioniert wie Tasker, ist aber bei weitem User freundlicher. Im Auslieferiungszustand werden folgende Zustände dargestellt:

- Standardlautstärke
- Status des Androidgerätes - Online/Offline
- nächste Alarmzeit
- nächster Alarmtag
- Ladestatus - Netztei angeschlossen / nicht angeschlossen
- Batteriestatus in %
- Bildschirmhelligkeit
- Bildschirnstatus An/Aus
- Media Lautstärke des Lautsprechers am Gerät
- Media Lautstärke des Bluetooth Lautsprechers
- Zustand von Automagic auf dem Gerät


Als Extra können noch aktueller Titel, Interpret und Album des verwendeten Mediaplayers angezeigt werden. 
Mit etwas Einarbeitung können jegliche Informationen welche Automagic bereit stellt in FHEM angezeigt werden. Hierzu bedarf es lediglich einer kleinen Anpassung des "Information" Flows 

Das Modul gibt Dir auch die Möglichkeit Deine Androidgeräte zu steuern. So können folgende Aktionen durchgeführt werden.

- Medienlautstärke regeln
- nächste Alarmzeit setzen
- Bildschirmhelligkeit einstellen
- Bildschirm An/Aus machen
- Mediaplayer steuern (Play, Stop, nächster Titel, vorheriger Titel)
- eine URL im Browser öffnen
- eine Nachricht senden welche am Bildschirm angezeigt wird
- eine Nachricht senden welche angesagt wird (TTS)


Für all diese Aktionen und Informationen wird auf dem Androidgerät Automagic und ein so genannter Flow benötigt. Die App müßt Ihr Euch besorgen, die Flows bekommt Ihr von mir zusammen mit dem AMAD Modul. 

Wie genau verwendet man nun AMAD?

Installiert Euch die App "Automagic Premium" aus dem App Store oder die Testversion von hier
ladet Euch das AMAD Modul und die Flowfiles von GitHub runter
installiert die zwei Flows und aktiviert erstmal nur den "Information" Flow, eventuell bei den FlowUpdates mal schauen ob es was neueres gibt und den entsprechenden Flow auf dem Gerät löschen und den neuen Flow von GitHub installieren
kopiert die Moduldatei 74_AMAD.pm nach $FHEMPATH/FHEM. Geht auf die FHEM Frontendseite und gebt dort in der Kommandozeile reload 74_AMAD.pm ein


Nun müsst Ihr nur noch ein Device in FHEM anlegen. 

Define

define name AMAD ip-adresse port interval 

Beispiel:

define WandTabletWohnzimmer AMAD 192.168.0.23 8090 180

Diese Anweisung erstellt ein neues AMAD-Device. Die Parameter IP-ADRESSE und PORT legen die IP Adresse des Android Gerätes sowie den, in den Flows des Trigger HTTP Request, angegebenen Port fest.
INTERVAL ist der Zeitabstand in dem ein erneuter Informationsabruf stattfinden soll. Alle x Sekunden. Bei mir hat sich 180 gut bewährt, also alle 3 Minuten
Bitte gebt für sofortige Erfolge als Port 8090 ein, das ist der Port der in den mitgelieferten Automagic Flows als Trigger Port eingetragen ist.
Dieser kann später mit Erfahrung auch geändert werden


Fertig! Nach anlegen des Devices sollten bereits die ersten Readings reinkommen. 

Readings:

- defaultVolume - Lautstärkewert welcher über "set defaultVolume" gesetzt wurde.
- deviceState - Status des Androidgerätes, muss selbst mit setreading gesetzt werden z.B. über die Anwesenheitskontrolle.
  Ist Offline gesetzt, wird der Intervall zum Informationsabruf aus gesetzt.
- nextAlarmDay - aktiver Alarmtag
- nextAlarmTime - aktive Alarmzeit
- powerLevel - Status der Batterie in %
- powerPlugged - Netzteil angeschlossen? 0=NEIN, 2=JA
- screenBrightness - Bildschirmhelligkeit von 0-255
- volumeMusikBluetooth - Media Lautstärke von angeschlossenden Bluetooth Lautsprechern
- volumeMusikSpeaker - Media Lautstärke der internen Lautsprecher
- screen - Bildschirm An oderAus
- automagicState - Statusmeldungen von der AutomagicApp

Die Readings volumeMusikBluetooth und volumeMusikSpeaker spiegeln die jeweilige Medialautstärke der angeschlossenden Bluetoothlautsprechern oder der internen Lautsprecher wieder.
Sofern man die jeweiligen Lautstärken ausschließlich über den Set Befehl setzt, wird eine der beiden immer mit dem defaultVolume Reading über ein stimmen.

Die Readings "currentMusicAlbum", "currentMusicArtist", "currentMusicTrack" werden nicht vom Modul AMAD gesteuert, sondern ausschließlich vom Automagic Flow. Hierfür ist es notwendig das der Flow entsprechend Deiner Netzwerkumgebung und Deines Androidgerätes angepasst wird.
Öffne den Flow SetCommands und folge dem Strang welcher ganz ganz links aussen lang geht. Dieser trifft auf eine Raute. Die Raute symbolisiert eine Bedingung. Es wird gefragt, ob ein bestimmtes WLan Netz vorhanden ist. Tragt bitte hier Euren Router oder Access Point ein. Als nächstes folgt Ihr dem Strang weiter und trifft auf 3 Rechtecke.
In jedem der 3 Rechtecke ist ein Befehl zum setzen eines der drei Readings eingetragen. Ihr müsst lediglich in allen drein die IP Eures FHEM Servers eintragen, sowie den korrekte DeviceNamen welchen Ihr in FHEM für dieses Androidgerät angegeben habt.

Das Reading automagicState muss explizit aktiviert werden. Hierfür geht Ihr in den Flow Information und dann ganz nach rechts. Dort steht eine einsame Raute (Bedingung) ohne Anbuindung an das Rechteck mit der Pause. Drückt auf das Rechteck mit der Pause und zieht das Plus bis runter auf die Raute. Nun habt Ihr eine Verbindung. Ab der Android 5.x Version setzt Ihr unter Einstellungen:Ton&Benachrichtigungen:Benachrichtigungszugriff ein Haken bei Automagic. Leider kann ich nicht sagen wie es sich bei Versionen der 4.xer Reihe verhält.


Set:

- defaultVolume - setzt die Medialautstärke. Entweder die internen Lautsprecher oder sofern angeschlossen die Bluetoothlautsprecher
- deviceState - setzt den Device Status Online/Offline. Siehe Readings
- mediaPlayer - steuert den Standard Mediaplayer. play, stop, Titel zürück, Titel vor.
- nextAlarmTime - setzt die Alarmzeit. Geht aber nur innerhalb der nächsten 24Std.
- openURL - öffnet eine URL im Standardbrowser
- screen - setzt den Bildschirm auf AN oder AUS mit Sperre
- screenBrightness - setzt die Bildschirmhelligkeit, von 0-255
- screenMsg - versendet eine Bildschirmnachricht
- ttsMsg - versendet eine Nachricht welche als Sprachnachricht ausgegeben wird

Wenn Ihr das "set screenBrightness" verwenden wollt, muss eine kleine Anpassung im Flow SetCommand vorgenommen werden. Öffnet die Aktion (eines der Vierecke ganz ganz unten) SetzeSystemeinstellung:System und macht einen Haken bei "Ich habe die Einstellungen überprüft, ich weiss was ich tue".



Anwendungsbeispiele:

Ich habe die Ladegeräte für meine Androidgeräte an Funkschaltsteckdosen. ein DOIF schaltet bei unter 30% die Steckdose ein und bei über 90% wieder aus. Morgens lasse ich mich über mein Tablet im Schlafzimmer mit Musik wecken. Verwendet wird hierzu der wakeuptimer des RESIDENTS Modules. Das abspielen stoppe ich dann von Hand. Danach erfolgt noch eine Ansage wie das Wetter gerade ist und wird.
Mein 10" Tablet im Wohnzimmer ist Mediaplayer für das Wohnzimmer mit Bluetoothlautsprechern. Die Lautstärke wird automatisch runter gesetzt wenn die Fritzbox einen Anruf auf das Wohnzimmer Handgerät signalisiert.



Und zu guter letzt möchte ich mich noch bedanken.

Der größte Dank geht an meinen Mentor Andre (justme1968), er hat mir mit hilfreichen Tips geholfen Perlcode zu verstehen und Spaß am programmieren zu haben.

Auch möchte ich mich bei Jens bedanken (jensb) welcher mir ebenfalls mit hilfreichen Tips bei meinen aller ersten Gehversuchen beim Perlcode schreiben unterstützt hat.

So und nun noch ein besonderer Dank an pah (Prof. Dr. Peter Henning ), ohne seine Aussage "Keine Ahnung hatten wir alle mal, das ist keine Ausrede" hätte ich bestimmt nicht angefangen Interesse an Modulentwicklung zu zeigen :-)
