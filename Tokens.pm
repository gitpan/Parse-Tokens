package Parse::Tokens;

use strict;
use vars	qw( @ISA $VERSION );

$VERSION = 0.15;

sub new
{
	my ( $proto, $params ) = @_;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless ($self, $class);
	$self->init( $params );
	$self;
}

sub init
{
    my( $self, $params ) = @_;
	no strict 'refs';
	for ( keys %$params )
	{
		my $ref = lc $_;
		$self->$ref($params->{$_});
	}
	use strict;
}

sub debug
{
	my( $self, $val ) = @_;
	$self->{DEBUG} = $val if defined $val;
	return $self->{DEBUG};
}

# this is returning a hash ref ($self I believe);
sub autoflush
{
	my( $self, $val ) = @_;
	$self->{AUTOFLUSH} = $val if defined $val;
	return $self->{AUTOFLUSH};
}

sub text
{
	my( $self, $val ) = @_;
	$self->{TEXT} = $val if defined $val;
	return $self->{TEXT};
}

sub delimiters
{
	my( $self, $delim ) = @_;
	if ( ref $delim eq 'ARRAY' )
	{
		$self->{DELIMITERS}{REAL} = $delim;
		$self->{DELIMITERS}{QUOTED}->[0] = quotemeta($delim->[0]);
		$self->{DELIMITERS}{QUOTED}->[1] = quotemeta($delim->[1]);
	}
	return ([
		$self->{DELIMITERS}{REAL},
		$self->{DELIMITERS}{QUOTED}
	]);
}

sub flush
{
	my( $self ) = @_;
	delete $self->{CACHE};
	return 1;
}

sub parse
{
	my( $self, $params ) = @_;
	$self->init( $params );
	return unless defined $self->{TEXT};
	my $delim = $self->delimiters();	# get delimiters
	$self->flush if $self->{AUTOFLUSH};

	unless( $self->{CACHE} )
	{
		# parse the text
		my $token = "($delim->[1]->[0])(.*?)($delim->[1]->[1])";
		# study $self->{TEXT};		#faster or not?
		my @chunk = split( m/$token/s, $self->{TEXT} );
		$self->{CACHE} = \@chunk;
	}

	my $n = 0;
	while ($n <= $#{$self->{CACHE}})
	{
		# find opening delimiter
		if ( $self->{CACHE}->[$n] eq $delim->[0]->[0] )
		{ $self->token([
			$self->{CACHE}->[$n],
			$self->{CACHE}->[++$n],
			$self->{CACHE}->[++$n]
		]); }

		# or it's just text
		else
		{ $self->ether($self->{CACHE}->[$n]); }
		$n++
	}
}

# an token consists of a left-delimiter, the contents, and a right-delimiter
sub token{}

# ether is anything not contained in an atom
sub ether{}

1;


__END__

=head1 NAME

Parse::Tokens - class for parsing text with embedded tokens

=head1 SYNOPSIS

  use Parse::Tokens;
  @ISA = ('Parse::Tokens');

  # overide SUPER::token
  sub token
  {
    my( $self, $token ) = @_;
    # $token->[0] - left bracket
    # $token->[1] - contents
    # $token->[2] - right bracket
    # do something with the token...
  }

  # overide SUPER::token
  sub ether
  {
    my( $self, $text ) = @_;
    # do something with the text...
  }

=head1 DESCRIPTION

C<Parse::Tokens> provides a base class for parsing delimited strings from text blocks. Use C<Parse::Tokens> as a base class for your own module or script. Very similar in style to C<HTML::Parser>.

=head1 Functions

=over 10

=item autoflush()

Turn on autoflushing causing the template cash (not the text) to be purged before each parse();.

=item delimiters()

Specify delimiters as an array reference pointing to the left and right delimiters. Returns array reference containing two array references of delimiters and escaped delimiters.

=item flush()

Flush the template cash.

=item parse()

Run the parser.

=item new()

Pass parameter as a hash reference. Options are: TEXT - a block of text; DELIMITERS - a array reference consisting of the left and right token delimiters (eg ['<?', '?>']); AUTOFLUSH - 0 or 1 (default). While these are all optional at initialization, both TEXT and DELIMITERS must be set prior to calling parse() or as parameters to parse().

=item text()

Load text.

=back

=head1 AUTHOR

Steve McKay, steve@colgreen.com

=head1 COPYRIGHT

Copyright 2000 by Steve McKay. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

perl(1).

=cut
