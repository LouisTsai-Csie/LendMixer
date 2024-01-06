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
