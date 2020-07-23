use Hash2Class;

our subset URL of Str where .starts-with("https://") || .starts-with("http://");
our subset Username of Str where /^ \w+ $/;
our subset Status of Str where "Accepted";
our subset Price of Real;
our subset ValidRating of Int where 1 <= $_ <= 5;
our subset Country of Str;
our subset Genre of Str;
our subset Year of UInt where $_ > 1900 && $_ <= 2100;

our class Artist does Hash2Class[
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
  data_quality    => Str,
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
  position => Str,
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

our class Release does Hash2Class[
  '@artists'        => Artist,
  '@companies'      => CatalogEntry,
  '@extraartists'   => Artist,
  '@formats'        => Format,
  '@genres'         => Genre,
  '@identifiers'    => Identifier,
  '@images'         => Image,
  '@labels'         => CatalogEntry,
  '@series'         => CatalogEntry,
  '@styles'         => Str,
  '@tracklist'      => Track,
  '@videos'         => Video,
  artists_sort      => Str,
  community         => Community,
  country           => Country,
  data_quality      => Str,
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

class ReleaseUserRating does Hash2Class[
  rating      => ValidRating,
  release     => UInt,
  username    => Username,
] { }

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
