package Bot::Cobalt::Frontend::Utils;
our $VERSION = '0.013';

use 5.10.1;
use strictures 1;

use Carp;

use base 'Exporter';

our @EXPORT_OK = qw/
  ask_yesno
  ask_question
/;

our %EXPORT_TAGS;

{ 
  my %seen;
  push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @EXPORT_OK
}

sub ask_question {
  my %args = @_;
  
  my $question = delete $args{prompt} || croak "No prompt => specified";
  my $default  = delete $args{default};
  
  my $validate_sub;
  if (defined $args{validate}) { 
    $validate_sub = ref $args{validate} eq 'CODE' ?
        delete $args{validate}
        : croak "validate => should be a coderef";
  }
  
  select(STDOUT); $|++;
  
  my $input;
  
  my $print_and_grab = sub {
    print "$question ";

    if (defined $default) {
      print "[$default] ";
    } else {
      print "> ";
    }

    $input = <STDIN>;

    chomp($input);

    $input = $default if defined $default and $input eq '';
    $input
  };
  
  $print_and_grab->();
  
  until ($input) {
    print "No input specified.\n";
    $print_and_grab->();
  }
  
  VALID: {
    if ($validate_sub) {
      my $invalid = $validate_sub->($input);
    
      last VALID unless defined $invalid;
    
      if ( $args{die_if_invalid} || $args{die_unless_valid} ) {
        die "Invalid input; $invalid\n";
      }
    
      until (not defined $invalid) {
        print "Invalid input; $invalid\n";
        $print_and_grab->();
        redo VALID
      }
    }
  }
    
  return $input
}

sub ask_yesno {
  my %args = @_;
  
  my $question = $args{prompt} || croak "No prompt => specified";

  my $default  = lc(
    substr($args{default}||'', 0, 1) || croak "No default => specified"
  );

  croak "default should be Y or N"
    unless $default =~ /^[yn]$/;

  my $yn = $default eq 'y' ? 'Y/n' : 'y/N' ;

  select(STDOUT); $|++;

  my $input;

  my $print_and_grab = sub {
    print "$question  [$yn] ";

    $input = <STDIN>;

    chomp($input);

    $input = $default if $input eq '';

    lc(substr $input, 0, 1)
  };

  $print_and_grab->();
   
  until ($input ~~ [qw/y n/]) {
    print "Invalid input; should be either Y or N\n";
    $print_and_grab->();
  }

  return $input eq 'y'
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Frontend::Utils - Helper utils for Bot::Cobalt frontends

=head1 SYNOPSIS

  use Bot::Cobalt::Frontend::Utils qw/ :all /;
  
  my $do_something = ask_yesno(
    prompt  => "Do some stuff?"
    default => 'y',
  );
  
  if ($do_something) {
    ## Yes
  } else {
    ## No
  }

  ## Ask a question with a default answer
  ## Keep asking until validate => returns undef
  my $answer = ask_question(
    prompt  => "Tastiest snack?"
    default => "cake",
    validate => sub {
      $_[0] ~~ ['cake', 'pie', 'cheese'] ?
        undef : "Snack options are cake, pie, cheese"
    },
  );

=head1 DESCRIPTION

This module exports simple helper functions for use by L<Bot::Cobalt> 
frontends.

The exported functions are fairly simplistic; take a gander at 
L<Term::UI> if you're looking for a rather more solid terminal/user 
interaction module.

=head1 EXPORTED

=head2 ask_yesno

Prompt the user for a yes or no answer.

A default 'y' or 'n' answer must be specified:

  my $yesno = ask_yesno(
    prompt  => "Do stuff?"
    default => "n"
  );

Returns false on a "no" answer, true on a "yes."

=head2 ask_question

Prompt the user with a question, possibly with a default answer, and 
optionally with a code reference to validate.

  my $ans = ask_question(
    prompt  => "Color of the sky?"
    default => "blue",
    validate => sub {
      $_[0] ~~ [qw/blue pink orange red/] ?
        undef : "Valid colors: blue, pink, orange, red"
    },
    die_if_invalid => 0,
  );

If a validation coderef is specified, it should return undef to signify 
successful validation or an error string describing the problem.

If B<die_if_invalid> is specified, an invalid answer will die() 
out rather than asking again.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
