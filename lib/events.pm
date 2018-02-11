package events;

use strict;
use Exporter;
use tools;

my @functions = qw(
    create
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
    my $options_ref = shift;

    # CHANNEL => $channel,
    # NICK    => $nick,
    # EVENT   => $event,
    # DATES   => [@dates],

    my $events_ref  = load_json_from_file($EVENTS_FILE);
    my $next_id     = calculate_next_id($events_ref);

    my $event_ref = {
        EVENT   => untaint($options_ref->{EVENT}),
        OWNER   => $options_ref->{NICK},
        CHANNEL => $options_ref->{CHANNEL},
        DATES   => check_dates( $options_ref->{DATES} ),
    };

    $events_ref->{$next_id} = $event_ref;

    my $response = write_data_to_json_file($EVENTS_FILE, $events_ref);

    if ($response == 1) {
        # File written successfully - return event id
        return $next_id;
    } else {
        return "Events data was not saved";
    }
}

sub check_dates {
    my $dates_array_ref = shift;

    my @dates;
    foreach my $date (@{ $dates_array_ref }) {
        my $untainted_date = untaint( $date );
        # todo - consider checking date format
        push(@dates, $untainted_date);
    }

    return \@dates;
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
