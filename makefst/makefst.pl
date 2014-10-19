#!/usr/bin/env perl

=pod

=head1 NAME

makefst.pl - Creates a FST of a sentence using the Paraphrase Database files.

=head1 SYNOPSIS

makefst.pl -p PARAPHRASES_FILE [OPTION]...

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

my $out_text = "text";
my $out_isyms = "isyms";
my $out_osyms = "osyms";
my $out_prefix;
my $out_ext = ".txt";

GetOptions(
    "phr_pp|p=s" => \$paraphrasesFile,
    "text|t=s" => \$out_text,
    "isyms|i=s" => \$out_isyms,
    "osyms|o=s" => \$out_osyms,
    "prefix" => \$out_prefix
);

pod2usage("You must supply the paraphrases file via -p parameter") if !defined $paraphrasesFile;
pod2usage(message=>"List of paraphrases does not exist: $paraphrasesFile", exitStatus=>2) if !-e $paraphrasesFile;

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
    my @symbols = @sentence;
    my $sent_length = scalar @sentence;

    my $counter = ".$.";
    my $out_textfile = $out_text . $counter . $out_ext;
    my $out_isymsfile = $out_isyms . $counter . $out_ext;
    my $out_osymsfile = $out_osyms . $counter . $out_ext;

    if(defined $out_prefix) {
        $out_textfile = $out_prefix . "_" . $out_textfile;
        $out_isymsfile = $out_prefix . "_" . $out_isymsfile;
        $out_osymsfile = $out_prefix . "_" . $out_osymsfile;
    }

    open my $fh_text, ">", $out_textfile;

    for my $i (0..$#sentence) {
        print_arc($fh_text, $i, $i+1, $sentence[$i], $sentence[$i]);
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

                    print_arc($fh_text, $from_state, $free_state, $preceding_par_word, $preceding_par_word);
                    push @symbols, $preceding_par_word;
                    $from_state = $free_state;
                    $free_state += 1;
                }

                my $last_word = $paraphrase_words[$#paraphrase_words];
                print_arc($fh_text, $from_state, $to_state, $last_word, $last_word);
                push @symbols, $last_word;

            }

        }
    }

    print_final_state($fh_text, $sent_length);

    close $fh_text;

    open my $fh_isyms, ">", $out_isymsfile;
    print_syms($fh_isyms, @symbols);
    close $fh_isyms;

    open my $fh_osyms, ">", $out_osymsfile;
    print_syms($fh_osyms, @symbols);
    close $fh_osyms;
}


sub print_arc {
    my ($fh, $from_state, $to_state, $input_sym, $output_sym, $weight) = @_;

    print $fh join " ", ($from_state, $to_state, $input_sym, $output_sym);
    print $fh " $weight" if defined $weight;
    print $fh "\n";
}

sub print_syms {
    my ($fh, @syms) = @_;

    print $fh "<eps> 0\n";

    for my $i (0..$#syms) {
        my $sym = $syms[$i];
        print $fh "$sym ".($i+1)."\n";
    }

}

sub print_final_state {
    my ($fh, $state, $weight) = @_;

    print $fh $state;
    print $fh " $weight" if defined $weight;
    print $fh "\n";
}

=pod

=head1 AUTHOR

Jindra Helcl <jindra.helcl@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2014 Jindra Helcl

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
