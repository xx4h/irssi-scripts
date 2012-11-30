#######################################################################
# Dependencies:
# install the perl module "WWW::Mechanize"
#
# Settings:
# /set bitly_apikey R_YOURKEY12345
# /set bitly_login LOGIN
# /set bitly_public ON/OFF (ON posts in channel / OFF posts private)
# /set bitly_output LOOK AT THIS URL (only needed if bitly_public ON)
#
# Usage:
# /bitly URL
# posts bit.ly-shortened url in the active window
# you can see the link in your bit.ly account
#
#######################################################################

use strict;
use WWW::Mechanize;

use vars qw($VERSION %IRSSI);

use Irssi qw(command_bind);
$VERSION = '1.01';
%IRSSI = (
 authors        => 'xx4h',
 contact        => 'melters@gmail.com',
 name           => 'bitly',
 description    => 'This script shortens'.
                   'a url via bit.ly api'.
                   'using a bit.ly account',
 changed        => 'Mon, Nov 26 2011',
 license        => 'Public Domain',
);


sub short {
my ($data, $server, $witem) = @_;

  my $login = Irssi::settings_get_str("bitly_login");
  my $apiKey = Irssi::settings_get_str("bitly_apikey");
  my $output = Irssi::settings_get_str("bitly_output");

  if (!$login || !$apiKey) {
      Irssi::print('You didn\'t set the login and/or apiKey', MSGLEVEL_CRAP);
      Irssi::print('You can find both here: http://bitly.com/a/your_api_key',MSGLEVEL_CRAP);
      return 0;
  }

  if (not $data) {
    Irssi::print('Usage: /bitly [url]', MSGLEVEL_CRAP);
    return 0;
  }

  my $shortthis = $data;

  $shortthis =~ s/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

  # building the bitly-api-string
  my $url_bitly_api = "https://api-ssl.bitly.com/v3/shorten?format=txt&login=$login&apiKey=$apiKey&longUrl=$shortthis";

  # set up the www-agent
  my $agent = WWW::Mechanize->new();

  eval{
      $agent->get($url_bitly_api);
  };
  if ($@){
      Irssi::print("Bitly warning: something went wrong, check url and try again", MSGLEVEL_CRAP);
      return 0;
  }
  my $shortened = $agent->content(format => 'txt');
  chomp($shortened);
  if (Irssi::settings_get_bool("bitly_public") == 0) {
    Irssi::print("Shortened URL: $shortened", MSGLEVEL_CRAP);
  }
  if (Irssi::settings_get_bool("bitly_public") == 1) {
    $witem->command("/SAY $output $shortened");
  }


}
Irssi::settings_add_str("misc", "bitly_apikey", undef);
Irssi::settings_add_str("misc", "bitly_login", undef);
Irssi::settings_add_str("misc", "bitly_output", 'here teh url:');
Irssi::settings_add_bool("misc", "bitly_public", 0);

Irssi::command_bind bitly => \&short;
