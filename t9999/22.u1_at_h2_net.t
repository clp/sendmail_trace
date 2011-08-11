use strict;
use warnings;

use Test::More tests => 1;

$\ = "\n";
my $project_dir = '.';
my $program_under_test = $project_dir . "/sendmail_trace.pl";

my $test_uid = 'u1\@h2.net' ;
my $test_out = `$program_under_test $test_uid` or die "Cannot run $program_under_test: [$!]";

$test_out =~ tr/\n\n//s;  # Remove blank lines.

my $test_output_file = "t.22.out";
my $outfile;
open $outfile, ">", $test_output_file  or die "Cannot open [$outfile]."; 
print { $outfile } $test_out;
close $outfile;

# Compare two files on disk: PUT o/p to ref o/p.
#TBD: Will this be too slow when very large o/p files are compared?
my $ref_out_file = "ref_9999_out/$test_output_file";
my $diff_out = `diff -s  $test_output_file  $ref_out_file`;
like( $diff_out, qr{Files.*are.identical.*}, "Compare program o/p to ref o/p for $test_uid");
