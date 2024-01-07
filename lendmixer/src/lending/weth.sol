// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC3156FlashBorrower } from "../interface/IERC3156FlashBorrower.sol";

interface IReceiver {
    function onTokenTransfer(address, uint256, bytes calldata) external returns(bool);
    function onTokenApproval(address, uint256, bytes calldata) external returns(bool);
}

contract WETH is IERC20 {
    /*//////////////////////////////////////////////////////////////
                                ERROR
    //////////////////////////////////////////////////////////////*/
    error WETH__EtherTransferFailed();
    error WETH__TokenTransferFailed();
    error WETH__TokenApprovalFailed();
    error WETH__BalanceNotEnough();
    error WETH__AllowanceNotEnough();
    error WETH__TokenNotSupport();
    error WETH__FlashMintAmountExceed();
    error WETH__FlashMintTotalExceed();
    error WETH__FlashLoanNotReceived();
    error WETH__FlashMintBalanceNotEnough();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    string public constant name   = "Wrapped Token";
    string public constant symbol = "WETH";

    bytes32 internal immutable onFlashLoanReturnValue = keccak256("ERC3156FlashBorrower.onFlashLoan");

    mapping(address=>uint256) internal _balanceOf;
    mapping(address=>mapping(address=>uint256)) internal _allowance;

    uint256 flashMintAmount;

    /*//////////////////////////////////////////////////////////////
                                EVENT
    //////////////////////////////////////////////////////////////*/
    event WETH__FlashMint(address initiator, address receiver, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                CONSTUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() payable {}

}