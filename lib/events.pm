package events;

use strict;
use Exporter;
use tools;

my @functions = qw(
    create
    add
    list
);

our $VERSION     = 1.00;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = @functions;
our %EXPORT_TAGS = (
    DEFAULT => [@functions],
    ALL     => [@functions],
);
our $EVENTS_FILE = 'events.json';
our $VOTES_FILE  = 'votes.json';

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
