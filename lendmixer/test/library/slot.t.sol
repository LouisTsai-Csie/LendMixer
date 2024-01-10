// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import {StorageSlot} from "../../src/library/slot.sol";

contract SlotTest is Test {
    StorageLayout internal storageLayout;

    function setUp() public {
        storageLayout = new StorageLayout();
    }

    function testGetAddressSlot() public {
        address key1 = makeAddr("key1");
        address key2 = makeAddr("key2");
        address key3 = makeAddr("key3");

        storageLayout.addValue(key1, address(0x01));
        storageLayout.addValue(key2, address(0x02));
        storageLayout.addValue(key3, address(0x03));

        bytes32 slot1 = keccak256(abi.encode(key1, 0));
        bytes32 slot2 = keccak256(abi.encode(key2, 0));
        bytes32 slot3 = keccak256(abi.encode(key3, 0));

        address value1 = storageLayout.getValue(slot1);
        address value2 = storageLayout.getValue(slot2);
        address value3 = storageLayout.getValue(slot3);

        assertEq(value1, address(0x01));
        assertEq(value2, address(0x02));
        assertEq(value3, address(0x03));
    }

    function testFuzzGetAddressSlot(address key, address value) public {
        storageLayout.addValue(key, value);

        bytes32 slot = keccak256(abi.encode(key, 0));

        address slotValue = storageLayout.getValue(slot);

        assertEq(slotValue, value);
    }
}

contract StorageLayout {
    mapping(address => address) private balances;

    function addValue(address key, address value) public {
        balances[key] = value;
    }

    function getValue(bytes32 slot) public view returns (address) {
        return StorageSlot.getAddressSlot(slot).value;
    }
}
