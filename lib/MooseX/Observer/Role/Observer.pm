package MooseX::Observer::Role::Observer;
# ABSTRACT: Tags a Class as being an Observer
use Moose::Role;
requires 'update';
1;

=pod

=head1 SYNOPSIS

    ############################################################################
    package Counter;

    use Moose;

    has count => (
        traits  => ['Counter'],
        is      => 'rw',
        isa     => 'Int',
        default => 0,
        handles => {
            inc_counter => 'inc',
            dec_counter => 'dec',
        },
    );

    # apply the observable-role and
    # provide methodnames, after which the observers are notified of changes
    with 'MooseX::Observer::Role::Observable' => { notify_after => [qw~
        count
        inc_counter
        dec_counter
        reset_counter
    ~] };

    sub reset_counter { shift->count(0) }

    sub _utility_method { ... }

    ############################################################################
    package Display;

    use Moose;

    # apply the oberserver-role, tagging the class as observer and ...
    with 'MooseX::Observer::Role::Observer';

    # ... require an update-method to be implemented
    # this is called after the observed subject calls an observed method
    sub update {
        my ( $self, $subject, $args, $eventname ) = @_;
        print $subject->count;
    }

    ############################################################################
    package main;

    my $counter = Counter->new();
    # add an observer of type "Display" to our observable counter
    $counter->add_observer( Display->new() );

    # increments the counter to 1, afterwards its observers are notified of changes
    # Display is notified of a change, its update-method is called 
    $counter->inc_counter;  # Display prints 1
    $counter->dec_counter;  # Display prints 0

=head1 DESCRIPTION

This is a simple role, that you have to apply to your oberservers. It simply
requires you to implement a method called update. This method is called
everytime the observed object changes.

=method update($subject, $args, $eventname)

This method has to be implemented by the class, that consumes this role. The
following arguments are passed.

=head3 1. the subject

The object being observed.

=head3 2. an arrayref containg arguments

The arguments of method, that was the reason for the observed class' change.

=head3 3. an eventname

The name of the method, that was the reason for the observed class' change.

=cut