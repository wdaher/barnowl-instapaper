use warnings;
use strict;

=head1 NAME

BarnOwl::Module::Instapaper

=head1 DESCRIPTION

Lets you save stuff to read later, on instapaper.

=cut

package BarnOwl::Module::Instapaper;

our $VERSION = 0.1;

require URI::Find::Schemeless;
use LWP::UserAgent;
use JSON;
use BarnOwl;

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
    ## TODO: maybe allow you to manually specify a url as an argument?
    my $cmd = shift;
    my $args = join(" ", @_);
    my $m = BarnOwl::getcurmsg();
    my $body = $m->body;

    ## Borrowed from http://perladvent.pm.org/2002/1st/
    # a list of the urls
    my @urls;
    my $actually_found_anything = 0;
    my $finder = URI::Find::Schemeless->new(sub {
	my $uri    = shift;  # object representing the url
	my $string = shift;  # text that was in the url
	# remember the $uri's address by adding it to @urls which
	# we can see from within this sub
	push @urls, $uri->abs;
	$actually_found_anything = 1;
	# return the original text back to leave the text
	# we were searching unaltered
	return $string;
     });

    # and process the text through that finder
    $finder->find(\$body);

    if ( $actually_found_anything ) {
	foreach my $url (@urls)
	{
	    process_url($url);
	}
    } else {
	BarnOwl::message("Sorry, homie, we didn't actually find any URLs in your message.");
    }
}

sub process_url {
    my $url = shift;
    BarnOwl::message("Trying to add $url...");

    my $req = HTTP::Request->new(POST => 'https://www.instapaper.com/api/add');
    $req->content_type('application/x-www-form-urlencoded');
    $req->content("username=$username&password=$password&url=$url");

    my $res = $ua->request($req);
    if ( $res->is_success ) {
	BarnOwl::message("Added $url to Instapaper. Enjoy!");
    } else {
	BarnOwl::message("Sorry, something went wrong: " . $res->status_line);
    }
}

BarnOwl::new_command(readlater => \&cmd_readlater, {
    summary => "Save a URL to Instapaper for later reading",
    usage   => "readlater [zephyr command-line]",
    description => "Scans the currently-selected message for a URL and saves it to your Instapaper account."
   });

1;
