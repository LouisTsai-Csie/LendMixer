// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IProxy {
    function changeAdmin(address _admin) external;
    function upgradeTo(address _implementation) external;
    function getAdmin() external;
    function getImplementation() external;
}