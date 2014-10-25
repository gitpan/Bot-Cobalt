package Bot::Cobalt::Timer;
our $VERSION = '0.016002';

use strictures 1;
use 5.10.1;

use Carp;
use Moo;

use Bot::Cobalt::Common qw/:types/;


use namespace::clean -except => 'meta';

## It's possible to pass in a different core.
## (Allows timers to fire against different syndicators if needed)
has 'core'  => (
  lazy => 1,

  is  => 'rw',
  isa => Object,

  default => sub {
    require Bot::Cobalt::Core;

    Bot::Cobalt::Core->instance 
      || die "Cannot find active Bot::Cobalt::Core instance"
  },
);

## May have a timer ID specified at construction for use by
## timer pool managers; if not, creating IDs is up to them.
## (See ::Core::Role::Timers)
has 'id' => (
  lazy => 1,

  is  => 'rw',
  isa => Str,

  predicate => 'has_id'
);

## 'at' is set regardless of whether delay()/at() is used
## (or 0 if none is ever set)
has 'at'    => (
  lazy => 1,

  is  => 'rw',
  isa => Num,

  default => sub { 0 },
);

has 'delay' => (
  lazy => 1,

  is  => 'rw',
  isa => Num,

  predicate => 'has_delay',
  clearer   => 'clear_delay',

  default   => sub { 0 },

  trigger   => sub {
    my ($self, $value) = @_;
    $self->at( time() + $value );
  },
);

has 'event' => (
  lazy => 1,

  is  => 'rw',
  isa => Str,

  predicate => 'has_event',
);

has 'args'  => (
  lazy => 1,

  is  => 'rw',
  isa => ArrayRef,

  default => sub { [] },
);

has 'alias' => (
  is  => 'rw',
  isa => Str,

  default => sub { scalar caller },
);

has 'context' => (
  lazy => 1,

  is  => 'rw',
  isa => Str,

  predicate => 'has_context',

  default   => sub { 'Main' },
);

has 'text'    => (
  lazy => 1,

  is  => 'rw',
  isa => Str,

  predicate => 'has_text'
);

has 'target'  => (
  lazy => 1,
  is  => 'rw',
  isa => Str,

  predicate => 'has_target'
);

has 'type'  => (
  lazy => 1,

  is  => 'rw',
  isa => Str,

  default => sub {
    my ($self) = @_;

    if ($self->has_context && $self->has_target) {
      ## Guessing we're a message.
      return 'msg'
    } else {
      ## Guessing we're an event.
      return 'event'
    }
  },

  coerce => sub {
    $_[0] =~ /message|privmsg/i ? 'msg' : lc($_[0]) ;
  },
);


sub _process_type {
  my ($self) = @_;
  ## If this is a special type, set up event and args.
  my $type = lc($self->type);

  if (grep { $_ eq $type } qw/msg message privmsg action/) {
    my $ev_name = $type eq 'action' ?
          'action' : 'message' ;
    $self->event( $ev_name );

    my @ev_args = ( $self->context, $self->target, $self->text );
    $self->args( \@ev_args );
  }

  return 1
}

sub is_ready {
  my ($self) = @_;
  return 1 if $self->at <= time;
  return
}

sub execute {
  my ($self) = @_;
  $self->_process_type;

  unless ( $self->event ) {
    carp "timer execute called but no event specified";
    return
  }

  unless ( $self->core->can('send_event') ) {
    carp "timer execute called but specified core can't send_event";
    return
  }

  my $args = $self->args;
  $self->core->send_event( $self->event, @$args );
  return 1
}

sub execute_if_ready { execute_ready(@_) }
sub execute_ready {
  my ($self) = @_;
  return $self->execute if $self->is_ready;
  return
}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Timer - Cobalt timer objects

=head1 SYNOPSIS

  my $timer = Bot::Cobalt::Timer->new(
    event  => 'my_timed_event',
    args   => [ $one, $two ],
  );
  
  $timer->delay(30);
  
  ## Add this instance to Core's TimerPool, for example:
  $core->timer_set( $timer );

=head1 DESCRIPTION

A B<Bot::Cobalt::Timer> instance represents a single timed event.

These are usually constructed for use by the L<Bot::Cobalt::Core> TimerPool; 
also see L<Bot::Cobalt::Core::Role::Timers/timer_set>.

  my $timer = Bot::Cobalt::Timer->new;

By default, timers that are executed will fire against the 
L<Bot::Cobalt::Core> singleton; you can pass in a different 'core =>' 
specification if needed.

=head1 METHODS

=head2 Timer settings

=head3 at

The absolute time that this timer is supposed to fire (epoch seconds).

This is normally set automatically when L</delay> is called.

(If it is tweaked manually, L</delay> is irrelevant information.)

=head3 delay

The time this timer is supposed to fire expressed in seconds from the 
time it was set.

(Sets L</at> to I<time()> + I<delay>)

=head3 event

The name of the event that should be fired via B<send_event> when this 
timer is executed.

=head3 args

An array reference containing any arguments attached to the L</event>.

=head3 id

This timer's unique identifier, used as a key in timer pools.

Note that a unique random ID is added when the Timer object is passed to 
L<Bot::Cobalt::Core::Role::Timers/timer_set> if no B<id> is explicitly 
specified.

=head3 alias

The alias tag attached to this timer. Defaults to C<caller()>

=head3 type

The type of event.

Valid types as of this writing are B<msg>, B<action>, and B<event>.

B<msg> and B<action> types require L</context>, L</text>, and L</target> 
attributes be specified.

If no type has been specified for this timer, B<type()> returns our best 
guess; for timed events carrying a L</context> and L</target> the 
default is B<msg>.

This is used to set up proper event names for special timer types.

=head3 context

B<msg and action timer types only>

The server context for an outgoing B<msg> or B<action>.

See L</type>

=head3 text

B<msg and action timer types only>

The text string to send with an outgoing B<msg> or B<action>.

See L</type>

=head3 target

B<msg and action timer types only>

The target channel or nickname for an outgoing B<msg> or B<action>.

See L</type>

=head2 Execution

A timer object can be instructed to execute as long as it was provided a 
proper B<core> object at construction time -- this is normally 
L<Bot::Cobalt::Core>, but any class that can B<send_event> will do.

=head3 is_ready

Returns boolean true if the timer is ready to execute; in other words, 
if the specified L</at> is reached.

=head3 execute_if_ready

L</execute> the timer if L</is_ready> is true.

=head3 execute

Execute the timer; if our B<core> object can B<send_event>, the timer's 
event is broadcast. Otherwise the timer will warn and return.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
