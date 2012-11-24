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
# Changelog:
# - added setting for posting the requested url in active channel
#   or private
# - added setting for adding a text which is set in front of the url
#   if u are posting in the active channel
#
#######################################################################

use strict;
use WWW::Mechanize;

use vars qw($VERSION %IRSSI);

use Irssi qw(command_bind);
$VERSION = '0.1';
%IRSSI = (
 authors        => 'xx4h',
 contact        => 'melters@gmail.com',
 name           => 'bitly',
 description    => 'This script shortens'.
                   'a url via bit.ly api'.
                   'using a bit.ly account',
 changed        => 'Mon, Feb 22 23:27 2011',
 license        => 'Public Domain',
);



sub short {
my ($data, $server, $witem) = @_;
  my $login = Irssi::settings_get_str("bitly_login");
  my $apikey = Irssi::settings_get_str("bitly_apikey");
  my $output = Irssi::settings_get_str("bitly_output");
if (not $data) {
  Irssi::print('Usage: /bitly [url]', MSGLEVEL_CRAP);
  return 0;
}

  my $shortthis = $data;

  $shortthis =~ s/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

  # split url into parts...not a very nice solution =)
  my $url_base = "http://api.bitly.com/v3/shorten?login=";
  my $url_apiKey = "&apiKey=";
  my $url_longUrl = "&longUrl=";
  my $url_format = "&format=txt";

  # get url back to one
  my $url = $url_base.$login.$url_apiKey.$apikey.$url_longUrl.$shortthis.$url_format;

  my $agent = WWW::Mechanize->new();

  eval{
      $agent->get($url);
  };
  if ($@){
      Irssi::print("Bitly warning: something went wrong, check url and try again", MSGLEVEL_CRAP);
      return 0;
  }
  my $shortened = $agent->content(format => 'text');
if (Irssi::settings_get_bool("bitly_public") == 0) {
  Irssi::print("Requested URL: $shortened", MSGLEVEL_CRAP);
}
if (Irssi::settings_get_bool("bitly_public") == 1) {
  Irssi::print("$output, $shortened", MSGLEVEL_PUBLIC);
}


}
Irssi::settings_add_str("misc", "bitly_apikey", '');
Irssi::settings_add_str("misc", "bitly_login", '');
Irssi::settings_add_str("misc", "bitly_output", 'here teh url');
Irssi::settings_add_bool("misc", "bitly_public", 0);

Irssi::command_bind bitly => \&short;
