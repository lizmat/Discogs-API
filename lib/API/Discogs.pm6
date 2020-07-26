#--------------- external modules ----------------------------------------------

use Hash2Class;
use Cro::HTTP::Client;

#--------------- file lexical constants ----------------------------------------

# supported currencies
my constant @currencies = <
  USD GBP EUR CAD AUD JPY CHF MXN BRL NZD SEK ZAR
>;

# not constant because of https://github.com/rakudo/rakudo/issues/3828
my %valid_query_key is Set = <
  anv artist barcode catno contributor country credit format genre
  label query release_title style submitter title track type year
>;

# needs to be defined here for visibility
my $default-client;

#--------------- useful subtypes -----------------------------------------------

subset AllowedCurrency of Str where * (elem) @currencies;
subset Country of Str;
subset Genre of Str;
subset Quality of Str;
subset Price of Real;
subset Status of Str where "Accepted";
subset Style of Str;
subset URL of Str where .starts-with("https://") || .starts-with("http://");
subset Username of Str where /^ \w+ $/;
subset ValidRating of Int where 1 <= $_ <= 5;
subset Year of UInt where $_ > 1900 && $_ <= 2100;

#--------------- useful roles --------------------------------------------------

my role PaginationShortcuts {
    method first-page-url(::?CLASS:D:)    { $.pagination.urls<first> // Nil }
    method next-page-url(::?CLASS:D:)     { $.pagination.urls<next>  // Nil }
    method previous-page-url(::?CLASS:D:) { $.pagination.urls<prev>  // Nil }
    method last-page-url(::?CLASS:D:)     { $.pagination.urls<first> // Nil }

    method items(::?CLASS:D:)    { $.pagination.items }
    method page(::?CLASS:D:)     { $.pagination.page }
    method pages(::?CLASS:D:)    { $.pagination.pages }
    method per-page(::?CLASS:D:) { $.pagination.per-page }
}

#--------------- actual class and its attributes -------------------------------

our class API::Discogs:ver<0.0.1>:auth<cpan:ELIZABETH> {
    has AllowedCurrency $.currency = %*ENV<DISCOGS_CURRENCY> // @currencies[0];
    has Cro::HTTP::Client $.client = $default-client;
    has UInt            $.per-page = 50;
    has Str $!token  is built = %*ENV<DISCOGS_TOKEN>;
    has Str $.key;
    has Str $!secret is built;

#--------------- supporting classes derived from the JSON API ------------------

    our class ArtistSummary does Hash2Class[
      anv          => Str,
      id           => UInt,
      join         => Str,
      name         => Str,
      resource_url => URL,
      role         => Str,
      tracks       => Str,
    ] { }

    our class Rating does Hash2Class[
      average => Numeric,
      count   => Int,
    ] { }

    our class User does Hash2Class[
      resource_url => URL,
      username     => Username,
    ] { }

    our class Community does Hash2Class[
      '@contributors' => User,
      data_quality    => Quality,
      have            => Int,
      rating          => Rating,
      status          => Status,
      submitter       => User,
      want            => Int,
    ] { }

    our class CatalogEntry does Hash2Class[
      catno            => Str,
      entity_type      => Int,
      entity_type_name => Str,
      id               => UInt,
      name             => Str,
      resource_url     => URL,
    ] { }

    our class Format does Hash2Class[
      '@descriptions' => Str,
      name            => Str,
      qty             => Int,
    ] { }

    our class Identifier does Hash2Class[
      type  => Str,
      value => Str,
    ] { }

    our class Image does Hash2Class[
      height       => UInt,
      resource_url => URL,
      type         => Str,
      uri          => URL,
      uri150       => URL,
      width        => UInt,
    ] { }

    our class Track does Hash2Class[
      duration => Str,
      position => UInt(Str),
      title    => Str,
      type_    => Str,
    ] { }

    our class Video does Hash2Class[
      description => Str,
      duration    => Int,
      embed       => Bool,
      title       => Str,
      uri         => URL,
    ] { }

    our class Member does Hash2Class[
      active       => Bool,
      id           => UInt,
      name         => Str,
      resource_url => Str,
    ] { }

    our class Value does Hash2Class[
      count => Int,
      title => Str,
      value => Str,
    ] { }

    our class FilterFacet does Hash2Class[
      '@values'              => Value,
      allows_multiple_values => Bool,
      id                     => Str,
      title                  => Str,
    ] { }

    our class Filters does Hash2Class[
      '%applied'   => FilterFacet,
      '%available' => UInt,
    ] { }

    our class StatsData does Hash2Class[
      in_collection => Int,
      in_wantlist   => Int,
    ] { }

    our class Stats does Hash2Class[
      '%source' => StatsData,
    ] { }

    our class Pagination does Hash2Class[
      '%urls'  => URL,
      items    => UInt,
      page     => UInt,
      pages    => UInt,
      per_page => UInt,
    ] { }

#--------------- the specific methods one can call -----------------------------

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

#-------------- getting the information of a specific release -------------------

    our class Release does Hash2Class[
      '@artists'        => ArtistSummary,
      '@companies'      => CatalogEntry,
      '@extraartists'   => ArtistSummary,
      '@formats'        => Format,
      '@genres'         => Genre,
      '@identifiers'    => Identifier,
      '@images'         => Image,
      '@labels'         => CatalogEntry,
      '@series'         => CatalogEntry,
      '@styles'         => Style,
      '@tracklist'      => Track,
      '@videos'         => Video,
      artists_sort      => Str,
      community         => Community,
      country           => Country,
      data_quality      => Quality,
      date_added        => DateTime(Str),
      date_changed      => DateTime(Str),
      estimated_weight  => UInt,
      format_quantity   => UInt,
      id                => UInt,
      lowest_price      => Price,
      master_id         => UInt,
      master_url        => URL,
      notes             => Str,
      num_for_sale      => UInt,
      released          => Str,
      release_formatted => Str,
      resource_url      => URL,
      status            => Status,
      thumb             => URL,
      title             => Str,
      uri               => URL,
      year              => Year,
    ] { }

    method release(API::Discogs:D:
      UInt:D $id, AllowedCurrency:D :$currency = $.currency
    --> Release) {
        self.GET("/releases/$id?$currency", Release)
    }

    our class UserReleaseRating does Hash2Class[
      rating      => ValidRating,
      release     => UInt,
      username    => Username,
    ] { }

    our class CommunityReleaseRating does Hash2Class[
      rating      => Rating,
      releasei_id => UInt,
    ] { }

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

#-------------- getting the information of a master release ---------------------

    our class MasterRelease does Hash2Class[
      '@artists'              => ArtistSummary,
      '@genres'               => Genre,
      '@images'               => Image,
      '@styles'               => Style,
      '@tracklist'            => Track,
      '@videos'               => Video,
      data_quality            => Quality,
      id                      => UInt,
      lowest_price            => Rat,
      main_release            => UInt,
      main_release_url        => URL,
      most_recent_release     => UInt,
      most_recent_release_url => URL,
      num_for_sale            => UInt,
      resource_url            => URL,
      title                   => Str,
      uri                     => URL,
      versions_url            => URL,
      year                    => Year,
    ] { }

    method master-release(API::Discogs:D:
      UInt:D $id
    --> MasterRelease:D) {
        self.GET("/masters/$id", MasterRelease)
    }

#-------------- getting the versions of a release -------------------------------

    our class ReleaseVersion does Hash2Class[
      '@major_formats' => Str,
      '%label'         => Str,
      catno            => Str,
      country          => Country,
      format           => Str,
      id               => UInt,
      released         => Str,
      resource_url     => URL,
      stats            => Stats,
      status           => Status,
      thumb            => URL,
      title            => Str,
    ] { }

    our class ReleaseVersions does Hash2Class[
      '@filter_facets' => FilterFacet,
      '@filters'       => Filters,
      '@versions'      => ReleaseVersion,
      pagination       => Pagination,
    ] does PaginationShortcuts { }

    method release-versions(API::Discogs:D:
      UInt:D $id
    --> ReleaseVersions:D) {
        self.GET(
          "/masters/$id/versions?" ~ self!pagination(%_),
          ReleaseVersions
        )
    }

#-------------- getting the information of a label ------------------------------

    our class SubLabel does Hash2Class[
      id           => UInt,
      name         => Str,
      resource_url => URL,
    ] { }

    our class Label does Hash2Class[
      '@images'    => Image,
      '@sublabels' => SubLabel,
      '@urls'      => URL,
      contact_info => Str,
      data_quality => Str,
      id           => UInt,
      name         => Str,
      profile      => Str,
      releases_url => URL,
      resource_url => URL,
      uri          => URL,
    ] { }

    method label(API::Discogs:D:
      UInt:D $id
    --> Label:D) {
        self.GET("/labels/$id", Label)
    }

#-------------- getting the releases of a label ---------------------------------

    our class LabelRelease does Hash2Class[
      artist       => Str,
      catno        => Str,
      format       => Format,
      id           => UInt,
      resource_url => URL,
      status       => Status,
      thumb        => URL,
      title        => Str,
      year         => UInt,
    ] { }

    our class LabelReleases does Hash2Class[
      '@releases' => LabelRelease,
      pagination  => Pagination,
    ] does PaginationShortcuts { }

    method label-releases(API::Discogs:D:
      UInt:D $id
    --> LabelReleases:D) {
        self.GET(
          "/labels/$id/releases?" ~ self!pagination(%_),
          LabelReleases
        )
    }

#-------------- getting the information about an artist -------------------------

    our class Artist does Hash2Class[
      '@images'         => Image,
      '@members'        => Member,
      '@namevariations' => Str,
      '@urls'           => URL,
      data_quality      => Quality,
      id                => UInt,
      name              => Str,
      profile           => Str,
      releases_url      => URL,
      resource_url      => URL,
      uri               => URL,
    ] { }

    method artist(API::Discogs:D:
      UInt:D $id
    --> Artist:D) {
        self.GET("/artists/$id", Artist)
    }

#-------------- getting the releases of an artist -------------------------------

    our class ArtistRelease does Hash2Class[
      '%stats'     => StatsData,
      artist       => Str,
      format       => Str,
      id           => UInt,
      label        => Str,
      resource_url => URL,
      role         => Str,
      status       => Status,
      thumb        => URL,
      title        => Str,
      type         => Str,
      year         => Year,
    ] { }

    our class ArtistReleases does Hash2Class[
      '@releases' => ArtistRelease,
      pagination  => Pagination,
    ] does PaginationShortcuts { }

    method artist-releases(API::Discogs:D:
      UInt:D $id
    --> ArtistReleases:D) {
        self.GET(
          "/artists/$id/releases?" ~ self!pagination(%_),
          ArtistReleases
        )
    }

#-------------- searching the Discogs database ----------------------------------

    our class SearchResult does Hash2Class[
      cover_image  => URL,
      id           => UInt,
      master_id    => UInt,
      master_url   => URL,
      resource_url => URL,
      thumb        => URL,
      title        => Str,
      type         => Str,
      uri          => URL,
      user_data    => StatsData,
    ] { }

    our class SearchResults does Hash2Class[
      '@results' => SearchResult,
      pagination => Pagination,
    ] does PaginationShortcuts { }

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

#--------------- runtime initialisations ---------------------------------------

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
