pragma solidity ^0.4.24;

import "./ERC721Token.sol";

contract StarNotary is ERC721Token { 

    struct Star { 
        string name;
        string story;
        string cent;
        string dec;
        string mag;
    }
    bytes32 mtStarHash;

    mapping(uint256 => Star) public tokenIdToStarInfo;
    mapping(uint256 => uint256) public starsForSale;
    mapping(bytes32 => uint256) public coordinateToTokenId;

    constructor () public {
        mtStarHash = _starHash(Star("", "", "", "", ""));
    }

    event LogHash(bytes32 indexed _hash, string _description);
    event LogUint256(uint256 indexed _number, string _description);

    function _starHash(Star star) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                star.name,
                star.story,
                star.cent,
                star.dec,
                star.mag
            )
        );
    }

    function _coordinateHash(Star star) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                star.cent,
                star.dec,
                star.mag
            )
        );
    }

    function createStar(
        string _name,
        string _story, 
        string _cent,
        string _dec,
        string _mag,
        uint256 _tokenId
    ) public { 
        Star storage star = tokenIdToStarInfo[_tokenId];
        bytes32 starHash = _starHash(star);
        require(starHash == mtStarHash, "tokenId for star already exists");
        
        Star memory newStar = Star(_name, _story, _cent,  _dec, _mag);
        
        bytes32 newStarCoordinateHash = _coordinateHash(newStar);
        uint256 tokenId = coordinateToTokenId[newStarCoordinateHash];
        emit LogHash(newStarCoordinateHash, "coordinate hash");
        emit LogUint256(tokenId, "tokenId");
        require(tokenId == 0, "star has coordinate duplicate");

        tokenIdToStarInfo[_tokenId] = newStar;
        coordinateToTokenId[newStarCoordinateHash] = _tokenId;

        ERC721Token.mint(_tokenId);
    }

    function putStarUpForSale(uint256 _tokenId, uint256 _price) public { 
        require(this.ownerOf(_tokenId) == msg.sender, "must own star to sell it");

        starsForSale[_tokenId] = _price;
    }

    function buyStar(uint256 _tokenId) public payable { 
        require(starsForSale[_tokenId] > 0, "star not for sale");

        uint256 starCost = starsForSale[_tokenId];
        address starOwner = this.ownerOf(_tokenId);

        require(msg.value >= starCost, "insufficent funds");

        clearPreviousStarState(_tokenId);

        transferFromHelper(starOwner, msg.sender, _tokenId);

        if(msg.value > starCost) { 
            msg.sender.transfer(msg.value - starCost);
        }

        starOwner.transfer(starCost);
    }

    function clearPreviousStarState(uint256 _tokenId) private {
        //clear approvals 
        tokenToApproved[_tokenId] = address(0);

        //clear being on sale 
        starsForSale[_tokenId] = 0;
    }
}