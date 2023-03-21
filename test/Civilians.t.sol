
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { Civilians } from "../src/Civilians.sol";
import { Rulers } from "../src/Rulers.sol";
import { Detectives } from "../src/Detectives.sol";

contract CiviliansTest is Test {

  Civilians civilians;
  Rulers rulers;
  Detectives detectives;
  address user1 = address(1);
  address user2 = address(2);

  function setUp() public {
    civilians = new Civilians("Civilians", "CVS", 20);
    detectives = new Detectives("Detectives", "DTS", 20, 1, address(0));
    rulers = new Rulers(
      "Rulers", 
      "RLS", 
      20, 
      0xeb673d1167741de01e46e8792e6936904dce49145827532ad0c39a679efbf8f2,
      address(0), 
      address(detectives)
    );
    vm.deal(user1, 10 ether);
  }

  function test_Mint() public {
    civilians = new Civilians("Civilians", "CVS", 20);
    civilians.mint(1, user1);
    uint256 user1Balance = civilians.balanceOf(user1);
    assertEq(user1Balance, 1);
  }

  function test_CantMintMoreThanMaxSupply() public {
    civilians = new Civilians("Civilians", "CVS", 20);
    vm.expectRevert("No supply left");
    civilians.mint(100, user1);
  }

  function test_OnlyAdminCaMint() public {
    civilians = new Civilians("Civilians", "CVS", 20);
    vm.startPrank(user1);
    vm.expectRevert(
      "AccessControl: account 0x0000000000000000000000000000000000000001 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );

    civilians.mint(1, user2);
  }

  function test_CheckMaxSupply() public {
    civilians = new Civilians("Civilians", "CVS", 20);
    uint256 supply = civilians.maxSupply();
    assertEq(supply, 20);
  }

  function test_IncreaseCivilianSp() public {
    civilians.mint(1, user1);
    vm.startPrank(user1);
    rulers.mint{value: 0.008 ether}();
    civilians.increaseCivilianSP(address(rulers), 0);

  } 

} 