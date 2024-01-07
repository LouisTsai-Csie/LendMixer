// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import { WETH } from "../../src/lending/weth.sol";
 
contract WETHTest is Test {
    WETH internal weth;
    
    address internal user;
    address internal user0;

    uint256 internal constant initialSupply = 1000 ether;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event WETH__FlashMint(address initiator, address receiver, uint256 amount);

    function setUp() public {
        // Role Creation
        user = makeAddr("user");
        user0 = makeAddr("user0");

        // WETH Creation
        weth = new WETH();

        // Token Distribution
        
        deal(user, initialSupply);
    }

contract TransferRecevier is Test {

    WETH internal weth;
    address internal owner;
    constructor(WETH _weth) payable {
        weth = _weth;
        owner = msg.sender;
    }
    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external returns(bool) {
        require(msg.sender==address(weth), "Invalid Caller");
        require(from==owner, "Invalid Initiator");
        weth.withdraw(amount);
        (address addr, bool result) = abi.decode(data, (address, bool));
        (bool success, ) = addr.call{value: amount}("");
        require(success, "Transfer Failed");
        return result;
    }

    function onTokenApproval(address from, uint256 amount, bytes memory data) external returns(bool) {
        require(msg.sender==address(weth), "Invalid Caller");
        require(from==owner, "Invalid Initiator");
        (address addr, bool result) = abi.decode(data, (address, bool));
        weth.withdrawFrom(from, payable(this), amount);
        (bool success, ) = addr.call{value: amount}("");
        require(success, "Transfer Failed");
        return result;
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(msg.sender==address(weth), "Invalid Caller");
        require(initiator==owner, "Invalid initiator");
        require(token==address(weth), "Token Not Support");
        (address addr, bool action, bool result) = abi.decode(data, (address, bool, bool));
        if(!action) weth.transfer(addr, amount+fee);
        if(result) return keccak256("ERC3156FlashBorrower.onFlashLoan");
        return keccak256("failed");
    }

    receive() external payable {}
}
