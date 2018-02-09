#!/usr/bin/perl
#
# IRC Meeting Organiser

# Copyright (C) 2018 Christopher Roberts
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use utf8;

use POE;
use POE::Component::IRC;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::BotCommand;
use POE::Component::IRC::Plugin::Connector;

use lib './lib';
use config;

use vars qw( $CONF $LAG $REC );

if ( (defined $ARGV[0]) and (-r $ARGV[0]) ) {
    $CONF = config::get_config($ARGV[0]);
} else {
    print "USAGE: slugrat.pl conf/template.conf\n";
    exit;
}

# Set the Ping delay
$LAG = 300;

# Set the Reconnect delay
$REC = 60;

my @channels = $CONF->param('channels');

# We create a new PoCo-IRC object
my $irc = POE::Component::IRC::State->spawn(
   nick     => $CONF->param('nickname'),
   ircname  => $CONF->param('ircname'),
   server   => $CONF->param('server'),
) or die "Oh noooo! $!";

# Commands
POE::Session->create(
    package_states => [
        main => [ qw(
            _default 
            _start 
            lag_o_meter
            irc_001 
            irc_invite
            irc_kick
            irc_botcmd_op
            irc_botcmd_ignore
            irc_public
        ) ],
    ],
    heap => { irc => $irc },
);

$poe_kernel->run();

# Start of IRC Bot Commands
# declared in POE::Session->create

sub _default {
    my ($kernel, $event, $args) = @_[KERNEL, ARG0 .. $#_];
    my @output = ( "$event: " );

    for my $arg (@$args) {
        if ( ref $arg eq 'ARRAY' ) {
            push( @output, '[' . join(', ', @$arg ) . ']' );
        }
        else {
            push ( @output, "'$arg'" );
        }
    }

    print join ' ', @output, "\n";

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;
}

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    # retrieve our component's object from the heap where we stashed it
    my $irc = $heap->{irc};

    $heap->{connector} = POE::Component::IRC::Plugin::Connector->new(
        delay       => $LAG,
        reconnect   => $REC,
    );
    $irc->plugin_add( 'Connector' => $heap->{connector} );

    # Commands
    $irc->plugin_add('BotCommand',
        POE::Component::IRC::Plugin::BotCommand->new(
            Commands => {
                op          => 'Currently has no other purpose than to tell you if you are an op or not!',
                ignore      => 'Maintain nick ignore list for bots - takes two arguments - add|del|list <nick>',
            },
            In_channels     => 1,
            In_private      => $CONF->param('private'),
            Auth_sub        => \&is_not_bot,
            Ignore_unauthorized => 1,
            Addressed       => $CONF->param('addressed'),
            Prefix          => $CONF->param('prefix'),
            Eat             => 1,
            Ignore_unknown  => 1,
        )
    );

    $irc->yield( register => 'all' );
    $irc->yield( connect => { } );

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;
}

sub lag_o_meter {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    my $time = localtime;
    print 'Time: ' . $time . ' Lag: ' . $heap->{connector}->lag() . "\n";

    $kernel->delay( 'lag_o_meter' => $LAG );

    return;
}

sub irc_001 {
    my ($kernel, $sender) = @_[KERNEL, SENDER];

    # Since this is an irc_* event, we can get the component's object by
    # accessing the heap of the sender. Then we register and connect to the
    # specified server.
    my $irc = $sender->get_heap();

    print "Connected to ", $irc->server_name(), "\n";

    # we join our channels
    $irc->yield( join => $_ ) for @channels;

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;
}

sub irc_invite {
    my ($kernel, $who, $where) = @_[KERNEL, ARG0 .. ARG1];
    my $nick = ( split /!/, $who )[0];

    if ($CONF->param('invites') == 0) {
        warn "Invites not permitted - invitation by $who to join $where was ignored";
        $irc->yield( privmsg => $nick => "My apologies but current configuration is to ignore invitations" );
        return;
    }

    # Add the channel to the list
    $CONF = config::add_channel($CONF, $where);

    # we join our channels
    $irc->yield( join => $where );

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;
}

sub irc_kick {
    my ($kernel, $kicker, $where, $kicked) = @_[KERNEL, ARG0 .. ARG2];

    # Remove the channel from the list
    $CONF = config::remove_channel($CONF, $where);

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;
}

sub irc_botcmd_op {
    my ($kernel, $who, $channel, $request) = @_[KERNEL, ARG0 .. ARG2];
    my $nick = ( split /!/, $who )[0];

    if ( is_op($channel, $nick) ) {
        $irc->yield( privmsg => $channel => "$nick: You are indeed a might op!");
    } else {
        $irc->yield( privmsg => $channel => "$nick: Only channel operators may do that!");
    } 

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;

}

sub irc_botcmd_ignore {
    my ($kernel, $who, $channel, $request) = @_[KERNEL, ARG0 .. ARG2];
    my $nick            = ( split /!/, $who )[0];
    my ($action, $bot)  = split(/\s+/, $request);

    unless ( ( is_op($channel, $nick) ) or ($nick eq $bot) ) {
        $irc->yield( privmsg => $channel => "$nick: Only channel operators may do that!");
        return;
    }

    if ((not defined $request) or ($request =~ /^\s*$/)) {
        $irc->yield( privmsg => $channel => "$nick: Command ignore should be followed by a nick.");
        return;
    }

    my $bots;
    if ($action =~ /^add$/i) {
        $bots = config::add_bot($CONF, $bot);
    } elsif ($action =~ /^(?:del|delete|remove)$/i) {
        $bots = config::remove_bot($CONF, $bot);
    } else {
        $bots = config::list_bots($CONF);
    }

    $irc->yield( privmsg => $channel => "$nick: Bots - $bots");

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;
}

sub irc_public {
    my ($kernel, $sender, $who, $where, $what) = @_[KERNEL, SENDER, ARG0 .. ARG2];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];

    if ( config::is_bot($CONF, $nick) ) {
        warn "blocked";
        return;
    }

    # Ignore slugrat: commands - handled by botcommand plugin
    my $whoami = $CONF->param('nickname');
    my $prefix = $CONF->param('prefix');

    # Cope with commands that are followed only with a space
    # This is a bug I think in botcommand plugin
    if (my ($command) = $what =~ /^(?:$prefix|$whoami:)\s*(op|ignore|help)\s+$/i) {
        warn "==================================== A ==================================";
        $irc->yield( privmsg => $channel => "$nick: $command followed by whitespace only is invalid.");

    # Do nothing - these requests being handled by irc_command_*
    } elsif ($what =~ /^(?:$prefix|$whoami:)\s*(?:op|ignore|help)/i) {
        warn "==================================== B ==================================";

    }

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;
}

# End of IRC Bot Commands

# Start of IRC slave functions

sub is_not_bot {
    my ($object, $nick, $where, $command, $args) = @_;

    if ( config::is_bot($CONF, $nick) ) {
        warn "blocked";
        return 0;
    }

    return 1;
}

sub is_op {
    my ($chan, $nick) = @_;

    return 0 unless $nick;
  
    if (
            ($irc->is_channel_operator($chan, $nick))
            or (($irc->nick_channel_modes($chan, $nick) =~ m/[aoq]/))
    ) {

        return 1;

  }

  return 0;
}
