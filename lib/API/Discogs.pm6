use API::Discogs::Classes;
use Cro::HTTP::Client;

# supported currencies
my constant @currencies = <
  USD GBP EUR CAD AUD JPY CHF MXN BRL NZD SEK ZAR
>;
subset AllowedCurrency of Str where * (elem) @currencies;

my %valid_query_key is Set = <
  anv artist barcode catno contributor country credit format genre label
  query release_title style submitter title track type year
>;

# needs to be defined here for visibility
my $default-client;

our class API::Discogs:ver<0.0.1>:auth<cpan:ELIZABETH> {
    has AllowedCurrency $.currency = @currencies[0];
    has Cro::HTTP::Client $.client = $default-client;
    has UInt            $.per-page = 50;
    has Str $.key;
    has Str $!secret is built;
    has Str $!token  is built;

    # helper method for setting pagination parameters
    method !pagination(%nameds --> Str:D) {
        my UInt $page     := %nameds<page>:delete     // 1;
        my UInt $per-page := %nameds<per-page>:delete // $.per-page;
        "page=$page&per_page=$per-page"
    }

    # main worker for creating non-asynchronous work
    method GET(API::Discogs:D: $uri, $class) {
        my @headers;
        @headers.push((Authorization => "Discogs key=$.key, secret=$!secret"))
          if $!secret && $.key;
        @headers.push((Authorization => "Discogs token=$!token"))
          if $!token;

        my $resp := await $.client.get($uri, :@headers);
        $class.new(await $resp.body)
    }

    method label(API::Discogs:D:
      UInt:D $id
    --> Label:D) {
        self.GET("/labels/$id", Label)
    }

    method label-releases(API::Discogs:D:
      UInt:D $id
    --> LabelReleases:D) {
        self.GET(
          "/labels/$id/releases?" ~ self!pagination(%_),
          LabelReleases
        )
    }

    method artist(API::Discogs:D:
      UInt:D $id
    --> Artist:D) {
        self.GET("/artists/$id", Artist)
    }

    method artist-releases(API::Discogs:D:
      UInt:D $id
    --> ArtistReleases:D) {
        self.GET(
          "/artists/$id/releases?" ~ self!pagination(%_),
          ArtistReleases
        )
    }

    method master-release(API::Discogs:D:
      UInt:D $id
    --> MasterRelease:D) {
        self.GET("/masters/$id", MasterRelease)
    }

    method release-versions(API::Discogs:D:
      UInt:D $id
    --> ReleaseVersions:D) {
        self.GET(
          "/masters/$id/versions?" ~ self!pagination(%_),
          ReleaseVersions
        )
    }

    method release(API::Discogs:D:
      UInt:D $id, AllowedCurrency:D :$currency = $.currency
    --> Release) {
        self.GET("/releases/$id?$currency", Release)
    }

    multi method user-release-rating(API::Discogs:D:
      UInt:D $id, Username $username
    --> UserReleaseRating:D) {
        self.GET("/releases/$id/rating/$username", UserReleaseRating)
    }
    multi method user-release-rating(API::Discogs:D:
      Release:D $release, Username $username
    --> UserReleaseRating:D) {
        self.user-release-rating($release.id, $username)
    }

    multi method community-release-rating(API::Discogs:D:
      UInt:D $id
    --> CommunityReleaseRating:D) {
        self.GET("/releases/$id/rating", CommunityReleaseRating)
    }
    multi method community-release-rating(API::Discogs:D:
      Release:D $release
    --> CommunityReleaseRating:D) {
        self.community-release-rating($release.id)
    }

    method search(API::Discogs:D: *%_ --> SearchResults:D) {
        my str @params = self!pagination(%_);
        for %_.kv -> $key, $value {
            if %valid_query_key{$key} {
                @params.push($key eq 'query'
                  ?? "q=$value"
                  !! "$key=$value"
                );
                %_{$key}:delete;
            }
        }
        if %_.keys -> @extra {
            die "Found unsupported query keys: @extra.sort()";
        }
        self.GET("/database/search?" ~ @params.join("&"), SearchResults)
    }
}

$default-client := Cro::HTTP::Client.new:
  base-uri => "https://api.discogs.com",
  headers => (
    Accepts    => "application/vnd.discogs.v2.discogs+json",
    User-agent => "Raku Discogs Agent v" ~ API::Discogs.^ver,
  );

=begin pod

=head1 NAME

API::Discogs - Provide basic API to Discogs

=head1 SYNOPSIS

=begin code :lang<raku>

use API::Discogs;

=end code

=head1 DESCRIPTION

API::Discogs provides a Raku library with access to the L<Discogs|https://discogs.com>
data and functions.

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/API-Discogs . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
