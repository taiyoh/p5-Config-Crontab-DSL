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
        day_of_week range MON, FRI;
        command 'echo "hello!"';
    };

    job {
        minute '1';
        hour   '4';
        day    [11 .. 13];
        command 'echo "world!"';
        deactivate;
    };

    job {
        minute every 10;
        hour range 10, 16;
        day every range(1,10), 3;
        command 'echo foo';
    };
};

1;
