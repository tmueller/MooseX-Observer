package MooseX::Observer::Role::Observable;

use MooseX::Role::Parameterized;
use Moose::Util::TypeConstraints;
use List::MoreUtils ();
 
{
    my $observerrole_type = role_type('MooseX::Observer::Role::Observer');
    subtype 'ArrayRefOfObservers'
        => as 'ArrayRef'
        => where { List::MoreUtils::all { $observerrole_type->check($_) } @$_ },
        => message { "The Object given must do the 'MooseX::Role::Observer' role." };
}
 
parameter notify_after => (isa => 'ArrayRef', default => sub { [] });

role {
    my $parameters = shift;
    my $notifications_after = $parameters->notify_after;

    my %args = @_;
    my $consumer = $args{consumer}; 
    
    has observers => (
        traits      => ['Array'],
        is          => 'bare',
        isa         => 'ArrayRefOfObservers',
        default     => sub { [] },
        writer      => '_observers',
        handles     => {
            add_observer            => 'push',
            count_observers         => 'count',
            all_observers           => 'elements',
            remove_all_observers    => 'clear',
            _filter_observers       => 'grep',
        },
    );

    for my $methodname (@{ $notifications_after }) {
        if ($consumer->find_attribute_by_name($methodname)) {
            
            after $methodname => sub {
                my $self = shift;
                $self->_notify(\@_, $methodname) if (@_);
            };
            
        } else {
            
            after $methodname => sub {
                my $self = shift;
                $self->_notify(\@_, $methodname);
            };
            
        }
    }
    
    sub _notify {
        my ($self, $args, $eventname) = @_;
        $_->update($self, $args, $eventname) for ( $self->all_observers );
    }
    
    sub remove_observer {
        my ($self, $observer) = @_;
        my @filtered = $self->_filter_observers( sub { $_ ne $observer } );
        $self->_observers(\@filtered);
    }
};
 
1;