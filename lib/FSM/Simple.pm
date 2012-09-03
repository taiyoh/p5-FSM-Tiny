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
    rules    => {},
    on_enter => sub {},
    on_exit  => sub {},
    on_transition => sub {}
);

Class::Accessor::Lite->mk_accessors(keys %Defaults);

sub new {
    my $package = shift;
    my %args = $_[1] ? %{ @_ } : %{ $_[0] };
    my $self = bless +{ %Defaults, %args }, $package;

    my $init = $self->current;
    my $end  = $self->finish;

    $self->rules->{$init} ||= FSM::Simple::State->new(code => sub { shift->next($end) });
    $self->rules->{$end}  ||= FSM::Simple::State->new(code => sub {});

    for my $key (keys %{ $self->rules }) {
        my $s = $self->rules->{$key};
        $self->register($key, $s) if ref $s eq 'CODE';
    }

    return $self;
}

sub _log { warn "[FSM::Simele DEBUG] ".join(' ', @_) . "\n" if $DEBUG }

sub register {
    my $self = shift;
    my ($key, $code) = @_;
    _log("register: ${key}");
    $self->rules->{$key} = FSM::Simple::State->new(code => $code);
}

sub unregister {
    my ($self, $key) = @_;
    _log("unregister: ${key}");
    delete $self->rules->{$key};
}

sub step {
    my $self = shift;
    _log("step start: " . $self->current);
    my $st = $self->rules->{$self->current} or return;
    $st->run(@_);
    my $next = $st->next || '';
    if ($self->rules->{$next}) {
        $self->current($next);
    }
    else {
        $self->current('');
    }
    return 1;
}

sub run {
    my $self = shift;
    my @args = @_;
    $self->on_enter->($self, @args);
    while (1) {
        if ($self->current eq $self->finish) {
            $self->step(@args);
            last;
        }
        $self->step(@args) or last;
        $self->on_transition->($self, @args);
    }
    $self->on_exit->($self, @args);
    $self;
}

package FSM::Simple::State;

sub new {
    my $package = shift;
    my %args = @_;
    bless \%args, $package;
}

sub next {
    my ($self, $v) = @_;
    $self->{next} = $v if @_ > 1;
    $self->{next};
}

sub run {
    my $self = shift;
    $self->{code}->($self, @_);
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
