# 21.short.t
# Two short tests, using an abbreviated pattern match and line counts.
# The long test, in another file, compares the entire output files,
# and is simpler and should obviate the need for these short tests.

use strict;
use warnings;
use Test::More tests => 2;

$\ = "\n";
my $project_dir = '.';
my $program_under_test = $project_dir . "/sendmail_trace.pl";


# NOTE:
#   If I use the /pattern/x 'x' modifier, any required white space
#   that is in the pattern, must also be in the matching string,
#   eg, by including \s+ or '.', or some other means.
my $ref_out_01 = q{^\*\*\*\*Jan.*jB88DYuG013138:.to=<u13@h362.com>
    .*jB88DZ5D000538.*jB88De7c008711.*jB88Degv009337.*};


my $test_uid = 'u13\@h362.com' ;
my $test_out = `$program_under_test $test_uid` or die "Cannot run $program_under_test: [$!]";

	# Compare the ref output to the program o/p to determine pass or fail.
  like( $test_out, qr/$ref_out_01/msx, "Check uid $test_uid" );

# Count o/p lines & compare to expected value.
$test_out =~ tr/\n\n//s;  # Remove blank lines.
my $num_output_lines = $test_out =~ tr/\n// + !/\n\z/ -2;
  # Ignore empty line at end if it exists.
  # Subtract 2 lines for first & last newlines in the scalar.

my $test_output_filename = "t.21.out";
my $outfile;
open $outfile, ">", $test_output_filename  or die "Cannot open [$outfile]."; 
print { $outfile } $test_out;

is( $num_output_lines, 88, "Expect 88 o/p lines for 9999-line i/p file.");

close $outfile ;

