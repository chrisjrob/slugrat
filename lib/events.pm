package events;

use strict;
use Exporter;

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

sub create {
    my $options = shift;
    
    # CHANNEL => $channel,
    # NICK    => $nick,
    # EVENT   => $event,
    # DATES   => [@dates],


}
