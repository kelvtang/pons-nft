# Metadata

## Metadata Structure: {String: AnyStruct}?
"editionNumber"     => Int      // Out of limited edition items
    "editionMax"    => Int      // Max number of NFT of this edition
"externalURL"       => String   // e.g. "https://example-nft.onflow.org/".concat(self.id.toString())
"url"               => String
    "mediaType"     => String   // e.g. "image/svg+xml"
"collectionName"    => String 
    "description"   => String   // Collection description
    "social"        => {String: String}  // {twitter: "https://twitter.com/xyz"}
"mintedTime"        => Date

"rareTraits"        => [PonsNftContract_v1 .rareTraitDescription]?



## Royalty system -- > need to make


"editionNumber", "editionMax", "externalURL", "url", "mediaType", "collectionName", "description", "social"

