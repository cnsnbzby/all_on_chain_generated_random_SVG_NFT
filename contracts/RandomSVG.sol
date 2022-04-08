// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "base64-sol/base64.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomSVG is ERC721URIStorage, VRFConsumerBase, Ownable {
    uint256 public tokenCounter;

    event CreatedRandomSVG(uint256 indexed tokenId, string tokenURI);
    event CreatedUnfinishedRandomSVG(
        uint256 indexed tokenId,
        uint256 randomNumber
    );
    event requestedRandomSVG(
        bytes32 indexed requestId,
        uint256 indexed tokenId
    );
    // indexing a parameter in an event means its gonna be a topic/indexed events???

    mapping(bytes32 => address) public requestIdToSender;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;
    mapping(bytes32 => uint256) public requestIdToTokenId;

    // below are SVG parameters
    bytes32 internal keyHash; // keyhash defines which chainlink node we are gonna work with
    uint256 internal fee; // fee/oracle gas to get random number
    uint256 public maxNumberOfPaths; // number of paths in svg creation, bigger this number, more gas we have to spend
    uint256 public maxNumberOfPathCommands; // similar case to above line
    uint256 public size;
    string[] public pathCommands;
    string[] public colors;

    constructor(
        // since all the networks we work on will have different below items, we need to parameterize them
        // thats why we first pass them to constructor and then to vrfconsumerbase constructor
        address _VRFCoordinator, // in orderto tell where this random number checker is
        address _LinkToken,
        bytes32 _keyhash, // to identify which chainlink node we work with
        uint256 _fee // varies by network
    )
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
        ERC721("RandomSVG", "rsNFT")
    {
        tokenCounter = 0;
        keyHash = _keyhash;
        fee = _fee;
        owner = msg.sender;
        price = 100000000000000000  // 0.1 ETH/MATIC/AVAX,  min price to create/mint an NFT
        maxNumberOfPaths = 10;
        maxNumberOfPathCommands = 5;
        size = 500;
        pathCommands = ["M", "L"]; // choose these since we oly wanna move in these ranges
        colors = ["red", "blue", "green", "yellow", "black", "white"];
    }

    function withdraw() public payable onlyOwner {
        // to withdraw all the money to owner
        payable(owner()).transfer(address(this).balance);
    }

    function create() public payable returns (bytes32 requestId) {
        // since we want to randomly create, there is no input parameter as in SVGNFT.sol example
        // we want svg to come up naturally by gettting random numbe and use it to generate random svg
        require(msg.value >= price,"Need to speend more ETH!";)
        requestId = requestRandomness(keyHash, fee); // to call this function our contract needs to be funded with link token
        requestIdToSender[requestId] = msg.sender; // to save who made the request and we will use this mapping to later saign our nft
        uint256 tokenId = tokenCounter;
        requestIdToTokenId[requestId] = tokenId; // mapping requestId to tokenId
        tokenCounter = tokenCounter + 1;
        emit requestedRandomSVG(requestId, tokenId);
    }

    // minting NFT is already done in fulfillrandomness, finishMint function is to add tokenURI to it
    function finishMint(uint256 tokenId) public {
        require(
            bytes(tokenURI(tokenId)).length <= 0,
            "tokenURI is already set!"
        ); // checking and making sure of tokenURI is not set
        require(tokenCounter > tokenId, "TokenId has not been minted yet!"); // checking to see if tokenId exists
        require(
            tokenIdToRandomNumber[tokenId] > 0,
            "Need to wait for the Chainlink node to respond!"
        ); // to see if a randomnumber to that tokenId exists
        uint256 randomNumber = tokenIdToRandomNumber[tokenId]; // getting random number to generate some SVG code
        string memory svg = generateSVG(randomNumber);
        string memory imageURI = svgToImageURI(svg);
        _setTokenURI(tokenId, formatTokenURI(imageURI));
        emit CreatedRandomSVG(tokenId, svg);
    }

    // this function is called by VRF coordinator to return random number
    // after taking random number we want to turn that into random svg
    // this function is just to get a random number, finishMint function is the main function doing the rest of the work with random number
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        // internal because we want only VRFCoordinator to call it and VRFC is overriding the implementation of fulfillrandomness
        address nftOwner = requestIdToSender[requestId];
        uint256 tokenId = requestIdToTokenId[requestId];

        // seen here that we waited to mint the nft until the random number is created
        _safeMint(nftOwner, tokenId); // safemint function creates NFT and assings it to an owner
        // after we minted, we dont want to call generate random svg here because its gonna cost a lot of gas
        // below storing randomnumber to make calculations later ourselves
        tokenIdToRandomNumber[tokenId] = randomNumber;
        emit CreatedUnfinishedRandomSVG(tokenId, randomNumber);
    }

    function generateSVG(uint256 _randomness)
        public
        view
        returns (string memory finalSvg)
    {
        // We will only use the path element, with stroke and d elements
        uint256 numberOfPaths = (_randomness % maxNumberOfPaths) + 1;
        finalSvg = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' height='", // anything inside double quotes will be single quote
                uint2str(size),
                "' width='",
                uint2str(size),
                "'>"
            )
        );
        for (uint256 i = 0; i < numberOfPaths; i++) {
            // we get a new random number for each path
            string memory pathSvg = generatePath(
                uint256(keccak256(abi.encode(_randomness, i))) // mixing random number with path number we are on into a new number
                // and casting as uint256
            );
            finalSvg = string(abi.encodePacked(finalSvg, pathSvg)); // concatting new path with our final SVG
        }
        finalSvg = string(abi.encodePacked(finalSvg, "</svg>"));
    }

    function generatePath(uint256 _randomness)
        public
        view
        returns (string memory pathSvg)
    {
        uint256 numberOfPathCommands = (_randomness % maxNumberOfPathCommands) +
            1;
        pathSvg = "<path d='";
        for (uint256 i = 0; i < numberOfPathCommands; i++) {
            string memory pathCommand = generatePathCommand(
                uint256(keccak256(abi.encode(_randomness, size + i)))
            );
            pathSvg = string(abi.encodePacked(pathSvg, pathCommand));
        }
        string memory color = colors[_randomness % colors.length]; // TO get random colour
        // below is putting all together above lines
        pathSvg = string(
            abi.encodePacked(
                pathSvg,
                "' fill='transparent' stroke='",
                color,
                "'/>"
            )
        );
    }

    function generatePathCommand(uint256 _randomness)
        public
        view
        returns (string memory pathCommand)
    {
        pathCommand = pathCommands[_randomness % pathCommands.length];
        uint256 parameterOne = uint256(
            keccak256(abi.encode(_randomness, size * 2))
        ) % size;
        uint256 parameterTwo = uint256(
            keccak256(abi.encode(_randomness, size * 2 + 1))
        ) % size;
        pathCommand = string(
            abi.encodePacked(
                pathCommand,
                " ",
                uint2str(parameterOne),
                " ",
                uint2str(parameterTwo)
            )
        );
    }

    // From: https://stackoverflow.com/a/65707309/11969592
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // You could also just upload the raw SVG and have solildity convert it!
    function svgToImageURI(string memory svg)
        public
        pure
        returns (string memory)
    {
        // example:
        // <svg width='500' height='500' viewBox='0 0 285 350' fill='none' xmlns='http://www.w3.org/2000/svg'><path fill='black' d='M150,0,L75,200,L225,200,Z'></path></svg>
        // data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNTAwJyBoZWlnaHQ9JzUwMCcgdmlld0JveD0nMCAwIDI4NSAzNTAnIGZpbGw9J25vbmUnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHBhdGggZmlsbD0nYmxhY2snIGQ9J00xNTAsMCxMNzUsMjAwLEwyMjUsMjAwLFonPjwvcGF0aD48L3N2Zz4=
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function formatTokenURI(string memory imageURI)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
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
