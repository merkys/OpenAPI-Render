package OpenAPI::View::reStructuredText;

use strict;
use warnings;

use List::Util qw( max );
use Text::ASCIITable;

use parent qw(OpenAPI::View);

sub header
{
    my( $self ) = @_;
    return _h( $self->{api}{info}{title} . ' v' .
               $self->{api}{info}{version},
               '=' );
}

sub path_header
{
    my( $self, $path ) = @_;
    return _h( $path, '-' );
}

sub operation_header
{
    my( $self, $path, $operation ) = @_;
    return _h( uc( $operation ) .
               ( $self->{api}{paths}{$path}{$operation}{description}
                    ? ': ' . $self->{api}{paths}{$path}{$operation}{description} : '' ),
               '+' );
}

sub parameters_header
{
    my( $self ) = @_;
    $self->{table} = Text::ASCIITable->new;
    $self->{table}->setOptions( 'drawRowLine', 1 );
    $self->{table}->setCols( 'Type', 'Name', 'Description', 'Mandatory?', 'Format', 'Example' );
    return '';
}

sub parameter
{
    my( $self, $parameter ) = @_;

    my $table = $self->{table};
    $table->addRow( $parameter->{in},
                    $parameter->{name},
                    $parameter->{description},
                    $parameter->{required} ? 'yes' : 'no',
                    $parameter->{schema}{type},
                    $parameter->{example} );
    return '';
}

sub parameters_footer
{
    my( $self ) = @_;
    return $self->{table}->draw( [ '+', '+', '-', '+' ],
                                 [ '|', '|', '|' ],
                                 [ '+', '+', '=', '+' ],
                                 [ '|', '|', '|' ],
                                 [ '+', '+', '-', '+' ] ) . "\n";
}

sub responses_header
{
    my( $self ) = @_;
    $self->{table} = Text::ASCIITable->new;
    $self->{table}->setOptions( 'drawRowLine', 1 );
    $self->{table}->setCols( 'HTTP code', 'Description' );
    return '';
}

sub response
{
    my( $self, $code, $response ) = @_;
    my $table = $self->{table};
    $table->addRow( $code, $response->{description} );
    return '';
}

sub responses_footer { &parameters_footer }

sub _h
{
    my( $text, $symbol ) = @_;
    $symbol = '-' unless $symbol;
    return $text . "\n" . ( $symbol x length $text ) . "\n\n";
}

1;
