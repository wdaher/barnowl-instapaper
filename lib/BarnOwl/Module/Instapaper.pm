use warnings;
use strict;

=head1 NAME

BarnOwl::Module::Instapaper

=head1 DESCRIPTION

Lets you save stuff to read later, on instapaper.

=cut

package BarnOwl::Module::Instapaper;

our $VERSION = 0.1;

use BarnOwl;
require URI::Find::Schemeless;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use JSON;

my $conffile = BarnOwl::get_config_dir() . "/instapaper";
open(my $fh, "<", "$conffile") || fail("Unable to read $conffile");
my $cfg = do {local $/; <$fh>};
close($fh);
eval {
    $cfg = from_json($cfg);
};
if($@) {
    fail("Unable to parse ~/.owl/instapaper: $@");
}
my $username = $cfg->{user};
my $password = $cfg->{password};

my $ua = LWP::UserAgent->new;
$ua->agent("BarnOwl-Instapaper/$VERSION");

sub cmd_readlater {
    my $msg = BarnOwl::getcurmsg();
    my $body = $msg->body;
    my $class = $msg->class;
    my $instance = $msg->instance;
    my $sender = $msg->sender;
    $sender =~ s/\@ATHENA.MIT.EDU//;
    my $selection = "($class / $instance / $sender)\n$body";
    if ( $msg->type eq 'Twitter' ) {
	$selection = "(\@$sender) $body";
    }

    ## Find all URLs and add them to @urls
    ## --- Borrowed from http://perladvent.pm.org/2002/1st/
    my @urls;
    my $actually_found_anything = 0;
    my $finder = URI::Find::Schemeless->new(sub {
	my $uri    = shift;  # object representing the url
	my $string = shift;
	push @urls, $uri->abs;
	$actually_found_anything = 1;
	return $string;
     });
    $finder->find(\$body);

    my $success = 0;
    if ( $actually_found_anything ) {
	foreach my $url (@urls)
	{
	    $success += process_url($url, $selection);
	}
    } else {
	BarnOwl::message("Sorry, homie, we didn't actually find any URLs in your message.");
    }
    
    if ( $success && $cfg->{'delete-after-success'} ) {
	$msg->delete();
	BarnOwl::command("recv:next");
    }
}

sub process_url {
    my $url = shift;
    my $selection = shift;
    BarnOwl::message("Trying to add $url...");
    my $req = POST 'https://www.instapaper.com/api/add', [ username  => $username,
							   password  => $password,
							   selection => $selection,
							   url       => $url ];

    my $res = $ua->request($req);
    if ( $res->is_success ) {
	BarnOwl::message("Added $url to Instapaper. Enjoy!");
	return 1;
    } else {
	BarnOwl::message("Sorry, something went wrong: " . $res->status_line);
	return 0;
    }
}

BarnOwl::new_command(readlater => \&cmd_readlater, {
    summary => "Save a URL to Instapaper for later reading",
    usage   => "readlater",
    description => "Scans the currently-selected message for a URL and saves it to your \n" .
	"Instapaper account."
   });

BarnOwl::command("bindkey recv I command readlater");

1;
