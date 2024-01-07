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

    /*//////////////////////////////////////////////////////////////
                                FUNCTION
    //////////////////////////////////////////////////////////////*/

    function totalSupply() external view returns(uint256) {
        return address(this).balance + flashMintAmount;
    }

    function balanceOf(address account) public view returns(uint256) {
        return _balanceOf[account];
    }

    function allowance(address owner, address spender) external view returns(uint256){
        return _allowance[owner][spender];
    }
    function approve(address spender, uint256 amount) external returns(bool) {
        _allowance[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transfer(address to, uint256 amount) external returns(bool) {
        uint256 balance = _balanceOf[msg.sender];
        if(balance < amount) revert WETH__BalanceNotEnough();

        if(to!=address(0) && to!=address(this)) {
            _balanceOf[msg.sender] -= amount;
            _balanceOf[to] += amount;
            emit Transfer(msg.sender, to, amount);
        } else {
            _balanceOf[msg.sender] -= amount;
            emit Transfer(msg.sender, address(0), amount);
            (bool success, ) = msg.sender.call{value: amount}("");
            if(!success) revert WETH__EtherTransferFailed();
        }
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) external returns(bool) {
        if(from!=msg.sender) {
            uint256 allowanceAmount = _allowance[from][msg.sender];
            if(allowanceAmount < amount) revert WETH__AllowanceNotEnough();
            _allowance[from][msg.sender] -= amount;
            emit Approval(from, msg.sender, allowanceAmount - amount);
        }

        uint256 balance = _balanceOf[from];
        if(balance<amount) revert WETH__BalanceNotEnough();

        if(to != address(0) && to != address(this)) {
            _balanceOf[from] -= amount;
            _balanceOf[to] += amount;
            emit Transfer(from, to, amount);
        } else {
            _balanceOf[from] -= amount;
            emit Transfer(msg.sender, address(0), amount);
            (bool success, ) = msg.sender.call{value: amount}("");
            if(!success) revert WETH__EtherTransferFailed();
        }
        return true;
    }
}