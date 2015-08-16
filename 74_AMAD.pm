################################################################
# $Id$
# Developed with Kate
#
#  (c) 2015 Copyright: Leon Gaultier (leongaultier at gmail dot com)
#  All rights reserved
#
#  This script is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  any later version.
#
#  The GNU General Public License can be found at
#  http://www.gnu.org/copyleft/gpl.html.
#  A copy is found in the textfile GPL.txt and important notices to the license
#  from the author is found in LICENSE.txt distributed with these scripts.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
################################################################

###### Version 0.3.6 ############




package main;

use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use HttpUtils;

sub AMAD_Initialize($) {

    my ($hash) = @_;

    $hash->{SetFn}     	= "AMAD_Set";
    $hash->{DefFn}      = "AMAD_Define";
    $hash->{UndefFn}    = "AMAD_Undef";
    $hash->{AttrFn}     = "AMAD_Attr";
    $hash->{ReadFn}     = "AMAD_Read";
    $hash->{AttrList} =
          "interval disable:1 "
         . $readingFnAttributes;
}

sub AMAD_Define($$) {

    my ( $hash, $def ) = @_;
    my @a = split( "[ \t][ \t]*", $def );

    return "too few parameters: define <name> AMAD <HOST> <PORT> <interval>" if ( @a != 5 );

    my $name    	= $a[0];
    my $host    	= $a[2];
    my $port		= $a[3];
    my $interval  	= 120;

    if(int(@a) == 5) {
        $interval = int($a[4]);
        if ($interval < 5 && $interval) {
           return "interval too small, please use something > 5 (sec), default is 120 (sec)";
        }
    }

    $hash->{HOST} 	= $host;
    $hash->{PORT} 	= $port;
    $hash->{INTERVAL} 	= $interval;

    Log3 $name, 3, "AMAD ($name) - defined with host $hash->{HOST} and interval $hash->{INTERVAL} (sec)";

    AMAD_GetUpdateLocal($hash);

    InternalTimer(gettimeofday()+$hash->{INTERVAL}, "AMAD_GetUpdateTimer", $hash, 0);
    
    $hash->{STATE} = "initialized";
    readingsSingleUpdate  ($hash,"deviceState","online",0);

    return undef;
}

sub AMAD_Undef($$) {
    my ($hash, $arg) = @_;

    RemoveInternalTimer($hash);

    return undef;
}

sub AMAD_Attr(@) {
    my ( $cmd, $name, $attrName, $attrVal) = @_;
    my $hash = $defs{$name};

    if ($attrName eq "disable") {
      if($cmd eq "set") {
	if($attrVal eq "0") {
	    RemoveInternalTimer($hash);
            InternalTimer(gettimeofday()+2, "AMAD_GetUpdateTimer", $hash, 0) if ($hash->{STATE} eq "disabled");
            $hash->{STATE}='active';
            Log3 $name, 3, "AMAD ($name) - enabled";
        } else {
            $hash->{STATE} = 'disabled';
            RemoveInternalTimer($hash);
	    Log3 $name, 3, "AMAD ($name) - disabled";
        }
      } elsif ($cmd eq "del") {
	  RemoveInternalTimer($hash);
          InternalTimer(gettimeofday()+2, "AMAD_GetUpdateTimer", $hash, 0) if ($hash->{STATE} eq "disabled");
          $hash->{STATE}='active';
          Log3 $name, 3, "AMAD ($name) - enabled";
	}
      } else {
	if($cmd eq "set") {
	  $attr{$name}{$attrName} = $attrVal;
          Log3 $name, 3, "AMAD ($name) - $attrName : $attrVal";
        } elsif ($cmd eq "del") {
      }
    }

    return undef;
}

sub AMAD_GetUpdateLocal($)
{
    my ($hash) = @_;
    my $name = $hash->{NAME};


    AMAD_RetrieveAutomagicInfo($hash);

    return 1;
}

sub AMAD_GetUpdateTimer($)
{
    my ($hash) = @_;
    my $name = $hash->{NAME};
 
    AMAD_RetrieveAutomagicInfo($hash) if (ReadingsVal($name,"deviceState","online") eq "online" && $hash->{STATE} eq "active" || $hash->{STATE} eq "error" || $hash->{STATE} eq "initialized");
  
    InternalTimer(gettimeofday()+$hash->{INTERVAL}, "AMAD_GetUpdateTimer", $hash, 1);
    Log3 $name, 4, "AMAD ($name) - Call AMAD_GetUpdateTimer";

    return 1;
}

sub AMAD_Set($$@)
{
    my ($hash, $name, $cmd, @val) = @_;
  
    my $list = "screenMsg"
	     . " ttsMsg"
	     . " defaultVolume:slider,0,1,15"
	     . " deviceState:online,offline"
	     . " mediaPlayer:play,stop,next,back"
	     . " screenBrightness:slider,0,1,255"
	     . " screen:on,off"
	     . " openURL"
	     . " nextAlarmTime:time";


  if (lc $cmd eq 'screenmsg'
      || lc $cmd eq 'ttsmsg'
      || lc $cmd eq 'defaultvolume'
      || lc $cmd eq 'mediaplayer'
      || lc $cmd eq 'devicestate'
      || lc $cmd eq 'screenbrightness'
      || lc $cmd eq 'screen'
      || lc $cmd eq 'openurl'
      || lc $cmd eq 'nextalarmtime') {
      
	  Log3 $name, 5, "AMAD ($name) - set $name $cmd ".join(" ", @val);
	  return AMAD_SelectSetCmd ($hash, $cmd, @val) if (@val);
  }

    return "Unknown argument $cmd, bearword as argument or wrong parameter(s), choose one of $list";
}

sub AMAD_RetrieveAutomagicInfo($)
{
    my ($hash) = @_;
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};
    my $port = $hash->{PORT};

    my $url = "http://" . $host . ":" . $port . "/fhem-amad/deviceInfo/";
  
    HttpUtils_NonblockingGet(
	{
	    url        => $url,
	    timeout    => 5,
	    #noshutdown => 0,
	    hash       => $hash,
	    method     => "GET",
	    doTrigger  => 1,
	    callback   => \&AMAD_RetrieveAutomagicInfoFinished,
	}
    );
    Log3 $name, 4, "AMAD ($name) - NonblockingGet get URL";
}

sub AMAD_RetrieveAutomagicInfoFinished($$$)
{
    my ( $param, $err, $data ) = @_;
    my $hash = $param->{hash};
    my $doTrigger = $param->{doTrigger};
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};

    Log3 $name, 4, "AMAD ($name) - AMAD_RetrieveAutomagicInfoFinished: calling Host: $host";

    if (defined($err)) {
      if ($err ne "")
      {
	  $hash->{STATE} = "error" if ($hash->{STATE} ne "initialized");
	  Log3 $name, 5, "AMAD ($name) - AMAD_RetrieveAutomagicInfoFinished: error while requesting AutomagicInfo: $err";
	  return;
      }
    }

    if($data eq "" and exists($param->{code}))
    {
	$hash->{STATE} = "error" if ($hash->{STATE} ne "initialized");
        Log3 $name, 5, "AMAD ($name) - AMAD_RetrieveAutomagicInfoFinished: received http code ".$param->{code}." without any data after requesting AMAD AutomagicInfo";
        return;
    }
    
    # $hash->{RETRIEVECACHE} = $data;		# zu Testzwecken
    
    my @valuestring = split('@@@@',  $data);
    my %buffer;
    foreach (@valuestring) {
	my @values = split('@@', $_);
	$buffer{$values[0]} = $values[1];
    }

    readingsBeginUpdate($hash);
    my $t;
    my $v;
    while (($t, $v) = each %buffer) {
	readingsBulkUpdate($hash, $t, $v) if (defined($v));
    }
    readingsEndUpdate($hash, 1);
    
    $hash->{STATE} = "active" if ($hash->{STATE} eq "error" || $hash->{STATE} eq "initialized");
    
    return undef;
}

sub AMAD_HTTP_POST($$)
{
    my ($hash, $url) = @_;
    my $name = $hash->{NAME};
    
    my $state = $hash->{STATE};
    
    if ($hash->{STATE} eq "initialized")
    {
	Log3 $name, 3, "AMAD ($name) - AMAD_HTTP_POST: set command only works if STATE active, please wait for next interval run";
	return "set command only works if STATE active, please wait for next interval run";
    }
    if ($hash->{STATE} eq "error")
    {
	Log3 $name, 3, "AMAD ($name) - AMAD_HTTP_POST: error while send Set command. Please check IP, PORT or wait for next interval run.";
	return "error while send Set command. Please check IP, PORT or wait for next interval run.";
    }
    
    $hash->{STATE} = "Send HTTP POST";
    
    HttpUtils_NonblockingGet(
	{
	    url        => $url,
	    timeout    => 5,
	    #noshutdown => 0,
	    method     => "POST",
	    doTrigger  => 1,
	}
    );
    Log3 $name, 4, "AMAD ($name) - Send HTTP POST with URL $url";

    $hash->{STATE} = $state;
    
    return undef;
}

sub AMAD_SelectSetCmd($$@)
{
    my ($hash, $cmd, @data) = @_;
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};
    my $port = $hash->{PORT};

    if (lc $cmd eq 'screenmsg') {
	my $msg = join(" ", @data);
	$msg =~ s/\s/%20/g;
	
	my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/screenMsg?message=$msg";
	Log3 $name, 4, "AMAD ($name) - Sub AMAD_SetScreenMsg";

	return AMAD_HTTP_POST ($hash,$url);
    }
    
    elsif (lc $cmd eq 'ttsmsg') {
	my $msg = join(" ", @data);
	$msg =~ s/\s/%20/g;
    
	my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/ttsMsg?message=$msg";
    
	return AMAD_HTTP_POST ($hash,$url);
    }
    
    elsif (lc $cmd eq 'defaultvolume') {
	my $vol = join(" ", @data);

	my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setVolume?volume=$vol";

	readingsSingleUpdate ($hash,$cmd,$vol,1);
	
	AMAD_GetUpdateLocal($hash);
	Log3 $name, 4, "AMAD ($name) - Starte Update GetUpdateLocal";
	return AMAD_HTTP_POST ($hash,$url);
    }
    
    elsif (lc $cmd eq 'mediaplayer') {
	my $btn = join(" ", @data);

	my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/mediaPlayer?button=$btn";
    
	return AMAD_HTTP_POST ($hash,$url);
    }
    
    elsif (lc $cmd eq 'devicestate') {
	my $v = join(" ", @data);

	readingsSingleUpdate ($hash,$cmd,$v,1);
      
	return undef;
    }
    
    elsif (lc $cmd eq 'screenbrightness') {
	my $bri = join(" ", @data);

	my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setBrightness?brightness=$bri";
    
	AMAD_GetUpdateLocal($hash);
	Log3 $name, 4, "AMAD ($name) - Starte Update GetUpdateLocal";
	return AMAD_HTTP_POST ($hash,$url);
    }
    
    elsif (lc $cmd eq 'screen') {
	my $mod = join(" ", @data);

	my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setScreenOnOff?screen=$mod";

	AMAD_GetUpdateLocal($hash);
	Log3 $name, 4, "AMAD ($name) - Starte Update GetUpdateLocal";
	return AMAD_HTTP_POST ($hash,$url);
    }
    
    elsif (lc $cmd eq 'openurl') {
	my $openurl = join(" ", @data);

	my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/openURL?url=$openurl";
    
	return AMAD_HTTP_POST ($hash,$url);
    }
    elsif (lc $cmd eq 'nextalarmtime') {
	my $alarmTime = join(" ", @data);
	my @alarm = split(":", $alarmTime);

	my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setAlarm?hour=".$alarm[0]."&minute=".$alarm[1];
    
	AMAD_GetUpdateLocal($hash);
	Log3 $name, 4, "AMAD ($name) - Starte Update GetUpdateLocal";
	return AMAD_HTTP_POST ($hash,$url);
    }

    return undef;
}


1;


=pod
=begin html
<a name="AMAD"></a>
<h3>AMAD - Automagic Android Device</h3>
<ul>
  At the moment no english documentation is available
</ul>
=end html
=begin html_DE
<a name="AMAD"></a>
<h3>AMAD - Automagic Android Device</h3>
<ul>
  Dieses Modul liefert, <b><u>in Verbindung mit der Android APP Automagic</u></b>, diverse Informationen von Android Ger&auml;ten.
  Die AndroidAPP Automagic (welche nicht von mir stammt und 2.90Euro kostet) funktioniert wie Tasker, ist aber bei weitem User freundlicher.
  Im Auslieferiungszustand werden folgende Zust&auml;nde dargestellt:
  <ul>
  <br>
    <li>Standardlautst&auml;rke</li>
    <li>Status des Androidger&auml;tes - Online/Offline</li>
    <li>n&auml;chste Alarmzeit</li>
    <li>n&auml;chster Alarmtag</li>
    <li>Ladestatus - Netztei angeschlossen / nicht angeschlossen</li>
    <li>Batteriestatus in %</li>
    <li>Bildschirmhelligkeit</li>
    <li>Bildschirnstatus An/Aus</li>
    <li>Media Lautst&auml;rke des Lautsprechers am Ger&auml;t</li>
    <li>Media Lautst&auml;rke des Bluetooth Lautsprechers</li>
    <li>Zustand von Automagic auf dem Ger&auml;t</li>
  </ul>
  <br><br>
  Als Extra k&ouml;nnen noch aktueller Titel, Interpret und Album des verwendeten Mediaplayers angezeigt werden.
  <br>
  Mit etwas Einarbeitung k&ouml;nnen jegliche Informationen welche Automagic bereit stellt in FHEM angezeigt werden. Hierzu bedarf es lediglich
  einer kleinen Anpassung des "Information" Flows
  <br>
  <br>
  Das Modul gibt Dir auch die M&ouml;glichkeit Deine Androidger&auml;te zu steuern. So k&ouml;nnen folgende Aktionen durchgef&uuml;hrt werden.
  <ul>
  <br>
    <li>Medienlautst&auml;rke regeln</li>
    <li>n&auml;chste Alarmzeit setzen</li>
    <li>Bildschirmhelligkeit einstellen</li>
    <li>Bildschirm An/Aus machen</li>
    <li>Mediaplayer steuern (Play, Stop, n&auml;chster Titel, vorheriger Titel)</li>
    <li>eine URL im Browser &ouml;ffnen</li>
    <li>eine Nachricht senden welche am Bildschirm angezeigt wird</li>
    <li>eine Nachricht senden welche <b>angesagt</b> wird (TTS)</li>
  </ul>
  <br><br> 
  F&uuml;r all diese Aktionen und Informationen wird auf dem Androidger&auml;t Automagic und ein so genannter Flow ben&ouml;tigt. Die App m&uuml;&szlig;t
  Ihr Euch besorgen, die Flows bekommt Ihr von mir zusammen mit dem AMAD Modul.
  <br><br>
  <b>Wie genau verwendet man nun AMAD?</b>
  <ul>
  <br>
    <li>Installiert Euch die App "Automagic Premium" aus dem App Store oder die Testversion von <a href="https://automagic4android.com/de/testversion">hier</a></li>
    <li>ladet Euch das AMAD Modul und die Flowfiles von <a href="https://github.com/LeonGaultier/fhem-AMAD">GitHub</a> runter</li>
    <li>installiert die zwei Flows und aktiviert erstmal nur den "Information" Flow, eventuell bei den <a href="https://github.com/LeonGaultier/fhem-AMAD/tree/master/Flow_Updates">
    FlowUpdates</a> mal schauen ob es was neueres gibt und den entsprechenden Flow auf dem Ger&auml;t l&ouml;schen und den neuen Flow von GitHub installieren</li>
    <li>kopiert die Moduldatei 74_AMAD.pm nach $FHEMPATH/FHEM. Geht auf die FHEM Frontendseite und gebt dort in der Kommandozeile <i>reload 74_AMAD.pm</i> ein</li>
  </ul>
  <br><br>
  Nun m&uuml;sst Ihr nur noch ein Device in FHEM anlegen.
  <br><br>
  <a name="AMADdefine"></a>
  <b>Define</b>
  <ul><br>
    <code>define &lt;name&gt; AMAD &lt;IP-ADRESSE&gt; &lt;PORT&gt; &lt;INTERVAL&gt;</code>
    <br><br>
    Beispiel:
    <ul><br>
      <code>define WandTabletWohnzimmer AMAD 192.168.0.23 8090 180</code><br>
    </ul>
    <br>
    Diese Anweisung erstellt ein neues AMAD-Device. Die Parameter IP-ADRESSE und PORT legen die IP Adresse des Android Ger&auml;tes
    sowie den, in den Flows des Trigger HTTP Request, angegebenen Port fest.<br>INTERVAL ist der Zeitabstand in dem ein erneuter Informationsabruf stattfinden soll. Alle x Sekunden.
    Bei mir hat sich 180 gut bew&auml;hrt, also alle 3 Minuten<br>
    <u><b>Bitte gebt f&uuml;r sofortige Erfolge als Port 8090 ein, das ist der Port der in den mitgelieferten Automagic Flows als Trigger Port eingetragen ist.<br>
    Dieser kann sp&auml;ter mit Erfahrung auch ge&auml;ndert werden</b></u>
  </ul>
  <br><br> 
  Fertig! Nach anlegen des Devices sollten bereits die ersten Readings reinkommen.
  <br><br>
  <a name="AMADreadings"></a>
  <b>Readings</b>
  <ul><br>
    <li>defaultVolume - Lautst&auml;rkewert welcher &uuml;ber "set defaultVolume" gesetzt wurde.</li>
    <li>deviceState - Status des Androidger&auml;tes, muss selbst mit setreading gesetzt werden z.B. &uuml;ber die Anwesenheitskontrolle.<br>
    Ist Offline gesetzt, wird der Intervall zum Informationsabruf aus gesetzt.</li>
    <li>nextAlarmDay - aktiver Alarmtag</li>
    <li>nextAlarmTime - aktive Alarmzeit</li>
    <li>powerLevel - Status der Batterie in %</li>
    <li>powerPlugged - Netzteil angeschlossen? 0=NEIN, 2=JA</li>
    <li>screenBrightness - Bildschirmhelligkeit von 0-255</li>
    <li>volumeMusikBluetooth - Media Lautst&auml;rke von angeschlossenden Bluetooth Lautsprechern</li>
    <li>volumeMusikSpeaker - Media Lautst&auml;rke der internen Lautsprecher</li>
    <li>screen - Bildschirm An oderAus</li>
    <li>automagicState - Statusmeldungen von der AutomagicApp</li>
    <br>
    Die Readings volumeMusikBluetooth und volumeMusikSpeaker spiegeln die jeweilige Medialautst&auml;rke der angeschlossenden Bluetoothlautsprechern oder der internen Lautsprecher wieder.<br>
    Sofern man die jeweiligen Lautst&auml;rken ausschlie&szlig;lich &uuml;ber den Set Befehl setzt, wird eine der beiden immer mit dem defaultVolume Reading &uuml;ber ein stimmen.<br><br>
    Die Readings "currentMusicAlbum", "currentMusicArtist", "currentMusicTrack" werden nicht vom Modul AMAD gesteuert, sondern ausschlie&szlig;lich vom Automagic Flow. Hierf&uuml;r ist es notwendig
    das der Flow entsprechend Deiner Netzwerkumgebung und Deines Androidger&auml;tes angepasst wird.<br>
    &Ouml;ffne den Flow SetCommands und folge dem Strang welcher ganz ganz links aussen lang geht. Dieser trifft auf eine Raute. Die Raute symbolisiert eine Bedingung. Es wird gefragt,
    ob ein bestimmtes WLan Netz vorhanden ist. Tragt bitte hier Euren Router oder Access Point ein. Als n&auml;chstes folgt Ihr dem Strang weiter und trifft auf 3 Rechtecke.<br>
    In jedem der 3 Rechtecke ist ein Befehl zum setzen eines der drei Readings eingetragen. Ihr m&uuml;sst lediglich in allen drein die IP Eures FHEM Servers eintragen, sowie den korrekte
    DeviceNamen welchen Ihr in FHEM f&uuml;r dieses Androidger&auml;t angegeben habt.<br><br>
    Das Reading automagicState muss explizit aktiviert werden. Hierf&uuml;r geht Ihr in den Flow Information und dann ganz nach rechts. Dort steht eine einsame Raute (Bedingung) ohne Anbuindung
    an das Rechteck mit der Pause. Dr&uuml;ckt auf das Rechteck mit der Pause und zieht das Plus bis runter auf die Raute. Nun habt Ihr eine Verbindung. Ab der Android 5.x Version setzt Ihr
    unter Einstellungen:Ton&Benachrichtigungen:Benachrichtigungszugriff ein Haken bei Automagic. Leider kann ich nicht sagen wie es sich bei Versionen der 4.xer Reihe verh&auml;lt.    
  </ul>
  <br><br>
  <a name="AMADset"></a>
  <b>Set</b>
  <ul><br>
    <li>defaultVolume - setzt die Medialautst&auml;rke. Entweder die internen Lautsprecher oder sofern angeschlossen die Bluetoothlautsprecher</li>
    <li>deviceState - setzt den Device Status Online/Offline. Siehe Readings</li>
    <li>mediaPlayer - steuert den Standard Mediaplayer. play, stop, Titel z&uuml;r&uuml;ck, Titel vor.</li>
    <li>nextAlarmTime - setzt die Alarmzeit. Geht aber nur innerhalb der n&auml;chsten 24Std.</li>
    <li>openURL - &ouml;ffnet eine URL im Standardbrowser</li>
    <li>screen - setzt den Bildschirm auf AN oder AUS mit Sperre</li>
    <li>screenBrightness - setzt die Bildschirmhelligkeit, von 0-255</li>
    <li>screenMsg - versendet eine Bildschirmnachricht</li>
    <li>ttsMsg - versendet eine Nachricht welche als Sprachnachricht ausgegeben wird</li>
    <br>
    Wenn Ihr das "set screenBrightness" verwenden wollt, muss eine kleine Anpassung im Flow SetCommand vorgenommen werden. &Ouml;ffnet die Aktion (eines der Vierecke ganz ganz unten)
    SetzeSystemeinstellung:System und macht einen Haken bei "Ich habe die Einstellungen &uuml;berpr&uuml;ft, ich weiss was ich tue".
  </ul>
  <br><br>
  <a name="AMADstate"></a>
  <b>STATE</b>
  <ul><br>
    Es gibt drei STATE Zust&auml;nde.
    <li>initialized - Ist der Status kurz nach einem define, ein Set Befehl ist hier noch nicht m&ouml;glich.</li>
    <li>error - beim letzten "get Information" gab es eine Fehlermeldung daher werden die Set Befehle ausgesetzt bis der n&auml;chsten "get Information" Durchlauf ohne Fehler beendet wird.</li>
    <li>activ - das Modul ist im aktiven Status und "Set Befehle" k&ouml;nnen gesetzt werden.</li>
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
  Modulentwicklung zu zeigen :-)</b>
</ul>
=end html_DE
=cut