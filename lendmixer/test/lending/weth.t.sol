// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import { WETH } from "../../src/lending/weth.sol";
 
contract WETHTest is Test {
    WETH internal weth;
    
    address internal user;
    address internal user0;

    uint256 internal constant initialSupply = 1000 ether;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event WETH__FlashMint(address initiator, address receiver, uint256 amount);

    function setUp() public {
        // Role Creation
        user = makeAddr("user");
        user0 = makeAddr("user0");

        // WETH Creation
        weth = new WETH();

        // Token Distribution
        
        deal(user, initialSupply);
    }

}
