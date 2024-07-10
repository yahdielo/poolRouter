// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {poolRouter} from "../src/poolRouter.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

interface CheatCodes {
           function prank(address) external;    
 }
 
contract PoolRouterTest is Test {

    CheatCodes public cheatCodes;
    poolRouter public swapper;
    IERC20 public weth;
    address public loaner;

    function setUp() public {

        swapper = new poolRouter();
        weth = IERC20(0x4200000000000000000000000000000000000006);
        cheatCodes = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        loaner =  0x89D0F320ac73dd7d9513FFC5bc58D1161452a657;

        uint256 lAmount = 10e18;
        cheatCodes.prank(loaner);
        //approve some random addres to give me weth
        bool _s = weth.approve(address(this), lAmount);
        require(_s, "approve weth to fund test failed");

         //transfer from loaner to this congtract
        bool s_ = weth.transferFrom(loaner, address(this), lAmount);
        require(s_, "deposit to fund test contract failed");
    }

    function testSwap() public {

        weth.approve(address(swapper), 1e18);
        swapper.swap(1e12);
    }
}

