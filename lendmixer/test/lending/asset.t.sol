// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AssetToken} from "../../src/lending/asset.sol";


contract AssetTokenTest is Test {

    address internal lendMixer;
    address internal user;
    ERC20 internal underlyingToken;
    AssetToken asset;

    event AssetToken__mintToken(address to, uint256 amount);
    event AssetToken__burnToken(address account, uint256 amount);    

    function setUp() public {
        // Role Creation
        lendMixer = makeAddr("lendMixer");
        user = makeAddr("user");

        // Underlying Token Creation
        underlyingToken = new UnderlyingToken();
        
        // Asset Token Parameter
        string memory assetName = "AssetToken";
        string memory assetSymbol = "AssetSymbol";

        // Asset Token Creation
        underlyingToken = new UnderlyingToken();
        asset = new AssetToken(lendMixer, underlyingToken, assetName, assetSymbol);

        // Assertion
        assertEq(asset.name(), assetName);
        assertEq(asset.symbol(), assetSymbol);
    }

    /// function mint(address to, uint256 amount) 
    function testAssetTokenMintOperationSuccess() public {
        uint256 mintAmount = 1e18;
        
        vm.startPrank(lendMixer);

        vm.expectEmit(true, false, false, false);
        emit AssetToken__mintToken(user, mintAmount);
        asset.mint(user, mintAmount);

        uint256 userBalance = asset.balanceOf(user);
        vm.stopPrank();

        assertEq(userBalance, mintAmount);
    }

    function testAssetTokenMintOperationFail() public {
        uint256 mintAmount = 1e18;

        vm.startPrank(user);
        vm.expectRevert();
        asset.mint(user, mintAmount);
        vm.stopPrank();
    }
    
    /// burn(address account, uint256 amount)
    function testAssetTokenBurnOperationSuccess() public {
        uint256 amount = 1e18;

        vm.startPrank(lendMixer);
        
        vm.expectEmit(true, false, false, false);
        emit AssetToken__mintToken(user, amount);
        asset.mint(user, amount);

        vm.expectEmit(true, false, false, false);
        emit AssetToken__burnToken(user, amount);
        asset.burn(user, amount);

        uint256 userBalance = asset.balanceOf(user);
        vm.stopPrank();

        assertEq(userBalance, 0);
    }

    function testAssetTokenBurnOperationFail() public {
        uint256 amount = 1e18;

        vm.startPrank(lendMixer);
        vm.expectEmit(true, false, false, false);
        emit AssetToken__mintToken(user, amount);
        asset.mint(user, amount);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert();
        asset.burn(user, amount);
        vm.stopPrank();
    }

    /// function getUnderlyingToken()
    function testGetUnderlyingToken() public {
        vm.startPrank(user);
        address token = address(asset.getUnderlyingToken());
        vm.stopPrank();

        assertEq(token, address(underlyingToken));   
    }

    /// function getExchangeRate()
    function testGetExchangeRate() public {
        vm.startPrank(user);
        uint256 exchangeRate = asset.getExchangeRate();
        vm.stopPrank();

        assertEq(exchangeRate, 1e18);
    }
}


/// @title simple underlying token
/// @notice underlying token used for lending protocol
/// @dev follow oppenzeppelin implementation
contract UnderlyingToken is ERC20 {

    uint256 internal constant initialSupply = 1e40;

    constructor() ERC20("Underlying Token", "UT") {
        _mint(msg.sender, initialSupply);
    }
}
