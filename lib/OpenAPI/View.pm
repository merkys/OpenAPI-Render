package OpenAPI::View;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( dereference );

sub dereference
{
    my( $node, $root ) = @_;

    if( ref $node eq 'ARRAY' ) {
        @$node = map { dereference( $_, $root ) } @$node;
    } elsif( ref $node eq 'HASH' ) {
        my @keys = keys %$node;
        if( scalar @keys == 1 && $keys[0] eq '$ref' ) {
            my @path = split '/', $node->{'$ref'};
            shift @path;
            $node = $root;
            while( @path ) {
                $node = $node->{shift @path};
            }
        } else {
            %$node = map { $_ => dereference( $node->{$_}, $root ) } @keys;
        }
    }
    return $node;
}

1;
