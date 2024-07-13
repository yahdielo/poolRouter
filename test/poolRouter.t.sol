// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {poolRouter} from "../src/poolRouter.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import  {IUniswapV3Pool} from "../src/interfaces/IUniswapV3Pool.sol";

interface CheatCodes {
           function prank(address) external;    
 }
 
contract PoolRouterTest is Test {

    CheatCodes public cheatCodes;
    IUniswapV3Pool public pool500;
    IUniswapV3Pool public pool3000;
    IUniswapV3Pool public brettSushiPool;
    poolRouter public swapper;
    IERC20 public weth;
    IERC20 public usdc;
    IERC20 public brett;

    address public loaner;
    uint256 lAmount;

    function setUp() public {

        swapper = new poolRouter();
        weth = IERC20(0x4200000000000000000000000000000000000006);
        usdc = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
        brett =IERC20(0x532f27101965dd16442E59d40670FaF5eBB142E4);
        cheatCodes = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        loaner =  0x89D0F320ac73dd7d9513FFC5bc58D1161452a657;
        brettSushiPool = IUniswapV3Pool(0xC4876EB31624a51888A2916f2D365B881bA9A8A3);

        //POols
        pool500 = IUniswapV3Pool(0xd0b53D9277642d899DF5C87A3966A349A798F224);
        pool3000 = IUniswapV3Pool(0x6c561B446416E1A00E8E93E221854d6eA4171372);
        //poolV2 = 

        lAmount = 100e18;
        cheatCodes.prank(loaner);
        //approve some random addres to give me weth
        bool _s = weth.approve(address(this), lAmount);
        require(_s, "approve weth to fund test failed");

         //transfer from loaner to this congtract
        bool s_ = weth.transferFrom(loaner, address(this), lAmount);
        require(s_, "deposit to fund test contract failed");
    }

    function testUniSwap500() public {
        //poolSwap(address tokenIn, address tokenOut, address pool,uint256 _amount)
        weth.approve(address(swapper), lAmount);
        swapper.poolSwap(address(weth),address(usdc),address(pool500),lAmount);
        uint256 balance = usdc.balanceOf(address(this));
        console.log(balance);
    }
    function testUniSwap3000() public {

        weth.approve(address(swapper), lAmount);
        swapper.poolSwap(address(weth),address(usdc),address(pool3000),lAmount);
        uint256 balance = usdc.balanceOf(address(this));
        console.log(balance);
    }
    function testSushiSwapV3() public {

        weth.approve(address(swapper), lAmount);
        swapper.poolSwap(address(weth),address(brett),address(brettSushiPool),lAmount);
        uint256 balance = brett.balanceOf(address(this));
        console.log(balance);
    }
}

