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

    /*//////////////////////////////////////////////////////////////
                                HELPER
    //////////////////////////////////////////////////////////////*/
    
    function _deposit(address addr, uint256 amount) internal {
        uint256 beforeBalance = weth.balanceOf(user);

        vm.prank(addr);
        vm.expectEmit(true, true, true, false);
        emit Transfer(address(0), addr, amount);
        weth.deposit{value: amount}();

        uint256 afterBalance = weth.balanceOf(user);
        assertEq(afterBalance, beforeBalance+amount);
    }

    function _approve(address from, address to, uint256 amount) internal {
        uint256 beforeAllowance = weth.allowance(from, to);
        vm.prank(from);
        vm.expectEmit(true, true, true, true);
        emit Approval(from, to, amount);
        bool success = weth.approve(to, amount);

        uint256 afterAllowance = weth.allowance(from, to);

        assertTrue(success);
        assertEq(afterAllowance, beforeAllowance+amount);
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTION
    //////////////////////////////////////////////////////////////*/

    // function deposit()
    function testDeposit() public {

        _deposit(user, initialSupply);
    }

    // function depositTo(address to)
    function testDepositTo() public {
        vm.prank(user);
        vm.expectEmit(true, true, true, false);
        emit Transfer(address(0), user0, initialSupply);
        weth.depositTo{value: initialSupply}(user0);

        uint256 balance = weth.balanceOf(user0);
        assertEq(balance, initialSupply);
    }

    // function depositToAndCall(address to, bytes calldata data)
    function testDepositToAndCallSuccess() public {
        bytes memory data = abi.encode(user0, true); 

        vm.prank(user);
        TransferRecevier receiver = new TransferRecevier(weth);

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), address(receiver), initialSupply);
        bool success = weth.depositToAndCall{value: initialSupply}(address(receiver), data);
        assertTrue(success);

        uint256 balance = user0.balance;
        assertEq(balance, initialSupply);
    }

    function testDepositToAndCallFailed() public {
        bytes memory data = abi.encode(user0, false);

        vm.prank(user);
        TransferRecevier receiver = new TransferRecevier(weth);

        vm.prank(user);
        vm.expectRevert();
        weth.depositToAndCall{value: initialSupply}(address(receiver), data);
    }

    // function withdraw(uint256 amount)
    function testWithdrawSuccess() public {
        uint256 balance;

        _deposit(user, initialSupply);

        balance = weth.balanceOf(user);

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit Transfer(user, address(0), initialSupply/2);
        weth.withdraw(balance/2);

        balance = weth.balanceOf(user);
        assertEq(balance, initialSupply/2);
    }

    function testWithdrawBalanceNotEnough() public {
        uint256 balance;

        _deposit(user, initialSupply);

        balance = weth.balanceOf(user);

        vm.prank(user);
        vm.expectRevert();
        weth.withdraw(balance*2);
    }

    // function withdrawTo(address payable to, uint256 amount)
    function testWithdrawToSuccess() public {
        uint256 balance;

        _deposit(user, initialSupply);

        balance = weth.balanceOf(user);

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit Transfer(user, address(0), initialSupply);
        weth.withdrawTo(payable(user0), initialSupply);

        balance = user0.balance;
        assertEq(balance, initialSupply);
    }

    function testWithdrawToBalanceNotEnough() public {
        uint256 balance;

        _deposit(user, initialSupply);

        balance = weth.balanceOf(user);

        vm.prank(user);
        vm.expectRevert();
        weth.withdrawTo(payable(user0), initialSupply*2);
    }

    // function withdrawFrom(address from, address payable to, uint256 amount)
    function testWithdrawFromMsgSender() public {
        uint256 balance;

        _deposit(user, initialSupply);

        balance = weth.balanceOf(user);

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit Transfer(user, address(0), initialSupply);
        weth.withdrawFrom(user, payable(user0), initialSupply);

        balance = user0.balance;
        assertEq(balance, initialSupply);
    }

    function testWithdrawFromMsgSenderBalanceNotEnough() public {
        uint256 balance;

        _deposit(user, initialSupply);

        balance = weth.balanceOf(user);

        vm.prank(user);
        vm.expectRevert();
        weth.withdrawFrom(user, payable(user0), initialSupply*2);
    }

    function testWithdrawFromNotMsgSender() public {
        uint256 balance;
        uint256 allowanceAmount;

        _deposit(user, initialSupply);

        balance = weth.balanceOf(user);

        _approve(user, user0, initialSupply);

        vm.prank(user0);
        vm.expectEmit(true, true, true, true);
        emit Approval(user,  user0, initialSupply);
        weth.withdrawFrom(user, payable(user0), initialSupply);

        balance = user0.balance;
        allowanceAmount = weth.allowance(user, user0);
        
        assertEq(balance, initialSupply);
        assertEq(allowanceAmount, 0);
    }   

    function testWithdrawFromNotMsgSenderBalanceNotEnough() public {

        _deposit(user, initialSupply);

        _approve(user, user0, initialSupply);

        vm.prank(user0);
        vm.expectRevert();
        weth.withdrawFrom(user, payable(user0), initialSupply*2);
    }

    // function approve(address spender, uint256 amount)
    function testApprove() public {

        _approve(user, user0, initialSupply);
    }

    // function approveAndCall(address spender, uint256 amount, bytes calldata data)
    function testApproveAndCallSuccess() public {
        bytes memory data = abi.encode(user, true);

        _deposit(user, initialSupply);

        vm.prank(user);
        TransferRecevier receiver = new TransferRecevier(weth);

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit Approval(user, address(receiver), initialSupply);
        weth.approveAndCall(address(receiver), initialSupply, data);
    }

    function testApproveAndCallFailed() public {
        bytes memory data = abi.encode(user, false);

        _deposit(user, initialSupply);

        vm.prank(user);
        TransferRecevier receiver = new TransferRecevier(weth);

        vm.prank(user);
        vm.expectRevert();
        weth.approveAndCall(address(receiver), initialSupply, data);
    }

    // function transfer(address to, uint256 amount)
    function testTransferSuccesss() public {
        
        _deposit(user, initialSupply);

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit Transfer(user, user0, initialSupply);
        bool success = weth.transfer(user0, initialSupply);

        assertTrue(success);
        assertEq(weth.balanceOf(user), 0);
        assertEq(weth.balanceOf(user0), initialSupply);
    }

    function testTransferBalanceNotEnough() public {
        
        _deposit(user, initialSupply);

        vm.prank(user);
        vm.expectRevert();
        weth.transfer(user0, initialSupply*2);
    }

    function testTransferToInvalidAddress() public {
        
        _deposit(user, initialSupply);

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit Transfer(user, address(0), initialSupply);
        bool success = weth.transfer(address(0), initialSupply);

        assertTrue(success);

        uint256 balance = user.balance;
        assertEq(balance, initialSupply);
    }

    // function transferFrom(address from, address to, uint256 amount)
    function testTransferFromSuccess() public {
        
        _deposit(user, initialSupply);

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit Transfer(user, user0, initialSupply);
        bool success = weth.transferFrom(user, user0, initialSupply);

        assertTrue(success);
        assertEq(weth.balanceOf(user0), initialSupply);
    }

    function testTransferFromBalanceNotEnough() public {
        
        _deposit(user, initialSupply);

        vm.prank(user);
        vm.expectRevert();
        weth.transferFrom(user, user0, initialSupply*2);
    }

    function testTransferFromNotMsgSender() public {
        
        _deposit(user, initialSupply);

        _approve(user, user0, initialSupply);

        vm.prank(user0);
        bool success = weth.transferFrom(user, user0, initialSupply);
        assertTrue(success);
    }

    function testTransferFromNotMsgSenderAllowanceNotEnough() public {
    
        _deposit(user, initialSupply);

        vm.prank(user0);
        vm.expectRevert();
        weth.transferFrom(user, user0, initialSupply*2);
    }

    function testTransferFromMsgSenderToInvalidAddress() public {
        _deposit(user, initialSupply);

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit Transfer(user, address(0), initialSupply);
        bool success = weth.transferFrom(user, address(0), initialSupply);

        assertTrue(success);
        assertEq(user.balance, initialSupply);
    }

    function testTransferFromNotMsgSenderToInvalidAddress() public {

        _deposit(user, initialSupply);

        _approve(user, user0, initialSupply);

        vm.prank(user0);
        bool success = weth.transferFrom(user, address(0), initialSupply);

        assertTrue(success);
        assertEq(user0.balance, initialSupply);
    }

    // function transferAndCall(address to, uint256 amount, bytes calldata data)
    function testTransferAndCallSuccess() public {
        bytes memory data = abi.encode(user0, true);

        _deposit(user, initialSupply);

        vm.prank(user);
        TransferRecevier receiver = new TransferRecevier(weth);
        
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit Transfer(user, address(receiver), initialSupply);
        bool success = weth.transferAndCall(address(receiver), initialSupply, data);

        assertTrue(success);
    }

    function testTransferAndCallBalanceNotEnough() public {
        bytes memory data = abi.encode(user0, true);

        _deposit(user, initialSupply);

        vm.prank(user);
        TransferRecevier receiver = new TransferRecevier(weth);

        vm.prank(user);
        vm.expectRevert();
        weth.transferAndCall(address(receiver), initialSupply*2, data);
    }
    
    function testTransferAndCallTokenTransferFailed() public {
        bytes memory data = abi.encode(user0, false);

        _deposit(user, initialSupply);

        vm.prank(user);
        TransferRecevier receiver = new TransferRecevier(weth);

        vm.prank(user);
        vm.expectRevert();
        weth.transferAndCall(address(receiver), initialSupply, data);
    }

    function testTransferAndCallInvalidAddress() public {
        bytes memory data = abi.encode(user0, false);

        _deposit(user, initialSupply);

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit Transfer(user, address(0), initialSupply);
        bool success =  weth.transferAndCall(address(0), initialSupply, data);

        assertTrue(success);
        assertEq(user.balance, initialSupply);
    }

    // function flashFee(address token, uint256) 
    function testFlashFee() public {
        vm.prank(user);
        uint256 value = weth.flashFee(address(weth), 0);
        assertEq(value, 0);
    }

    function testFlashFeeTokenNotSupport() public {
        vm.prank(user);
        vm.expectRevert();
        weth.flashFee(address(0), 0);
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
