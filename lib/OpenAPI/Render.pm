package OpenAPI::Render;

use strict;
use warnings;

use Clone qw( clone );
use JSON qw( decode_json );
use version;

# ABSTRACT: Render OpenAPI specifications as documents
# VERSION

=method C<new>

Given an OpenAPI specification in raw JSON or parsed data structure, constructs a C<OpenAPI::Render> object.
Does not modify input values.

=cut

sub new
{
    my( $class, $api ) = @_;

    if( ref $api ) {
        # Parsed JSON given, need to make a copy as dereferencing will modify it.
        $api = clone $api;
    } else {
        # Raw JSON given, need to parse.
        $api = decode_json $api;
    }

    my $self = { api => _dereference( $api, $api ) };

    if( exists $self->{api}{openapi} ) {
        my $version = version->parse( $self->{api}{openapi} );
        if( $version < version->parse( '3' ) || $version > version->parse( '4' ) ) {
            warn "unsupported OpenAPI version $self->{api}{openapi}, " .
                 'results may be incorrect', "\n";
        }
    } else {
        warn 'top-level attribute "openapi" not found, cannot ensure ' .
             'this is OpenAPI, cannot check version', "\n";
    }

    my( $base_url ) = map { $_->{url} } @{$api->{servers} };
    $self->{base_url} = $base_url if $base_url;

    return bless $self, $class;
}

=method C<show>

Main generating method (does not take any parameters).
Returns a string with rendered representation of an OpenAPI specification.

=cut

sub show
{
    my( $self ) = @_;

    my $html = $self->header;
    my $api = $self->api;

    for my $path (sort keys %{$api->{paths}}) {
        $html .= $self->path_header( $path );
        for my $operation ('get', 'post', 'patch', 'put', 'delete') {
            next if !$api->{paths}{$path}{$operation};
            my @parameters = (
                exists $api->{paths}{$path}{parameters}
                   ? @{$api->{paths}{$path}{parameters}} : (),
                exists $api->{paths}{$path}{$operation}{parameters}
                   ? @{$api->{paths}{$path}{$operation}{parameters}} : (),
                exists $api->{paths}{$path}{$operation}{requestBody}
                   ? _RequestBody2Parameters( $api->{paths}{$path}{$operation}{requestBody} ) : (),
                );
            my $responses = $api->{paths}{$path}{$operation}{responses};

            $html .= $self->operation_header( $path, $operation ) .

                     $self->parameters_header .
                     join( '', map { $self->parameter( $_ ) } @parameters ) .
                     $self->parameters_footer .

                     $self->responses_header .
                     join( '', map { $self->response( $_, $responses->{$_} ) }
                                   sort keys %$responses ) .
                     $self->responses_footer .

                     $self->operation_footer( $path, $operation );
        }
    }

    $html .= $self->footer;
    return $html;
}

=method C<header>

Text added before everything else.
Empty in the base class.

=cut

sub header { return '' }

=method C<footer>

Text added after everything else.
Empty in the base class.

=cut

sub footer { return '' }

=method C<path_header>

Text added before each path.
Empty in the base class.

=cut

sub path_header { return '' }

=method C<operation_header>

Text added before each operation.
Empty in the base class.

=cut

sub operation_header { return '' }

=method C<parameters_header>

Text added before parameters list.
Empty in the base class.

=cut

sub parameters_header { return '' };

=method C<parameter>

Returns representation of a single parameter.
Empty in the base class.

=cut

sub parameter { return '' }

=method C<parameters_footer>

Text added after parameters list.
Empty in the base class.

=cut

sub parameters_footer { return '' };

=method C<responses_header>

Text added before responses list.
Empty in the base class.

=cut

sub responses_header { return '' };

=method C<parameter>

Returns representation of a single response.
Empty in the base class.

=cut

sub response { return '' };

=method C<responses_footer>

Text added after responses list.
Empty in the base class.

=cut

sub responses_footer { return '' };

=method C<operation_footer>

Text added after each operation.
Empty in the base class.

=cut

sub operation_footer { return '' }

=method C<api>

Returns the parsed and dereferenced input OpenAPI specification.
Note that in the returned data structure all references are dereferenced, i.e., flat.

=cut

sub api
{
    my( $self ) = @_;
    return $self->{api};
}

sub _dereference
{
    my( $node, $root ) = @_;

    if( ref $node eq 'ARRAY' ) {
        @$node = map { _dereference( $_, $root ) } @$node;
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
            %$node = map { $_ => _dereference( $node->{$_}, $root ) } @keys;
        }
    }
    return $node;
}

sub _RequestBody2Parameters
{
    my( $requestBody ) = @_;

    return if !exists $requestBody->{content} ||
              !exists $requestBody->{content}{'multipart/form-data'} ||
              !exists $requestBody->{content}{'multipart/form-data'}{schema};

    my $schema = $requestBody->{content}{'multipart/form-data'}{schema};

    return if $schema->{type} ne 'object';
    return ( map { {
                      in     => 'query',
                      name   => $_,
                      schema => $schema->{properties}{$_} } }
                 sort keys %{$schema->{properties}} ),
           ( map { {
                      in             => 'query',
                      name           => $_,
                      schema         => $schema->{patternProperties}{$_},
                      'x-is-pattern' => 1 } }
                 sort keys %{$schema->{patternProperties}} );
}

1;
