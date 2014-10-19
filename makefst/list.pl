#!/usr/bin/env perl

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

input - veta + seznam parafrazi
output - seznam ruznych vet s parafrazema

=cut

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

my $paraphrasesFile;
my $lexFile;
my @sentence;

GetOptions(
    "phr_pp|p=s" => \$paraphrasesFile,
    "lex_pp|l=s" => \$lexFile
);

@sentence = @ARGV;
my %paraphrases;

print "Loading paraphrases...";
open my $fh, "-|", "gunzip -c $paraphrasesFile" or die "Cannot open pipe to paraphrases list";

while (<$fh>) {
    my @parts = split / \|\|\| /;

    $paraphrases{lc $parts[1]}{lc $parts[2]} = 1;
}

print "OK\n";
close $fh;

for my $word (@sentence) {

    if (defined $paraphrases{lc $word}) {
        print "( $word";

        for my $para (sort keys %{$paraphrases{lc $word}}) {
            print ", $para";
        }

        print ")";
    } else {
        print " $word ";
    }


}

=pod

=head1 AUTHOR

Jindra Helcl <jindra.helcl@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2014 Jindra Helcl

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
