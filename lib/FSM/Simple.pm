package FSM::Simple;

# http://www.crsr.net/Programming_Languages/PerlAutomata.html
use strict;
use warnings;

our $VERSION = '0.01';
our $DEBUG = 0;

use Class::Accessor::Lite;

my %Defaults = (
    current  => 'init',
    finish   => 'end',
    (map { $_ => {} } qw/rules context/),
    (map { $_ => sub {} } qw/on_enter on_exit on_transition/)
);

Class::Accessor::Lite->mk_accessors(keys %Defaults);

sub new {
    my $package = shift;
    my %args = $_[1] ? %{ @_ } : %{ $_[0] };
    my $self = bless +{ %Defaults, %args }, $package;

    my $init = $self->current;
    my $end  = $self->finish;

    $self->rules->{$init} ||= FSM::Simple::State->new(code => sub {}, guards => [ end => 1 ]);
    $self->rules->{$end}  ||= FSM::Simple::State->new(code => sub {});

    for my $key (keys %{ $self->rules }) {
        my $s = $self->rules->{$key};
        if (my $r = ref $s) {
            if ($r eq 'ARRAY') {
                $self->register($key, @$s);
            }
            elsif ($r eq 'CODE') {
                $self->register($key, $s);
            }
        }
    }

    return $self;
}

sub _log { warn "[FSM::Simele DEBUG] ".join(' ', @_) . "\n" if $DEBUG }

sub register {
    my $self = shift;
    my ($key, $code, $guards) = @_;
    $guards ||= [];
    _log("register: ${key}");
    return if (ref($code) || '') ne 'CODE' || (!scalar(@$guards) && $self->finish ne $key);
    $self->rules->{$key} = FSM::Simple::State->new(
        code   => $code,
        guards => $guards
    );
}

sub unregister {
    my ($self, $key) = @_;
    _log("unregister: ${key}");
    delete $self->rules->{$key};
}

sub step {
    my $self = shift;
    my $st = $self->rules->{$self->current} or return;
    $st->run($self->context);
    $self->current($st->next($self->context));
    _log("next -> " . $self->current);
    return 1;
}

sub run {
    my $self = shift;
    $self->context(+{ %{ $self->context }, %{ $_[0] || {} } });
    local $_ = $self->context;
    $self->on_enter->($self->context);
    while (1) {
        if ($self->current eq $self->finish) {
            $self->step;
            last;
        }
        $self->step or last;
        $self->on_transition->($self->context);
    }
    $self->on_exit->($self->context);
    $self;
}

package FSM::Simple::State;

sub new {
    my $package = shift;
    my %args = @_;
    my @guards = @{ $args{guards} || [] };
    my @list;
    while (@guards) {
        my ($key, $code) = splice @guards, 0, 2;
        push @list, FSM::Simple::Guard->new(
            key  => $key,
            code => (ref($code) || '') ne 'CODE' ? sub { $code } : $code
        );
    }
    $args{guards} = \@list;
    bless \%args, $package;
}

sub next {
    my ($self, $context) = @_;
    for my $guard (@{ $self->{guards} }) {
        return $guard->key if $guard->check($context);
    }
    return '';
}

sub run {
    my ($self, $context) = @_;
    local $_ = $context;
    $self->{code}->($context);
}

package FSM::Simple::Guard;

sub key { shift->{key} }

sub code { shift->{code} }

sub new {
    my $package = shift;
    my %args = @_;
    bless +{ key  => '', code => sub { 1 }, %args }, $package;
}

sub check {
    my ($self, $context) = @_;
    return $self->code->($context);
}

1;
=head1 NAME

FSM::Simple - Perl extention to do something

=head1 VERSION

This document describes FSM::Simple version 0.01.

=head1 SYNOPSIS

    use FSM::Simple;

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

=head2 Functions

=head3 C<< hello() >>

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

<<YOUR NAME HERE>> E<lt><<YOUR EMAIL ADDRESS HERE>>E<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, <<YOUR NAME HERE>>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
