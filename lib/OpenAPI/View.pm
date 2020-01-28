package OpenAPI::View;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    dereference
    RequestBody2Parameters
);

sub new
{
    my( $class, $api ) = @_;

    my $self = { api => dereference( $api, $api ) };

    my( $base_url ) = map { $_->{url} } @{$api->{servers} };
    $self->{base_url} = $base_url if $base_url;

    return bless $self, $class;
}

sub show
{
    my( $self ) = @_;

    print $self->header;

    my $api = $self->{api};

    for my $path (sort keys %{$api->{paths}}) {
        print $self->path_header( $path );
        for my $operation ('get', 'post', 'patch', 'put', 'delete') {
            next if !$api->{paths}{$path}{$operation};
            print $self->operation_header( $path, $operation );
            my @parameters = (
                exists $api->{paths}{$path}{parameters}
                   ? @{$api->{paths}{$path}{parameters}} : (),
                exists $api->{paths}{$path}{$operation}{parameters}
                   ? @{$api->{paths}{$path}{$operation}{parameters}} : (),
                exists $api->{paths}{$path}{$operation}{requestBody}
                   ? RequestBody2Parameters( $api->{paths}{$path}{$operation}{requestBody} ) : (),
                );
            print map { $self->parameter( $_ ) } @parameters;
            print $self->operation_footer( $path, $operation );
        }
    }

    print $self->footer;
}

sub header {}
sub footer {}
sub path_header {}
sub operation_header {}
sub operation_footer {}
sub parameter {}

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
