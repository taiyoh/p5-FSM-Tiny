#!perl -w
use strict;
use Test::More;

use FSM::Simple;

#++$FSM::Simple::DEBUG;

my $fsm = FSM::Simple->new({
    on_enter      => sub {
        my $context = shift;
        $context->{count} = 0;
        $context->{str}   = "foo";
    },
    on_transition => sub { shift->{str} .= "bar" },
    on_exit       => sub { shift->{str} .= "baz" }
});

$fsm->register(init => sub {}, [
    add => sub { shift->{count} < 20 },
    end => sub { shift->{count} >= 20 }
]);

$fsm->register(add => sub { ++shift->{count} }, [
    init => 1
]);

$fsm->register(end => sub { shift->{count} *= 5 });

$fsm->run;

is $fsm->context->{count}, 100, "state machine ran";

# (init -> add (-> init)) x 20 + end
is $fsm->context->{str}, "foo".("bar" x 41)."baz", "on_* event correctly fired";

done_testing;
