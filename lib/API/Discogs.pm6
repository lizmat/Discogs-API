use API::Discogs::Classes;
use Cro::HTTP::Client;

# supported currencies
my constant @currencies = <
  USD GBP EUR CAD AUD JPY CHF MXN BRL NZD SEK ZAR
>;
subset AllowedCurrency of Str where * (elem) @currencies;

# needs to be defined here for visibility
my $default-client;

class API::Discogs:ver<0.0.1>:auth<cpan:ELIZABETH> {
    has AllowedCurrency $.currency = @currencies[0];
    has Cro::HTTP::Client $.client = $default-client;
    has UInt            $.per-page = 50;
    has Str $.key;
    has Str $!secret is built;

    # helper method for setting pagination parameters
    method !pagination(%nameds --> Str:D) {
        my UInt $page     := %nameds<page>     // 1;
        my UInt $per-page := %nameds<per-page> // $.per-page;
        "page=$page&per_page=$per-page"
    }

    # main worker for creating non-asynchronous work
    method GET(API::Discogs:D: $uri, $class) {
        my $resp := await $.client.get(
          $!secret && $.key
            ?? ($uri, headers => (
                 Authorization => "Discogs key=$.key, secret=$!secret"
               ))
            !! $uri
        );
        $class.new(await $resp.body)
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
}

$default-client := Cro::HTTP::Client.new:
  base-uri => "https://api.discogs.com",
  headers => (
    Accepts    => "application/vnd.discogs.v2.discogs+json",
    User-agent => "Raku Discogs Agent v" ~ API::Discogs.^ver,
  );

my $discogs := API::Discogs.new;
#my $release := $discogs.release(249504);
#dd $_ for $release.community.contributors;
#dd $release.released;
#dd $release.date_added;
#dd $release.artists;
#
#my $user-rating := $discogs.user-release-rating($release, "memory");
#dd $user-rating;
#
#my $community-rating := $discogs.community-release-rating($release);
#dd $community-rating;
#
#my $master-release = $discogs.master-release(1000);
#dd $_ for $master-release.tracklist;
#
#my $release-versions = $discogs.release-versions(1000,:2page,:2per-page);
#dd $release-versions.next-page-url;
#dd $_ for $release-versions(:2per-page).pagination.urls;

#my $artist = $discogs.artist(108713);
#dd $artist.name;
#dd $_ for $artist.namevariations;
#dd $artist.profile;

my $artist-releases = $discogs.artist-releases(108713);
dd $_ for $artist-releases.releases;

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
