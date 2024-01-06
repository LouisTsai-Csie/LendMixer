// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { AssetToken } from "../lending/asset.sol";
import { Storage } from "../proxy/storage.sol";
import { IERC3156FlashBorrower } from "../interface/IERC3156FlashBorrower.sol";

contract LendMixer is Storage, Initializable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                ERROR
    //////////////////////////////////////////////////////////////*/
    error LendMixer__TokenAlreadyUnderService();
    error LendMixer__TokenNotSupport();
    error LendMixer__ReceiverNotContract();
    error LendMixer__FlashLoanAmountNotEnough();
    error LendMixer__FlashLoanReceiverBadImplement();
    error LendMixer__FlashLoanPaidBackNotEnough();
    error LendMixer__FlashloanNotComplete();
    error LendMixer__DepositAmountNotEnough();

    /*//////////////////////////////////////////////////////////////
                                EVENT
    //////////////////////////////////////////////////////////////*/
    event LendMixer__UpdateAssetTokenConfig(ERC20 token, AssetToken assetToken, bool permission);
    event LendMixer__FlashLoanService(address receiver, ERC20 token, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier nonFlashLoan(ERC20 token) {
        if(isFlashLoanActive[token]) revert LendMixer__FlashloanNotComplete();
        _;
    }
    
    /*//////////////////////////////////////////////////////////////
                                CONSTUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                FUNCTION
    //////////////////////////////////////////////////////////////*/
    function initialize() external initializer {}

    function deposit(ERC20 token, uint256 amount) external nonReentrant nonFlashLoan(token){
        if(!isSupportToken(token)) revert LendMixer__TokenNotSupport();
        token.transferFrom(msg.sender, address(this), amount);
        AssetToken assetToken = tokenToAssetToken[token];
        assetToken.mint(msg.sender, amount);
    }

    function withdraw(AssetToken assetToken, uint256 amount) external nonReentrant {
        ERC20 token = assetToken.getUnderlyingToken();
        if(!isSupportToken(token)) revert LendMixer__TokenNotSupport();
        uint256 totalSupply = assetToken.totalSupply();
        uint256 share = amount * token.balanceOf(address(this)) / totalSupply;
        assetToken.burn(msg.sender, amount);
        token.transfer(msg.sender, share);
    }

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256) {
        if(!isSupportToken(ERC20(token))) revert LendMixer__TokenNotSupport();
        return ERC20(token).balanceOf(address(this));
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256) {
        if(!isSupportToken(ERC20(token))) revert LendMixer__TokenNotSupport();
        return amount * 3 / 1000;
    }

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        // Receiver Validati
        if(!isContract(address(receiver))) revert LendMixer__ReceiverNotContract();
        // Token Validation
        if(!isSupportToken(ERC20(token))) revert LendMixer__TokenNotSupport();
        // Amount Validation
        uint256 balanceBefore = ERC20(token).balanceOf(address(this));
        
        if(amount > balanceBefore) revert LendMixer__FlashLoanAmountNotEnough();
        
        emit LendMixer__FlashLoanService(address(receiver), ERC20(token), amount);
        isFlashLoanActive[ERC20(token)] = true;
        ERC20(token).transfer(address(receiver), amount);

        AssetToken assetToken = tokenToAssetToken[ERC20(token)];
        uint256 fee = assetToken.getFeeRate(amount); 
        bytes32 result = IERC3156FlashBorrower(receiver).onFlashLoan(msg.sender, token, amount, fee, data);

        if(result!=keccak256("ERC3156FlashBorrower.onFlashLoan")) revert LendMixer__FlashLoanReceiverBadImplement();

        uint256 balanceAfter = ERC20(token).balanceOf(address(this));

        if(balanceAfter < balanceBefore+fee) revert LendMixer__FlashLoanPaidBackNotEnough();

        isFlashLoanActive[ERC20(token)] = false;

        return true;
    }

    function setAssetTokenConfig(ERC20 token, bool permission) external returns(AssetToken){
        AssetToken assetToken = tokenToAssetToken[token];
        if(permission) {
            if(address(assetToken)!=address(0)) {
                revert LendMixer__TokenAlreadyUnderService();
            }

            string memory name = string.concat("LendMixer ", IERC20Metadata(address(token)).name());
            string memory symbol = string.concat("l", IERC20Metadata(address(token)).symbol());

            assetToken = new AssetToken(address(this), token, name, symbol);
            tokenToAssetToken[token] = assetToken;
        } else {
            delete tokenToAssetToken[token];
        }
        emit LendMixer__UpdateAssetTokenConfig(token, assetToken, permission);
        return assetToken;
    }

    function isSupportToken(ERC20 token) public view returns(bool) {
        AssetToken assetToken = tokenToAssetToken[token];
        return address(assetToken) != address(0);
    }

    function getAssetTokenFromToken(ERC20 token) external view returns(AssetToken) {
        return tokenToAssetToken[token];
    }

    function isContract(address addr) internal view returns(bool){
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size!=0;
    }

    function version() external pure returns(string memory){
        return "1.0.0";
    }
}