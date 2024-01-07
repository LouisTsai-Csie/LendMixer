// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AssetToken } from "../lending/asset.sol";

contract Storage {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    mapping(ERC20=>AssetToken) public tokenToAssetToken;
    mapping(ERC20=>bool) internal isFlashLoanActive;
}