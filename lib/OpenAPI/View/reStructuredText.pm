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
    $self->{table}->setCols( 'Type', 'Name', 'Description' );
    return '';
}

sub parameter
{
    my( $self, $parameter ) = @_;

    my $table = $self->{table};
    $table->addRow( $parameter->{in}, $parameter->{name}, $parameter->{description} );
    return '';
    
    #~ my @parameter;
    #~ push @parameter,
         #~ h3( $parameter->{name} ),
         #~ $parameter->{description} ? p( $parameter->{description} ) : ();
    #~ if( $parameter->{schema} && $parameter->{schema}{enum} ) {
        #~ my @values = @{$parameter->{schema}{enum}};
        #~ if( !$parameter->{required} ) {
            #~ unshift @values, '';
        #~ }
        #~ push @parameter,
             #~ popup_menu( -name => $parameter->{name},
                         #~ -values => \@values,
                         #~ ($parameter->{in} eq 'path'
                            #~ ? ( '-data-in-path' => 1 ) : ()) );
    #~ } elsif( ($parameter->{schema}{type} &&
              #~ $parameter->{schema}{type} eq 'object') ||
             #~ ($parameter->{schema}{format} &&
              #~ $parameter->{schema}{format} eq 'binary') ) {
        #~ push @parameter,
             #~ filefield( -name => $parameter->{name} );
    #~ } else {
        #~ push @parameter,
             #~ input( { -type => 'text',
                      #~ -name => $parameter->{name},
                      #~ ($parameter->{in} eq 'path'
                        #~ ? ( '-data-in-path' => 1 ) : ()),
                      #~ (exists $parameter->{example}
                        #~ ? ( -placeholder => $parameter->{example} )
                        #~ : ()) } );
    #~ }
    #~ return @parameter;
}

sub parameters_footer
{
    my( $self ) = @_;
    return $self->{table}->draw( [ '+', '+', '-', '-' ],
                                 [ '|', '|', '|' ],
                                 [ '+', '+', '=', '=' ],
                                 [ '|', '|', '|' ],
                                 [ '+', '+', '-', '-' ] ) . "\n";
}

sub _h
{
    my( $text, $symbol ) = @_;
    $symbol = '-' unless $symbol;
    return $text . "\n" . ( $symbol x length $text ) . "\n\n";
}

1;
