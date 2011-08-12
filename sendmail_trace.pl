#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.10';

# Init
$\ = "\n";
# Hash of arrays; the arrays hold refs to lines in the log file
# that are related to the specified email address to trace.
my %uid; 
my @buffer;

# Declare subs 
sub print_all_matching_lines ( $ );
sub print_array_with_stars( $ );
sub read_each_line2();
sub read_qid_from_line( $ );
sub read_the_buffer2();
sub save_line( $$ );
sub usage();


# Get email address to trace, from cmd line.
my $uid_wanted;
$ARGV[ 0 ] ? $uid_wanted = $ARGV[ 0 ] : usage();

my $sendmail_log_file;
my $sendmail_raw_log = "maillog.mx";
open $sendmail_log_file, '<', $sendmail_raw_log
   or die "Cannot open $sendmail_raw_log: [$!]";



read_each_line2();

read_the_buffer2();

print_all_matching_lines( \%uid );



###
###############   Function Definitions   ###############
###


sub read_each_line2()
{
  READLINE: while ( my $line = <$sendmail_log_file> )
    {
        chomp $line;
        my $qid = read_qid_from_line( $line );
        next if ( !$qid );   # Skip lines w/o a qid.

        if ( $line =~ /^.* <$uid_wanted> .*$/x )  # Simple test for uid in the line.
        {
            save_line( $line, $qid );
            next READLINE;
        }
        else
        {
            # If matching uid not found, look for matching qid.
            push @buffer, $line;   # Add the line to the buffer.

            # If buffer is full, remove one line from front.
            my $max_buffer_size = 100;
              # Use 1400, to match widely-separated lines.
            if ( scalar( @buffer ) > $max_buffer_size )
            {
                my $line_from_buffer = shift @buffer;
                my $qid_from_buffer = read_qid_from_line( $line_from_buffer );

                if ( $qid_from_buffer  and  exists $uid{$qid_from_buffer} )
                {
                    save_line( $line_from_buffer, $qid_from_buffer )
                }
            }
            next READLINE;
        }
    }   # End of READLINE
}   # End of sub read_each_line2()


sub read_the_buffer2()
{
    # After reading all lines in the input file,
    # check each line in the FIFO buffer.  If it matches a qid from the %uid
    # hash, save it otherwise discard it.
    foreach my $line ( @buffer )
    {
        my ($qid) = $line =~ /: ([\dA-Za-z]{14}):/;
        push @{ $uid{ $qid } }, \$line if ( exists $uid{$qid} );
    }
}


sub read_qid_from_line( $ )
{
    my ( $line ) = @_;
    #OK.ORG.140ms  my $qid_pattern = q{^.*\[\d+\]: .* \s  (\w{14}) (?:\.|:\s+)? .*$};
    #FASTER.than.ORG.120ms  my $qid_pattern = q{^.*:  \s  (\w{14}) (?:\.|:\s+)? .*$};
    my $qid_pattern = q{:\s([\dA-Za-z]{14}):};  # PG's simple pattern. Is it adequate?
    return $1 if ( $line =~ /$qid_pattern/x );
    return undef;
}


sub save_line( $$ )
{
    my ( $line, $qid ) = @_;
    push @{ $uid{ $qid } }, \$line;
}


sub print_all_matching_lines ( $ )
{
    my $ref = shift;   # The arg is a ref to the uid structure, %uid.
    my %hash = %$ref;

    # Unwrap the data structure holding the lines to print:
    #   hash of arrays of refs; one array per qid;
    #   each array holds refs to the related lines.
    #
    # Deref the hash value to get one array for each qid key.
    # Sort the keys, to get o/p in qid order; note that this
    # does not necessarily put o/p records in chronological time order.
    foreach my $q ( sort keys %hash )
    {
        print "";
        print_array_with_stars( $hash{ $q } );
    }
    print "";
}


sub print_array_with_stars ( $ )
{
    # The arg is a reference to the array.
    # Each element of the array is a reference to a line from the log.
    my $arg = shift;
    print ${ shift @$arg } if ( defined @$arg ); # Print the first line w/ no stars.
    print "****${$_}" foreach ( @$arg )          # Print other lines w/ stars.
}


sub usage()
{
    print "\nUsage:\n$0 <email address>";
    print "    Enter one argument only: a full email address,";
    print "    (eg, u1\@h2.net or u13\@h2.net or u13\@h362.com).";
    print "    The program prints all lines for that addr and";
    print "    for any related messages (having the same qid)";
    print "    found in the sendmail log file.";
    exit 1;
}

