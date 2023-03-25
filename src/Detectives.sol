// SPDX-License-Identifier: UNLICENSED

pragma solidity  ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Detectives is ERC721Enumerable, AccessControl {

    /**
    RANKS:  
    1-Detective I
    2-Detective II
    3-Detective III
    4-Lieutenant
    5-Captain
    6-Commander
    */

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using Strings for uint256;

    struct Detective {
        // Packed into 1 slot 16 + 16 = 32
        uint128 actualRank;
        uint128 sP;
    }

    bytes32 public constant SPD_ROLE = keccak256("SPD_ROLE");
    uint96 public constant maxSupply = 30;
    uint96 public constant mintPrice = 0.008 ether;
    string public constant baseExtension = ".json";
    uint128[] public detectiveStatePsychopath = [80, 99, 100, 120, 160, 199, 200];
    mapping(uint256 => Detective) public tokenIdToDetective;
    string private baseURI;

    error UnsuccessfulWithdraw();

    constructor(
        address _spdAddr
    )
    ERC721("Detectives", "DETECTIVES") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SPD_ROLE, _spdAddr);
    }

    modifier tokenMustExist(uint256 _tokenId) {
        require(_exists(_tokenId), "Token doesn't exist");
        _;
    }

    function updateBaseURI(string memory _baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
    }

    function getDetectiveRank(uint256 _tokenId) external view tokenMustExist(_tokenId) returns (uint256) {
        return tokenIdToDetective[_tokenId].actualRank;
    }

    function mint(address _rulersTokenAddr) external payable {
        require(maxSupply > totalSupply(), "No supply left");
        require(msg.value >= mintPrice, "Not enought ETH");
        require(balanceOf(msg.sender) == 0, "Can only mint 1 token");
        require(IERC721(_rulersTokenAddr).balanceOf(msg.sender) == 0, "You're a ruler");

        uint256 _index = 0;

        uint256 newTokenId = _tokenIds.current();
        tokenIdToDetective[newTokenId].sP = detectiveStatePsychopath[_index];
        tokenIdToDetective[newTokenId].actualRank = 1;
        _safeMint(msg.sender, newTokenId);
        _tokenIds.increment();


    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        for(uint256 _index; _index < ownerTokenCount; _index++){
            tokenIds[_index] = tokenOfOwnerByIndex(_owner, _index);
        }

        return tokenIds;
    }

    function increaseDetectiveSP(uint256 _tokenId) external tokenMustExist(_tokenId) onlyRole(SPD_ROLE) {
        require(tokenIdToDetective[_tokenId].sP != detectiveStatePsychopath[6], "Token SP is at limit!");

        if(hasRole(SPD_ROLE, _msgSender())) {
            bool _isFound = false;
            while(_isFound == false) {
                uint256 _index = 0;
                if(tokenIdToDetective[_tokenId].sP == detectiveStatePsychopath[_index]) {
                    _index++;
                    tokenIdToDetective[_tokenId].sP = detectiveStatePsychopath[_index];
                    _isFound = true;
    
                } else {
                    _index++;
                }
           }
        }
        
    }

    function levelUpRank(uint256 _tokenId) external tokenMustExist(_tokenId) onlyRole(SPD_ROLE) {
        if(tokenIdToDetective[_tokenId].actualRank < 6) {
            tokenIdToDetective[_tokenId].actualRank++;
        }
    }

    function levelDownRank(uint256 _tokenId) external tokenMustExist(_tokenId) onlyRole(SPD_ROLE) {
        if(tokenIdToDetective[_tokenId].actualRank > 1) {
            tokenIdToDetective[_tokenId].actualRank--;
        }
    }

    function killDetective(uint256 _tokenId) external tokenMustExist(_tokenId) onlyRole(SPD_ROLE) {
        if(tokenIdToDetective[_tokenId].sP == detectiveStatePsychopath[4]) {
            _burn(_tokenId);
        }
        
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "Contract is empty");

        (bool success, ) = payable(msg.sender).call{value: _balance}("");
        if (!success) {
            revert UnsuccessfulWithdraw();
        }

        assert(_balance == 0);
    }

    function tokenURI(uint256 _tokenId) public view virtual override tokenMustExist(_tokenId) returns(string memory _tokenURI) {
        return bytes(baseURI).length > 0 ?
           string(abi.encodePacked(baseURI, _tokenId.toString(), baseExtension)) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}