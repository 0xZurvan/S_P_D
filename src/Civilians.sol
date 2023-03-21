// SPDX-License-Identifier: UNLICENSED

pragma solidity  ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Civilians is ERC721Enumerable, AccessControl {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using Strings for uint256;

    struct Civilian {
        uint256 id;
        uint256 sP;
        bool dead;
        address suspicius;
    }

    uint256 public maxSupply;
    string constant baseExtension = ".json";
    uint256[] public civilianStatePsychopath = [80, 99, 100, 120, 160, 199, 200];
    string private baseURI;
    mapping(uint256 => Civilian) public tokenIdToCivilian;

    constructor(
        string memory _contractName,
        string memory _contractSymbol,
        uint256 _setMaxSupply
    )
    ERC721(_contractName, _contractSymbol) {
        maxSupply = _setMaxSupply;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function updateBaseURI(string memory _baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
    }

    function mint(uint256 _amount, address _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(totalSupply() + _amount < maxSupply, "No supply left");

        for(uint256 _nfts; _nfts < _amount; _nfts++) {
            uint256 newTokenId = _tokenIds.current();
            tokenIdToCivilian[newTokenId].id = newTokenId;
            tokenIdToCivilian[newTokenId].dead = false;
            tokenIdToCivilian[newTokenId].sP = civilianStatePsychopath[0];
            _safeMint(_to, newTokenId);
            _tokenIds.increment();

        }

    }

    function increaseCivilianSP(address _rulersTokenAddr, uint256 _tokenId) external {
        require(_exists(_tokenId), "Error, token doesn't exist");
        require(tokenIdToCivilian[_tokenId].sP != civilianStatePsychopath[6], "Error, token SP at his limit!");

        if(IERC721(_rulersTokenAddr).balanceOf(msg.sender) >= 1) {
            bool isFound = false;
            while(isFound == false) {
                uint256 _index = 0;
                if(tokenIdToCivilian[_tokenId].sP == civilianStatePsychopath[_index]) {
                    _index++;
                    tokenIdToCivilian[_tokenId].sP = civilianStatePsychopath[_index];
    
                } else {
                    _index++;
                }
           }
        }
        
    }

    function killCivilian(address _rulersTokenAddr, uint256 _tokenId) external {
        require(_exists(_tokenId), "Error, token doesn't exist");

        if(IERC721(_rulersTokenAddr).balanceOf(msg.sender) >= 1) {
            _burn(_tokenId);
        }
        
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(this).balance > 0, "Error, the contract is empty");

        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory _tokenURI) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ?
           string(abi.encodePacked(baseURI, _tokenId.toString(), baseExtension)) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}