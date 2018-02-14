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
use events;

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
            irc_botcmd_ignore
            irc_botcmd_add
            irc_botcmd_list
            irc_botcmd_delete
            irc_botcmd_show
            irc_botcmd_edit
            irc_botcmd_open
            irc_botcmd_close
            irc_botcmd_accept
            irc_botcmd_reject
            irc_botcmd_voters
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

    my $botnick = $CONF->param('nickname');

    # Commands
    $irc->plugin_add('BotCommand',
        POE::Component::IRC::Plugin::BotCommand->new(
            Commands => {
                ignore      => 'Maintain nick ignore list for bots - takes two arguments - add|del|list <nick>',
                add         => "To add an event, use: $botnick: add \"Name of event\" <ISO Date 1> <ISO Date 2> ...",
                list        => "To list all events, use: $botnick: list <all|created|open|closed>",
                delete      => "To delete an event, use: $botnick: delete <event id>",
                show        => "To show the detail for an event, use: $botnick: show <event id>",
                edit        => "To edit an event, use: $botnick: edit <event id> \"Name of Event\" <ISO Date 1> <ISO Date 2> ...",
                open        => "To open an event, use: $botnick: open <event id>",
                close       => "To close an event, use: $botnick: close <event id>",
                accept      => "To accept an event, use: $botnick: accept <event id> <A> <B>",
                reject      => "To reject all dates for an event, use: $botnick: reject <event id>",
                voters      => "To view the voters for an event, use: $botnick: voters <event id>",
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
        $irc->yield( notice => $nick => "Current configuration is to ignore invitations" );
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

# Maintains list of bots (or other nicks) to ignore
# Options are add, delete or list
#
sub irc_botcmd_ignore {
    my ($kernel, $who, $channel, $request) = @_[KERNEL, ARG0 .. ARG2];
    my $nick            = ( split /!/, $who )[0];
    my ($action, $bot)  = split(/\s+/, $request);

    unless ( ( is_op($channel, $nick) ) or ($nick eq $bot) ) {
        $irc->yield( notice => $channel => "Only channel operators may do that!");
        return;
    }

    if ((not defined $request) or ($request =~ /^\s*$/)) {
        $irc->yield( notice => $channel => "Command ignore should be followed by a nick.");
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

    $irc->yield( notice => $channel => "$nick: Bots - $bots");

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;
}

# Add Event
# <majorbull> slugrat: add "Pub Meet" 2018-02-06 2018-02-13 2018-02-21
#
sub irc_botcmd_add {
    my ($kernel, $who, $channel, $request) = @_[KERNEL, ARG0 .. ARG2];
    my $nick            = ( split /!/, $who )[0];

    my ($event_id, $event_name) = events::create($channel, $nick, $request);

    if (defined $event_name) {
        $irc->yield( notice => $channel => "$event_name created successfully - ID $event_id");
    } else {
        $irc->yield( notice => $channel => "Event could not be created - error $event_id");
    }

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;

}

# Edit Event
# <majorbull> slugrat: edit 1 "Pub Meet" 2018-02-06 2018-02-13 2018-02-21
#
sub irc_botcmd_edit {
    my ($kernel, $who, $channel, $request) = @_[KERNEL, ARG0 .. ARG2];
    my $nick            = ( split /!/, $who )[0];

    my ($event_id, $event_name) = events::edit($channel, $nick, $request);

    if ( ($event_id != 0) and (defined $event_name) ) {
        $irc->yield( notice => $channel => "$event_name updated successfully - ID $event_id");
    } else {
        $irc->yield( notice => $channel => "Event could not be updated - error $event_id");
    }

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;

}

# List Events
# <majorbull> slugrat: list
#
sub irc_botcmd_list {
    my ($kernel, $who, $channel, $request) = @_[KERNEL, ARG0 .. ARG2];

    my $nick        = ( split /!/, $who )[0];
    my $status      = requested_status($request);
    my $events_ref  = events::list($channel, $status);
    my $count       = keys %{ $events_ref };

    if ($count == 0) {
        $irc->yield( notice => $channel => "There are currently no events.");
        return;
    }

    foreach my $event_id (sort keys %{ $events_ref }) {
        $irc->yield( notice => $channel => "$event_id - $events_ref->{ $event_id }{EVENT} ($events_ref->{ $event_id }{STATUS})");
    }

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;

}

# Delete Event
# <majorbull> slugrat: delete <event id>
#
sub irc_botcmd_delete {
    my ($kernel, $who, $channel, $request) = @_[KERNEL, ARG0 .. ARG2];
    my $nick            = ( split /!/, $who )[0];

    my ($response, $message) = events::delete($channel, $nick, $request);
    $irc->yield( notice => $channel => $message);

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;

}

# Show Event
# <majorbull> slugrat: show <event id>
#
sub irc_botcmd_show {
    my ($kernel, $who, $channel, $request) = @_[KERNEL, ARG0 .. ARG2];
    my $nick            = ( split /!/, $who )[0];

    my ($event_id, $event_ref, $scores_ref) = events::detail($channel, $nick, $request);

    if ($event_id == 0) {
        $irc->yield( notice => $channel => "$event_ref" );
        return;
    }

    my $char = 65;
    foreach my $date (sort @{ $event_ref->{DATES} }) {
        my $score = keys @{ $scores_ref->{ $event_id }{ $date } };
        my $votes = ($score == 1) ? 'vote' : 'votes';
        $irc->yield( notice => $channel => chr($char) . " - $event_ref->{EVENT} on $date - $score $votes" );
        $char++;
    }

    my $botnick = $CONF->param('nickname');
    if ($event_ref->{STATUS} ne 'OPEN') {
        $irc->yield( notice => $channel => "To open the event, use $botnick: open $event_id" );
    } else {
        $irc->yield( notice => $channel => "To accept event dates, use $botnick: accept 1ABC.");
    }

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;

}

# View Voters for an Event
# <majorbull> slugrat: voters <event id>
#
sub irc_botcmd_voters {
    my ($kernel, $who, $channel, $request) = @_[KERNEL, ARG0 .. ARG2];
    my $nick            = ( split /!/, $who )[0];

    my ($event_id, $event_ref, $scores_ref) = events::detail($channel, $nick, $request);

    if ($event_id == 0) {
        $irc->yield( notice => $channel => "$event_ref" );
        return;
    }

    my $char = 65;
    foreach my $date (sort @{ $event_ref->{DATES} }) {
        my $score = keys @{ $scores_ref->{ $event_id }{ $date } };
        my $votes = ($score == 1) ? 'vote' : 'votes';
        my $voters = '';
        if ($score != 0) {
            $voters = '(' . join(" ", @{ $scores_ref->{ $event_id }{ $date } } ) . ')';
        }

        $irc->yield( notice => $channel => chr($char) . " - $event_ref->{EVENT} on $date - $score $votes $voters" );
        $char++;
    }

    my $botnick = $CONF->param('nickname');
    if ($event_ref->{STATUS} ne 'OPEN') {
        $irc->yield( notice => $channel => "To open the event, use $botnick: open $event_id" );
    }

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;

}

# Open Event
# <majorbull> slugrat: open <event id>
#
sub irc_botcmd_open {
    my ($kernel, $who, $channel, $request) = @_[KERNEL, ARG0 .. ARG2];
    my $nick            = ( split /!/, $who )[0];

    my ($response, $message) = events::eopen($channel, $nick, $request);
    $irc->yield( notice => $channel => $message);

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;
}

# Close Event
# <majorbull> slugrat: close <event id>
#
sub irc_botcmd_close {
    my ($kernel, $who, $channel, $request) = @_[KERNEL, ARG0 .. ARG2];
    my $nick            = ( split /!/, $who )[0];

    my ($response, $message) = events::eclose($channel, $nick, $request);
    $irc->yield( notice => $channel => $message);

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;
}

# Accept Event
# <majorbull> slugrat: accept <event id> A B C
#
sub irc_botcmd_accept {
    my ($kernel, $who, $channel, $request) = @_[KERNEL, ARG0 .. ARG2];
    my $nick            = ( split /!/, $who )[0];

    my ($response, $message) = events::accept($channel, $nick, $request);
    $irc->yield( notice => $channel => $message);

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;
}

# Reject Event
# <majorbull> slugrat: reject <event id>
#
sub irc_botcmd_reject {
    my ($kernel, $who, $channel, $request) = @_[KERNEL, ARG0 .. ARG2];
    my $nick            = ( split /!/, $who )[0];

    my ($response, $message) = events::accept($channel, $nick, $request);
    $irc->yield( notice => $channel => $message);

    # Restart the lag_o_meter
    $kernel->delay( 'lag_o_meter' => $LAG );

    return;
}

# Enable the ability to respond to everything, not just pre-defined commands
# Neater and more predictable to stick to bot commands if possible
#
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
        $irc->yield( notice => $channel => "$command followed by whitespace only is invalid.");

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

sub requested_status {
    my $request = shift;

    my $status = 'OPEN';
    if ($request =~ /^\s*(all|created|open|closed)\s*$/i) {
        $status = uc($request);
    }
        
    return $status;
}
