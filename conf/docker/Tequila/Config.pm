=head1 NAME

B<Tequila::Config> - Autoconfigure L<Tequila::Client>

=cut

package Tequila::Config;

our ($server, $serverurl, $sessionsdir);

sub want_test_tequila {
    # This is 2022. We run things out of containers. We don't parse
    # `hostname` anymore.
    return ($ENV{TEQUILA_ENVIRONMENT} || "meh.") eq "test";
}

$sessionsdir = "/var/www/Tequila/Sessions";
$server = want_test_tequila ? "test-tequila.epfl.ch" : "tequila.epfl.ch";
$serverurl = "https://${server}/tequila/";
warn $serverurl;

1;
