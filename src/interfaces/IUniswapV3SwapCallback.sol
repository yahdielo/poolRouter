// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV3SwapCallback {

    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}