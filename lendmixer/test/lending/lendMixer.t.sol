// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ProxyAdmin } from "../../src/proxy/proxyAdmin.sol";
import { Proxy } from "../../src/proxy/proxy.sol";
import { LendMixer } from "../../src/lending/lendMixer.sol";
import { AssetToken } from "../../src/lending/asset.sol";
import { ILendMixer } from "../../src/interface/ILendMixer.sol";
import { IERC3156FlashBorrower } from "../../src/interface/IERC3156FlashBorrower.sol";

contract LendMixerTest is Test {

    ProxyAdmin internal proxyAdmin;
    Proxy internal proxy;
    LendMixer internal lendMixer;
    ERC20 internal token;

    address internal user;
    address internal owner;

    event ProxyAdmin__UpgradeImplementation(address payable proxy, address implementation);
    event ProxyAdmin__ChangeProxyAdmin(address payable proxy, address admin);
    
    event LendMixer__UpdateAssetTokenConfig(ERC20 token, AssetToken assetToken, bool permission);
    event LendMixer__FlashLoanService(address receiver, ERC20 token, uint256 amount);

    function setUp() public {
        // Role Creation
        user = makeAddr("user");
        owner = makeAddr("owner");

        // ProxyAdmin Creation
        vm.prank(owner);
        proxyAdmin = new ProxyAdmin();
        assertEq(proxyAdmin.owner(), owner);

        // LendMixer Creation
        lendMixer = new LendMixer();

        // Proxy Creation
        vm.startPrank(owner);
        proxy = new Proxy();
        proxy.changeAdmin(address(proxyAdmin));

        vm.expectEmit(true, true, false, false);
        emit ProxyAdmin__UpgradeImplementation(payable(proxy), address(lendMixer));
        proxyAdmin.upgradeTo(payable(proxy), address(lendMixer));
        assertEq(proxyAdmin.getProxyImplementation(payable(proxy)), address(lendMixer));
        vm.stopPrank();

        vm.prank(user);
        string memory version = ILendMixer(address(proxy)).version();
        assertEq(version, "1.0.0");

        // Underlying Token Creation
        token = new UnderlyingToken();
    }

    // function setAssetTokenConfig(ERC20 token, bool permission) 
    function testSetAssetTokenConfigPermissionTrue() public {
        AssetToken assetToken;

        vm.prank(user);
        vm.expectEmit(true, false, true, false);
        emit LendMixer__UpdateAssetTokenConfig(token, assetToken, true);
        assetToken = ILendMixer(address(proxy)).setAssetTokenConfig(token, true);

        address asset = address(ILendMixer(address(proxy)).getAssetTokenFromToken(token));
        bool isSupport = ILendMixer(address(proxy)).isSupportToken(token);

        assertEq(asset, address(assetToken));
        assertEq(assetToken.name(), "LendMixer Underlying Token");
        assertEq(assetToken.symbol(), "lUT");
        assertEq(isSupport, true);
    }

    function testSetAssetTokenConfigAlreadyUnderService() public {
        AssetToken assetToken;

        vm.prank(user);
        vm.expectEmit(true, false, true, false);
        emit LendMixer__UpdateAssetTokenConfig(token, assetToken, true);
        assetToken = ILendMixer(address(proxy)).setAssetTokenConfig(token, true);

        vm.prank(user);
        vm.expectRevert();
        assetToken = ILendMixer(address(proxy)).setAssetTokenConfig(token, true);
    }

    function testSetAssetTokenConfigPermissionFalse() public {
        AssetToken assetToken;
        address asset;
        bool isSupport;

        vm.expectEmit(true, false, true, false);
        emit LendMixer__UpdateAssetTokenConfig(token, assetToken, true);
        assetToken = ILendMixer(address(proxy)).setAssetTokenConfig(token, true);
        
        asset = address(ILendMixer(address(proxy)).getAssetTokenFromToken(token));
        isSupport = ILendMixer(address(proxy)).isSupportToken(token);

        assertEq(asset, address(assetToken));
        assertEq(isSupport, true);

        vm.expectEmit(true, false, true, false);
        emit LendMixer__UpdateAssetTokenConfig(token, assetToken, false);
        assetToken = ILendMixer(address(proxy)).setAssetTokenConfig(token, false);

        asset = address(ILendMixer(address(proxy)).getAssetTokenFromToken(token));
        isSupport = ILendMixer(address(proxy)).isSupportToken(token);

        assertEq(asset, address(0));
        assertEq(isSupport, false);
    }

    // function deposit(ERC20 token, uint256 amount)
    function testDepositSuccess() public {
        AssetToken assetToken = ILendMixer(address(proxy)).setAssetTokenConfig(token, true);

        deal(address(token), user, 1e20);
        assertEq(token.balanceOf(user), 1e20);

        vm.startPrank(user);
        token.approve(address(proxy), 1e20);
        ILendMixer(address(proxy)).deposit(token, 1e20);
        vm.stopPrank();

        uint256 balance = assetToken.balanceOf(user);
        assertEq(balance, 1e20);
    }

    function testDepositFailed() public {

        deal(address(token), user, 1e20);
        assertEq(token.balanceOf(user), 1e20);

        vm.startPrank(user);
        token.approve(address(proxy), 1e20);
        vm.expectRevert();
        ILendMixer(address(proxy)).deposit(token, 1e20);
        vm.stopPrank();
    }

    // function withdraw(AssetToken assetToken, uint256 amount)
    function testWithdrawSuccess() public {
        AssetToken assetToken = ILendMixer(address(proxy)).setAssetTokenConfig(token, true);

        deal(address(token), user, 1e20);
        assertEq(token.balanceOf(user), 1e20);

        vm.startPrank(user);
        token.approve(address(proxy), 1e20);
        ILendMixer(address(proxy)).deposit(token, 1e20);
        assertEq(token.balanceOf(user), 0);
        assertEq(assetToken.balanceOf(user), 1e20);
        vm.stopPrank();

        vm.startPrank(user);
        ILendMixer(address(proxy)).withdraw(assetToken, 1e20);
        assertEq(token.balanceOf(user), 1e20);
        assertEq(assetToken.balanceOf(user), 0);
        vm.stopPrank();
    }

    function testWithdrawFailed() public {
        AssetToken assetToken = ILendMixer(address(proxy)).setAssetTokenConfig(token, true);

        deal(address(token), user, 1e20);
        assertEq(token.balanceOf(user), 1e20);

        vm.startPrank(user);
        token.approve(address(proxy), 1e20);
        ILendMixer(address(proxy)).deposit(token, 1e20);
        assertEq(token.balanceOf(user), 0);
        assertEq(assetToken.balanceOf(user), 1e20);
        vm.stopPrank();

        ILendMixer(address(proxy)).setAssetTokenConfig(token, false);

        vm.startPrank(user);
        vm.expectRevert();
        ILendMixer(address(proxy)).withdraw(assetToken, 1e20);
        vm.stopPrank();
    }

    // function maxFlashLoan(address token)
    function testMaxFlashLoanSuccess() public {
        AssetToken assetToken = ILendMixer(address(proxy)).setAssetTokenConfig(token, true);

        deal(address(token), user, 1e20);
        assertEq(token.balanceOf(user), 1e20);

        vm.startPrank(user);
        token.approve(address(proxy), 1e20);
        ILendMixer(address(proxy)).deposit(token, 1e20);
        vm.stopPrank();

        uint256 maxFlashLoanAmount = ILendMixer(address(proxy)).maxFlashLoan(address(token));
        assertEq(maxFlashLoanAmount, 1e20);
    } 

    function testMaxFlashLoanFailed() public {
        ILendMixer(address(proxy)).setAssetTokenConfig(token, true);

        deal(address(token), user, 1e20);
        assertEq(token.balanceOf(user), 1e20);

        vm.startPrank(user);
        token.approve(address(proxy), 1e20);
        ILendMixer(address(proxy)).deposit(token, 1e20);
        vm.stopPrank();

        ILendMixer(address(proxy)).setAssetTokenConfig(token, false);

        vm.expectRevert();
        ILendMixer(address(proxy)).maxFlashLoan(address(token));
    }
    
    // function flashFee(address token, uint256 amount)
    function testFlashFeeSuccess() public {
        ILendMixer(address(proxy)).setAssetTokenConfig(token, true);

        uint256 balance = ILendMixer(address(proxy)).flashFee(address(token), 1e20);
        assertEq(balance, 3e17);
    } 

    function testFlashFeeFailed() public {
        ILendMixer(address(proxy)).setAssetTokenConfig(token, false);
        
        vm.expectRevert();
        ILendMixer(address(proxy)).flashFee(address(token), 1e20);
    }

    // function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
    function testFlashLoanSuccess() public {

        ILendMixer(address(proxy)).setAssetTokenConfig(token, true);

        vm.prank(user);
        Receiver receiver = new Receiver(proxy);

        deal(address(token), address(receiver), 1e20);
        deal(address(token), address(proxy), 1e20);

        vm.prank(user);
        bool success = ILendMixer(address(proxy)).flashLoan(
            address(receiver), 
            address(token),
            1e18, 
            abi.encode(true, true)
        );

        assertTrue(success);
    }

    function testFlashLoanIsNotContract() public {

        vm.prank(user);
        vm.expectRevert();        
        ILendMixer(address(proxy)).flashLoan(
            user, 
            address(token), 
            0, 
            abi.encode(true, true)
        );
    }
    
    function testFlashLoanTokenNotSupport() public {
        ILendMixer(address(proxy)).setAssetTokenConfig(token, false);

        Receiver receiver = new Receiver(proxy);

        vm.prank(user);
        vm.expectRevert();
        ILendMixer(address(proxy)).flashLoan(
            address(receiver), 
            address(token), 
            0, 
            abi.encode(true, true)
        );
    }

    function testFlashLoanAmountNotEnough() public {
        ILendMixer(address(proxy)).setAssetTokenConfig(token, true);

        vm.prank(user);
        Receiver receiver = new Receiver(proxy);

        deal(address(token), address(receiver), 1e20);
        deal(address(token), address(proxy), 1e20);

        vm.prank(user);
        vm.expectRevert();
        ILendMixer(address(proxy)).flashLoan(
            address(receiver), 
            address(token), 
            1e21, 
            abi.encode(true, true)
        );
    }

    function testFlashLoanRepayAmountNotEnough() public {
        ILendMixer(address(proxy)).setAssetTokenConfig(token, true);

        vm.prank(user);
        Receiver receiver = new Receiver(proxy);

        deal(address(token), address(receiver), 1e20);
        deal(address(token), address(proxy), 1e20);

        vm.prank(user);
        vm.expectRevert();
        ILendMixer(address(proxy)).flashLoan(
            address(receiver), 
            address(token), 
            1e18, 
            abi.encode(false, true)
        );
    }

    function testFlashLoanReturnValueInvalid() public {
        ILendMixer(address(proxy)).setAssetTokenConfig(token, true);

        vm.prank(user);
        Receiver receiver = new Receiver(proxy);

        deal(address(token), address(receiver), 1e20);
        deal(address(token), address(proxy), 1e20);

        vm.prank(user);
        vm.expectRevert();
        ILendMixer(address(proxy)).flashLoan(
            address(receiver), 
            address(token), 
            1e18, 
            abi.encode(true, false)
        );
    }

    function testFlashLoanNonReentrantDeposit() public {
        ILendMixer(address(proxy)).setAssetTokenConfig(token, true);

        vm.prank(user);
        ReentrantReceiver receiver = new ReentrantReceiver(proxy);

        deal(address(token), address(receiver), 1e20);
        deal(address(token), address(proxy), 1e20);

        vm.prank(user);
        vm.expectRevert();
        ILendMixer(address(proxy)).flashLoan(
            address(receiver), 
            address(token), 
            1e18, 
            abi.encode(true, false)
        );
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

contract Receiver is Test {
    address internal owner;
    Proxy internal proxy;

    constructor(Proxy _proxy) payable {
        owner = msg.sender;
        proxy = _proxy;
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(msg.sender==address(proxy), "Not LendMixer");
        require(initiator==owner, "Invalid Initiator");
        (bool repayEnough, bool returnSuccess) = abi.decode(data, (bool, bool));
        uint256 totalAmount = repayEnough? amount+fee:amount;
        ERC20(token).transfer(msg.sender, totalAmount);
        return returnSuccess? keccak256("ERC3156FlashBorrower.onFlashLoan"):keccak256("failed");
    }
}

contract ReentrantReceiver is Test {
    address internal owner;
    Proxy internal proxy;

    constructor(Proxy _proxy) payable {
        owner = msg.sender;
        proxy = _proxy;
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(msg.sender==address(proxy), "Not LendMixer");
        require(initiator==owner, "Invalid Initiator");
        LendMixer(address(proxy)).deposit(ERC20(token), amount);
        ERC20(token).transfer(msg.sender, fee);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}