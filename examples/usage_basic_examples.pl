#!/usr/bin/env perl

use WebService::GoogleAPI::Client;
use Data::Dumper qw (Dumper);
use strict;
use warnings;
use File::Temp qw/ tempfile tempdir /;
use File::Which;



## assumes gapi.json configuration in working directory with scoped project and user authorization    
my $gapi_client = WebService::GoogleAPI::Client->new( debug=> 1, gapi_json => './gapi.json', user=> 'peter@shotgundriver.com' );


use Email::Simple;    ## RFC2822 formatted messages
use MIME::Base64;

my $r; ## using to contain result of queries ( Mojo::Message::Response instance )

my $my_email_address = 'peter@shotgundriver.com';


if ( 0 )
{
    print "Sending email to self\n";
    $r = $gapi_client->api_query( 
                            api_endpoint_id => 'gmail.users.messages.send',
                            options    => { raw => encode_base64( Email::Simple->create( header => [To => $my_email_address, From => $my_email_address, Subject =>"Test email from '$my_email_address' ",], body => "This is the body of email to '$my_email_address'", )->as_string ) },
                        );

}


my $text_to_speech_request_options =  {
        'input' => {
        'text' => 'Using the Web-Services-Google-Client Perl module, it is now a simple matter to access all of the Google API Resources in a consistent manner. Nice work Peter!'
        },
        'voice' => {
        'languageCode' => 'en-gb',
        'name' => 'en-GB-Standard-A',
        'ssmlGender' => 'FEMALE'
        },
        'audioConfig' => {
          'audioEncoding'=> 'MP3'
        }
    };

## Using this API requires authorised https://www.googleapis.com/auth/cloud-platform scope 

if ( 0 ) ## use a full manually constructed non validating standard user agent query builder approach ( includes auto O-Auth token handling )
{
    $r = $gapi_client->api_query( 
        method => 'POST',
        path   => 'https://texttospeech.googleapis.com/v1/text:synthesize',
        options => $text_to_speech_request_options
    ) ;

}
else  ## use the api end-point id and take full advantage of pre-submission validation etc
{
    $r = $gapi_client->api_query( 
        api_endpoint_id => 'texttospeech.text.synthesize', 
        # method => 'POST',                                                   ## not required as determined from API SPEC
        # path   => 'https://texttospeech.googleapis.com/v1/text:synthesize', ## not required as determined from API SPEC
        options => $text_to_speech_request_options
    ) ;
    ## NB - this approach will also autofill any defaults that aren't defined 
    ##      confirm that the user has the required scope before submitting to Google.
    ##      confirms that all required fields are populated
    ##      where an error is detected - result is a 418 code ( I'm a teapot ) with the body containing the error descriptions

}

if ( $r->is_success ) ## $r is a standard Mojo::Message::Response instance
{
  my $returned_data =  $r->json; ## convert from json to native hashref - result is a hashref with a key 'audioContent' containing synthesized audio in base64-encoded MP3 format
  my $decoded_mp3 = decode_base64( $returned_data->{audioContent} );

  my $tmp = File::Temp->new( UNLINK => 0, SUFFIX => '.mp3' ); ## should prolly unlink=1 if not planning to use output file in future
  print $tmp  $decoded_mp3;
  
  if ( which('ffplay') ) 
  {
    print "ffplay -nodisp  -autoexit  $tmp\n";
    `ffplay -nodisp  -autoexit  $tmp`;
      
  }
  close($tmp);

}
else 
{
    if ( $r->code eq '418' )
    {
        print qq{Cool - I'm a teapot - this was caught ebfore sending the request through to Google \n};
        print $r->body;
    }
    else ## other error - should appear in warnings but can inspect $r for more detail
    {
        print Dumper $r;
    }
    
}


#  
