unit class API::Discogs:ver<0.0.1>:auth<cpan:ELIZABETH>;

use Hash2Class;
#use Cro::HTTP::Client;
#
#my $client := Cro::HTTP::Client.new:
#  base-uri => "https://api.discogs.com",
#  headers => [
#    User-agent => "Raku Discogs Agent v" ~ $?CLASS.^ver,
#  ];
#my $resp := await $client.get("/releases/249504");
#my $json := await $resp.body;

our subset URL of Str where .starts-with("https://") || .starts-with("http://");
our subset Username of Str where /^ \w+ $/;
our subset Status of Str where "Accepted";
our subset Price of Real;
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

use JSON::Fast;
my $json := from-json("249504.release".IO.slurp);

my $release := Release.new($json);
dd $_ for $release.community.contributors;
dd $release.released;
dd $release.date_added;
dd $release.artists;

#dd $json<artists>[0];
#my $artist = Artist.new($json<artists>[0]);
#dd $artist.^methods>>.name.sort;
#dd $artist.name;

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
