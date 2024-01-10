// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../src/interface/IProxy.sol";

contract ProxyAdmin {
    /*//////////////////////////////////////////////////////////////
                                ERROR
    //////////////////////////////////////////////////////////////*/
    error ProxyAdmin__OnlyOwner();
    error ProxyAdmin__StaticcallFailed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    address public owner;

    /*//////////////////////////////////////////////////////////////
                                EVENT
    //////////////////////////////////////////////////////////////*/
    event ProxyAdmin__UpgradeImplementation(address payable proxy, address implementation);
    event ProxyAdmin__ChangeProxyAdmin(address payable proxy, address admin);

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert ProxyAdmin__OnlyOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() payable {
        owner = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                                FUNCTION
    //////////////////////////////////////////////////////////////*/
    function getProxyAdmin(address proxy) external view returns (address) {
        (bool success, bytes memory data) = proxy.staticcall(abi.encodeWithSignature("getAdmin()"));

        if (!success) {
            revert ProxyAdmin__StaticcallFailed();
        }

        (address admin) = abi.decode(data, (address));
        return admin;
    }

    function getProxyImplementation(address proxy) external view returns (address) {
        (bool success, bytes memory data) = proxy.staticcall(abi.encodeWithSignature("getImplementation()"));

        if (success == false) {
            revert ProxyAdmin__StaticcallFailed();
        }

        (address implementation) = abi.decode(data, (address));
        return implementation;
    }

    function changeProxyAdmin(address payable proxy, address admin) external onlyOwner {
        IProxy(proxy).changeAdmin(admin);
        emit ProxyAdmin__ChangeProxyAdmin(proxy, admin);
    }

    function upgradeTo(address payable proxy, address implementation) external onlyOwner {
        IProxy(proxy).upgradeTo(implementation);
        emit ProxyAdmin__UpgradeImplementation(proxy, implementation);
    }
}
