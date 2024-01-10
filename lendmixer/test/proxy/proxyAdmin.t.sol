// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import {ProxyAdmin} from "../../src/proxy/proxyAdmin.sol";
import {Proxy} from "../../src/proxy/proxy.sol";

contract ProxyAdminTest is Test {
    ProxyAdmin internal proxyAdmin;
    Proxy internal proxy;

    address internal owner;

    event ProxyAdmin__UpgradeImplementation(address payable proxy, address implementation);
    event ProxyAdmin__ChangeProxyAdmin(address payable proxy, address admin);

    function setUp() public {
        // Role Creation
        owner = makeAddr("owner");

        // ProxyAdmin Creation
        vm.prank(owner);
        proxyAdmin = new ProxyAdmin();
        assertEq(proxyAdmin.owner(), owner);

        // Proxy Creation
        vm.startPrank(owner);
        proxy = new Proxy();
        proxy.changeAdmin(address(proxyAdmin));
        vm.stopPrank();
    }

    /// function getProxyAdmin(address proxy)
    function testGetProxyAdmin() public {
        vm.startPrank(owner);
        address proxyAdminAddress = proxyAdmin.getProxyAdmin(address(proxy));
        vm.stopPrank();

        assertEq(proxyAdminAddress, address(proxyAdmin));
    }

    /// changeProxyAdmin(address payable proxy, address admin)
    function testChangeProxyAdminSuccess() public {
        address anotherAdmin = makeAddr("anotherAdmin");
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, false);
        emit ProxyAdmin__ChangeProxyAdmin(payable(proxy), anotherAdmin);
        proxyAdmin.changeProxyAdmin(payable(proxy), anotherAdmin);
        vm.stopPrank();
    }

    function testChangeProxyAdminFailed() public {
        address anotherAdmin = makeAddr("anotherAdmin");
        address user = makeAddr("user");
        vm.startPrank(user);
        vm.expectRevert();
        proxyAdmin.changeProxyAdmin(payable(proxy), anotherAdmin);
        vm.stopPrank();
    }

    /// upgradeTo(address payable proxy, address implementation)
    function testUpgradeToV1() public {
        ImplementationV1 implementationV1 = new ImplementationV1();
        address implementation;
        address user = makeAddr("user");

        vm.startPrank(owner);
        vm.expectEmit(true, false, false, false);
        emit ProxyAdmin__UpgradeImplementation(payable(proxy), address(implementationV1));
        proxyAdmin.upgradeTo(payable(proxy), address(implementationV1));
        implementation = proxyAdmin.getProxyImplementation(payable(proxy));
        vm.stopPrank();

        assertEq(implementation, address(implementationV1));

        vm.prank(user);
        string memory version = ImplementationV1(address(proxy)).version();

        assertEq(version, "1.0");
    }

    function testUpgradeToV2() public {
        ImplementationV1 implementationV1 = new ImplementationV1();
        ImplementationV2 implementationV2 = new ImplementationV2();
        address implementation;
        address user = makeAddr("user");

        vm.startPrank(owner);
        vm.expectEmit(true, false, false, false);
        emit ProxyAdmin__UpgradeImplementation(payable(proxy), address(implementationV1));
        proxyAdmin.upgradeTo(payable(proxy), address(implementationV1));
        implementation = proxyAdmin.getProxyImplementation(payable(proxy));
        vm.stopPrank();

        assertEq(implementation, address(implementationV1));

        vm.prank(user);
        string memory version1 = ImplementationV1(address(proxy)).version();

        assertEq(version1, "1.0");

        vm.startPrank(owner);
        vm.expectEmit(true, false, false, false);
        emit ProxyAdmin__UpgradeImplementation(payable(proxy), address(implementationV2));
        proxyAdmin.upgradeTo(payable(proxy), address(implementationV2));
        implementation = proxyAdmin.getProxyImplementation(payable(proxy));
        vm.stopPrank();

        assertEq(implementation, address(implementationV2));

        vm.prank(user);
        string memory version2 = ImplementationV2(address(proxy)).version();

        assertEq(version2, "2.0");
    }

    /// function getProxyImplementation(address proxy)
    function testGetProxyImplementationFailed() public {
        address user = makeAddr("user");
        address errorProxy = makeAddr("errorProxy");
        vm.startPrank(user);
        vm.expectRevert();
        proxyAdmin.getProxyImplementation(errorProxy);
        vm.stopPrank();
    }
}

contract ImplementationV1 {
    uint256 count;

    function assign() external {
        count = 1;
    }

    function version() external pure returns (string memory) {
        return "1.0";
    }
}

contract ImplementationV2 {
    uint256 count;

    function assign() external {
        count = 2;
    }

    function version() external pure returns (string memory) {
        return "2.0";
    }
}
