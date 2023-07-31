// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant TANGRTING_BALANCE = 10 ether;
    address USER= makeAddr("user");
    
    function setUp() external{
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, 10 ether);
    }

    function testMinimumDollarIsFive() public{
        assertEq(fundMe.MINIMUM_USD(),5e18);
    }

    function testOwnerIsMsgSender() public{
        assertEq(fundMe.getOwner(),msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public{
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoghETH() public{
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDateStructure() public{
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testAddsFunderToArrayOfFunders() public funded{
        address fundr = fundMe.getFunder(0);
        assertEq(fundr, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded{
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded{
        //环境
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        
        //行为
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //断言
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }

    function testWithdrawFromMultiplleFunders() public funded{
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw(); 
        vm.stopPrank();

        assertEq(address(fundMe).balance, 0);
        assertEq(fundMe.getOwner().balance, startingOwnerBalance + startingFundMeBalance);
    }
}