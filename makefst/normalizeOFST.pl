#!/usr/bin/env perl

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

my %fst;
my $finalState;

my $file = shift or pod2usage("You must supply input file");
my $outputFile = $file . ".norm";

open my $fh, $file or die "Cannot open input file: $file";


while (<$fh>) {
    chomp;

    my @parts = split /\s+/;

    $finalState = $parts[0] and last if scalar @parts != 5;

    my $score = $parts[4];

    if (!defined $fst{$parts[0]}) {
        $fst{$parts[0]} = [];
    }

    push @{$fst{$parts[0]}}, {
        to_state => $parts[1],
        input => $parts[2],
        output => $parts[3],
        score => $score
    }
}

close $fh;
open my $out_fh, '>', $outputFile or die "Cannot open output file for writing: $outputFile";

for my $state (sort keys %fst) {

    my $sum = 0;
    my @arcs = @{$fst{$state}};

    map {$sum += $_->{score}} @arcs;
    map {$_->{score} /= $sum} @arcs;
    map {print_arc($out_fh, $state, $_)} @arcs;
}


print $out_fh "$finalState 1\n";

close $out_fh;



sub print_arc {
    my ($out, $from, $arc) = @_;

    print $out join (" ", $from, $arc->{to_state}, $arc->{input}, $arc->{output}, $arc->{score});
    print $out "\n";
}

=pod

=head1 AUTHOR

Jindra Helcl <jindra.helcl@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2014 Jindra Helcl

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
