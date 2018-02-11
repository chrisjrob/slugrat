package tools;

use strict;
use Exporter;

my @functions = qw(
    untaint
    load_json_from_file
    write_data_to_json_file
);

our $VERSION     = 1.00;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = @functions;
our %EXPORT_TAGS = (
    DEFAULT => [@functions],
    ALL     => [@functions],
);

sub untaint {
    my $tainted = shift;

    # Remove unapproved characters
    $tainted =~ s/[^\w\d\-\s()]//g;

    # Untaint remainder
    $tainted =~ m/^([\w\d\-\s()]+)$/;

    my $untainted = $1;

    return $untainted;
}

sub load_json_from_file {
    my $file = shift;

    use File::Slurp qw(read_file);
    use JSON;

    my $json = '{}';
    if ( (defined $file) and (-e $file) ) {
        $json = read_file($file);
    }
    my $data  = from_json($json, {utf8 => 0}); 

    return $data;
}

sub write_data_to_json_file {
    my($filename, $ref) = @_;

    use File::Slurp qw(write_file);
    use JSON;

    my $response = write_file($filename, to_json($ref));
    return $response;
}

