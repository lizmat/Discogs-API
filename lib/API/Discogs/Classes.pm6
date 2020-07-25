use Hash2Class;

#--------------- useful subtypes -----------------------------------------------

our subset Country of Str;
our subset Genre of Str;
our subset Quality of Str;
our subset Price of Real;
our subset Status of Str where "Accepted";
our subset Style of Str;
our subset URL of Str where .starts-with("https://") || .starts-with("http://");
our subset Username of Str where /^ \w+ $/;
our subset ValidRating of Int where 1 <= $_ <= 5;
our subset Year of UInt where $_ > 1900 && $_ <= 2100;

#--------------- useful roles --------------------------------------------------

my role PaginationURLs {
    method first-page-url(::?CLASS:D:)    { $.pagination.urls<first> // Nil }
    method next-page-url(::?CLASS:D:)     { $.pagination.urls<next>  // Nil }
    method previous-page-url(::?CLASS:D:) { $.pagination.urls<prev>  // Nil }
    method last-page-url(::?CLASS:D:)     { $.pagination.urls<first> // Nil }
}

#--------------- classes derived from the JSON API -----------------------------

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

our class UserReleaseRating does Hash2Class[
  rating      => ValidRating,
  release     => UInt,
  username    => Username,
] { }

our class CommunityReleaseRating does Hash2Class[
  rating      => Rating,
  releasei_id => UInt,
] { }

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

our class Member does Hash2Class[
  active       => Bool,
  id           => UInt,
  name         => Str,
  resource_url => Str,
] { }

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

class StatsData does Hash2Class[
  in_collection => Int,
  in_wantlist   => Int,
] { }

class Stats does Hash2Class[
  '%source' => StatsData,
] { }

class ReleaseVersion does Hash2Class[
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

class Value does Hash2Class[
  count => Int,
  title => Str,
  value => Str,
] { }

class FilterFacet does Hash2Class[
  '@values'              => Value,
  allows_multiple_values => Bool,
  id                     => Str,
  title                  => Str,
] { }

class Pagination does Hash2Class[
  '%urls'  => URL,
  items    => UInt,
  page     => UInt,
  pages    => UInt,
  per_page => UInt,
] { }

class Filters does Hash2Class[
  '%applied'   => FilterFacet,
  '%available' => UInt,
] { }

class ReleaseVersions does Hash2Class[
  '@filter_facets' => FilterFacet,
  '@filters'       => Filters,
  '@versions'      => ReleaseVersion,
  pagination       => Pagination,
] does PaginationURLs { }

=begin pod

=head1 NAME

API::Discogs::Classes - classes of the Discogs API

=head1 SYNOPSIS

=begin code :lang<raku>

use API::Discogs::Classes

=end code

=head1 DESCRIPTION

API::Discogs::Classes provides the classes that are needed for the data
provided by <Discogs|https://discogs.com>.

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
