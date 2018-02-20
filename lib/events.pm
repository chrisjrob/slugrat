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
    scores
);

our $VERSION     = 1.00;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = @functions;
our %EXPORT_TAGS = (
    DEFAULT => [@functions],
    ALL     => [@functions],
);

# Create an event from a name followed by a list of dates
#
sub create {
    my ($channel, $nick, $request) = @_;

    use Text::ParseWords;
    my ($event, @dates) = parse_line(' ', 0, $request);
    splice( @dates, 12, );

    my $count = @dates;
    if ($count < 2) {
        return "You must add at least two dates";
    }

    my $events_ref  = tools::load_json_from_file("data/${channel}_events.json");
    my $next_id     = calculate_next_id($events_ref);

    my $event_ref = {
        EVENT   => tools::untaint($event),
        OWNER   => $nick,
        CHANNEL => $channel,
        DATES   => check_dates( @dates ),
        STATUS  => 'CREATED',
    };

    $events_ref->{$next_id} = $event_ref;

    my $response = tools::write_data_to_json_file("data/${channel}_events.json", $events_ref);

    if ($response == 1) {
        # File written successfully - return event id
        return($next_id, $event_ref->{EVENT});
    } else {
        return "Events data was not saved: $response";
    }
}

# Edit an existing event from 
# event_id "name of event" list of dates
#
sub edit {
    my ($channel, $nick, $request, $isop) = @_;

    use Text::ParseWords;
    my ($event_id, $event_name, @dates) = parse_line(' ', 0, $request);

    my $events_ref  = tools::load_json_from_file("data/${channel}_events.json");

    if (not defined $events_ref->{ $event_id }) {
        return(0, "Event ID $event_id not found");
    } elsif ($channel ne $events_ref->{ $event_id }{CHANNEL}) {
        return(0, "You must be in the event's channel");
    } elsif ( ($nick ne $events_ref->{ $event_id }{OWNER}) and (not $isop) ) {
        return(0, "You are not the owner of event $event_id");
    } elsif ($events_ref->{ $event_id }{STATUS} eq 'OPEN') {
        return(0, "The event is currently open and cannot be edited");
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

    my $response = tools::write_data_to_json_file("data/${channel}_events.json", $events_ref);

    if ($response == 1) {
        # File written successfully - return event id
        return($event_id, $event_ref->{EVENT});
    } else {
        return "Events data was not saved: $response";
    }
}

# List events in format required by edit function
#
sub list {
    my $channel = shift;
    my $request = shift;

    my $status = 'OPEN';
    my $event_id = 'ALL';

    if ($request =~ /^\s*(\d+)$/) {
        $event_id   = $1;
        $status     = 'ALL';
    } elsif ($request =~ /^([A-Za-z]+)$/) {
        $status = requested_status($1);
    }

    my $events_ref  = tools::load_json_from_file("data/${channel}_events.json");

    my $filtered_ref = filter_by($events_ref, {
        EVENT   => $event_id,
        STATUS  => $status,
        CHANNEL => $channel,
    });

    return $filtered_ref;
}

# Delete event
#
sub delete {
    my ($channel, $nick, $request, $isop) = @_;

    my $event_id = tools::untaint($request);

    unless ($event_id =~ /^\d+$/) {
        return(0, "Please specify the event ID to be deleted");
    }

    my $events_ref  = tools::load_json_from_file("data/${channel}_events.json");

    # Pre-delete validations
    if (not defined $events_ref->{ $event_id }) {
        return(0, "Event ID $event_id not found");
    } elsif ($channel ne $events_ref->{ $event_id }{CHANNEL}) {
        return(0, "You must be in the event's channel");
    } elsif ( ($nick ne $events_ref->{ $event_id }{OWNER}) and (not $isop) ) {
        return(0, "You are not the owner of event $event_id");
    } elsif ($events_ref->{ $event_id }{STATUS} ne 'CLOSED') {
        return(0, "The event $event_id is not yet closed");
    }

    delete $events_ref->{ $event_id };

    my $response = tools::write_data_to_json_file("data/${channel}_events.json", $events_ref);

    if ($response == 1) {
        purge_votes_for_event( $channel, $event_id );
        return(1, "Event $event_id deleted successfully");
    } else {
        return(0, "Events data was not saved: $response");
    }

}

# Return detail for event
# as list of dates with scores against each
#
sub detail {
    my ($channel, $nick, $request) = @_;

    my $event_id = tools::untaint($request);

    unless ($event_id =~ /^\d+$/) {
        return(0, "Please specify the event ID");
    }

    my $events_ref  = tools::load_json_from_file("data/${channel}_events.json");
    my $scores_ref  = scores_by_date( $channel );

    if (defined $events_ref->{ $event_id }) {
        return($request, $events_ref->{ $event_id }, $scores_ref);
    } else {
        return(0, "Event ID $event_id not found");
    }
}

# Open event for voting
#
sub eopen {
    my ($channel, $nick, $request, $isop) = @_;

    my $event_id = tools::untaint($request);

    unless ($event_id =~ /^\d+$/) {
        return(0, "Please specify the event ID to open");
    }

    my $events_ref  = tools::load_json_from_file("data/${channel}_events.json");

    if (not defined $events_ref->{ $event_id }) {
        return(0, "Event $event_id not found.");
    } elsif ( $events_ref->{ $event_id }{STATUS} eq 'OPEN' ) {
        return(0, "Event $event_id is already open.");
    } elsif ( ( $events_ref->{ $event_id }{OWNER} ne $nick ) and (not $isop) ) {
        return(0, "Only the event owner or an operator can do that.");
    }

    $events_ref->{ $event_id }{STATUS} = 'OPEN';

    my $response = tools::write_data_to_json_file("data/${channel}_events.json", $events_ref);

    if ($response == 1) {
        return(1, "Event $event_id now open");
    } else {
        return(0, "Events data was not saved: $response");
    }

}

# Close event for voting
#
sub eclose {
    my ($channel, $nick, $request, $isop) = @_;

    my $event_id = tools::untaint($request);

    unless ($event_id =~ /^\d+$/) {
        return(0, "Please specify the event ID to close");
    }

    my $events_ref  = tools::load_json_from_file("data/${channel}_events.json");

    if (not defined $events_ref->{ $event_id }) {
        return(0, "Event ID not found");
    } elsif ( ( $events_ref->{ $event_id }{OWNER} ne $nick ) and (not $isop) ) {
        return(0, "Only the event owner or an operator can do that.");
    }

    $events_ref->{ $event_id }{STATUS} = 'CLOSED';

    my $response = tools::write_data_to_json_file("data/${channel}_events.json", $events_ref);

    if ($response == 1) {
        return(1, "Event $event_id now closed");
    } else {
        return(0, "Events data was not saved: $response");
    }

}

# User vote
#
sub accept {
    my ($channel, $nick, $request) = @_;

    # Decipher user input from 12ABC
    my ($event_id, @date_ids) = read_event_date_input( $request );
    return( $event_id, $date_ids[0] ) if ($event_id == 0);

    # Load events as may be required in similar functions like select
    my $events_ref  = tools::load_json_from_file("data/${channel}_events.json");

    # Check event ID exists
    if (not defined $events_ref->{ $event_id }) {
        return(0, "Event $event_id not found");
    }

    # Check event is open
    if ( $events_ref->{ $event_id }{STATUS} ne 'OPEN' ) {
        return(0, "Event $event_id is not yet open");
    }

    # Generate a list of dates from the input date ids
    my @dates = list_dates_from_ids( $channel, $request, $events_ref, $event_id, @date_ids );
 
    # Check there is at least one matching date
    my $count = @dates;
    if ($count == 0) {
        return( 0, "No dates have been selected");
    }

    # Save vote
    my $dates = join(',', @dates);
    my $response = append_vote($channel,$nick,$event_id,$dates);

    # Return confirmation message
    $dates = join_with_comma_and(@dates);

    if ($response == 1) {
        # File written successfully - return event id
        return(1, "You have accepted dates: $dates");
    } else {
        return(0, "Your date choices were not saved: $response");
    }

}

# Select final date
#
sub select {
    my ($channel, $nick, $request, $isop) = @_;

    # Decipher user input from 12ABC
    my ($event_id, @date_ids) = read_event_date_input( $request );
    return( $event_id, $date_ids[0] ) if ($event_id == 0);

    # Load events 
    my $events_ref  = tools::load_json_from_file("data/${channel}_events.json");

    # Pre-select validations
    if (not defined $events_ref->{ $event_id }) {
        return(0, "Event ID $event_id not found");
    } elsif ($channel ne $events_ref->{ $event_id }{CHANNEL}) {
        return(0, "You must be in the event's channel");
    } elsif ( ($nick ne $events_ref->{ $event_id }{OWNER}) and (not $isop) ) {
        return(0, "You are not the owner of event $event_id");
    } elsif ($events_ref->{ $event_id }{STATUS} ne 'CLOSED') {
        return(0, "The event $event_id is not yet closed");
    }

    # Generate a list of dates from the input date ids
    my @dates = list_dates_from_ids( $channel, $request, $events_ref, $event_id, @date_ids );

    # Check there is at least one matching date
    my $count = @dates;
    if ($count == 0) {
        return(0, "No dates have been selected");
    }

    # Add Scheduled dates
    $events_ref->{ $event_id }{SCHEDULED} = \@dates;
    my $response = tools::write_data_to_json_file("data/${channel}_events.json", $events_ref);

    # Return confirmation message
    my $dates = join_with_comma_and(@dates);

    if ($response == 1) {
        # File written successfully - return event id
        return(1, "You have selected dates: $dates");
    } else {
        return(0, "Your date choices were not saved: $response");
    }

}


################################## INTERNAL FUNCTIONS ###################################


# Accepts requested status and returns either
# untainted and validated input or 
# returns OPEN - i.e. default status
#
sub requested_status {
    my $request = shift;

    my $status = 'OPEN';
    if ($request =~ /^\s*(all|created|open|closed)\s*$/i) {
        $status = uc($1);
    }
        
    return $status;
}

# Return a date list by checking 
# event dates against input date ids
#
sub list_dates_from_ids {
    my ($channel, $request, $events_ref, $event_id, @date_ids) = @_;

    my $dates_ref = dates_by_id($events_ref->{ $event_id }{DATES});

    my @dates;
    if ($request =~ /^\d+\s*(?:any|all)$/i) {
        @dates = @{ $events_ref->{ $event_id }{DATES} };
    } elsif ($request =~ /^\d+\s*(?:none)$/i) {
        # Leave @dates empty
    } else {
        # Create array of dates accepted
        foreach my $date_id (sort @date_ids) {
            if (defined $dates_ref->{ $date_id }) {
                my $date = $dates_ref->{ $date_id };
                push(@dates, $date);
            }
        }
    }

    return @dates;
}

# Take 1ABC request 
# Return 1, A, B, C
#
sub read_event_date_input {
    my $request = shift;

    # Untaint and split
    my ($event_id, $date_str);
    if ($request =~ /^([0-9]+)([A-Za-z\s,]+)?$/) {
        ($event_id, $date_str) = ($1, $2);
    } else {
        return(0, "Please enter in format: 1 A B C (spaces optional).");
    }

    # Make request consistent format ABC
    $date_str =~ tr/a-z/A-Z/;
    $date_str =~ s/[\s,]*//g;

    my @date_ids = split("", $date_str);

    return( $event_id, @date_ids );
}

# Accepts an Event ID and
# return a hash ref of scores by date
#
sub scores_by_date {
    my ($channel, $event_id) = @_;
    
    my $scores_ref          = load_scores_for_channel( $channel );
    my $scores_by_date_ref  = map_scores_by_date( $scores_ref );

    return $scores_by_date_ref;
}

# Loads all scores from CSV
# earlier votes are overwritten by later votes
# returns hash ref
#
sub load_scores_for_channel {
    my $channel = shift;

    my $filename = "data/${channel}_votes.csv";

    if (! -e $filename) {
        return;
    }

    open(my $fh_votes, '<', $filename) 
        or die "Cannot read from $filename $!";

    my %scores;
    while ( defined(my $line = <$fh_votes>) ) {
        chomp($line);
        my ($chan, $nick, $evid, @dates) = split(',', $line);

        next if ($chan ne $channel);

        # Allow later votes to overwrite earlier votes
        $scores{ $evid }{ $nick } = \@dates;
    }

    close($fh_votes) or die "Cannot close $filename $!";

    return \%scores;
}

# Accept scores hash ref by nick 
# return scores hash ref by date
#
sub map_scores_by_date {
    my $scores_ref = shift;    

    my %scores;
    foreach my $event_id (sort keys %{ $scores_ref }) {
        foreach my $nick (sort keys %{ $scores_ref->{ $event_id } }) {
            foreach my $date (sort @{ $scores_ref->{ $event_id }{ $nick } }) {
                push( @{ $scores{ $event_id }{ $date } }, $nick );
            }
        }
    }

    return \%scores;

}


# Join array in format a, b and c
# 
sub join_with_comma_and {
    my @dates = @_;

    my $count = @dates;
    if ($count == 0) {
        return "None";
    }

    my $dates = join(', ', @dates);

    if ($count > 1) {
        $dates =~ s/,\s([^,]+)$/ and $1/;
    }

    return $dates;
}

sub append_vote {
    my ($channel, $nick, $event_id, $dates) = @_;

    my $filename = "data/${channel}_votes.csv";

    open(my $fh_votes, ">>", $filename) 
        or die "Cannot write to $filename $!";

    print $fh_votes "$channel,$nick,$event_id,$dates\n";

    close($fh_votes) or die "Cannot close $filename: $!";

    return 1;
}

sub dates_by_id {
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
        if ( (defined $filters_ref->{EVENT}) and ($filters_ref->{EVENT} ne 'ALL') and ($event_id ne $filters_ref->{EVENT}) ) {
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

sub purge_votes_for_event {
    my ($channel, $event_id) = @_;

    my $filename    = "data/${channel}_votes.csv";
    my $tempfile    = "$filename.temp";

    open(my $fh_votes, "<", $filename) 
        or die "Cannot read from $filename $!";

    open(my $fh_temp, ">", $tempfile) 
        or die "Cannot write to $tempfile $!";

    while ( defined(my $line = <$fh_votes>) ) {
        chomp($line);
        my ($chan, $nick, $evid, @dates) = split(',', $line);

        if ($evid == $event_id) {
            # skip
        } else {
            print $fh_temp "$line\n";
        }
    }

    close($fh_temp) or die "Cannot close $tempfile $!";
    close($fh_votes) or die "Cannot close $filename: $!";

    rename($tempfile, $filename) or die "Cannot rename $tempfile to $filename: $!";

    return;
}

