package Parse::Tokens;

use strict;
use vars	qw( @ISA $VERSION );

$VERSION = 0.20;

sub new
{
	my ( $proto, $params ) = @_;
	my $class = ref($proto) || $proto;
	my $self = {
		loose_paring	=> undef,
		debug			=> undef,
		autoflush		=> undef,
		text			=> undef,
		delimiters		=> [],
		delim_index		=> {}
	};
	bless ($self, $class);
	$self->{delimiters} = [];
	$self->init( $params );
	$self;
}

sub init
{
    my( $self, $args ) = @_;
	no strict 'refs';
	for ( keys %$args )
	{
		my $ref = lc $_;
		$self->$ref($args->{$_});
	}
	use strict;
}

sub debug
{
	my( $self, $arg ) = @_;
	$self->{debug} = $arg if defined $arg;
	return $self->{debug};
}

sub loose_paring
{
	my( $self, $arg ) = @_;
	$self->{loose_paring} = $arg if defined $arg;
#	return 1;
	return $self->{loose_paring};
}

# this is returning a hash ref ($self I believe);
sub autoflush
{
	my( $self, $arg ) = @_;
	$self->{autoflush} = $arg if defined $arg;
	return $self->{autoflush};
}

sub text
{
	my( $self, $arg ) = @_;
	$self->flush;
	$self->{text} = $arg if defined $arg;
	return $self->{text};
}

sub delimiters
{
	my( $self, $args ) = @_;
	# we currently support both a ref to an array of delims
	# as well as an ref to an array of array refs with delims
	if ( ref($args) eq 'ARRAY' )
	{
		# we have multiple arrays
		if( ref($args->[0]) eq 'ARRAY' )
		{
			for( @$args )
			{
				$self->_add_delims( $_ );
			}	
		}
		# we have only this array
		else
		{
			$self->_add_delims( $args );
		}
	}
	return @{$self->{delimiters}};
}

sub _add_delims
{ 
	# add a delim pair (real and quoted) to the delimiters array
	my( $self, $args ) = @_;
	push(
		@{$self->{delimiters}}, {
			real	=> $args,
			quoted	=> [
				quotemeta($args->[0]),
				quotemeta($args->[1])
			]
		}
	);
	$self->{delim_index}->{$args->[0]} = $#{$self->{delimiters}};
	$self->{delim_index}->{$args->[1]} = $#{$self->{delimiters}};
}

sub flush
{
	my( $self ) = @_;
	delete $self->{cache};
	return 1;
}

sub parse
{
	my( $self, $args ) = @_;
	$self->init( $args );
	return unless defined $self->{text};
	$self->flush if $self->{autoflush};

	my @delim = $self->delimiters();
	my $match_rex = $self->match_rex( \@delim );

	unless( $self->{cache} )
	{
		# parse the text
		my @chunk = split( m/$match_rex/so, $self->{text} );
		$self->{cache} = \@chunk;
	}

	my $n = 0;
	while ($n <= $#{$self->{cache}})
	{
		# find opening delimiter
		
		# if the first element of the token is the element of a token
		#if ( $self->{cache}->[$n] eq $delim[0]->{real}->[0] || $self->{cache}->[$n] eq $delim[1]->{real}->[0] )
		if ( $self->{cache}->[$n] eq $delim[$self->{delim_index}->{$self->{cache}->[$n]}]->{real}->[0] )
		{ $self->token([
			$self->{cache}->[$n],
			$self->{cache}->[++$n],
			$self->{cache}->[++$n]
		]); }

		# or it's just text
		else
		{ $self->ether($self->{cache}->[$n]); }
		$n++
	}
}


sub match_rex
{
	# construct our token finding regular expression
	my( $self, $delim ) = @_;
	my $rex;
	if( $self->loose_paring() )
	{
		my( @left, @right );
		for( @$delim )
		{
			push( @left, $_->{quoted}->[0] );
			push( @right, $_->{quoted}->[1] );
		}
		$rex = '('.join('|', @left).')(.*?)('.join('|', @right).')';
	}
	else
	{
		my( @sets );
		for( @$delim )
		{
			push( @sets, qq{($_->{quoted}->[0])(.*?)($_->{quoted}->[1])} );
		}
		$rex = join( '|', @sets );
	}
	return $rex;
}



# an token consists of a left-delimiter, the contents, and a right-delimiter
sub token{
	die join( ', ', @_ );
}

# ether is anything not contained in an atom
sub ether{
	die join( ', ', @_ );
}

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

=head1 FUNCTIONS

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

=head1 CHANGES

0.20 - added multi-token support

=head1 AUTHOR

Steve McKay, steve@colgreen.com

=head1 COPYRIGHT

Copyright 2000 by Steve McKay. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

perl(1).

=cut
