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

my $debug_paraphrases = 0;

GetOptions(
    "phr_pp|p=s" => \$paraphrasesFile,
);

my @paraphrases;
# many to many paraphrases - index the length of the paraphrased string

print "Loading paraphrases...";

open my $fh, "gunzip -c $paraphrasesFile |" or die "Cannot open pipe to paraphrases list";

while (<$fh>) {
    my @parts = split / \|\|\| /;

    my $original = lc $parts[1];
    my $paraphrase = lc $parts[2];

    $original =~ s/\s+/ /g;
    $paraphrase =~ s/\s+/ /g;

    my $orig_length = scalar(split /\s+/, $original);

    if (!defined $paraphrases[$orig_length]) {
        $paraphrases[$orig_length] = {};
    }

    $paraphrases[$orig_length]{$original}{$paraphrase} = 1;
}

print "OK\n";
close $fh;

while (<>) {
    chomp;
    my @sentence = split /\s+/;
    my $sent_length = scalar @sentence;


    for my $i (0..$#sentence) {
        print_arc($i, $i+1, $sentence[$i], $sentence[$i]);
    }

    my $free_state = $sent_length + 1;

    for my $par_length (1..$sent_length) {
        next if !defined $paraphrases[$par_length];

        for my $word_idx (0..$sent_length - $par_length) {

            my $end_word_idx = $word_idx + $par_length - 1;
            my @orig_words = @sentence[$word_idx..$end_word_idx];

            my $orig_key = join " ", map(lc, @orig_words);

            next if !defined $paraphrases[$par_length]{$orig_key};

            # do sth
            if ($debug_paraphrases) {
                print "sent_len: $sent_length\n";
                print "par_len: $par_length\n";
                print "orig_key: $orig_key\n";
                print "orig_words: " . (join " ", @orig_words) . "\n";
                print "paraphrases: " . join " | ", keys %{$paraphrases[$par_length]{$orig_key}};
                print "\n\n";
            }


            for my $paraphrase (keys %{$paraphrases[$par_length]{$orig_key}}) {

                my $from_state = $word_idx;
                my $to_state = $end_word_idx + 1;

                my @paraphrase_words = split /\s+/, $paraphrase;

                for my $par_word_idx (1..$#paraphrase_words) {
                    my $preceding_par_word = $paraphrase_words[$par_word_idx - 1];

                    print_arc($from_state, $free_state, $preceding_par_word, $preceding_par_word);
                    $from_state = $free_state;
                    $free_state += 1;
                }

                my $last_word = $paraphrase_words[$#paraphrase_words];
                print_arc($from_state, $to_state, $last_word, $last_word);

            }

        }
    }
}


sub print_arc {
    my ($from_state, $to_state, $input_sym, $output_sym, $weight) = @_;

    print join " ", ($from_state, $to_state, $input_sym, $output_sym);
    print " $weight" if defined $weight;
    print "\n";
}

=pod

=head1 AUTHOR

Jindra Helcl <jindra.helcl@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2014 Jindra Helcl

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
