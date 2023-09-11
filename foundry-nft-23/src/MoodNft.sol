// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "lib/openzeppelin-contracts/contracts/utils/Base64.sol";


contract MoodNft is ERC721 {
    uint256 private s_tokenCounter;
    string private s_sadSvgImageUri;
    string private s_happySvgImageUri;

    enum Mood {
        HAPPY,
        SAD
    }

    mapping(uint256 => Mood) private s_tokenIdToMood;

    constructor(
        string memory sadSvgImageUri,
        string memory happySvgImageUri
    ) ERC721("MoodNft", "MN") {
        s_tokenCounter = 0;
        s_sadSvgImageUri = sadSvgImageUri;
        s_happySvgImageUri = happySvgImageUri;
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToMood[s_tokenCounter] = Mood.HAPPY;
            s_tokenCounter++;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory imageURI;
        if(s_tokenIdToMood[tokenId] == Mood.HAPPY) {
            imageURI = s_happySvgImageUri;
        } else {
            imageURI = s_sadSvgImageUri;
        }
        // string. cat is cool but we need to convert it to bytes so use abi.encodePacked
        // string memory tokenMetadata = string.concat('{"name": "', name(), '", "description": "An NFT that reflects the owners mood.", "attributes": [{"trait_type": "moodiness", "value": 100}], "image": "', imageURI, '"}');
        return
        string(
            abi.encodePacked(
                Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name": "', name(),
                        '", "description": "An NFT that reflects the owners mood.", "attributes": [{"trait_type": "moodiness", "value": 100}], "image": "',
                        imageURI,
                        '"}'
                        )
                    )
                )
            )
        ); 
    }
}
