use warnings;
use strict;

=head1 NAME

BarnOwl::Module::Instapaper

=head1 DESCRIPTION

Lets you save stuff to read later, on instapaper.

=cut

package BarnOwl::Module::Instapaper;

our $VERSION = 0.1;

sub cmd_readlater {
    my $cmd = shift;
    my $args = join(" ", @_);
}

sub trim {
    my $s = shift;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    return $s;
}

sub colorize {
    my $text = shift;
    my $num = shift;
    my $color;
    if($num <= 3) { $color = "green" }
    elsif($num <= 6) {$color = "yellow"}
    else {$color = "red";}

    return '@<@color(' . $color . ")$text>";
}

BarnOwl::new_command(readlater => \&cmd_readlater, {
    summary => "Save a URL to Instapaper for later reading",
    usage   => "readlater [zephyr command-line]",
    description => "Scans the currently-selected message for a URL and saves it to your Instapaper account."
   });

1;
