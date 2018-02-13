package events;

use strict;
use Exporter;
use tools;

my @functions = qw(
    create
    add
    list
    delete
    open
    close
    accept
);

our $VERSION     = 1.00;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = @functions;
our %EXPORT_TAGS = (
    DEFAULT => [@functions],
    ALL     => [@functions],
);
our $EVENTS_FILE = 'events.json';
our $VOTES_FILE  = 'votes.csv';

sub create {
    my ($channel, $nick, $request) = @_;

    use Text::ParseWords;
    my ($event, @dates) = parse_line(' ', 0, $request);

    my $events_ref  = tools::load_json_from_file($EVENTS_FILE);
    my $next_id     = calculate_next_id($events_ref);

    my $event_ref = {
        EVENT   => tools::untaint($event),
        OWNER   => $nick,
        CHANNEL => $channel,
        DATES   => check_dates( @dates ),
        STATUS  => 'CREATED',
    };

    $events_ref->{$next_id} = $event_ref;

    my $response = tools::write_data_to_json_file($EVENTS_FILE, $events_ref);

    if ($response == 1) {
        # File written successfully - return event id
        return($next_id, $event_ref->{EVENT});
    } else {
        return "Events data was not saved: $response";
    }
}

sub edit {
    my ($channel, $nick, $request) = @_;

    use Text::ParseWords;
    my ($event_id, $event_name, @dates) = parse_line(' ', 0, $request);

    my $events_ref  = tools::load_json_from_file($EVENTS_FILE);

    if (not defined $events_ref->{ $event_id }) {
        return(0, "Event ID $event_id not found");
    } elsif ($channel ne $events_ref->{ $event_id }{CHANNEL}) {
        return(0, "You must be in the event's channel");
    } elsif ($nick ne $events_ref->{ $event_id }{OWNER}) {
        return(0, "You are not the owner of event $event_id");
    }

    my $count = @dates;

    my $event_ref;
    if ($count == 0) {
        $event_ref = {
            EVENT   => tools::untaint($event_name),
            OWNER   => $nick,
            CHANNEL => $channel,
            DATES   => $events_ref->{ $event_id }{DATES},
            STATUS  => $events_ref->{ $event_id }{STATUS},
        };
    } else {
        $event_ref = {
            EVENT   => tools::untaint($event_name),
            OWNER   => $nick,
            CHANNEL => $channel,
            DATES   => check_dates( @dates ),
            STATUS  => $events_ref->{ $event_id }{STATUS},
        };
    }

    $events_ref->{ $event_id } = $event_ref;

    my $response = tools::write_data_to_json_file($EVENTS_FILE, $events_ref);

    if ($response == 1) {
        # File written successfully - return event id
        return($event_id, $event_ref->{EVENT});
    } else {
        return "Events data was not saved: $response";
    }
}

sub list {
    my $channel = shift;
    my $status  = shift;

    if (not defined $status) {
        $status = 'ALL';
    }
    $status = uc( $status );

    my $events_ref  = tools::load_json_from_file($EVENTS_FILE);

    my $filtered_ref = filter_by($events_ref, {
        STATUS  => $status,
        CHANNEL => $channel,
    });

    return $filtered_ref;
}

sub delete {
    my ($channel, $nick, $request) = @_;

    unless ($request =~ /^\d+$/) {
        return(0, "Please specify the event ID to be deleted");
    }

    my $events_ref  = tools::load_json_from_file($EVENTS_FILE);

    my $response = 0;
    my $message  = "Event $request not found";

    my %remaining;
    foreach my $event_id (keys %{ $events_ref }) {
        if ( ($event_id == $request) and ($channel eq $events_ref->{ $event_id }{CHANNEL}) and ($nick eq $events_ref->{ $event_id }{OWNER}) ) {
            # Skip record to delete it
            $response = 1;
            $message  = "Event $event_id deleted successfully.";
        } elsif ($event_id == $request) {
            $remaining{ $event_id } = $events_ref->{ $event_id };
            $response = 0;
            $message  = "You must be in the event channel and be the event owner to delete it.";
        } else {
            $remaining{ $event_id } = $events_ref->{ $event_id };
        }
    }

    if ($response == 0) {
        return($response, $message);
    }

    $response = tools::write_data_to_json_file($EVENTS_FILE, \%remaining);

    if ($response == 1) {
        return(1, $message);
    } else {
        return(0, "Events data was not saved: $response");
    }

}

sub detail {
    my ($channel, $nick, $request) = @_;

    unless ($request =~ /^\d+$/) {
        return(0, "Please specify the event ID to show");
    }

    my $events_ref  = tools::load_json_from_file($EVENTS_FILE);

    if (defined $events_ref->{ $request }) {
        return($request, $events_ref->{ $request });
    } else {
        return(0, "Event ID not found");
    }
}

sub eopen {
    my ($channel, $nick, $request) = @_;

    unless ($request =~ /^\d+$/) {
        return(0, "Please specify the event ID to open");
    }

    my $events_ref  = tools::load_json_from_file($EVENTS_FILE);

    if (not defined $events_ref->{ $request }) {
        return(0, "Event $request not found.");
    } elsif ( $events_ref->{ $request }{STATUS} eq 'OPEN' ) {
        return(0, "Event $request is already open.");
    }

    $events_ref->{ $request }{STATUS} = 'OPEN';

    my $response = tools::write_data_to_json_file($EVENTS_FILE, $events_ref);

    if ($response == 1) {
        return(1, "Event $request now open");
    } else {
        return(0, "Events data was not saved: $response");
    }

}

sub eclose {
    my ($channel, $nick, $request) = @_;

    unless ($request =~ /^\d+$/) {
        return(0, "Please specify the event ID to close");
    }

    my $events_ref  = tools::load_json_from_file($EVENTS_FILE);

    if (not defined $events_ref->{ $request }) {
        return(0, "Event ID not found");
    }

    $events_ref->{ $request }{STATUS} = 'CLOSED';

    my $response = tools::write_data_to_json_file($EVENTS_FILE, $events_ref);

    if ($response == 1) {
        return(1, "Event $request now closed");
    } else {
        return(0, "Events data was not saved: $response");
    }

}

sub accept {
    my ($channel, $nick, $request) = @_;

    # Check valid request
    if ($request !~ /^[0-9]+(?:[A-Za-z\s]+)?$/) {
        return(0, "Please enter in format: 1 A B C (spaces optional).");
    }

    # Make request consistent format 1ABC
    $request =~ tr/a-z/A-Z/;
    $request =~ s/\s*//g;

    my ($event_id, @date_ids) = split("", $request);

    # Check event ID exists
    my $events_ref  = tools::load_json_from_file($EVENTS_FILE);
    if (not defined $events_ref->{ $event_id }) {
        return(0, "Event $event_id not found");
    } elsif ( $events_ref->{ $event_id }{STATUS} ne 'OPEN' ) {
        return(0, "Event $event_id is not yet open");
    }

    my $dates_ref = map_dates($events_ref->{ $event_id }{DATES});

    # Create array of dates accepted
    my @dates;
    foreach my $date_id (sort @date_ids) {
        if (defined $dates_ref->{ $date_id }) {
            my $date = $dates_ref->{ $date_id };
            push(@dates, $date);
        }
    }

    my $dates = join(',', @dates);

    append_vote($channel,$nick,$event_id,$dates);

    $dates = join_with_comma_and(@dates);

    return(1, "You have accepted dates: $dates");
}

# Join array in format a, b and c
# 
sub join_with_comma_and {
    my @dates = @_;

    my $dates = join(', ', @dates);

    my $count = @dates;
    if ($count > 1) {
        $dates =~ s/,\s([^,]+)$/ and $1/;
    }

    return $dates;
}

sub append_vote {
    my ($channel, $nick, $event_id, $dates) = @_;

    open(my $fh_votes, ">>", $VOTES_FILE) 
        or die "Cannot write to $VOTES_FILE: $!";

    print $fh_votes "$channel,$nick,$event_id,$dates\n";

    close($fh_votes) or die "Cannot close $VOTES_FILE: $!";

    return;
}

sub map_dates {
    my $dates_ref = shift;

    my %dates;
    my $char = 65;
    foreach my $date (sort @{ $dates_ref }) {
        $dates{ chr($char) } = $date;
        $char++;
    }

    return \%dates;
}

sub filter_by {
    my $events_ref  = shift;
    my $filters_ref = shift;

    my %filtered;
    foreach my $event_id (sort keys %{ $events_ref }) {
        if ( (defined $filters_ref->{STATUS}) and ($filters_ref->{STATUS} ne 'ALL') and ($events_ref->{ $event_id }{STATUS} ne $filters_ref->{STATUS}) ) {
            next;
        }
        if ( (defined $filters_ref->{OWNER}) and ($filters_ref->{OWNER} ne 'ALL') and ($events_ref->{ $event_id }{OWNER} ne $filters_ref->{OWNER}) ) {
            next;
        }
        if ( (defined $filters_ref->{CHANNEL}) and ($filters_ref->{CHANNEL} ne 'ALL') and ($events_ref->{ $event_id }{CHANNEL} ne $filters_ref->{CHANNEL}) ) {
            next;
        }
        $filtered{ $event_id } = $events_ref->{ $event_id };
    }

    return \%filtered;
}

sub check_dates {
    my @dates = @_;

    my @untainted;
    foreach my $date (@dates) {
        my $untainted_date = tools::untaint( $date );
        # todo - consider checking date format
        push(@untainted, $untainted_date);
    }

    return \@untainted;
}

sub calculate_next_id {
    my $events_ref = shift;

    my ($last_id) = reverse sort keys %{ $events_ref };

    if (defined $last_id) {
        $last_id++;
    } else {
        $last_id = 1;
    }

    return $last_id;
}
