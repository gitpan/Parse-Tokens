package Parse::Tokens;

# Copyright 2000-2001 by Steve McKay. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use vars	qw( @ISA $VERSION );

$VERSION = 0.17;

sub new
{
	my ( $proto, $params ) = @_;
	my $class = ref( $proto ) || $proto;
	my $self = {
		text => undef,
		delimiters => undef,
		autoflush => undef,
		debug => undef,
	};
	bless( $self, $class );
	$self->init( $params );
	return $self;
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
	return 1;
}

sub debug
{
	my( $self, $val ) = @_;
	$self->{debug} = $val if defined $val;
	return $self->{debug};
}

# this is returning a hash ref ($self I believe);
sub autoflush
{
	my( $self, $val ) = @_;
	$self->{autoflush} = $val if defined $val;
	return $self->{autoflush};
}

sub text
{
	my( $self, $val ) = @_;
	$self->flush();
	$self->{text} = $val if defined $val;
	return $self->{text};
}

sub delimiters
{
	my( $self, $delim ) = @_;
	if ( ref( $delim ) eq 'ARRAY' )
	{
		$self->{delimiters}{real} = $delim;
		$self->{delimiters}{escaped}->[0] = quotemeta( $delim->[0] );
		$self->{delimiters}{escaped}->[1] = quotemeta( $delim->[1] );
	}
	return( $self->{delimiters}{real}, $self->{delimiters}{escaped} );
}

sub flush
{
	my( $self ) = @_;
	delete $self->{cache};
	return 1;
}

sub parse
{
	my( $self, $params ) = @_;
	$self->init( $params );
	return unless defined $self->{text};
	$self->flush if $self->{autoflush};

	unless( $self->{cache} )
	{
		# parse the text
		my $token = "($self->{delimiters}{escaped}->[0])(.*?)($self->{delimiters}{escaped}->[1])";
		# study $self->{text};		#faster or not?
		my @chunk = split( m/$token/s, $self->{text} );
		$self->{cache} = \@chunk;
	}

	my $n = 0;
	while( $n <= $#{$self->{cache}} )
	{
		# find opening delimiter
		if ( $self->{cache}->[$n] eq $self->{delimiters}{real}->[0] )
		{ $self->token([
			$self->{cache}->[$n],
			$self->{cache}->[++$n],
			$self->{cache}->[++$n]
		]); }

		# or it's just text
		else
		{ $self->ether( $self->{cache}->[$n] ) }
		$n++
	}
	return 1;
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

=item new()

Initializes a Parse::Tokens object. Pass parameter as a hash reference. Options are: text - a block of text, delimiters - an array reference consisting of the left and right token delimiters (eg ['<?', '?>']), autoflush - 0(default) or 1, While these are all optional at initialization, both 'text' and 'delimiters' are required prior to or when calling the parse() method.

=item delimiters()

Specify delimiters as an array reference pointing to the left and right delimiters. Returns a two-part array containing two array references of the real (origional) and the escaped (internal) delimiters.

=item text()

Load the text to be parsed. Flushes any existing text.

=item parse()

Run the parser. Accepts an hash reference with initialization parameters.

=item flush()

Flush the template cash. This happens automatically when new text is provided to the module.

=item autoflush()

Turn on autoflushing causes Parse::Tokens to reparse the template text on every call to parse().

=back

=head1 CHANGES

delimiters() now returns an array of real, escaped delimiters. This is different that previous behavior where an array reference was returned.

=head1 AUTHOR

Steve McKay, steve@colgreen.com

=head1 COPYRIGHT

Copyright 2000-2001 by Steve McKay. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

perl(1).

=cut

