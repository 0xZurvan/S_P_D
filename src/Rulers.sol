
// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.19;

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

    bytes32 public constant s_SPD_ROLE = keccak256("SPD_ROLE");
    bytes32 public constant s_baseExtension = ".json";
    uint96 public constant s_maxSupply = 20;
    uint96 public constant s_mintPrice = 0.008 ether;
    address private immutable s_detectivesTokenAddr;
    bytes32 private immutable s_rulerStatePsychopath;
    mapping(uint256 => string) private s_tokenURIs;
    mapping(uint256 => Ruler) private s_tokenIdToRuler;

    error UnsuccessfulWithdraw();

    constructor(
        bytes32 _setRulerStatePsychopath,
        address _spdAddr,
        address _setDetectiveTokenAddr
    ) 
    ERC721("Rulers", "RULERS") {
        s_rulerStatePsychopath = _setRulerStatePsychopath;
        s_detectivesTokenAddr = _setDetectiveTokenAddr;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(s_SPD_ROLE, _spdAddr);
    }

    modifier tokenMustExist(uint256 _tokenId) {
        require(_exists(_tokenId), "Token doesn't exist");
        _;
    }

    modifier enoughApproval(address _approvalTokenAddr) {
        require(IERC20(_approvalTokenAddr).balanceOf(msg.sender) >= 1, "Don't have approval");
        _;
    }

    modifier onlyDetective {
        require(IDetectives(s_detectivesTokenAddr).balanceOf(msg.sender) >= 1, "Not a detective");
        _;
    }

    receive() external payable {}

    function setURIs(uint256 _state, string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
       s_tokenURIs[_state] = _uri;
    }

    function mint() external payable {
        require(s_maxSupply > totalSupply(), "No supply left");
        require(msg.value >= s_mintPrice, "Not enought ETH");
        require(balanceOf(msg.sender) == 0, "Can only mint 1 token");
        require(IDetectives(s_detectivesTokenAddr).balanceOf(msg.sender) == 0, "You're a detective");

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

    function ifMatchRevealIdentity(
        address _approvalTokenAddr, 
        uint256 _tokenId, 
        address _suspiciusAddr
    ) 
    external 
    payable 
    onlyDetective
    tokenMustExist(_tokenId) 
    enoughApproval(_approvalTokenAddr) 
    returns (bool)
    {
        
        IERC20(_approvalTokenAddr).transfer(_suspiciusAddr, 1);
        uint256 _senderTokenId = IDetectives(s_detectivesTokenAddr).tokenOfOwnerByIndex(msg.sender, 0);

        if(ownerOf(_tokenId) == _suspiciusAddr) {
            s_tokenIdToRuler[_tokenId].isUriRevealed = true;
            s_tokenIdToRuler[_tokenId].isSPRevealed = true;
            IDetectives(s_detectivesTokenAddr).levelUpRank(_senderTokenId);

            return true;

        } else {
            IDetectives(s_detectivesTokenAddr).increaseDetectiveSP(_tokenId);
            IDetectives(s_detectivesTokenAddr).levelDownRank(_senderTokenId);

            return false;

        }
    }

    function investigateSpfToken(
        address _approvalTokenAddr, 
        uint256 _tokenId
    ) 
    external payable 
    onlyDetective 
    tokenMustExist(_tokenId) 
    enoughApproval(_approvalTokenAddr) 
    returns(bytes32 _statePsychopath) 
    {        
        if(s_tokenIdToRuler[_tokenId].isSPRevealed == true) {
            return s_tokenIdToRuler[_tokenId].sP;
        }
        
    }

    function killRuler(
        address _approvalTokenAddr, 
        uint256 _tokenId
    ) external payable 
    onlyDetective 
    tokenMustExist(_tokenId) 
    enoughApproval(_approvalTokenAddr) 
    {

        if(s_tokenIdToRuler[_tokenId].isSPRevealed == true  || IERC20(_approvalTokenAddr).balanceOf(msg.sender) >= 4) {
            _burn(_tokenId);
        }
        
    }

    function burnByOwner(uint256 _tokenId) external tokenMustExist(_tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Only token owner");

        _burn(_tokenId);
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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 _tokenId) public view virtual override tokenMustExist(_tokenId) returns(string memory _tokenURI) {
        bytes32 _baseExtension = s_baseExtension;

        if(s_tokenIdToRuler[_tokenId].isUriRevealed == true) {
            string memory currentURI = s_tokenURIs[1];
            return bytes(currentURI).length > 0 ?
                string(abi.encodePacked(currentURI, _tokenId.toString(), _baseExtension)) : "";

        } else if(msg.sender == ownerOf(_tokenId)) {
            string memory currentURI = s_tokenURIs[1];
            return bytes(currentURI).length > 0 ?
                string(abi.encodePacked(currentURI, _tokenId.toString(), _baseExtension)) : "";

        } else {
            string memory currentURI = s_tokenURIs[0];
            return bytes(currentURI).length > 0 ?
                string(abi.encodePacked(currentURI, _tokenId.toString(), _baseExtension)) : "";

        }
    }

    function revealRulerData(uint256 _tokenId) public view tokenMustExist(_tokenId) returns (Ruler memory) {
        require(s_tokenIdToRuler[_tokenId].isSPRevealed == true, "Information isn't revealed");

        return s_tokenIdToRuler[_tokenId];
    }
        
}