// SPDX-License-Identifier: UNLICENSED

pragma solidity  ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IDetectives {
    function balanceOf(address _addr) external view returns (uint256);
    function increaseDetectiveSP(uint256 _tokenId) external;
    function levelUpRank(uint256 _tokenId) external;
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external returns (uint256);
    function levelDownRank(uint256 _tokenId) external;
}

contract Rulers is ERC721Enumerable, AccessControl {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using Strings for uint256;

    struct Ruler {
        bool isUriRevealed;
        bool isSPRevealed;
        bytes32 sP;
    }

    bytes32 public constant SPD_ROLE = keccak256("SPD_ROLE");

    uint256 public immutable maxSupply;
    uint256 public constant mintPrice = 0.008 ether;
    string public constant baseExtension = ".json";
    address private detectivesTokenAddr;
    bytes32 rulerStatePsychopath;
    mapping(uint256 => string) private tokenURIs;
    mapping(uint256 => Ruler) internal tokenIdToRuler;

    constructor(
        string memory _contractName,
        string memory _contractSymbol,
        uint256 _setMaxSupply,
        bytes32 _setRulerStatePsychopath,
        address _spdAddr,
        address _setDetectiveTokenAddr
    ) 
    ERC721(_contractName, _contractSymbol) {
        maxSupply = _setMaxSupply;
        rulerStatePsychopath = _setRulerStatePsychopath;
        detectivesTokenAddr = _setDetectiveTokenAddr;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SPD_ROLE, _spdAddr);
    }

    receive() external payable {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function updateRulersSP(bytes32 _sP) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rulerStatePsychopath = _sP;
    }

    function setURIs(uint256 _state, string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
       tokenURIs[_state] = _uri;
    }

    function mint() external payable {
        require(maxSupply > totalSupply(), "Error, sold out!");
        require(msg.value >= mintPrice, "Error, not enought ETH");
        require(balanceOf(msg.sender) == 0, "Error, you can only mint 1 token");
        require(IDetectives(detectivesTokenAddr).balanceOf(msg.sender) == 0, "Error, you're a detective");

        uint256 newTokenId = _tokenIds.current();
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

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory _tokenURI) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(tokenIdToRuler[_tokenId].isUriRevealed == true) {
            string memory currentURI = tokenURIs[1];
            return bytes(currentURI).length > 0 ?
                string(abi.encodePacked(currentURI, _tokenId.toString(), baseExtension)) : "";

        } else if(msg.sender == ownerOf(_tokenId)) {
            string memory currentURI = tokenURIs[1];
            return bytes(currentURI).length > 0 ?
                string(abi.encodePacked(currentURI, _tokenId.toString(), baseExtension)) : "";

        } else {
            string memory currentURI = tokenURIs[0];
            return bytes(currentURI).length > 0 ?
                string(abi.encodePacked(currentURI, _tokenId.toString(), baseExtension)) : "";

        }
    }

    function ifMatchRevealIdentity(address _approvalTokenAddr, uint256 _tokenId, address _suspiciusAddr) external payable returns (bool) {
        require(_exists(_tokenId), "Error, token doesn't exist");
        require(IERC20(_approvalTokenAddr).balanceOf(msg.sender) >= 1, "Error, you don't have approval");
        require(IDetectives(detectivesTokenAddr).balanceOf(msg.sender) >= 1, "Error, you're not a detective");
        
        IERC20(_approvalTokenAddr).transfer(_suspiciusAddr, 1);
        uint256 _senderTokenId = IDetectives(detectivesTokenAddr).tokenOfOwnerByIndex(msg.sender, 0);

        if(ownerOf(_tokenId) == _suspiciusAddr) {
            tokenIdToRuler[_tokenId].isUriRevealed = true;
            tokenIdToRuler[_tokenId].isSPRevealed = true;
            IDetectives(detectivesTokenAddr).levelUpRank(_senderTokenId);

            return true;

        } else {
            IDetectives(detectivesTokenAddr).increaseDetectiveSP(_tokenId);
            IDetectives(detectivesTokenAddr).levelDownRank(_senderTokenId);

            return false;

        }
    }

    function investigateSpfToken(address _approvalTokenAddr, uint256 _tokenId) external payable returns(bytes32 _statePsychopath) {
        require(_exists(_tokenId), "Error, token doesn't exist");
        require(IERC20(_approvalTokenAddr).balanceOf(msg.sender) >= 1, "Error, you don't have approval");
        require(IDetectives(detectivesTokenAddr).balanceOf(msg.sender) >= 1, "Error, you're not a detective");
        
        if(tokenIdToRuler[_tokenId].isSPRevealed == true) {
            return tokenIdToRuler[_tokenId].sP;
        }
        
    }

    function killRuler(address _approvalTokenAddr, uint256 _tokenId) external payable {
        require(_exists(_tokenId), "Error, token doesn't exist");
        require(IERC20(_approvalTokenAddr).balanceOf(msg.sender) >= 1, "Error, you don't have approval");
        require(IDetectives(detectivesTokenAddr).balanceOf(msg.sender) >= 1, "Error, you're not a detective");

        if(tokenIdToRuler[_tokenId].isSPRevealed == true  || IERC20(_approvalTokenAddr).balanceOf(msg.sender) >= 4) {
            _burn(_tokenId);
        }
        
    }

    function burnByOwner(uint256 _tokenId) external {
        require(_exists(_tokenId), "Error, the doesn't must");
        require(ownerOf(_tokenId) == msg.sender, "Error, you're not the owner of this token");

        _burn(_tokenId);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(this).balance > 0, "Error, the contract is empty");

        payable(msg.sender).transfer(address(this).balance);
    }

    function revealRulerData(uint256 _tokenId) public view returns (Ruler memory) {
        require(tokenIdToRuler[_tokenId].isSPRevealed == true, "Error, this is private information");

        return tokenIdToRuler[_tokenId];
    }
   
        
}