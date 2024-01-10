// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AssetToken} from "../../src/lending/asset.sol";
import {IERC3156FlashBorrower} from "./IERC3156FlashBorrower.sol";

interface ILendMixer {
    function deposit(ERC20 token, uint256 amount) external;
    function withdraw(AssetToken assetToken, uint256 amount) external;
    function maxFlashLoan(address token) external returns (uint256);
    function flashFee(address token, uint256 amount) external returns (uint256);
    function flashLoan(address receiver, address token, uint256 amount, bytes calldata data) external returns (bool);
    function setAssetTokenConfig(ERC20 token, bool permission) external returns (AssetToken);
    function isSupportToken(ERC20 token) external view returns (bool);
    function getAssetTokenFromToken(ERC20 token) external view returns (AssetToken);
    function version() external returns (string memory);
}
