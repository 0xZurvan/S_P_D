// SPDX-License-Identifier: UNLICENSED

pragma solidity  ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IRulers {
    function balanceOf(address _addr) external view returns (uint256);
}

interface IDetectives {
    function balanceOf(address _addr) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns(uint256);
    function increaseDetectiveSP(uint256 _tokenId) external;
    function getDetectiveRank(uint256 _tokenId) external view returns (uint256);
}

contract Approval is ERC20, AccessControl {

    uint128 public constant s_maxSupply = 200e18;
    uint96 public constant s_illegalPrice = 1 ether;
    uint96 public constant s_maxRequests = 20;
    address internal immutable s_illegalSeller;
    address[] public s_requesters;
    uint256 public s_burntSupply;
    mapping(address => uint256) public s_detectiveTorequestAmount;
    address private immutable s_detectivesTokenAddr;
    address private immutable s_rulersTokenAddr;
    mapping(address => uint256) private s_detectiveToFee;

    error UnsuccessfulWithdraw();

    constructor(
        address _illegalSeller,
        address _detectivesTokenAddr,
        address _rulersTokenAddr
        )
    ERC20("Approval", "APPROVAL") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        s_illegalSeller = _illegalSeller;
        s_detectivesTokenAddr = _detectivesTokenAddr;
        s_rulersTokenAddr = _rulersTokenAddr;

    }

    function requetApproval() external payable {
        require(balanceOf(msg.sender) > 0, "Can't request more approval");
        require(s_requesters.length < s_maxRequests, "Requests are at their limit");
        require(IDetectives(s_detectivesTokenAddr).balanceOf(msg.sender) >= 1, "Not a detective");
         
        uint256 _fee;
        if(s_detectiveTorequestAmount[msg.sender] >= 7) {
            _fee = 14 wei;
            require(msg.value >= _fee, "Pay your fees");
            s_detectiveTorequestAmount[msg.sender] = 0;

        } else {
            _fee = 1 wei;
            require(msg.value >= _fee, "Pay your feeds");
            s_detectiveTorequestAmount[msg.sender]++;
        }

        s_detectiveToFee[msg.sender] = msg.value;
        s_requesters.push(msg.sender);
    }

    function deleteRequester(address _requester) external {
        require(IRulers(s_rulersTokenAddr).balanceOf(msg.sender) >= 1, "Not a ruler");
        require(balanceOf(_requester) >= 1, "Requester hasn't receive approval yet");
        
        bool _isFound = false;
        while(_isFound == false) {
            uint256 _index = 0;
            if(s_requesters[_index] == _requester) {
                delete s_requesters[_index];
                _isFound = true;
            } else {
                _index++;
            }
        }

    }

    function sendToRequester(address _requester, uint256 _detectiveTokenId) external {
        uint256 _bigNumber = 1e18;
        uint256 _total;

        require(IRulers(s_rulersTokenAddr).balanceOf(msg.sender) >= 1, "Not a ruler");
        require(
            totalSupply() + _total <= (s_maxSupply - s_burntSupply),
            "Max has been reached."
        );

        if(IDetectives(s_detectivesTokenAddr).getDetectiveRank(_detectiveTokenId) == 6) {
            _total = 5 * _bigNumber;
            _mint(_requester, _total);

        } else if(IDetectives(s_detectivesTokenAddr).getDetectiveRank(_detectiveTokenId) >= 4) {
            _total = 3 * _bigNumber;
            _mint(_requester, _total);

        } else if(IDetectives(s_detectivesTokenAddr).getDetectiveRank(_detectiveTokenId) >= 2) {
            _total = 2 * _bigNumber;
            _mint(_requester, _total);

        } else {
            _mint(_requester, _bigNumber);
        }

        transferFrom(address(this), msg.sender, s_detectiveToFee[_requester]);

    }

    function buyIlegallys(uint256 _amount) external payable {
        uint256 bigNumber = _amount * s_illegalPrice;

        require(msg.value >= bigNumber, "Must send right amount.");
        require(IDetectives(s_detectivesTokenAddr).balanceOf(msg.sender) >= 1, "Error, you are not a detective");
        require(
            totalSupply() + bigNumber <= (s_maxSupply - s_burntSupply),
            "Max has been reached."
        );

        // Pay to the illegalSeller
        payable(s_illegalSeller).transfer(msg.value);

        _mint(msg.sender, bigNumber);

        uint256 _tokenId = IDetectives(s_detectivesTokenAddr).tokenOfOwnerByIndex(msg.sender, 0);
        IDetectives(s_detectivesTokenAddr).increaseDetectiveSP(_tokenId);
    }

    function burn(address _account, uint256 _amount) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only admin can burn"
        );
        require(s_maxSupply - s_burntSupply > 0, "Nothing to burn.");

        s_burntSupply += _amount;
        _burn(_account, _amount);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _balance = address(this).balance;
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only admin can withdraw");
        require(_balance > 0, "Contract is empty");

        (bool success, ) = payable(msg.sender).call{value: _balance}("");
        if (!success) {
            revert UnsuccessfulWithdraw();
        }

        assert(_balance == 0);
    }

}