// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import  {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";
import  {IUniswapV3SwapCallback} from "./interfaces/IUniswapV3SwapCallback.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {TickMath} from "./lib/TickMath.sol";
import {Path} from "./lib/path.sol";
import {CallbackValidation} from "./lib/callBackValidation.sol";
import {TransferHelper } from "./lib/TransferHelper.sol";


contract poolRouter is IUniswapV3SwapCallback {

    using Path for bytes;
    address brett = 0x532f27101965dd16442E59d40670FaF5eBB142E4;

    event AmountIn(uint256);
    event AmountOut(int256);

    uint160 private constant MIN_SQRT_RATIO = 4295128739;
    uint160 private constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    constructor(){}

    function poolSwap(address tokenIn, address tokenOut, address pool,uint256 _amount) external {
        require(_amount > 0,"amount can't be zero");

        // Tranfer _amount of tokenIn to the contract
        bool approveTokenIn = IERC20(tokenIn).transferFrom(msg.sender, address(this), _amount);
        require(approveTokenIn, "tokenIn transfer failed");

        // Approve the pool to spend tokenIn
        bool approvePoolSpending = IERC20(tokenIn).approve(address(pool), _amount);
        require(approvePoolSpending, "Approve pool spending failed");

        bool zeroForOne = true;

        IUniswapV3Pool(pool).swap({
            recipient: address(this),
            zeroForOne: zeroForOne,
            amountSpecified: int256(_amount),
            sqrtPriceLimitX96: zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
            data: abi.encode(pool, tokenIn, pool)
        });
        
        //get token balance
        uint256  amountOut = IERC20(tokenOut).balanceOf(address(this));

        //tranfer amountOut to msg.sender
        bool tx_s = IERC20(tokenOut).transfer(msg.sender, amountOut);
        require(tx_s,"Amount transfer to caller failed");
    }

   function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0, "Invalid amounts");
        
        // decode pool address pass in call data
        (address to, address tokenIn, address pool) = abi.decode(_data, (address, address, address));
        require(msg.sender == pool,"Unauthorized caller");

        IERC20(tokenIn).transfer(to, uint256(amount0Delta));
        }
}
