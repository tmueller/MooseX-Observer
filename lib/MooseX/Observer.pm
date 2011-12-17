package MooseX::Observer;
# ABSTRACT: Simple Moose-Roles to implement the Observer Pattern
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

This is a distribution, that provides roles, that implement the observer
pattern. 

MooseX::Observer::Role::Observable is a parameterized role, that is applied
to your observed class. Usually when applying the 
MooseX::Observer::Role::Observable role, you provide a list of methodnames. 
After method modifiers are installed for these methods. They call the 
_notify-method, which in turn calls the update-method of all observers.

MooseX::Observer::Role::Observer is a simple role, that you have to apply to
your oberservers. It simply requires you to implement a method called update.
This method is called everytime the observed object changes.

The observers update-method receives an instance of the observed subject, an
arrayref of arguments and an eventname, which is simply the name of the method,
that triggered the notification.

=head1 ATTRIBUTES

Since Moose-Attributes can create accessors, which are methods, that can be 
applied method modifiers to, you can include attributenames in the list of 
observed methods.

In the synopsis, 'count' is an attribute, that is included in the list of 
observed methods.

MooseX::Observer::Role::Observable is then smart enough to notify observers
only in case of a setter-call to an attribute.

    $counter->count(5); # setter-call will notify all observers
    $counter->count();  # getter-call won't notify any observer of changes

But it is not smart enough to detect changes to the value itself. A simple 
"$before ne $after" might not always work. Or would it?

    $counter->count(5); # setter-call will notify all observers...
    $counter->count(5); # ... again, although value was not changed

=head1 MANUAL NOTIFICATION

When applying the MooseX::Observer::Role::Observable role, you provide a list of 
methodnames. After method modifiers are installed for these methods, that 
call the _notify-method, which in turn notifies all observers of changes.

For Example, the after method modifier for count would look like this:

    after count => sub {
        my $self = shift;
        $self->_notify(\@_, 'count') if (@_);
    };

But you can also call the _notify-method yourself. Its arguments are passed to 
the update-method of the observers. You don't need to supply arguments, but 
because your observed subject should not need to know anything about the 
oberservers implementations, you should provide the following arguments:

=head3 1. an arrayref containg arguments

The standard behaviour is to pass all arguments of the observed method. 

    $self->count(5); # [5] will be passed to _notify

You should pass at least an emtpty array to _notify.

=head3 2. an eventname

The standard behaviour is to pass the name of the observed method.

    $self->count(5); # 'count' will be passed to _notify

Feel free to supply a custom eventname here. If you don't rely on eventnames
in your observers, you can ommit this argument. But
MooseX::Observer::Role::Observable will always pass the observed methods name
as eventname.

=head1 CAVEATS

The same rules apply as for normal roles. Because the attribute definition 
happens at runtime, the role consumption has to happen after the attribute.
See L<Moose::Manual::Roles/"Required-Attributes"> for more details.

In the SYNOPSIS the MooseX::Observer::Role::Observable role is applied after the
count attribute, because the methodlist given to the role refers to inc_counter,
dec_counter and the count attribute itself.

=head1 INSPIRATION

Moose testcase called "collection_with_roles.t" already implemented an observer
role. In fact MooseX::Observer::Role::Observable is largely similar to the role
used in the testcase. I just added passing parameters to the observers update
method and the posibility to remove observers.

=cut