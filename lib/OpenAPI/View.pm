package OpenAPI::View;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    dereference
    RequestBody2Parameters
);

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

sub RequestBody2Parameters
{
    my( $requestBody ) = @_;

    return if !exists $requestBody->{content} ||
              !exists $requestBody->{content}{'multipart/form-data'} ||
              !exists $requestBody->{content}{'multipart/form-data'}{schema};

    my $schema = $requestBody->{content}{'multipart/form-data'}{schema};

    return if $schema->{type} ne 'object';
    return map { {
                    in     => 'query',
                    name   => $_,
                    schema => $schema->{properties}{$_} } }
               sort keys %{$schema->{properties}};
}

1;
