########################################################################
# Dependencies:
# install the perl module "WWW::Mechanize"
#
# Settings:
# /set gbpaste_standard_lang LANG
# /set gbpaste_output_public ON/OFF (post public or not)
# /set gbpaste_output_message HERE THE URL (only needed if public post)
# /set gbpaste_private_data ON/OFF (privates your data on gbpaste)
# /set gbpaste_private_nick ON/OFF (set Name with your nick or anonymus)
# /set gbpaste_display_paste ON/OFF (if on all you paste will be displayed
#                                   [only to see for you])
#
# Usage:
# /read
# Write/Paste all u want to get on gbpaste.org
# /paste [-l [LANG]]
# - only -l argument will show u a list of available code-langs
# - with -l LANG will post it to gbpaste in choosen language
# - without anything the gbpaste_standard_lang is used
#
# if there are bugs etc. pls mail to me =) thx
#
#######################################################################
# Changelog:
# - added options for public/private
# - added some exception handling
#
######################################################################

use strict;
use WWW::Mechanize;

use vars qw($VERSION %IRSSI $PWD);

use Irssi qw(command_bind);
$VERSION = '0.14';
%IRSSI = (
    authors     =>  'xx4h',
    contact     =>  'xx4h.h4xx@gmail.com',
    name        =>  'paste',
    description =>  'This script auto-paste'.
                    'your lines to gbpaste.org'.
                    'and posts the link to it'.
                    'in the channel',
    changed     =>  'Mon, Feb 21 02:39 2011',
    license     =>  'Public Domain',
);

my $url = "http://gbpaste.org/index.php";
my @_paste = undef;
my @langs;

my $nickname = Irssi::settings_get_str("nick");

eval {
    open FILE, "<$PWD.irssi/scripts/langs";
    @langs = <FILE>;
    Irssi::print("PasteScript:". ($#langs + 1) ." language codes loaded", MSGLEVEL_CRAP);
    close FILE;
};
if ($@) {
    Irssi::print("languages file not found", MSGLEVEL_CRAP);
};


sub begin_paste {
    my ($arg, $server, $witem) = @_;
    @_paste = ();
    Irssi::signal_add_first("send text", "paste");
}

sub paste {
    my ($data) = @_;
    push @_paste, $data;
    if (Irssi::settings_get_bool("gbpaste_display_paste") == 1) {
        Irssi::print("$data", MSGLEVEL_CRAP);
    }
    Irssi::signal_stop();
}


sub stop_paste {
    my ($args) = @_;
    my $output_message = Irssi::settings_get_str("gbpaste_output_message");
    my $language;
    my @arguments = split(' ', $args);


    my $count = @arguments;
    for (my $i=0;$i<$count;$i++) {
    if (@arguments[$i] =~ /^-l/) {
        my $argu = @arguments[$i + 1];
        if ($argu eq undef) {
                        Irssi::print("@langs", MSGLEVEL_CRAP);
                        Irssi::print("Use one of the above langs");
                        return;
                }
        for (my $t=0;$t<=$#langs;$t++) {

            if (@langs[$t] eq "$argu\n") {
                $language = $argu;
                Irssi::print("posting with $language format");
            }
        }
        if ($language eq undef) {
                        Irssi::print("$argu is not in the library! Type \"/paste -l\" to get the list");
                        return;
                }

        }
    }
    if ($language eq undef) {
    $language = Irssi::settings_get_str("gbpaste_standard_lang");
        Irssi::print("Sending with standard language: $language");
    }
    Irssi::signal_remove("send text", "paste");
    Irssi::print('Sending ' . ($#_paste + 1) . ' lines to gbpaste.org...');

    my $data;
    $data = join("\n", @_paste);
    if ($data eq undef) {
    Irssi::print("there is nothing to paste!", MSGLEVEL_CRAP);
    return 0;
    }
    my $agent = WWW::Mechanize->new();

    $agent->agent_alias("Windows Mozilla");
    eval {
    $agent->get($url);
    }; #die "no success :(" ,$agent->response->status_line unless $agent->success;
    if ($@) {
    Irssi::print("something went wrong, pls try again", MSGLEVEL_CRAP);
    };
    $agent->field("code", $data);

    # nick or anonymus
    if (Irssi::settings_get_bool("gbpaste_private_nick") == 0) {
    $agent->field("nick", $nickname);
    } else {
    $agent->field("nick", "anonymus");
    }

    # private or not
    if (Irssi::settings_get_bool("gbpaste_private_data") == 1) {
    $agent->tick("private", 'on');
    }

    if ($language eq undef) {
    $agent->field("lang", "text");
    } else {
    $agent->field("lang", $language);
    }
    $agent->click();



    my $pasteurl = $agent->uri();
    if (Irssi::settings_get_bool("gbpaste_output_public") == 0) {
    Irssi::print("gbpaste URL: $pasteurl", MSGLEVEL_CRAP);
    } else {
    Irssi::print("$output_message, $pasteurl", MSGLEVEL_PUBLIC);
    }

}
Irssi::settings_add_str("misc", "gbpaste_output_message", "here teh url");
Irssi::settings_add_bool("misc", "gbpaste_output_public", 0);
Irssi::settings_add_bool("misc", "gbpaste_private_data", 0);
Irssi::settings_add_bool("misc", "gbpaste_private_nick", 0);
Irssi::settings_add_bool("misc", "gbpaste_display_paste", 0);
Irssi::settings_add_str("misc", "gbpaste_standard_lang", "text");

Irssi::command_bind read => \&begin_paste;
Irssi::command_bind paste => \&stop_paste;

