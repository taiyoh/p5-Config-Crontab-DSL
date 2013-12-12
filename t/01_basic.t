use strict;
use warnings;

use Test::More;

use t::Foo;

my $res = t::Foo->dump;

my $ref = <<DATA;
## hoge--
FOO=bar
0 0 * * 1-5 echo "hello!"
#1 4 11,12,13 * * echo "world!"
*/10 10-16 1-10/3 * * echo foo
DATA

is $res, $ref;


done_testing;
