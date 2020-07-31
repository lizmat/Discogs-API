use Test;
use Discogs::API;

sub artist-summary-ok($artist) is export {
    isa-ok $artist, Discogs::API::ArtistSummary, 'did we get a summary';
    ok $artist.anv ~~ Str, 'did we get an artist name variation';
    ok $artist.id ~~ UInt, 'did we get an unsigned int as ID';
    ok $artist.join ~~ Str, 'did we get a join string';
    ok $artist.name ~~ Str, 'did we get a name';
    ok $artist.resource-url ~~ URL, 'did we get a resource URL';
    ok $artist.role ~~ Str, 'did we get a role string';
    ok $artist.tracks ~~ Str, 'did we get a tracks string';
}

sub catalog-entry-ok($entry) is export {
    isa-ok $entry, Discogs::API::CatalogEntry, 'did we get a catalog entry';
    ok $entry.catno ~~ Str, 'did we get a string for the catalog number';
    ok $entry.entity-type ~~ UInt, 'did we get an unsigned int for type';
    ok $entry.entity-type-name ~~ Str, 'did we get a string for type name';
    ok $entry.id ~~ UInt, 'did we get an unsigned int for id';
    ok $entry.name ~~ Str, 'did we get a string for the name';
    ok $entry.resource-url ~~ URL, 'did we get a URL for the resource';
}

sub community-ok($community) is export {
    isa-ok $community, Discogs::API::Community, 'did we get a community';

    for $community.contributors -> $contributor {
        user-ok($contributor);
    }

    ok $community.data-quality ~~ Quality, 'did we get a quality';
    ok $community.have ~~ UInt, 'did we get an unsigned int for have';

    if $community.rating -> $rating {
        isa-ok $rating, Discogs::API::Rating, 'did we get a Rating';
        is $rating.average, 3.59, 'did we get correct average';
        is $rating.count, 137, 'did we get correct count';
    }

    ok $community.status ~~ Status, 'did we get a status';
    is $community.status, "Accepted", 'did we get the right status';

    user-ok($community.submitter);

    is $community.want, 278, 'did we get correct want';
}

sub format-ok($format) is export {
    isa-ok $format, Discogs::API::Format, 'did we get a format';

    my @descriptions := $format.descriptions;
    is +@descriptions, 3, 'did we get correct number of descriptions';

    for @descriptions -> $description {
        ok $description ~~ Str, 'did we get a string for description';
    }
    ok $format.name ~~ Str, 'did we get a string for the name';
    ok $format.qty ~~ UInt, 'did we get a unsigned int for quantity';
}

sub identifier-ok($identifier) is export {
    isa-ok $identifier, Discogs::API::Identifier, 'did we get an identifier';
    ok $identifier.type ~~ Str, 'did we get a type string';
    ok $identifier.value ~~ Str, 'did we get a value string';
}

sub image-ok($image) is export {
    isa-ok $image, Discogs::API::Image, 'did we get an image';
    ok $image.height ~~ UInt, 'did we get an integer height';
    ok $image.resource-url ~~ URL, 'did we get a URL resource';
    ok $image.type ~~ Str, 'did we get a Str type';
    ok $image.uri ~~ URL, 'did we get a uri';
    ok $image.uri150 ~~ URL, 'did we get a uri150';
    ok $image.width ~~ UInt, 'did we get an integer width';
}

sub in-collection-wantlist-ok($object) is export {
    ok $object.community-in-collection ~~ UInt,
      'did we get an unsigned int for in community collection';
    ok $object.community-in-wantlist ~~ UInt,
      'did we get an unsigned int for in community want list';
    ok $object.user-in-collection ~~ UInt,
      'did we get an unsigned int for in user collection';
    ok $object.user-in-wantlist ~~ UInt,
      'did we get an unsigned int for in user want list';
}

sub member-ok($member) is export {
    isa-ok $member, Discogs::API::Member, 'did we get a member';
    ok $member.active ~~ Bool, 'did we get a bool for active';
    ok $member.id ~~ UInt, 'did we get an artist id';
    ok $member.name ~~ Str, 'did we get an artist name';
    ok $member.resource-url ~~ URL, 'did we get a resource URL';
}

sub rating-ok($rating) is export {
    isa-ok $rating, Discogs::API::Rating, 'did we get a Rating';
    ok $rating.average ~~ Rational, 'did we get rational for average';
    ok $rating.count ~~ UInt, 'did we get unsigned in for count';
}

sub track-ok($track) is export {
    isa-ok $track, Discogs::API::Track, 'did we get a Track object';
    ok $track.duration ~~ Str, 'did we get a string for the duration';
    ok $track.position ~~ Str, 'did we get a string for position';
    ok $track.title ~~ Str, 'did we get a string for title';
    ok $track.type ~~ Str, 'did we get a string for type';
}

sub user-ok($user) is export {
    isa-ok $user, Discogs::API::User, 'did we get a submitter';
    ok $user.resource-url ~~ URL, 'did we get a URL';
    ok $user.username ~~ Username, 'did we get a username';
}

sub video-ok($video) is export {
    isa-ok $video, Discogs::API::Video, 'did we get a Video object';
    ok $video.description ~~ Str, 'did we get a string for description';
    ok $video.duration ~~ UInt, 'did we get an unsigned int for duration';
    ok $video.embed ~~ Bool, 'did we get a bool for embedding';
    ok $video.title ~~ Str, 'did we get a string for title';
    ok $video.uri ~~ URL, 'did we get a URL for uri';
}

# vim: expandtab shiftwidth=4
