package t::Foo;

use strict;
use warnings;
use utf8;

use Config::Crontab::DSL;

crontab {
    comment "hoge--";
    env FOO => "bar";

    job {
        minute '0';
        hour   '0';
        command 'echo "hello!"';
    };

    job {
        minute '1';
        hour   '4';
        command 'echo "world!"';
        deactivate;
    };
};

1;
