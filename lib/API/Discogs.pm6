#--------------  external modules ----------------------------------------------

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

# for methods that need the original client
my role NeedsClient {
    has $.client is rw;
}

my role PaginationShortcuts {  # does NeedsClient

    method first-page-url(::?CLASS:D:)    { $.pagination.urls<first> // Nil }
    method next-page-url(::?CLASS:D:)     { $.pagination.urls<next>  // Nil }
    method previous-page-url(::?CLASS:D:) { $.pagination.urls<prev>  // Nil }
    method last-page-url(::?CLASS:D:)     { $.pagination.urls<first> // Nil }

    method items(::?CLASS:D:)    { $.pagination.items }
    method page(::?CLASS:D:)     { $.pagination.page }
    method pages(::?CLASS:D:)    { $.pagination.pages }
    method per-page(::?CLASS:D:) { $.pagination.per-page }

    method !GET(Str:D $URL) {
        $URL
          ?? $.client.GET($URL, self.WHAT)
          !! $URL
    }

    method first-page(::?CLASS:D:)    { self!GET(self.first-page-url)    }
    method next-page(::?CLASS:D:)     { self!GET(self.next-page-url)     }
    method previous-page(::?CLASS:D:) { self!GET(self.previous-page-url) }
    method last-page(::?CLASS:D:)     { self!GET(self.last-page-url)     }
}

#--------------- actual class and its attributes -------------------------------

our class API::Discogs:ver<0.0.1>:auth<cpan:ELIZABETH> {
    has Cro::HTTP::Client $.client = $default-client;
    has AllowedCurrency $.currency = %*ENV<DISCOGS_CURRENCY> // @currencies[0];
    has UInt            $.per-page = 50;
    has Str $!token  is built = %*ENV<DISCOGS_TOKEN>;
    has Str $.key;
    has Str $!secret is built;

#--------------- the specific methods one can call -----------------------------

    # helper method for setting pagination parameters, must be last one
    method !pagination(%named --> Str:D) {
        my UInt $page     := %named<page>:delete     // 1;
        my UInt $per-page := %named<per-page>:delete // $.per-page;

        if %named.keys -> @extra {
            die "Found unsupported query keys: @extra.sort()";
        }
        "page=$page&per_page=$per-page"
    }

    # helper method for gathering named parameters
    method !gather-nameds(%nameds, @keys --> Str:D) {
        my str @text;
        for @keys -> $key {
            if %nameds{$key}:delete -> $value {
                @text.push("$key.subst('-','_',:g)='$value'")
            }
        }
        @text.join('&')
    }

    # main worker for creating non-asynchronous work
    method GET(API::Discogs:D: $uri, $class) {
        my @headers;
        @headers.push((Authorization => "Discogs key=$.key, secret=$!secret"))
          if $!secret && $.key;
        @headers.push((Authorization => "Discogs token=$!token"))
          if $!token;

        my $resp := await $.client.get($uri, :@headers);
        my $object := $class.new(await $resp.body);

        $object.client = self if $class ~~ NeedsClient;
        $object
    }

    # accessing the Cro::HTTP::Client
    multi method client(API::Discogs:U:) { $default-client }
    multi method client(API::Discogs:D:) { $!client }

#--------------- supporting classes derived from the JSON API ------------------

    our class ArtistSummary does Hash2Class[ # OK
      anv          => Str,
      id           => UInt,
      join         => Str,
      name         => Str,
      resource_url => { type => URL, name => "resource-url" },
      role         => Str,
      tracks       => Str,
    ] { }

    our class Rating does Hash2Class[ # OK
      average => Numeric,
      count   => Int,
    ] { }

    our class User does Hash2Class[ # OK
      resource_url => { type => URL, name => 'resource-url' },
      username     => Username,
    ] { }

    our class Community does Hash2Class[ # OK
      '@contributors' => User,
      data_quality    => { type => Quality, name => 'data-quality' },
      have            => Int,
      rating          => Rating,
      status          => Status,
      submitter       => User,
      want            => Int,
    ] { }

    our class CatalogEntry does Hash2Class[ # OK
      catno            => Str,
      entity_type      => { type => Int, name => 'entity-type' },
      entity_type_name => { type => Str, name => 'entity-type-name' },
      id               => UInt,
      name             => Str,
      resource_url => { type => URL, name => 'resource-url' },
    ] { }

    our class Format does Hash2Class[ # OK
      '@descriptions' => Str,
      name            => Str,
      qty             => Int,
    ] { }

    our class Identifier does Hash2Class[ # OK
      type  => Str,
      value => Str,
    ] { }

    our class Image does Hash2Class[ # OK
      height       => UInt,
      resource_url => { type => URL, name => 'resource-url' },
      type         => Str,
      uri          => URL,
      uri150       => URL,
      width        => UInt,
    ] { }

    our class Track does Hash2Class[ # OK
      duration => Str,
      position => UInt(Str),
      title    => Str,
      type_    => { type => Str, name => 'type' },
    ] { }

    our class Video does Hash2Class[ # OK
      description => Str,
      duration    => Int,
      embed       => Bool,
      title       => Str,
      uri         => URL,
    ] { }

    our class Member does Hash2Class[ # OK
      active       => Bool,
      id           => UInt,
      name         => Str,
      resource_url => { type => URL, name => 'resource-url' },
    ] { }

    our class Pagination does Hash2Class[ # OK
      '%urls'  => URL,
      items    => UInt,
      page     => UInt,
      pages    => UInt,
      per_page => { type => UInt, name => 'per-page' },
    ] { }

#-------------- getting the information of a master release ---------------------
    our class Release { ... }  # need to stub for fetch- methods

    our class MasterRelease does Hash2Class[ # OK
      '@artists'              => ArtistSummary,
      '@genres'               => Genre,
      '@images'               => Image,
      '@styles'               => Style,
      '@tracklist'            => Track,
      '@videos'               => Video,
      data_quality            => { type => Quality, name => 'data-quality' },
      id                      => UInt,
      lowest_price            => { type => Price, name => 'lowest-price' },
      main_release            => { type => UInt, name => 'main-release' },
      main_release_url        => { type => URL, name => 'main-release-url' },
      most_recent_release     => { type => UInt,
                                   name => 'most-recent-release' },
      most_recent_release_url => { type => URL,
                                   name => 'most-recent-release-url' },
      num_for_sale            => { type => UInt, name => 'num-for-sale' },
      resource_url            => { type => URL, name => 'resource-url' },
      title                   => Str,
      uri                     => URL,
      versions_url            => { type => URL, name => 'versions-url' },
      year                    => Year,
    ] does NeedsClient {
        method fetch-main-release(--> Release:D) {
            $.client.release($.main-release)
        }
        method fetch-most-recent-release(--> Release:D) {
            $.client.release($.most-recent-release)
        }
    }

    method master-release(API::Discogs:D:
      UInt:D $id
    --> MasterRelease:D) {
        self.GET("/masters/$id", MasterRelease)
    }

#-------------- getting the information of a specific release -------------------

    our class Release does Hash2Class[ # OK
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
      artists_sort      => { type => Str, name => 'artists-sort' },
      community         => Community,
      country           => Country,
      data_quality      => { type => Quality, name => 'data-quality' },
      date_added        => { type => DateTime(Str), name => 'date-added' },
      date_changed      => { type => DateTime(Str), name => 'date-changed' },
      estimated_weight  => { type => UInt, name => 'estimated-weight' },
      format_quantity   => { type => UInt, name => 'format-quantity' },
      id                => UInt,
      lowest_price      => { type => Price, name => 'lowest-price' },
      master_id         => { type => UInt, name => 'master-id' },
      master_url        => { type => URL, name => 'master-url' },
      notes             => Str,
      num_for_sale      => { type => UInt, name => 'num-for-sale' },
      released          => Str,
      release_formatted => { type => Str, name => 'release-formatted' },
      resource_url      => { type => URL, name => 'resource-url' },
    ] does NeedsClient {
        method average()      { $.community.rating.average }
        method contributors() { $.community.contributors   }
        method count()        { $.community.rating.count   }
        method have()         { $.community.have           }
        method submitter()    { $.community.submitter      }
        method want()         { $.community.have           }

        method fetch-master-release(--> MasterRelease:D) {
            $.client.master-release($.master-id)
        }
    }

    method release(API::Discogs:D:
      UInt:D $id, AllowedCurrency:D :$currency = $.currency
    --> Release:D) {
        self.GET("/releases/$id?$currency", Release)
    }

#-------------- getting the rating of a specific release -----------------------

    our class UserReleaseRating does Hash2Class[ # OK
      rating      => ValidRating,
      release     => UInt,
      username    => Username,
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
    multi method user-release-rating(API::Discogs:D:
      Release:D $release, User:D $user
    --> UserReleaseRating:D) {
        self.user-release-rating($release.id, $user.username)
    }
    multi method user-release-rating(API::Discogs:D:
      UInt:D $id, User:D $user
    --> UserReleaseRating:D) {
        self.user-release-rating($id, $user.username)
    }

    our class CommunityReleaseRating does Hash2Class[ # OK
      rating     => Rating,
      release_id => { type => UInt, name => 'release-id' },
    ] { }

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

#-------------- getting the versions of a master release ------------------------

    our class StatsData does Hash2Class[ # OK
      in_collection => { type => Int, name => 'in-collection' },
      in_wantlist   => { type => Int, name => 'in-wantlist' },
    ] { }

    our class Stats does Hash2Class[ # OK
      user      => StatsData,
      community => StatsData,
    ] { }

    our class Value does Hash2Class[ # OK
      count => Int,
      title => Str,
      value => Str,
    ] { }

    our class FilterFacet does Hash2Class[ # OK
      '@values'              => Value,
      allows_multiple_values => { type => Bool,
                                  name => 'allows-multiple-values' },
      id                     => Str,
      title                  => Str,
    ] { }

    our class Filters does Hash2Class[ # OK
      '%applied'   => FilterFacet,
      '%available' => UInt,
    ] { }

    our class MasterReleaseVersion does Hash2Class[ # OK
      '@major_formats' => { type => Str, name => 'major-formats' },
      '%label'         => Str,
      catno            => Str,
      country          => Country,
      format           => Str,
      id               => UInt,
      released         => UInt(Str),
      resource_url     => { type => URL, name => 'resource-url' },
      stats            => Stats,
      status           => Status,
      thumb            => URL,
      title            => Str,
    ] {
        method user-in-collection(MasterReleaseVersion:D: --> UInt:D) {
            $.stats.user.in-collection
        }
        method user-in-wantlist(MasterReleaseVersion:D: --> UInt:D) {
            $.stats.user.in-wantlist
        }
        method community-in-collection(MasterReleaseVersion:D: --> UInt:D) {
            $.stats.community.in-collection
        }
        method community-in-wantlist(MasterReleaseVersion:D: --> UInt:D) {
            $.stats.community.in-wantlist
        }
    }

    our class MasterReleaseVersions does Hash2Class[ # OK
      '@filter_facets' => { type => FilterFacet, name => 'filter-facets' },
      '@filters'       => Filters,
      '@versions'      => MasterReleaseVersion,
      pagination       => Pagination,
    ] does NeedsClient does PaginationShortcuts { }

    method master-release-versions(API::Discogs:D:
      UInt:D $id,
    --> MasterReleaseVersions:D) {
        self.GET(
          "/masters/$id/versions?"
            ~ self!gather-nameds(
                %_, <format label released country sort sort-order>
              )
            ~ self!pagination(%_),
          MasterReleaseVersions
        )
    }

#-------------- getting the information of a label ------------------------------

    our class SubLabel does Hash2Class[ # OK
      id           => UInt,
      name         => Str,
      resource_url => { type => URL, name => 'resource-url' },
    ] { }

    our class Label does Hash2Class[ # OK
      '@images'    => Image,
      '@sublabels' => SubLabel,
      '@urls'      => URL,
      contact_info => { type => Str, name => 'contact-info' },
      data_quality => { type => Quality, name => 'data-quality' },
      id           => UInt,
      name         => Str,
      profile      => Str,
      releases_url => { type => URL, name => 'releases-url' },
      resource_url => { type => URL, name => 'resource-url' },
      uri          => URL,
    ] { }

    method label(API::Discogs:D:
      UInt:D $id
    --> Label:D) {
        self.GET("/labels/$id", Label)
    }

#-------------- getting the releases of a label ---------------------------------

    our class LabelRelease does Hash2Class[ # OK
      artist       => Str,
      catno        => Str,
      format       => Format,
      id           => UInt,
      resource_url => { type => URL, name => 'resource-url' },
      status       => Status,
      thumb        => URL,
      title        => Str,
      year         => UInt,
    ] { }

    our class LabelReleases does Hash2Class[ # OK
      '@releases' => LabelRelease,
      pagination  => Pagination,
    ] does NeedsClient does PaginationShortcuts { }

    method label-releases(API::Discogs:D:
      UInt:D $id
    --> LabelReleases:D) {
        self.GET(
          "/labels/$id/releases?" ~ self!pagination(%_),
          LabelReleases
        )
    }

#-------------- getting the information about an artist -------------------------

    our class Artist does Hash2Class[ # OK
      '@images'         => Image,
      '@members'        => Member,
      '@namevariations' => Str,
      '@urls'           => URL,
      data_quality      => { type => Quality, name => 'data-quality' },
      id                => UInt,
      name              => Str,
      profile           => Str,
      releases_url      => { type => URL, name => 'releases-url' },
      resource_url      => { type => URL, name => 'resource-url' },
      uri               => URL,
    ] { }

    method artist(API::Discogs:D:
      UInt:D $id
    --> Artist:D) {
        self.GET("/artists/$id", Artist)
    }

#-------------- getting the releases of an artist -------------------------------

    our class ArtistRelease does Hash2Class[ # OK
      artist       => Str,
      format       => Str,
      id           => UInt,
      label        => Str,
      resource_url => { type => URL, name => 'resource-url' },
      role         => Str,
      stats        => Stats,
      status       => Status,
      thumb        => URL,
      title        => Str,
      type         => Str,
      year         => Year,
    ] {
        method user-in-collection(ArtistRelease:D: --> UInt:D) {
            $.stats.user.in-collection
        }
        method user-in-wantlist(ArtistRelease:D: --> UInt:D) {
            $.stats.user.in-wantlist
        }
        method community-in-collection(ArtistRelease:D: --> UInt:D) {
            $.stats.community.in-collection
        }
        method community-in-wantlist(ArtistRelease:D: --> UInt:D) {
            $.stats.community.in-wantlist
        }
    }

    our class ArtistReleases does Hash2Class[ # OK
      '@releases' => ArtistRelease,
      pagination  => Pagination,
    ] does NeedsClient does PaginationShortcuts { }

    method artist-releases(API::Discogs:D:
      UInt:D $id
    --> ArtistReleases:D) {
        self.GET(
          "/artists/$id/releases?"
            ~ self!gather-nameds(%_, <sort sort-order>)
            ~ self!pagination(%_),
          ArtistReleases
        )
    }

#-------------- searching the Discogs database ----------------------------------

    our class SearchResult does Hash2Class[ # OK
      cover_image  => URL,
      id           => UInt,
      master_id    => { type => UInt, name => 'master-id' },
      master_url   => { type => URL, name => 'master-url' },
      resource_url => { type => URL, name => 'resource-url' },
      thumb        => URL,
      title        => Str,
      type         => Str,
      uri          => URL,
      user_data    => { type => StatsData, name => 'user-data' },
    ] {
        method user-in-collection(ArtistRelease:D: --> UInt:D) {
            $.user-data.in-collection
        }
        method user-in-wantlist(ArtistRelease:D: --> UInt:D) {
            $.user-data.in-wantlist
        }
    }

    our class SearchResults does Hash2Class[ # OK
      '@results' => SearchResult,
      pagination => Pagination,
    ] does NeedsClient does PaginationShortcuts { }

    method search(API::Discogs:D: *%_ --> SearchResults:D) {
        my str @params;
        for %_.kv -> $key, $value {
            if %valid_query_key{$key} {
                @params.push($key eq 'query'
                  ?? "q=$value"
                  !! "$key=$value"
                );
                %_{$key}:delete;
            }
        }
        self.GET(
          "/database/search?" ~ @params.join("&") ~ self!pagination(%_),
          SearchResults
        )
    }
}

#--------------- runtime initialisations ---------------------------------------

$default-client := Cro::HTTP::Client.new:
  base-uri => "https://api.discogs.com",
  headers => (
    Accepts    => "application/vnd.discogs.v2.discogs+json",
    User-agent => "Raku Discogs Agent v" ~ API::Discogs.^ver,
  );

# vim: expandtab shiftwidth=4
