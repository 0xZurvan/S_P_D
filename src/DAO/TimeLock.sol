// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract TimeLock is AccessControl, TimelockController {

    constructor(uint256 _initialMinDelay, address[] memory _initialProposer, address[] memory _initialExecutor) 
    TimelockController(_initialMinDelay, _initialProposer, _initialExecutor, msg.sender) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, TimelockController)
        returns (bool) {

        return super.supportsInterface(interfaceId);
    }

    function _getProposerRole(address _rulersTokenAddr) public {
        require(IERC721(_rulersTokenAddr).balanceOf(msg.sender) == 1, "Error, you're not a Ruler");

        _grantRole(PROPOSER_ROLE, msg.sender);
    }

    function _getExecutorRole(address _rulersTokenAddr) public {
        require(IERC721(_rulersTokenAddr).balanceOf(msg.sender) == 1, "Error, you're not a Ruler");

        _grantRole(EXECUTOR_ROLE, msg.sender);
    }

}