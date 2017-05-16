###############################################################################
# 
# Developed with Kate
#
#  (c) 2015-2017 Copyright: Marko Oldenburg (leongaultier at gmail dot com)
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
#
# $Id$
#
###############################################################################
##
##
## Das JSON Modul immer in einem eval aufrufen
# $data = eval{decode_json($data)};
#
# if($@){
#   Log3($SELF, 2, "$TYPE ($SELF) - error while request: $@");
#  
#   readingsSingleUpdate($hash, "state", "error", 1);
#
#   return;
# }
#
#
###### Möglicher Aufbau eines JSON Strings für die AMADCommBridge
#
#  {"amad": {"AMADDEVICE": "nexus7-Wohnzimmer","FHEMCMD": "setreading"},"payload": {"reading0": "value0","reading1": "value1","readingX": "valueX"}}
#
#
##
##
##
##



package main;


my $missingModul = "";

use strict;
use warnings;

use Encode qw(encode);
eval "use JSON;1" or $missingModul .= "JSON ";


my $modulversion = "3alpha9";
my $flowsetversion = "2.6.12";




# Declare functions
sub AMADDevice_Attr(@);
sub AMADDevice_checkDeviceState($);
sub AMADDevice_decrypt($);
sub AMADDevice_Define($$);
sub AMADDevice_encrypt($);
sub AMADDevice_GetUpdate($);
sub AMADDevice_Initialize($);
sub AMADDevice_WriteReadings($$);
sub AMADDevice_SelectSetCmd($$@);
sub AMADDevice_Set($$@);
sub AMADDevice_Undef($$);
sub AMADDevice_Parse($$);




sub AMADDevice_Initialize($) {

    my ($hash) = @_;
    
    $hash->{Match}          = '.*';

    $hash->{SetFn}      = "AMADDevice_Set";
    $hash->{DefFn}      = "AMADDevice_Define";
    $hash->{UndefFn}    = "AMADDevice_Undef";
    $hash->{AttrFn}     = "AMADDevice_Attr";
    $hash->{ParseFn}    = "AMADDevice_Parse";
    
    $hash->{AttrList}   = "setOpenApp ".
                "checkActiveTask ".
                "setFullscreen:0,1 ".
                "setScreenOrientation:0,1 ".
                "setScreenBrightness:noArg ".
                "setBluetoothDevice ".
                "setScreenlockPIN ".
                "setScreenOnForTimer ".
                "setOpenUrlBrowser ".
                "setNotifySndFilePath ".
                "setTtsMsgSpeed ".
                "setUserFlowState ".
                "setTtsMsgLang:de,en ".
                "setAPSSID ".
                "root:0,1 ".
                "port ".
                "disable:1 ".
                $readingFnAttributes;
    
    foreach my $d(sort keys %{$modules{AMADDevice}{defptr}}) {
    
        my $hash = $modules{AMADDevice}{defptr}{$d};
        $hash->{VERSIONMODUL}      = $modulversion;
        $hash->{VERSIONFLOWSET}    = $flowsetversion;
    }
}

sub AMADDevice_Define($$) {

    my ( $hash, $def ) = @_;
    my @a = split( "[ \t]+", $def );
    splice( @a, 1, 1 );
    my $iodev;
    my $i = 0;

    
    foreach my $param ( @a ) {
        if( $param =~ m/IODev=([^\s]*)/ ) {
        
            $iodev = $1;
            splice( @a, $i, 3 );
            last;
        }
        
        $i++;
    }
    
    return "too few parameters: define <name> AMADDevice <HOST-IP>" if( @a < 2 );
    return "Cannot define a HEOS device. Perl modul $missingModul is missing." if ( $missingModul );
    
    
    my ($name,$host)                            = @a;

    $hash->{HOST}                               = $host;
    $hash->{PORT}                               = 8090;
    $hash->{VERSIONMODUL}                       = $modulversion;
    $hash->{VERSIONFLOWSET}                     = $flowsetversion;
    $hash->{helper}{infoErrorCounter}           = 0 if( $hash->{HOST} );
    $hash->{helper}{setCmdErrorCounter}         = 0 if( $hash->{HOST} );
    $hash->{helper}{deviceStateErrorCounter}    = 0 if( $hash->{HOST} );


    AssignIoPort($hash,$iodev) if( !$hash->{IODev} );
    
    if(defined($hash->{IODev}->{NAME})) {
    
        Log3 $name, 3, "AMADDevice ($name) - I/O device is " . $hash->{IODev}->{NAME};
    
    } else {
    
        Log3 $name, 1, "AMADDevice ($name) - no I/O device";
    }
    
    
    $iodev = $hash->{IODev}->{NAME};
    
    my $code = $iodev ."-". $name if( defined($iodev) );
    my $d = $modules{AMADDevice}{defptr}{$code};
    
    return "AMADDevice device $name on AMADCommBridge $iodev already defined."
    if( defined($d) && $d->{IODev} == $hash->{IODev} && $d->{NAME} ne $name );

    Log3 $name, 3, "AMADDevice ($name) - defined with Code: $code on port $hash->{PORT}";

    $attr{$name}{room} = "AMAD" if( !defined( $attr{$name}{room} ) );
        
    readingsBeginUpdate($hash);
    readingsBulkUpdate( $hash, "state", "initialized");
    readingsBulkUpdate( $hash, "deviceState", "unknown");
    readingsEndUpdate($hash,1);
        

    if( $init_done ) {
        
        #AMADDevice_GetUpdate($hash);
            
    } else {
        
        #InternalTimer( gettimeofday()+30, "AMADDevice_GetUpdate", $hash, 0 ) if( ($hash->{HOST}) );
    }

    $modules{AMADDevice}{defptr}{$code} = $hash;

    return undef;
}

sub AMADDevice_Undef($$) {

    my ( $hash, $arg )  = @_;
    my $name            = $hash->{NAME};
    
    my $code = $hash->{IODev}->{NAME} ."-". $name if( defined($hash->{IODev}->{NAME}) );
    
    RemoveInternalTimer( $hash );
    delete $modules{AMADDevice}{defptr}{$code};

    return undef;
}

sub AMADDevice_Attr(@) {

    my ( $cmd, $name, $attrName, $attrVal ) = @_;
    my $hash = $defs{$name};
    
    my $orig = $attrVal;

    if( $attrName eq "disable" ) {
        if( $cmd eq "set" ) {
            if( $attrVal eq "0" ) {
            
                RemoveInternalTimer( $hash );
                InternalTimer( gettimeofday()+2, "AMADDevice_GetUpdate", $hash, 0 ) if( ReadingsVal( $hash->{NAME}, "state", 0 ) eq "disabled" );
                readingsSingleUpdate ( $hash, "state", "active", 1 );
                Log3 $name, 3, "AMADDevice ($name) - enabled";
            } else {
            
                readingsSingleUpdate ( $hash, "state", "disabled", 1 );
                RemoveInternalTimer( $hash );
                Log3 $name, 3, "AMADDevice ($name) - disabled";
            }
            
        } else {
        
            RemoveInternalTimer( $hash );
            InternalTimer( gettimeofday()+2, "AMADDevice_GetUpdate", $hash, 0 ) if( ReadingsVal( $hash->{NAME}, "state", 0 ) eq "disabled" );
            readingsSingleUpdate ( $hash, "state", "active", 1 );
            Log3 $name, 3, "AMADDevice ($name) - enabled";
        }
    }
    
    elsif( $attrName eq "checkActiveTask" ) {
        if( $cmd eq "del" ) {
            CommandDeleteReading( undef, "$name checkActiveTask" ); 
        }
        
        Log3 $name, 3, "AMADDevice ($name) - $cmd $attrName $attrVal and run statusRequest";
        RemoveInternalTimer( $hash );
        InternalTimer( gettimeofday(), "AMADDevice_GetUpdate", $hash, 0 )
    }
    
    elsif( $attrName eq "port" ) {
        if( $cmd eq "set" ) {
        
            $hash->{PORT} = $attrVal;
            Log3 $name, 3, "AMADDevice ($name) - set port to $attrVal";

            if( $hash->{BRIDGE} ) {
                delete $modules{AMADDevice}{defptr}{BRIDGE};
                TcpServer_Close( $hash );
                Log3 $name, 3, "AMADDevice ($name) - CommBridge Port changed. CommBridge are closed and new open!";
                
                AMADDevice_CommBridge_Open( $hash );
            }
        } else {
        
            $hash->{PORT} = 8090;
            Log3 $name, 3, "AMADDevice ($name) - set port to default";
    
            if( $hash->{BRIDGE} ) {
                delete $modules{AMADDevice}{defptr}{BRIDGE};
                TcpServer_Close( $hash );
                Log3 $name, 3, "AMADDevice ($name) - CommBridge Port changed. CommBridge are closed and new open!";
                
                AMADDevice_CommBridge_Open( $hash );
            }
        }
    }
    
    elsif( $attrName eq "setScreenlockPIN" ) {
        if( $cmd eq "set" && $attrVal ) {
        
            $attrVal = AMADDevice_encrypt($attrVal);
            
        } else {
        
            CommandDeleteReading( undef, "$name screenLock" );
        }
    }
    
    elsif( $attrName eq "setUserFlowState" ) {
        if( $cmd eq "del" ) {
        
            CommandDeleteReading( undef, "$name userFlowState" ); 
        }
        
        Log3 $name, 3, "AMADDevice ($name) - $cmd $attrName $attrVal and run statusRequest";
        RemoveInternalTimer( $hash );
        InternalTimer( gettimeofday(), "AMADDevice_GetUpdate", $hash, 0 )
    }
    
    
    
    if( $cmd eq "set" ) {
        if( $attrVal && $orig ne $attrVal ) {
        
            $attr{$name}{$attrName} = $attrVal;
            return $attrName ." set to ". $attrVal if( $init_done );
        }
    }
    
    return undef;
}

sub AMADDevice_GetUpdate($) {

    my ( $hash ) = @_;
    my $name = $hash->{NAME};
    my $bhash = $modules{AMADDevice}{defptr}{BRIDGE};
    my $bname = $bhash->{NAME};
    
    RemoveInternalTimer( $hash );

    if( $init_done && ( ReadingsVal( $name, "deviceState", "unknown" ) eq "unknown" or ReadingsVal( $name, "deviceState", "online" ) eq "online" ) && AttrVal( $name, "disable", 0 ) ne "1" && ReadingsVal( $bname, "fhemServerIP", "not set" ) ne "not set" ) {
    
        AMADDevice_statusRequest( $hash );
        AMADDevice_checkDeviceState( $hash );
        
    } else {

        Log3 $name, 4, "AMADDevice ($name) - GetUpdate, FHEM or Device not ready yet";
        Log3 $name, 3, "AMADDevice ($bname) - GetUpdate, Please set $bname fhemServerIP <IP-FHEM> NOW!" if( ReadingsVal( $bname, "fhemServerIP", "none" ) eq "none" );

        InternalTimer( gettimeofday()+15, "AMADDevice_GetUpdate", $hash, 0 );
    }
}

sub AMADDevice_WriteReadings($$) {

    my ( $hash, $decode_json ) = @_;
    
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};


    ############################
    #### schreiben der Readings
    readingsBeginUpdate($hash);

    Log3 $name, 5, "AMADDevice ($name) - Processing data: $decode_json";
    readingsSingleUpdate( $hash, "state", "active", 1) if( ReadingsVal( $name, "state", 0 ) ne "initialized" or ReadingsVal( $name, "state", 0 ) ne "active" );
    
    ### Event Readings
    my $t;
    my $v;
    
    
    while( ( $t, $v ) = each %{$decode_json->{payload}} ) {
        readingsBulkUpdate( $hash, $t, $v ) if( defined( $v ) );
        $v =~ s/\bnull\b/off/g if( ($t eq "nextAlarmDay" || $t eq "nextAlarmTime") && $v eq "null" );
        $v =~ s/\bnull\b//g;
    }
    
    readingsBulkUpdate( $hash, "deviceState", "offline" ) if( $decode_json->{payload}{airplanemode} && $decode_json->{payload}{airplanemode} eq "on" );
    readingsBulkUpdate( $hash, "deviceState", "online" ) if( $decode_json->{payload}{airplanemode} && $decode_json->{payload}{airplanemode} eq "off" );

    readingsBulkUpdate( $hash, "lastStatusRequestState", "statusRequest_done" );

    $hash->{helper}{infoErrorCounter} = 0;
    ### End Response Processing
    
    readingsBulkUpdate( $hash, "state", "active" ) if( ReadingsVal( $name, "state", 0 ) eq "initialized" );
    readingsEndUpdate( $hash, 1 );
    
    $hash->{helper}{deviceStateErrorCounter} = 0 if( $hash->{helper}{deviceStateErrorCounter} > 0 and ReadingsVal( $name, "deviceState", "offline") eq "online" );
    
    return undef;
}

sub AMADDevice_Set($$@) {
    
    my ( $hash, $name, $cmd, @val ) = @_;
    
    my $bhash = $modules{AMADDevice}{defptr}{BRIDGE};
    my $bname = $bhash->{NAME};
    
    if( $name ne "$bname" ) {
        my $apps = AttrVal( $name, "setOpenApp", "none" );
        my $btdev = AttrVal( $name, "setBluetoothDevice", "none" );
        my $activetask = AttrVal( $name, "setActiveTask", "none" );
  
        my $list = "";
        $list .= "screenMsg ";
        $list .= "ttsMsg ";
        $list .= "volume:slider,0,1,15 ";
        $list .= "mediaGoogleMusic:play/pause,stop,next,back " if( ReadingsVal( $bname, "fhemServerIP", "none" ) ne "none");
        $list .= "mediaAmazonMusic:play/pause,stop,next,back " if( ReadingsVal( $bname, "fhemServerIP", "none" ) ne "none");
        $list .= "mediaSpotifyMusic:play/pause,stop,next,back " if( ReadingsVal( $bname, "fhemServerIP", "none" ) ne "none");
        $list .= "mediaTuneinRadio:play/pause,stop,next,back " if( ReadingsVal( $bname, "fhemServerIP", "none" ) ne "none");
        $list .= "mediaAldiMusic:play/pause,stop,next,back " if( ReadingsVal( $bname, "fhemServerIP", "none" ) ne "none");
        $list .= "mediaYouTube:play/pause,stop,next,back " if( ReadingsVal( $bname, "fhemServerIP", "none" ) ne "none");
        $list .= "mediaVlcPlayer:play/pause,stop,next,back " if( ReadingsVal( $bname, "fhemServerIP", "none" ) ne "none");
        $list .= "mediaAudible:play/pause,stop,next,back " if( ReadingsVal( $bname, "fhemServerIP", "none" ) ne "none");
        $list .= "screenBrightness:slider,0,1,255 ";
        $list .= "screen:on,off,lock,unlock ";
        $list .= "screenOrientation:auto,landscape,portrait " if( AttrVal( $name, "setScreenOrientation", "0" ) eq "1" );
        $list .= "screenFullscreen:on,off " if( AttrVal( $name, "setFullscreen", "0" ) eq "1" );
        $list .= "openURL ";
        $list .= "openApp:$apps " if( AttrVal( $name, "setOpenApp", "none" ) ne "none" );
        $list .= "nextAlarmTime:time ";
        $list .= "timer:slider,1,1,60 ";
        $list .= "statusRequest:noArg ";
        $list .= "system:reboot,shutdown,airplanemodeON " if( AttrVal( $name, "root", "0" ) eq "1" );
        $list .= "bluetooth:on,off ";
        $list .= "notifySndFile ";
        $list .= "clearNotificationBar:All,Automagic ";
        $list .= "changetoBTDevice:$btdev " if( AttrVal( $name, "setBluetoothDevice", "none" ) ne "none" );
        $list .= "activateVoiceInput:noArg ";
        $list .= "volumeNotification:slider,0,1,7 ";
        $list .= "volumeRingSound:slider,0,1,7 ";
        $list .= "vibrate:noArg ";
        $list .= "sendIntent ";
        $list .= "openCall ";
        $list .= "closeCall:noArg ";
        $list .= "currentFlowsetUpdate:noArg ";
        $list .= "installFlowSource ";
        $list .= "doNotDisturb:never,always,alarmClockOnly,onlyImportant ";
        $list .= "userFlowState ";
        $list .= "sendSMS ";
        $list .= "startDaydream:noArg ";

        if( lc $cmd eq 'screenmsg'
            || lc $cmd eq 'ttsmsg'
            || lc $cmd eq 'volume'
            || lc $cmd eq 'mediagooglemusic'
            || lc $cmd eq 'mediaamazonmusic'
            || lc $cmd eq 'mediaspotifymusic'
            || lc $cmd eq 'mediatuneinradio'
            || lc $cmd eq 'mediaaldimusic'
            || lc $cmd eq 'mediayoutube'
            || lc $cmd eq 'mediavlcplayer'
            || lc $cmd eq 'mediaaudible'
            || lc $cmd eq 'screenbrightness'
            || lc $cmd eq 'screenorientation'
            || lc $cmd eq 'screenfullscreen'
            || lc $cmd eq 'screen'
            || lc $cmd eq 'openurl'
            || lc $cmd eq 'openapp'
            || lc $cmd eq 'nextalarmtime'
            || lc $cmd eq 'timer'
            || lc $cmd eq 'bluetooth'
            || lc $cmd eq 'system'
            || lc $cmd eq 'notifysndfile'
            || lc $cmd eq 'changetobtdevice'
            || lc $cmd eq 'clearnotificationbar'
            || lc $cmd eq 'activatevoiceinput'
            || lc $cmd eq 'volumenotification'
            || lc $cmd eq 'volumeringsound'
            || lc $cmd eq 'screenlock'
            || lc $cmd eq 'statusrequest'
            || lc $cmd eq 'sendsms'
            || lc $cmd eq 'sendintent'
            || lc $cmd eq 'currentflowsetupdate'
            || lc $cmd eq 'installflowsource'
            || lc $cmd eq 'opencall'
            || lc $cmd eq 'closecall'
            || lc $cmd eq 'donotdisturb'
            || lc $cmd eq 'userflowstate'
            || lc $cmd eq 'startdaydream'
            || lc $cmd eq 'vibrate') {

            Log3 $name, 5, "AMADDevice ($name) - set $name $cmd ".join(" ", @val);
                
            return AMADDevice_SelectSetCmd( $hash, $cmd, @val ) if( lc $cmd eq 'statusrequest' );
            return "set command only works if state not equal initialized" if( ReadingsVal( $hash->{NAME}, "state", 0 ) eq "initialized");
            return "Cannot set command, FHEM Device is disabled" if( AttrVal( $name, "disable", "0" ) eq "1" );
            
            return "Cannot set command, FHEM Device is unknown" if( ReadingsVal( $name, "deviceState", "online" ) eq "unknown" );
            return "Cannot set command, FHEM Device is offline" if( ReadingsVal( $name, "deviceState", "online" ) eq "offline" );
        
            return AMADDevice_SelectSetCmd( $hash, $cmd, @val ) if( (@val) or (lc $cmd eq 'activatevoiceinput') or (lc $cmd eq 'vibrate') or (lc $cmd eq 'currentflowsetupdate') or (lc $cmd eq 'closecall') or (lc $cmd eq 'startdaydream') );
        }

        return "Unknown argument $cmd, bearword as argument or wrong parameter(s), choose one of $list";
    
    } elsif( $modules{AMADDevice}{defptr}{BRIDGE} ) {
    
        my $list = "";
    
        ## set Befehle für die AMADDevice_CommBridge
        $list .= "expertMode:0,1 " if( $modules{AMADDevice}{defptr}{BRIDGE} );
        $list .= "fhemServerIP " if( $modules{AMADDevice}{defptr}{BRIDGE} );
        
        if( lc $cmd eq 'expertmode'
            || lc $cmd eq 'fhemserverip' ) {
            
            readingsSingleUpdate( $hash, $cmd, $val[0], 0 );
            
            return;
        }
        
        return "Unknown argument $cmd, bearword as argument or wrong parameter(s), choose one of $list";
    }
}

sub AMADDevice_SelectSetCmd($$@) {

    my ( $hash, $cmd, @data ) = @_;
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};
    my $port = $hash->{PORT};

    if( lc $cmd eq 'screenmsg' ) {
        my $msg = join( " ", @data );

        $msg =~ s/%/%25/g;
        $msg =~ s/\s/%20/g;

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/screenMsg?message=$msg";
        Log3 $name, 4, "AMADDevice ($name) - Sub AMADDevice_SetScreenMsg";
    
        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'ttsmsg' ) {

        my $msg     = join( " ", @data );
        my $speed   = AttrVal( $name, "setTtsMsgSpeed", "1.0" );
        my $lang    = AttrVal( $name, "setTtsMsgLang","de" );

        $msg =~ s/%/%25/g;
        $msg =~ s/\s/%20/g;    

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/ttsMsg?message=".$msg."&msgspeed=".$speed."&msglang=".$lang;
    
        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'userflowstate' ) {

        my $datas = join( " ", @data );
        my ($flow,$state) = split( ":", $datas);
        
        $flow          =~ s/\s/%20/g;    

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/flowState?flowstate=".$state."&flowname=".$flow;
    
        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'volume' ) {
    
        my $vol = join( " ", @data );

        if( $vol =~ /^\+(.*)/ or $vol =~ /^-(.*)/ ) {

            if( $vol =~ /^\+(.*)/ ) {
            
                $vol =~ s/^\+//g;
                $vol = ReadingsVal( $name, "volume", 15 ) + $vol;
            }
            
            elsif( $vol =~ /^-(.*)/ ) {
            
                $vol =~ s/^-//g;
                printf $vol;
                $vol = ReadingsVal( $name, "volume", 15 ) - $vol;
            }
        }

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setVolume?volume=$vol";

        return AMADDevice_HTTP_POST( $hash, $url );
    }
    
    elsif( lc $cmd eq 'volumenotification' ) {
    
        my $vol = join( " ", @data );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setNotifiVolume?notifivolume=$vol";

        return AMADDevice_HTTP_POST( $hash, $url );
    }
    
    elsif( lc $cmd eq 'volumeringsound' ) {
    
        my $vol = join( " ", @data );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setRingSoundVolume?ringsoundvolume=$vol";

        return AMADDevice_HTTP_POST( $hash, $url );
    }
    
    elsif( lc $cmd =~ /^media/ ) {
    
        my $btn = join( " ", @data );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/multimediaControl?mplayer=".$cmd."&button=".$btn;
    
        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'screenbrightness' ) {
    
        my $bri = join( " ", @data );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setBrightness?brightness=$bri";

        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'screen' ) {
    
        my $mod = join( " ", @data );
        my $scot = AttrVal( $name, "setScreenOnForTimer", undef );
        $scot = 60 if( !$scot );

        if ($mod eq "on" || $mod eq "off") {

            my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setScreenOnOff?screen=".$mod."&screenontime=".$scot if ($mod eq "on" || $mod eq "off");
            
            return AMADDevice_HTTP_POST( $hash,$url );
        }

        elsif ($mod eq "lock" || $mod eq "unlock") {

            return "Please set \"setScreenlockPIN\" Attribut first" if( AttrVal( $name, "setScreenlockPIN", "none" ) eq "none" );
            my $PIN = AttrVal( $name, "setScreenlockPIN", undef );
            $PIN = AMADDevice_decrypt($PIN);

            my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/screenlock?lockmod=".$mod."&lockPIN=".$PIN;

            return AMADDevice_HTTP_POST( $hash,$url );
        }
    }
    
    elsif( lc $cmd eq 'screenorientation' ) {
    
        my $mod = join( " ", @data );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setScreenOrientation?orientation=$mod";

        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'activatevoiceinput' ) {

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setvoicecmd";

        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'screenfullscreen' ) {
    
        my $mod = join( " ", @data );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setScreenFullscreen?fullscreen=$mod";

        readingsSingleUpdate( $hash, $cmd, $mod, 1 );

        return AMADDevice_HTTP_POST( $hash, $url );
    }
    
    elsif( lc $cmd eq 'openurl' ) {
    
        my $openurl = join( " ", @data );
        my $browser = AttrVal( $name, "setOpenUrlBrowser", "com.android.chrome|com.google.android.apps.chrome.Main" );
        my @browserapp = split( /\|/, $browser );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/openURL?url=".$openurl."&browserapp=".$browserapp[0]."&browserappclass=".$browserapp[1];
    
        return AMADDevice_HTTP_POST( $hash, $url );
    }
    
    elsif (lc $cmd eq 'nextalarmtime') {
    
        my $value = join( " ", @data );
        my @alarm = split( ":", $value );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setAlarm?hour=".$alarm[0]."&minute=".$alarm[1];

        return AMADDevice_HTTP_POST( $hash, $url );
    }
    
    elsif (lc $cmd eq 'timer') {
    
        my $timer = join( " ", @data );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setTimer?minute=$timer";

        return AMADDevice_HTTP_POST( $hash, $url );
    }
    
    elsif( lc $cmd eq 'statusrequest' ) {
    
        AMADDevice_statusRequest( $hash );
        return undef;
    }
    
    elsif( lc $cmd eq 'openapp' ) {
    
        my $app = join( " ", @data );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/openApp?app=$app";
    
        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'system' ) {
    
        my $systemcmd = join( " ", @data );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/systemcommand?syscmd=$systemcmd";

        readingsSingleUpdate( $hash, "airplanemode", "on", 1 ) if( $systemcmd eq "airplanemodeON" );
        readingsSingleUpdate( $hash, "deviceState", "offline", 1 ) if( $systemcmd eq "airplanemodeON" || $systemcmd eq "shutdown" );
    
        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'donotdisturb' ) {
    
        my $disturbmod = join( " ", @data );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/donotdisturb?disturbmod=$disturbmod";
    
        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'bluetooth' ) {
    
        my $mod = join( " ", @data );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setbluetooth?bluetooth=$mod";
    
        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'notifysndfile' ) {
    
        my $notify = join( " ", @data );
        my $filepath = AttrVal( $name, "setNotifySndFilePath", "/storage/emulated/0/Notifications/" );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/playnotifysnd?notifyfile=".$notify."&notifypath=".$filepath;
    
        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'changetobtdevice' ) {
    
        my $swToBtDevice = join( " ", @data );    
        my @swToBtMac = split( /\|/, $swToBtDevice );
        my $btDevices = AttrVal( $name, "setBluetoothDevice", "none" ) if( AttrVal( $name, "setBluetoothDevice", "none" ) ne "none" );
        my @btDevice = split( ',', $btDevices );
        my @btDeviceOne = split( /\|/, $btDevice[0] );
        my @btDeviceTwo = split( /\|/, $btDevice[1] );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setbtdevice?swToBtDeviceMac=".$swToBtMac[1]."&btDeviceOne=".$btDeviceOne[1]."&btDeviceTwo=".$btDeviceTwo[1];

        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'clearnotificationbar' ) {
    
        my $appname = join( " ", @data );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/clearnotificationbar?app=$appname";
    
        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'vibrate' ) {

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/setvibrate";

        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'sendintent' ) {
    
        my $intentstring = join( " ", @data );
        my ( $action, $exkey1, $exval1, $exkey2, $exval2 ) = split( "[ \t][ \t]*", $intentstring );
        $exkey1 = "" if( !$exkey1 );
        $exval1 = "" if( !$exval1 );
        $exkey2 = "" if( !$exkey2 );
        $exval2 = "" if( !$exval2 );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/sendIntent?action=".$action."&exkey1=".$exkey1."&exval1=".$exval1."&exkey2=".$exkey2."&exval2=".$exval2;

        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'installflowsource' ) {
    
        my $flowname = join( " ", @data );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/installFlow?flowname=$flowname";

        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'opencall' ) {
    
        my $string = join( " ", @data );
        my ($callnumber, $time) = split( "[ \t][ \t]*", $string );
        $time = "none" if( !$time );

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/openCall?callnumber=".$callnumber."&hanguptime=".$time;

        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'closecall' ) {

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/closeCall";

        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'startdaydream' ) {

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/startDaydream";

        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'currentflowsetupdate' ) {

        my $url = "http://" . $host . ":" . $port . "/fhem-amad/currentFlowsetUpdate";

        return AMADDevice_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'sendsms' ) {
        my $string = join( " ", @data );
        my ($smsmessage, $smsnumber) = split( "\\|", $string );
        
        $smsmessage =~ s/%/%25/g;
        $smsmessage =~ s/\s/%20/g;
    
        my $url = "http://" . $host . ":" . $port . "/fhem-amad/setCommands/sendSms?smsmessage=".$smsmessage."&smsnumber=".$smsnumber;

        return AMADDevice_HTTP_POST( $hash,$url );
    }

    return undef;
}

sub AMADDevice_Parse($$) {

    my ($io_hash,$json) = @_;
    my $name            = $io_hash->{NAME};
    my $amadDevice;
    my $decode_json;


    $decode_json        = eval{decode_json($json)};
    if($@){
        Log3 $name, 3, "AMADDevice ($name) - error while request: $@";
        #readingsSingleUpdate($hash, "state", "error", 1);
        return;
    }
    
    Log3 $name, 3, "AMADDevice ($name) - ParseFn was called";
    Log3 $name, 3, "AMADDevice ($name) - ParseFn was called, !!! JSON: $json";
    Log3 $name, 3, "AMADDevice ($name) - ParseFn was called, !!! AMAD: $decode_json->{amad}{AMADDEVICE}";


    $amadDevice         = $decode_json->{amad}{AMADDEVICE};
    my $code               = $io_hash->{NAME} ."-". $amadDevice;
        
    if( my $hash        = $modules{AMADDevice}{defptr}{$code} ) {        
        my $name        = $hash->{NAME};
                        
        AMADDevice_WriteReadings($hash,$decode_json);
        Log3 $name, 4, "AMADDevice ($name) - find logical device: $hash->{NAME}";
                        
        return $hash->{NAME};
            
    } else {

        return "UNDEFINED $amadDevice AMADDevice $decode_json->{payload}{'DEVICE-IP'} IODev=$name";
    }
}


##################################
##################################
#### my little helpers ###########
sub AMADDevice_checkDeviceState($) {

    my ( $hash ) = @_;
    my $name = $hash->{NAME};

    Log3 $name, 4, "AMADDevice ($name) - AMADDevice_checkDeviceState: run Check";

    RemoveInternalTimer( $hash );
    
    if( ReadingsAge( $name, "deviceState", 90 ) > 90 ) {
    
        AMADDevice_statusRequest( $hash ) if( $hash->{helper}{deviceStateErrorCounter} == 0 );
        readingsSingleUpdate( $hash, "deviceState", "offline", 1 ) if( ReadingsAge( $name, "deviceState", 180) > 180 and $hash->{helper}{deviceStateErrorCounter} > 0 );
        $hash->{helper}{deviceStateErrorCounter} = ( $hash->{helper}{deviceStateErrorCounter} + 1 );
    }
    
    InternalTimer( gettimeofday()+90, "AMADDevice_checkDeviceState", $hash, 0 );
    
    Log3 $name, 4, "AMADDevice ($name) - AMADDevice_checkDeviceState: set new Timer";
}

sub AMADDevice_encrypt($) {

    my ($decodedPIN) = @_;
    my $key = getUniqueId();
    my $encodedPIN;
    
    return $decodedPIN if( $decodedPIN =~ /^crypt:(.*)/ );

    for my $char (split //, $decodedPIN) {
        my $encode = chop($key);
        $encodedPIN .= sprintf("%.2x",ord($char)^ord($encode));
        $key = $encode.$key;
    }
    
    return 'crypt:'. $encodedPIN;
}

sub AMADDevice_decrypt($) {

    my ($encodedPIN) = @_;
    my $key = getUniqueId();
    my $decodedPIN;

    $encodedPIN = $1 if( $encodedPIN =~ /^crypt:(.*)/ );

    for my $char (map { pack('C', hex($_)) } ($encodedPIN =~ /(..)/g)) {
        my $decode = chop($key);
        $decodedPIN .= chr(ord($char)^ord($decode));
        $key = $decode.$key;
    }

    return $decodedPIN;
}




1;

=pod

=item device
=item summary    Integrates Android devices into FHEM and displays several settings.
=item summary_DE Integriert Android-Geräte in FHEM und zeigt verschiedene Einstellungen an.

=begin html

<a name="AMADDevice"></a>
<h3>AMADDevice</h3>
<ul>
  <u><b>AMADDevice - Automagic Android Device</b></u>
  <br>
  This module integrates Android devices into FHEM and displays several settings <b><u>using the Android app "Automagic"</u></b>.
  Automagic is comparable to the "Tasker" app for automating tasks and configuration settings. But Automagic is more user-friendly. The "Automagic Premium" app currently costs EUR 2.90.
  <br>
  Any information retrievable by Automagic can be displayed in FHEM by this module. Just define your own Automagic-"flow" and send the data to the AMADDeviceCommBridge. One even can control several actions on Android devices.
  <br>
  To be able to make use of all these functions the Automagic app and additional flows need to be installed on the Android device. The flows can be retrieved from the FHEM directory, the app can be bought in Google Play Store.
  <br><br>
  <b>How to use AMADDevice?</b>
  <ul>
    <li>install the "Automagic Premium" app from the Google Play store.</li>
    <li>install the flowset 74_AMADDeviceautomagicFlowset$VERSION.xml from the directory $INSTALLFHEM/FHEM/lib/ on your Android device and activate.</li>
  </ul>
  <br>
  Now you need to define a device in FHEM.
  <br><br>
  <a name="AMADDevicedefine"></a>
  <b>Define</b>
  <ul><br>
    <code>define &lt;name&gt; AMADDevice &lt;IP-ADDRESS&gt;</code>
    <br><br>
    Example:
    <ul><br>
      <code>define WandTabletWohnzimmer AMADDevice 192.168.0.23</code><br>
    </ul>
    <br>
    With this command two new AMADDevice devices in a room called AMADDevice are created. The parameter &lt;IP-ADDRESS&lt; defines the IP address of your Android device. The second device created is the AMADDeviceCommBridge which serves as a communication device from each Android device to FHEM.<br>
    !!!Coming Soon!!! The communication port of each AMADDevice device may be set by the definition of the "port" attribute. <b>One needs background knowledge of Automagic and HTTP requests as this port will be set in the HTTP request trigger of both flows, therefore the port also needs to be set there.
    <br>
    The communication port of the AMADDeviceCommBridge device can easily be changed within the attribut "port".</b>
  </ul>
  <br><a name="AMADDeviceCommBridge"></a>
  <b>AMADDevice Communication Bridge</b>
  <ul>
    Creating your first AMADDevice device automatically creates the AMADDeviceCommBridge device in the room AMADDevice. With the help  of the AMADDeviceCommBridge any Android device communicates initially to FHEM.<b>To make the IP addresse of the FHEM server known to the Android device, the FHEM server IP address needs to be configured in the AMADDeviceCommBridge. WITHOUT THIS STEP THE AMADDeviceCommBridge WILL NOT WORK PROPERLY.</b><br>
    Please us the following command for configuration of the FHEM server IP address in the AMADDeviceCommBridge: <i>set AMADDeviceCommBridge fhemServerIP &lt;FHEM-IP&gt;.</i><br>
    Additionally the <i>expertMode</i> may be configured. By this setting a direct communication with FHEM will be established without the restriction of needing to make use of a notify to execute set commands.
  </ul><br>
  <br>
  <b><u>You are finished now! After 15 seconds latest the readings of your AMADDevice Android device should be updated. Consequently each 15 seconds a status request will be sent. If the state of your AMADDevice Android device does not change to "active" over a longer period of time one should take a look into the log file for error messages.</u></b>
  <br><br><br>
  <a name="AMADDevicereadings"></a>
  <b>Readings</b>
  <ul>
    <li>airplanemode - on/off, state of the aeroplane mode</li>
    <li>androidVersion - currently installed version of Android</li>
    <li>automagicState - state of the Automagic App <b>(prerequisite Android >4.3). In case you have Android >4.3 and the reading says "not supported", you need to enable Automagic inside Android / Settings / Sound & notification / Notification access</b></li>
    <li>batteryHealth - the health of the battery (1=unknown, 2=good, 3=overheat, 4=dead, 5=over voltage, 6=unspecified failure, 7=cold)</li>
    <li>batterytemperature - the temperature of the battery</li>
    <li>bluetooth - on/off, bluetooth state</li>
    <li>checkActiveTask - state of an app (needs to be defined beforehand). 0=not active or not active in foreground, 1=active in foreground, <b>see note below</b></li>
    <li>connectedBTdevices - list of all devices connected via bluetooth</li>
    <li>connectedBTdevicesMAC - list of MAC addresses of all devices connected via bluetooth</li>
    <li>currentMusicAlbum - currently playing album of mediaplayer</li>
    <li>currentMusicApp - currently playing player app (Amazon Music, Google Play Music, Google Play Video, Spotify, YouTube, TuneIn Player, Aldi Life Music)</li>
    <li>currentMusicArtist - currently playing artist of mediaplayer</li>
    <li>currentMusicIcon - cover of currently play album<b>Noch nicht fertig implementiert</b></li>
    <li>currentMusicState - state of currently/last used mediaplayer</li>
    <li>currentMusicTrack - currently playing song title of mediaplayer</li>
    <li>daydream - on/off, daydream currently active</li>
    <li>deviceState - state of Android devices. unknown, online, offline.</li>
    <li>doNotDisturb - state of do not Disturb Mode</li>
    <li>dockingState - undocked/docked, Android device in docking station</li>
    <li>flow_SetCommands - active/inactive, state of SetCommands flow</li>
    <li>flow_informations - active/inactive, state of Informations flow</li>
    <li>flowsetVersionAtDevice - currently installed version of the flowsets on the Android device</li>
    <li>incomingCallerName - Callername from last Call</li>
    <li>incomingCallerNumber - Callernumber from last Call</li>
    <li>incommingWhatsAppMessageFrom - last WhatsApp message</li>
    <li>incommingWhatsTelegramMessageFrom - last telegram message</li>
    <li>intentRadioName - name of the most-recent streamed intent radio</li>
    <li>intentRadioState - state of intent radio player</li>
    <li>keyguardSet - 0/1 keyguard set, 0=no 1=yes, does not indicate whether it is currently active</li>
    <li>lastSetCommandError - last error message of a set command</li>
    <li>lastSetCommandState - last state of a set command, command send successful/command send unsuccessful</li>
    <li>lastStatusRequestError - last error message of a statusRequest command</li>
    <li>lastStatusRequestState - ast state of a statusRequest command, command send successful/command send unsuccessful</li>
    <li>nextAlarmDay - currently set day of alarm</li>
    <li>nextAlarmState - alert/done, current state of "Clock" stock-app</li>
    <li>nextAlarmTime - currently set time of alarm</li>
    <li>powerLevel - state of battery in %</li>
    <li>powerPlugged - 0=no/1,2=yes, power supply connected</li>
    <li>screen - on locked,unlocked/off locked,unlocked, state of display</li>
    <li>screenBrightness - 0-255, level of screen-brightness</li>
    <li>screenFullscreen - on/off, full screen mode</li>
    <li>screenOrientation - Landscape/Portrait, screen orientation (horizontal,vertical)</li>
    <li>screenOrientationMode - auto/manual, mode for screen orientation</li>
    <li>state - current state of AMADDevice device</li>
    <li>userFlowState - current state of a Flow, established under setUserFlowState Attribut</li>
    <li>volume - media volume setting</li>
    <li>volumeNotification - notification volume setting</li>
    <br>
    Prerequisite for using the reading checkActivTask the package name of the application to be checked needs to be defined in the attribute <i>checkActiveTask</i>. Example: <i>attr Nexus10Wohnzimmer
    checkActiveTask com.android.chrome</i> f&uuml;r den Chrome Browser.
    <br><br>
  </ul>
  <br><br>
  <a name="AMADDeviceset"></a>
  <b>Set</b>
  <ul>
    <li>activateVoiceInput - start voice input on Android device</li>
    <li>bluetooth - on/off, switch bluetooth on/off</li>
    <li>clearNotificationBar - All/Automagic, deletes all or only Automagic notifications in status bar</li>
    <li>closeCall - hang up a running call</li>
    <li>currentFlowsetUpdate - start flowset update on Android device</li>
    <li>installFlowSource - install a Automagic flow on device, <u>XML file must be stored in /tmp/ with extension xml</u>. <b>Example:</b> <i>set TabletWohnzimmer installFlowSource WlanUebwerwachen.xml</i></li>
    <li>doNotDisturb - sets the do not Disturb Mode, always Disturb, never Disturb, alarmClockOnly alarm Clock only, onlyImportant only important Disturbs</li>
    <li>mediaAmazonMusic - play/stop/next/back , controlling the amazon music media player</li>
    <li>mediaGoogleMusic - play/stop/next/back , controlling the google play music media player</li>
    <li>mediaSpotifyMusic - play/stop/next/back , controlling the spotify media player</li>
    <li>mediaTuneinRadio - play/stop/next/back , controlling the TuneinRadio media player</li>
    <li>mediaAldiMusic - play/stop/next/back , controlling the Aldi music media player</li>
    <li>mediaAudible - play/stop/next/back , controlling the Audible media player</li>
    <li>mediaYouTube - play/stop/next/back , controlling the YouTube media player</li>
    <li>mediaVlcPlayer - play/stop/next/back , controlling the VLC media player</li>
    <li>nextAlarmTime - sets the alarm time. Only valid for the next 24 hours.</li>
    <li>notifySndFile - plays a media-file <b>which by default needs to be stored in the folder "/storage/emulated/0/Notifications/" of the Android device. You may use the attribute setNotifySndFilePath for defining a different folder.</b></li>
    <li>openCall - initial a call and hang up after optional time / set DEVICE openCall 0176354 10 call this number and hang up after 10s</li>
    <li>screenBrightness - 0-255, set screen brighness</li>
    <li>screenMsg - display message on screen of Android device</li>
    <li>sendintent - send intent string <u>Example:</u><i> set $AMADDeviceDEVICE sendIntent org.smblott.intentradio.PLAY url http://stream.klassikradio.de/live/mp3-192/stream.klassikradio.de/play.m3u name Klassikradio</i>, first parameter contains the action, second parameter contains the extra. At most two extras can be used.</li>
    <li>sendSMS - Sends an SMS to a specific phone number. Bsp.: sendSMS Dies ist ein Test|555487263</li>
    <li>startDaydream - start Daydream</li>
    <li>statusRequest - Get a new status report of Android device. Not all readings can be updated using a statusRequest as some readings are only updated if the value of the reading changes.</li>
    <li>timer - set a countdown timer in the "Clock" stock app. Only seconds are allowed as parameter.</li>
    <li>ttsMsg - send a message which will be played as voice message</li>
    <li>userFlowState - set Flow/s active or inactive,<b><i>set Nexus7Wohnzimmer Badezimmer:inactive vorheizen</i> or <i>set Nexus7Wohnzimmer Badezimmer vorheizen,Nachtlicht Steven:inactive</i></b></li>
    <li>vibrate - vibrate Android device</li>
    <li>volume - set media volume. Works on internal speaker or, if connected, bluetooth speaker or speaker connected via stereo jack</li>
    <li>volumeNotification - set notifications volume</li>
  </ul>
  <br>
  <b>Set (depending on attribute values)</b>
  <ul>
    <li>changetoBtDevice - switch to another bluetooth device. <b>Attribute setBluetoothDevice needs to be set. See note below!</b></li>
    <li>openApp - start an app. <b>attribute setOpenApp</b></li>
    <li>openURL - opens a URLS in the standard browser as long as no other browser is set by the <b>attribute setOpenUrlBrowser</b>.<b>Example:</b><i> attr Tablet setOpenUrlBrowser de.ozerov.fully|de.ozerov.fully.MainActivity, first parameter: package name, second parameter: Class Name</i></li>
    <li>screen - on/off/lock/unlock, switch screen on/off or lock/unlock screen. In Automagic "Preferences" the "Device admin functions" need to be enabled, otherwise "Screen off" does not work. <b>attribute setScreenOnForTimer</b> changes the time the display remains switched on!</li>
    <li>screenFullscreen - on/off, activates/deactivates full screen mode. <b>attribute setFullscreen</b></li>
    <li>screenLock - Locks screen with request for PIN. <b>attribute setScreenlockPIN - enter PIN here. Only use numbers, 4-16 numbers required.</b></li>
    <li>screenOrientation - Auto,Landscape,Portait, set screen orientation (automatic, horizontal, vertical). <b>attribute setScreenOrientation</b></li>
    <li>system - issue system command (only with rooted Android devices). reboot,shutdown,airplanemodeON (can only be switched ON) <b>attribute root</b>, in Automagic "Preferences" "Root functions" need to be enabled.</li>
    <li>setAPSSID - set WLAN AccesPoint SSID to prevent WLAN sleeps</li>
    <li>setNotifySndFilePath - set systempath to notifyfile (default /storage/emulated/0/Notifications/</li>
    <li>setTtsMsgSpeed - set speaking speed for TTS (Value between 0.5 - 4.0, 0.5 Step) default is 1.0</li>
    <li>setTtsMsgLang - set speaking language for TTS, de or en (default is de)</li>
    <br>
    To be able to use "openApp" the corresponding attribute "setOpenApp" needs to contain the app package name.
    <br><br>
    To be able to switch between bluetooth devices the attribute "setBluetoothDevice" needs to contain (a list of) bluetooth devices defined as follows: <b>attr &lt;DEVICE&gt; BTdeviceName1|MAC,BTDeviceName2|MAC</b> No spaces are allowed in any BTdeviceName. Defining MAC please make sure to use the character : (colon) after each  second digit/character.<br>
    Example: <i>attr Nexus10Wohnzimmer setBluetoothDevice Logitech_BT_Adapter|AB:12:CD:34:EF:32,Anker_A3565|GH:56:IJ:78:KL:76</i> 
  </ul>
  <br><br>
  <a name="AMADDevicestate"></a>
  <b>state</b>
  <ul>
    <li>initialized - shown after initial define.</li>
    <li>active - device is active.</li>
    <li>disabled - device is disabled by the attribute "disable".</li>
  </ul>
  <br><br><br>
  <u><b>Further examples and reading:</b></u>
  <ul><br>
    <a href="http://www.fhemwiki.de/wiki/AMADDevice#Anwendungsbeispiele">Wiki page for AMADDevice (german only)</a>
  </ul>
  <br><br><br>
</ul>

=end html
=begin html_DE

<a name="AMADDevice"></a>
<h3>AMADDevice</h3>
<ul>
  <u><b>AMADDevice - Automagic Android Device</b></u>
  <br>
  Dieses Modul liefert, <b><u>in Verbindung mit der Android APP Automagic</u></b>, diverse Informationen von Android Ger&auml;ten.
  Die AndroidAPP Automagic (welche nicht von mir stammt und 2.90 Euro kostet) funktioniert wie Tasker, ist aber bei weitem User freundlicher.
  <br>
  Mit etwas Einarbeitung k&ouml;nnen jegliche Informationen welche Automagic bereit stellt in FHEM angezeigt werden. Hierzu bedarf es lediglich eines eigenen Flows welcher seine Daten an die AMADDeviceCommBridge sendet. Das Modul gibt auch die M&ouml;glichkeit Androidger&auml;te zu steuern.
  <br>
  F&uuml;r all diese Aktionen und Informationen wird auf dem Androidger&auml;t "Automagic" und ein so genannter Flow ben&ouml;tigt. Die App ist &uuml;ber den Google PlayStore zu beziehen. Das ben&ouml;tigte Flowset bekommt man aus dem FHEM Verzeichnis.
  <br><br>
  <b>Wie genau verwendet man nun AMADDevice?</b>
  <ul>
    <li>man installiert die App "Automagic Premium" aus dem PlayStore.</li>
    <li>dann installiert man das Flowset 74_AMADDeviceautomagicFlowset$VERSION.xml aus dem Ordner $INSTALLFHEM/FHEM/lib/ auf dem Androidger&auml;t und aktiviert die Flows.</li>
  </ul>
  <br>
  Es mu&szlig; noch ein Device in FHEM anlegt werden.
  <br><br>
  <a name="AMADDevicedefine"></a>
  <b>Define</b>
  <ul><br>
    <code>define &lt;name&gt; AMADDevice &lt;IP-ADRESSE&gt;</code>
    <br><br>
    Beispiel:
    <ul><br>
      <code>define WandTabletWohnzimmer AMADDevice 192.168.0.23</code><br>
    </ul>
    <br>
    Diese Anweisung erstellt zwei neues AMADDevice-Device im Raum AMADDevice.Der Parameter &lt;IP-ADRESSE&gt; legt die IP Adresse des Android Ger&auml;tes fest.<br>
    Das zweite Device ist die AMADDeviceCommBridge welche als Kommunikationsbr&uuml;cke vom Androidger&auml;t zu FHEM diehnt. !!!Comming Soon!!! Wer den Port &auml;ndern m&ouml;chte, kann dies &uuml;ber das Attribut "port" tun. <b>Ihr solltet aber wissen was Ihr tut, da dieser Port im HTTP Request Trigger der beiden Flows eingestellt ist. Demzufolge mu&szlig; der Port dort auch ge&auml;ndert werden. Der Port f&uuml;r die Bridge kann ohne Probleme im Bridge Device mittels dem Attribut "port" ver&auml;ndert werden.
    <br>
    Der Port f&uuml;r die Bridge kann ohne Probleme im Bridge Device mittels dem Attribut "port" ver&auml;ndert werden.</b>
  </ul>
  <br><a name="AMADDeviceCommBridge"></a>
  <b>AMADDevice Communication Bridge</b>
  <ul>
    Beim ersten anlegen einer AMADDevice Deviceinstanz wird automatisch ein Ger&auml;t Namens AMADDeviceCommBridge im Raum AMADDevice mit angelegt. Dieses Ger&auml;t diehnt zur Kommunikation vom Androidger&auml;t zu FHEM ohne das zuvor eine Anfrage von FHEM aus ging. <b>Damit das Androidger&auml;t die IP von FHEM kennt, muss diese sofort nach dem anlegen der Bridge &uuml;ber den set Befehl in ein entsprechendes Reading in die Bridge  geschrieben werden. DAS IST SUPER WICHTIG UND F&Uuml;R DIE FUNKTION DER BRIDGE NOTWENDIG.</b><br>
    Hierf&uuml;r mu&szlig; folgender Befehl ausgef&uuml;hrt werden. <i>set AMADDeviceCommBridge fhemServerIP &lt;FHEM-IP&gt;.</i><br>
    Als zweites Reading kann <i>expertMode</i> gesetzen werden. Mit diesem Reading wird eine unmittelbare Komminikation mit FHEM erreicht ohne die Einschr&auml;nkung &uuml;ber ein
    Notify gehen zu m&uuml;ssen und nur reine set Befehle ausf&uuml;hren zu k&ouml;nnen.
  </ul><br>
  <b><u>NUN bitte die Flows AKTIVIEREN!!!</u></b><br>
  <br>
  <b><u>Fertig! Nach anlegen der Ger&auml;teinstanz und dem eintragen der fhemServerIP in der CommBridge sollten nach sp&auml;testens 15 Sekunden bereits die ersten Readings reinkommen. Nun wird alle 15 Sekunden probiert einen Status Request erfolgreich ab zu schlie&szlig;en. Wenn der Status sich &uuml;ber einen l&auml;ngeren Zeitraum nicht auf "active" &auml;ndert, sollte man im Log nach eventuellen Fehlern suchen.</u></b>
  <br><br><br>
  <a name="AMADDevicereadings"></a>
  <b>Readings</b>
  <ul>
    <li>airplanemode - Status des Flugmodus</li>
    <li>androidVersion - aktuell installierte Androidversion</li>
    <li>automagicState - Statusmeldungen von der AutomagicApp <b>(Voraussetzung Android >4.3). Ist Android gr&ouml;&szlig;er 4.3 vorhanden und im Reading steht "wird nicht unterst&uuml;tzt", mu&szlig; in den Androideinstellungen unter Ton und Benachrichtigungen -> Benachrichtigungszugriff ein Haken f&uuml;r Automagic gesetzt werden</b></li>
    <li>batteryHealth - Zustand der Battery (1=unbekannt, 2=gut, 3=&Uuml;berhitzt, 4=tot, 5=&Uumlberspannung, 6=unbekannter Fehler, 7=kalt)</li>
    <li>batterytemperature - Temperatur der Batterie</li>
    <li>bluetooth - on/off, Bluetooth Status an oder aus</li>
    <li>checkActiveTask - Zustand einer zuvor definierten APP. 0=nicht aktiv oder nicht aktiv im Vordergrund, 1=aktiv im Vordergrund, <b>siehe Hinweis unten</b></li>
    <li>connectedBTdevices - eine Liste der verbundenen Ger&auml;t</li>
    <li>connectedBTdevicesMAC - eine Liste der MAC Adressen aller verbundender BT Ger&auml;te</li>
    <li>currentMusicAlbum - aktuell abgespieltes Musikalbum des verwendeten Mediaplayers</li>
    <li>currentMusicApp - aktuell verwendeter Mediaplayer (Amazon Music, Google Play Music, Google Play Video, Spotify, YouTube, TuneIn Player, Aldi Life Music)</li>
    <li>currentMusicArtist - aktuell abgespielter Musikinterpret des verwendeten Mediaplayers</li>
    <li>currentMusicIcon - Cover vom aktuell abgespielten Album <b>Noch nicht fertig implementiert</b></li>
    <li>currentMusicState - Status des aktuellen/zuletzt verwendeten Mediaplayers</li>
    <li>currentMusicTrack - aktuell abgespielter Musiktitel des verwendeten Mediaplayers</li>
    <li>daydream - on/off, Daydream gestartet oder nicht</li>
    <li>deviceState - Status des Androidger&auml;tes. unknown, online, offline.</li>
    <li>doNotDisturb - aktueller Status des nicht st&ouml;ren Modus</li>
    <li>dockingState - undocked/docked Status ob sich das Ger&auml;t in einer Dockinstation befindet.</li>
    <li>flow_SetCommands - active/inactive, Status des SetCommands Flow</li>
    <li>flow_informations - active/inactive, Status des Informations Flow</li>
    <li>flowsetVersionAtDevice - aktuell installierte Flowsetversion auf dem Device</li>
    <li>incomingCallerName - Anrufername des eingehenden Anrufes</li>
    <li>incomingCallerNumber - Anrufernummer des eingehenden Anrufes</li>
    <li>incommingWhatsAppMessageFrom - letzte WhatsApp Nachricht</li>
    <li>incommingWhatsTelegramMessageFrom - letzte Telegram Nachricht</li>
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
    <li>userFlowState - aktueller Status eines Flows, festgelegt unter dem setUserFlowState Attribut</li>
    <li>volume - Media Lautst&auml;rkewert</li>
    <li>volumeNotification - Benachrichtigungs Lautst&auml;rke</li>
    <br>
    Beim Reading checkActivTask mu&szlig; zuvor der Packagename der zu pr&uuml;fenden App als Attribut <i>checkActiveTask</i> angegeben werden. Beispiel: <i>attr Nexus10Wohnzimmer
    checkActiveTask com.android.chrome</i> f&uuml;r den Chrome Browser.
    <br><br>
  </ul>
  <br><br>
  <a name="AMADDeviceset"></a>
  <b>Set</b>
  <ul>
    <li>activateVoiceInput - aktiviert die Spracheingabe</li>
    <li>bluetooth - on/off, aktiviert/deaktiviert Bluetooth</li>
    <li>clearNotificationBar - All,Automagic, l&ouml;scht alle Meldungen oder nur die Automagic Meldungen in der Statusleiste</li>
    <li>closeCall - beendet einen laufenden Anruf</li>
    <li>currentFlowsetUpdate - f&uuml;rt ein Flowsetupdate auf dem Device durch</li>
    <li>doNotDisturb - schaltet den nicht st&ouml;ren Modus, always immer st&ouml;ren, never niemals st&ouml;ren, alarmClockOnly nur Wecker darf st&ouml;ren, onlyImportant nur wichtige St&ouml;rungen</li>
    <li>installFlowSource - installiert einen Flow auf dem Device, <u>das XML File muss unter /tmp/ liegen und die Endung xml haben</u>. <b>Bsp:</b> <i>set TabletWohnzimmer installFlowSource WlanUebwerwachen.xml</i></li>
    <li>mediaAmazonMusic - play, stop, next, back  ,steuert den Amazon Musik Mediaplayer</li>
    <li>mediaGoogleMusic - play, stop, next, back  ,steuert den Google Play Musik Mediaplayer</li>
    <li>mediaSpotifyMusic - play, stop, next, back  ,steuert den Spotify Mediaplayer</li>
    <li>mediaTuneinRadio - play, stop, next, back  ,steuert den TuneIn Radio Mediaplayer</li>
    <li>mediaAldiMusic - play, stop, next, back  ,steuert den Aldi Musik Mediaplayer</li>
    <li>mediaAudible - play, stop, next, back  ,steuert den Audible Mediaplayer</li>
    <li>mediaYouTube - play, stop, next, back  ,steuert den YouTube Mediaplayer</li>
    <li>mediaVlcPlayer - play, stop, next, back  ,steuert den VLC Mediaplayer</li>
    <li>nextAlarmTime - setzt die Alarmzeit. gilt aber nur innerhalb der n&auml;chsten 24Std.</li>
    <li>openCall - ruft eine Nummer an und legt optional nach X Sekunden auf / set DEVICE openCall 01736458 10 / ruft die Nummer an und beendet den Anruf nach 10s</li>
    <li>screenBrightness - setzt die Bildschirmhelligkeit, von 0-255.</li>
    <li>screenMsg - versendet eine Bildschirmnachricht</li>
    <li>sendintent - sendet einen Intentstring <u>Bsp:</u><i> set $AMADDeviceDEVICE sendIntent org.smblott.intentradio.PLAY url http://stream.klassikradio.de/live/mp3-192/stream.klassikradio.de/play.m3u name Klassikradio</i>, der erste Befehl ist die Aktion und der zweite das Extra. Es k&ouml;nnen immer zwei Extras mitgegeben werden.</li>
    <li>sendSMS - sendet eine SMS an eine bestimmte Telefonnummer. Bsp.: sendSMS Dies ist ein Test|555487263</li>
    <li>startDaydream - startet den Daydream</li>
    <li>statusRequest - Fordert einen neuen Statusreport beim Device an. Es k&ouml;nnen nicht von allen Readings per statusRequest die Daten geholt werden. Einige wenige geben nur bei Status&auml;nderung ihren Status wieder.</li>
    <li>timer - setzt einen Timer innerhalb der als Standard definierten ClockAPP auf dem Device. Es k&ouml;nnen nur Sekunden angegeben werden.</li>
    <li>ttsMsg - versendet eine Nachricht welche als Sprachnachricht ausgegeben wird</li>
    <li>userFlowState - aktiviert oder deaktiviert einen oder mehrere Flows,<b><i>set Nexus7Wohnzimmer Badezimmer vorheizen:inactive</i> oder <i>set Nexus7Wohnzimmer Badezimmer vorheizen,Nachtlicht Steven:inactive</i></b></li>
    <li>vibrate - l&auml;sst das Androidger&auml;t vibrieren</li>
    <li>volume - setzt die Medialautst&auml;rke. Entweder die internen Lautsprecher oder sofern angeschlossen die Bluetoothlautsprecher und per Klinkenstecker angeschlossene Lautsprecher, + oder - vor dem Wert reduziert die aktuelle Lautst&auml;rke um den Wert</li>
    <li>volumeNotification - setzt die Benachrichtigungslautst&auml;rke.</li>
  </ul>
  <br>
  <b>Set abh&auml;ngig von gesetzten Attributen</b>
  <ul>
    <li>changetoBtDevice - wechselt zu einem anderen Bluetooth Ger&auml;t. <b>Attribut setBluetoothDevice mu&szlig; gesetzt sein. Siehe Hinweis unten!</b></li>
    <li>notifySndFile - spielt die angegebene Mediadatei auf dem Androidger&auml;t ab. <b>Die aufzurufende Mediadatei sollte sich im Ordner /storage/emulated/0/Notifications/ befinden. Ist dies nicht der Fall kann man &uuml;ber das Attribut setNotifySndFilePath einen Pfad vorgeben.</b></li>
    <li>openApp - &ouml;ffnet eine ausgew&auml;hlte App. <b>Attribut setOpenApp</b></li>
    <li>openURL - &ouml;ffnet eine URL im Standardbrowser, sofern kein anderer Browser &uuml;ber das <b>Attribut setOpenUrlBrowser</b> ausgew&auml;hlt wurde.<b> Bsp:</b><i> attr Tablet setOpenUrlBrowser de.ozerov.fully|de.ozerov.fully.MainActivity, das erste ist der Package Name und das zweite der Class Name</i></li>
    <li>setAPSSID - setzt die AccessPoint SSID um ein WLAN sleep zu verhindern</li>
    <li>screen - on/off/lock/unlock schaltet den Bildschirm ein/aus oder sperrt/entsperrt ihn, in den Automagic Einstellungen muss "Admin Funktion" gesetzt werden sonst funktioniert "Screen off" nicht. <b>Attribut setScreenOnForTimer</b> &auml;ndert die Zeit wie lange das Display an bleiben soll!</li>
    <li>screenFullscreen - on/off, (aktiviert/deaktiviert) den Vollbildmodus. <b>Attribut setFullscreen</b></li>
    <li>screenLock - Sperrt den Bildschirm mit Pinabfrage. <b>Attribut setScreenlockPIN - hier die Pin daf&uuml;r eingeben. Erlaubt sind nur Zahlen. Es m&uuml;&szlig;en mindestens 4, bis max 16 Zeichen verwendet werden.</b></li>
    <li>screenOrientation - Auto,Landscape,Portait,  aktiviert die Bildschirmausrichtung (Automatisch,Horizontal,Vertikal). <b>Attribut setScreenOrientation</b></li>
    <li>system - setzt Systembefehle ab (nur bei gerootetet Ger&auml;en). reboot,shutdown,airplanemodeON (kann nur aktiviert werden) <b>Attribut root</b>, in den Automagic Einstellungen muss "Root Funktion" gesetzt werden</li>
    <li>setNotifySndFilePath - setzt den korrekten Systempfad zur Notifydatei (default ist /storage/emulated/0/Notifications/</li>
    <li>setTtsMsgSpeed - setzt die Sprachgeschwindigkeit bei der Sprachausgabe(Werte zwischen 0.5 bis 4.0 in 0.5er Schritten) default ist 1.0</li>
    <li>setTtsMsgSpeed - setzt die Sprache bei der Sprachausgabe, de oder en (default ist de)</li>
    <br>
    Um openApp verwenden zu k&ouml;nnen, muss als Attribut der Package Name der App angegeben werden.
    <br><br>
    Um zwischen Bluetoothger&auml;ten wechseln zu k&ouml;nnen, mu&szlig; das Attribut setBluetoothDevice mit folgender Syntax gesetzt werden. <b>attr &lt;DEVICE&gt; BTdeviceName1|MAC,BTDeviceName2|MAC</b> Es muss
    zwingend darauf geachtet werden das beim BTdeviceName kein Leerzeichen vorhanden ist. Am besten zusammen oder mit Unterstrich. Achtet bei der MAC darauf das Ihr wirklich nach jeder zweiten Zahl auch
    einen : drin habt<br>
    Beispiel: <i>attr Nexus10Wohnzimmer setBluetoothDevice Logitech_BT_Adapter|AB:12:CD:34:EF:32,Anker_A3565|GH:56:IJ:78:KL:76</i> 
  </ul>
  <br><br>
  <a name="AMADDevicestate"></a>
  <b>state</b>
  <ul>
    <li>initialized - Ist der Status kurz nach einem define.</li>
    <li>active - die Ger&auml;teinstanz ist im aktiven Status.</li>
    <li>disabled - die Ger&auml;teinstanz wurde &uuml;ber das Attribut disable deaktiviert</li>
  </ul>
  <br><br><br>
  <u><b>Anwendungsbeispiele:</b></u>
  <ul><br>
    <a href="http://www.fhemwiki.de/wiki/AMADDevice#Anwendungsbeispiele">Hier verweise ich auf den gut gepflegten Wikieintrag</a>
  </ul>
  <br><br><br>
</ul>

=end html_DE
=cut
