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

###### Version 0.2.0 ############




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
    
    $hash->{STATE} = "active";
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
 
    AMAD_RetrieveAutomagicInfo($hash) if (ReadingsVal($name,"deviceState","online") eq "online" && $hash->{STATE} eq "active");
  
    InternalTimer(gettimeofday()+$hash->{INTERVAL}, "AMAD_GetUpdateTimer", $hash, 1);
    Log3 $name, 4, "AMAD ($name) - Call AMAD_GetUpdateTimer";

    return 1;
}

sub AMAD_Set($$@)
{
    my ($hash, $name, $cmd, @val) = @_;
  
    my $list = "screenMsg"
	     . " ttsMsg"
	     . " Volume:slider,0,1,15"
	     . " DeviceState:online,offline"
	     . " MediaPlayer:play,stop,next,back"
	     . " Brightness:slider,0,1,255"
	     . " Screen:on,off"
	     . " openURL";
  
  
    if (lc $cmd eq 'screenmsg') {
	    Log3 $name, 4, "AMAD ($name) - set $name $cmd ".join(" ", @val);
	    return AMAD_SetScreenMsg ($hash, @val) if (defined(@val));
    }
    elsif (lc $cmd eq 'ttsmsg') {
	    Log3 $name, 4, "AMAD ($name) - set $name $cmd ".join(" ", @val) if (defined(@val));
	    return AMAD_SetTtsMsg ($hash, @val);
    }
    elsif (lc $cmd eq 'volume') {
	    Log3 $name, 4, "AMAD ($name) - set $name $cmd ".join(" ", @val) if (defined(@val));
	    return AMAD_SetVolume ($hash, @val);
    }
    elsif (lc $cmd eq 'mediaplayer') {
	    Log3 $name, 4, "AMAD ($name) - set $name $cmd ".join(" ", @val) if (defined(@val));
	    return AMAD_SetMediaplayer ($hash, @val);
    }
    elsif (lc $cmd eq 'devicestate') {
	    Log3 $name, 4, "AMAD ($name) - set $name $cmd ".join(" ", @val) if (defined(@val));
	    my $v = join(" ", @val);

	    readingsSingleUpdate ($hash,$cmd,$v,1);
      
	    return undef;
    }
    elsif (lc $cmd eq 'brightness') {
	    Log3 $name, 4, "AMAD ($name) - set $name $cmd ".join(" ", @val) if (defined(@val));
	    return AMAD_SetBrightness ($hash, @val);
    }
    elsif (lc $cmd eq 'screen') {
	    Log3 $name, 4, "AMAD ($name) - set $name $cmd ".join(" ", @val) if (defined(@val));
	    return AMAD_SetScreen ($hash, @val);
    }
    elsif (lc $cmd eq 'openurl') {
	    Log3 $name, 4, "AMAD ($name) - set $name $cmd ".join(" ", @val) if (defined(@val));
	    return AMAD_SetOpenURL ($hash, @val);
    }
    

    return "Unknown argument $cmd, bearword as argument or wrong parameter(s), choose one of $list";
}

sub AMAD_RetrieveAutomagicInfo($)
{
    my ($hash) = @_;
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};
    my $port = $hash->{PORT};

    my $url = "http://" . $host . ":" . $port . "/automagic/deviceInfo";
  
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

    Log3 $name, 3, "AMAD ($name) - AMAD_RetrieveAutomagicInfoFinished: calling Host: $host";

    if (defined($err)) {
      if ($err ne "")
      {
	  Log3 $name, 4, "AMAD ($name) - AMAD_RetrieveAutomagicInfoFinished: error while requesting AutomagicInfo: $err";
	  return;
      }
    }

    if($data eq "" and exists($param->{code}))
    {
        Log3 $name, 4, "AMAD ($name) - AMAD_RetrieveAutomagicInfoFinished: received http code ".$param->{code}." without any data after requesting AMAD AutomagicInfo";
        return;
    }
    
    # $hash->{RETRIEVECACHE} = $data;		# zu Testzwecken
    
    my @valuestring = split('@@',  $data);
    my %buffer;
    foreach (@valuestring) {
	my @values = split(' ', $_);
	$buffer{$values[0]} = $values[1];
    }

    readingsBeginUpdate($hash);
    my $t;
    my $v;
    while (($t, $v) = each %buffer) {
	readingsBulkUpdate($hash, $t, $v) if (defined($v));
    }
    readingsEndUpdate($hash, 1);
    
    return undef;
}

sub AMAD_HTTP_POST($$)
{
    my ($hash, $url) = @_;
    my $name = $hash->{NAME};
    
    my $state = $hash->{STATE};
    
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

sub AMAD_SetScreenMsg($@)
{
    my ($hash, @data) = @_;
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};
    my $port = $hash->{PORT};

    my $msg = join(" ", @data);
    $msg =~ s/\s/%20/g;
    
    my $url = "http://" . $host . ":" . $port . "/automagic/screenMsg?message=$msg";
    Log3 $name, 4, "AMAD ($name) - Sub AMAD_SetScreenMsg";

    return AMAD_HTTP_POST ($hash,$url);
}

sub AMAD_SetTtsMsg($@) {
    my ($hash, @data) = @_;
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};
    my $port = $hash->{PORT};
    
    my $msg = join(" ", @data);
    $msg =~ s/\s/%20/g;
    
    my $url = "http://" . $host . ":" . $port . "/automagic/ttsMsg?message=$msg";
    
    return AMAD_HTTP_POST ($hash,$url);
}

sub AMAD_SetVolume($@) {
    my ($hash, @data) = @_;
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};
    my $port = $hash->{PORT};
    
    my $vol = join(" ", @data);

    my $url = "http://" . $host . ":" . $port . "/automagic/setVolume?volume=$vol";
    
    AMAD_GetUpdateLocal($hash);
    Log3 $name, 4, "AMAD ($name) - Starte Update GetUpdateLocal";
    return AMAD_HTTP_POST ($hash,$url);
}

sub AMAD_SetBrightness($@) {
    my ($hash, @data) = @_;
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};
    my $port = $hash->{PORT};
    
    my $bri = join(" ", @data);

    my $url = "http://" . $host . ":" . $port . "/automagic/setBrightness?brightness=$bri";
    
    AMAD_GetUpdateLocal($hash);
    Log3 $name, 4, "AMAD ($name) - Starte Update GetUpdateLocal";
    return AMAD_HTTP_POST ($hash,$url);
}

sub AMAD_SetScreen($@) {
    my ($hash, @data) = @_;
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};
    my $port = $hash->{PORT};
    
    my $mod = join(" ", @data);

    my $url = "http://" . $host . ":" . $port . "/automagic/setScreenOnOff?screen=$mod";
    
    return AMAD_HTTP_POST ($hash,$url);
}

sub AMAD_SetOpenURL($@) {
    my ($hash, @data) = @_;
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};
    my $port = $hash->{PORT};
    
    my $openurl = join(" ", @data);

    my $url = "http://" . $host . ":" . $port . "/automagic/openURL?url=$openurl";
    
    return AMAD_HTTP_POST ($hash,$url);
}

sub AMAD_SetMediaplayer($@) {
    my ($hash, @data) = @_;
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};
    my $port = $hash->{PORT};
    
    my $btn = join(" ", @data);

    my $url = "http://" . $host . ":" . $port . "/automagic/mediaPlayer?button=$btn";
    
    return AMAD_HTTP_POST ($hash,$url);
}

1;


=pod
=begin html_DE
<a name="AMAD"></a>
<h3>AMAD - Automagic Android Device</h3>
<ul>
  Dieses Modul liefert, <b><u>in Verbindung mit der Android APP Automagic</u></b>, diverse Informationen von Android Ger&auml;ten. 
  Weiterhin gibt es Dir die M&ouml;glichkeit diese zu steuern. Bis jetzt ist das &auml;ndern der Medialautst&auml;rke m&ouml;glich,
  sowie Play, Stop, Titel-Next, Titel-Back eines im Automagic-Flow ausgesuchten Players.<br>
  An Informationen k&ouml;nnen alle wiedergegeben werden, welche von Automagic als Action in Form einer Variable gesammelt und als 
  HTTP Respons Text zur&uuml;ck gegeben werden.
  F&uuml;r all diese Informationen/Aktionen ist ein sogenannter Flow in Automagic auf dem entsprechenden Android Ger&auml;t n&ouml;t.
  Als Trigger im Flow wird immer ein HTTP Request mit einem selbst vergebenen Port und einer angepassten URL verwendet. Dieser Port 
  muß der selbe sein welcher beim anölegen des Devices vergeben wurde!!
  <br><br>
  <a name="AMADdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; AMAD &lt;IP-ADRESSE&gt; &lt;PORT&gt; &lt;interval&gt;</code>
    <br><br>
    Beispiel:
    <ul>
      <code>define Nexus10Wohnzimmer AMAD 192.168.0.23 8080 180</code><br>
    </ul>
    <br>
    Diese Anweisung erstellt ein neues AMAD-Device. Die Parameter IP-ADRESSE und PORT legen die IP Adresse des Android Ger&aaml;tes
    sowie den unter Automagic im Trigger HTTP Request angegebenen Port fest.<br>
  </ul>
</ul>
=end html_DE
=cut
