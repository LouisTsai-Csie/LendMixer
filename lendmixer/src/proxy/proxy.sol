// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../library/slot.sol";

contract Proxy {
    /*//////////////////////////////////////////////////////////////
                                ERROR
    //////////////////////////////////////////////////////////////*/
    error Proxy__ZeroAddressNotAllowed();
    error Proxy__ImplementationNotContract();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation"))-1);
    bytes32 private constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin"))-1);
    
    /*//////////////////////////////////////////////////////////////
                                EVENT
    //////////////////////////////////////////////////////////////*/
    event Proxy__UpdateImplementation(address indexed admin, address indexed impl);

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier ifAdmin() {
        if(msg.sender==_getAdmin()) {
            _;
        } else {
            _delegate();
        }
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() payable {
        _setAdmin(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTION
    //////////////////////////////////////////////////////////////*/
    function _getAdmin() public view returns(address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    function _setAdmin(address _admin) private {
        if(_admin==address(0)) {
            revert Proxy__ZeroAddressNotAllowed();
        }
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = _admin;
    }
    
    function _getImplementation() private view returns(address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    function _setImplementation(address _implementation) private {
        uint256 size;

        assembly { size := extcodesize(_implementation) }

        if(size==0) revert Proxy__ImplementationNotContract();

        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = _implementation;
    }

    function changeAdmin(address _admin) external ifAdmin {
        _setAdmin(_admin);
    }

    function upgradeTo(address _implementation) external ifAdmin {
        _setImplementation(_implementation);
    }

    function getAdmin() external ifAdmin returns(address) {
        return _getAdmin();
    }

    function getImplementation() external ifAdmin returns(address) {
        return _getImplementation();
    }

    function _delegate() private {
        address impl = _getImplementation();
        assembly {
            let freeMemoryPosition := 0x40
            let calldataMemoryOffset := mload(freeMemoryPosition)
            mstore(freeMemoryPosition, add(calldataMemoryOffset, calldatasize()))
            calldatacopy(calldataMemoryOffset, 0x0, calldatasize())
            let ret := delegatecall(gas(), impl, calldataMemoryOffset, calldatasize(), 0, 0)
            let returndataMemoryOffset := mload(freeMemoryPosition)
            mstore(freeMemoryPosition, add(returndataMemoryOffset, returndatasize()))
            returndatacopy(returndataMemoryOffset, 0x0, returndatasize())
            switch ret
            case 0 {
                revert(returndataMemoryOffset, returndatasize())
            }
            default {
                return(returndataMemoryOffset, returndatasize())
            }
        }
    } 

    fallback() external payable {
        _delegate();
    }
    
    receive() external payable {
        _delegate();
    }
}