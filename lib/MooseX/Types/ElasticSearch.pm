package MooseX::Types::ElasticSearch;

# ABSTRACT: Useful types for ElasticSearch

use DateTime::Format::Epoch::Unix;
use DateTime::Format::ISO8601;
use ElasticSearch;

use MooseX::Types -declare => [
    qw(
      Location
      QueryType
      ES
      ESDateTime
      ) ];

use MooseX::Types::Moose qw/Int Str ArrayRef HashRef/;

coerce ArrayRef, from Str, via { [$_] };

class_type ES, { class => 'ElasticSearch' };
coerce ES, from Str, via {
    my $server = $_;
    $server = "127.0.0.1$server" if ( $server =~ /^:/ );
    return
      ElasticSearch->new( servers   => $server,
                          transport => 'httptiny',
                          timeout   => 30, );
};

coerce ES, from HashRef, via {
    return ElasticSearch->new(%$_);
};

coerce ES, from ArrayRef, via {
    my @servers = @$_;
    @servers = map { /^:/ ? "127.0.0.1$_" : $_ } @servers;
    return
      ElasticSearch->new( servers   => \@servers,
                          transport => 'httptiny',
                          timeout   => 30, );
};

enum QueryType, qw(query_and_fetch query_then_fetch dfs_query_and_fetch dfs_query_then_fetch);

class_type ESDateTime;
coerce ESDateTime, from Str, via {
    if ( $_ =~ /^\d+$/ ) {
        DateTime::Format::Epoch::Unix->parse_datetime($_);
    } else {
        DateTime::Format::ISO8601->parse_datetime($_);
    }
};

subtype Location,
  as ArrayRef,
  where { @$_ == 2 },
  message { "Location is an arrayref of longitude and latitude" };

coerce Location, from HashRef,
  via { [ $_->{lon} || $_->{longitude}, $_->{lat} || $_->{latitude} ] };
coerce Location, from Str, via { [ reverse split(/,/) ] };

1;

=head1 SYNOPSIS

 use MooseX::Types::ElasticSearch qw(:all);

=head1 TYPES

=head2 ES

This type matches against an L<ElasticSearch> instance. It coerces from a C<Str>, C<ArrayRef> and C<HashRef>.

If the string contains only the port number (e.g. C<":9200">), then C<127.0.0.1:9200> is assumed.

=head2 Location

ElasticSearch expects values for geo coordinates (C<geo_point>) as an C<ArrayRef> of longitude and latitude.
This type coerces from C<Str> (C<"lat,lon">) and C<HashRef> (C<< { lat => 41.12, lon => -71.34 } >>).

=head2 QueryType

C<Enum> type. Valid values are: C<query_and_fetch query_then_fetch dfs_query_and_fetch dfs_query_then_fetch>

=head2 ESDateTime

ElasticSearch returns dates in the ISO8601 date format. This type coerces from C<Str> to L<DateTime>
objects using L<DateTime::Format::ISO8601>.

=head1 TODO

B<More types>

Please don't hesitate and send other useful types in.