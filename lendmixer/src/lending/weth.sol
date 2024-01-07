// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC3156FlashBorrower } from "../interface/IERC3156FlashBorrower.sol";

interface IReceiver {
    function onTokenTransfer(address, uint256, bytes calldata) external returns(bool);
    function onTokenApproval(address, uint256, bytes calldata) external returns(bool);
}

contract WETH is IERC20 {

}