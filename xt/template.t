# Template for writing a new tests

use 5.006;
use strict;
use warnings;
use feature 'say';

use Data::Dumper;
use Data::Printer;
$Data::Dumper::Maxdepth = 1;

use WebService::GoogleAPI::Client;

use Test::More;

my $default_file = $ENV{'GOOGLE_TOKENSFILE'} || 'gapi.json';
my $user         = $ENV{'GMAIL_FOR_TESTING'} || ''; ## TODO - populate from gapi.json if needed
my $gapi = WebService::GoogleAPI::Client->new( debug => 0 );

if ( $gapi->auth_storage->file_exists($default_file) ) {
    $gapi->auth_storage->setup( { type => 'jsonfile', path => $default_file } );
    $gapi->user($user);

    subtest 'CalendarList->list subtest' => sub {
        ok(1);
        ## place your subtests here
    };

}
else {
    say 'Cant run test cause json file with tokens not exists!';
}

done_testing();
