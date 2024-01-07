// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AssetToken is ERC20 {
    /*//////////////////////////////////////////////////////////////
                                ERROR
    //////////////////////////////////////////////////////////////*/
    error AssetToken_onlyLendMixer();
    error AssetToken_zeroAddressNotAllowed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    uint256 public feeRate;
    uint256 internal constant feePrecision = 1e18;
    uint256 internal constant feeInitial = 3e15;
    ERC20 immutable underlyingToken;
    address internal lendMixer;

    /*//////////////////////////////////////////////////////////////
                                EVENT
    //////////////////////////////////////////////////////////////*/
    event AssetToken__mintToken(address to, uint256 amount);
    event AssetToken__burnToken(address account, uint256 amount);
    event AssetToken__updateFeeRate(uint256 originalFee, uint256 updatedFee);

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier onlyLendMixer() {
        if(msg.sender!=lendMixer) {
            revert AssetToken_onlyLendMixer();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address _lendMixer,
        ERC20 _underlyingToken,
        string memory _assetName,
        string memory _assetSymbol
    )
        ERC20(_assetName, _assetSymbol)
    {
        if(_lendMixer==address(0)) revert AssetToken_zeroAddressNotAllowed();      
        lendMixer = _lendMixer;

        if(address(_underlyingToken)==address(0)) revert AssetToken_zeroAddressNotAllowed();
        underlyingToken = _underlyingToken;

        feeRate = feeInitial;
    }

    
    /*//////////////////////////////////////////////////////////////
                                FUNCTION
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 amount) external onlyLendMixer {
        _mint(to, amount);
        emit AssetToken__mintToken(to, amount);
    }

    function burn(address account, uint256 amount) external onlyLendMixer {
        _burn(account, amount);
        emit AssetToken__burnToken(account, amount);
    }

    function getUnderlyingToken() external view returns(ERC20){
        return underlyingToken;
    }

    function getFeeRate(uint256 amount) external view returns(uint256) {
        return amount * feeRate / feePrecision;
    }

    function updateFeeRate(uint256 amount) external onlyLendMixer returns(uint256) {
        uint256 originalFee = feeRate;
        feeRate = amount;
        emit AssetToken__updateFeeRate(originalFee, amount);
    }

}