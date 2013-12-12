use strict;
use warnings;

use Test::More;

use t::Foo;

my $res = t::Foo->dump;

my $ref = <<DATA;
## hoge--
FOO=bar
0 0 * * * echo "hello!"
#1 4 * * * echo "world!"
DATA

is $res, $ref;


done_testing;
