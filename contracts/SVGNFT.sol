// below contract takes some SVG code
// outputs an NFT URI with this SVG
// storing metadata on chain

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // borrowing openzeppelins ERC721 contract
// with above extension its easier to set and unset tokenURI compared to normal ERC721
import "base64-sol/base64.sol"; // importing base64 for encoding svg file in base64 base

contract SVGNFT is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;
    event CreatedSVGNFT(uint256 indexed tokenId, string tokenURI); // emitting an event everytime we create an svg nft

    // constructor to mint our contract (collectible factory) and create to create an instance of this collectible

    // SVG NFT is name and svgNFT is token symbol, every time we mint one of the below token, its gonna be a type of SVG NFT
    constructor() ERC721("SVG NFT", "svgNFT") {
        // it says we use ERC721 constructor as part of our constructor
        tokenCounter = 0;
    }

    // use SVG viewer to see your svg file

    function create(string memory svg) public {
        // we are passing svg variable to public create function
        _safeMint(msg.sender, tokenCounter); // takes address owner and tokenId, here tokencounter is token id
        //ERC721 function, minting one SVG NFT like one crypto punk/ape
        string memory imageURI = svgToImageURI(svg);
        _setTokenURI(tokenCounter, formatTokenURI(imageURI));
        tokenCounter = tokenCounter + 1; // incrementing everytime we create one collectible
        emit CreatedSVGNFT(tokenCounter, svg);
    }

    // You could also just upload the raw SVG and have solildity convert it!
    function svgToImageURI(string memory svg)
        public
        pure
        returns (string memory)
    {
        // since this function does not read anything from chain, it is not view but pure function
        // example:
        // XX <svg width='500' height='500' viewBox='0 0 285 350' fill='none' xmlns='http://www.w3.org/2000/svg'><path fill='black' d='M150,0,L75,200,L225,200,Z'></path></svg>
        // data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNTAwJyBoZWlnaHQ9JzUwMCcgdmlld0JveD0nMCAwIDI4NSAzNTAnIGZpbGw9J25vbmUnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHBhdGggZmlsbD0nYmxhY2snIGQ9J00xNTAsMCxMNzUsMjAwLEwyMjUsMjAwLFonPjwvcGF0aD48L3N2Zz4=
        // image URI is always gonna start with data:image/svg+xml;base64
        string memory baseURL = "data:image/svg+xml;base64,"; //as it always starts with this, data is image and file is svg+xml for svg file
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        ); // turning svg variable to base64 encoded version, above line starting with XX
        // it will turn into sth like PHN2ZyB3aWR0aD0nNTAwJyBoZWlnaHQ9JzUwMCcgdmlld0JveD0nMCAwIDI4NSAzNTAnIGZpbGw9J25vb
        return string(abi.encodePacked(baseURL, svgBase64Encoded)); // concatting two strings with string method
    }

    // below function takes imageURI and creates a json object
    function formatTokenURI(string memory imageURI)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked( // concatting baseURL with imageURI
                    "data:application/json;base64,", // here check how data is application and file is json compared to imageURI
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "SVG NFT", // You can add whatever name here
                                '", "description":"An NFT based on SVG!", "attributes":"", "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
