// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import  {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";
import  {IUniswapV3SwapCallback} from "./interfaces/IUniswapV3SwapCallback.sol";
import {IERC20} from "./interfaces/IERC20.sol";
/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}
/// @notice Provides validation for callbacks from Uniswap V3 Pools
library CallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool) {
        return verifyCallback(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee));
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback(address factory, PoolAddress.PoolKey memory poolKey)
        internal
        view
        returns (IUniswapV3Pool pool)
    {
        pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
        require(msg.sender == address(pool));
    }
}
library TransferHelper {
    /// @notice Approves the `spender` to spend `value` of the `token`'s balance from the caller's address
    /// @param token The contract address of the token to be approved
    /// @param to The address which will spend the funds
    /// @param value The amount of tokens to be spent
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20(token).approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::safeApprove: approve failed');
    }

    /// @notice Transfers `value` tokens from the caller's address to `to`
    /// @param token The contract address of the token to be transferred
    /// @param to The address receiving the tokens
    /// @param value The amount of tokens to be transferred
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20(token).transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::safeTransfer: transfer failed');
    }

    /// @notice Transfers `value` tokens from `from` to `to` using the allowance mechanism
    /// @param token The contract address of the token to be transferred
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param value The amount of tokens to be transferred
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20(token).transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::safeTransferFrom: transferFrom failed');
    }

    /// @notice Transfers `value` ETH to `to`
    /// @param to The address of the recipient
    /// @param value The amount of ETH to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

contract poolRouter is IUniswapV3SwapCallback {


    IUniswapV3Pool public pool;
    IERC20 public immutable weth;
    IERC20 public immutable  usdc;
    address public immutable factory;

    event decodedData(bool);

    
    constructor(){
        pool = IUniswapV3Pool(0xd0b53D9277642d899DF5C87A3966A349A798F224);
        weth = IERC20(0x4200000000000000000000000000000000000006);
        usdc = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
        factory = 0x33128a8fC17869897dcE68Ed026d694621f6FDfD;
    }

    function swap(uint256 _amount) external {
        // Transfer the specified amount of WETH to this contract.
        weth.transferFrom(msg.sender, address(this), _amount);

        // Approve the pool to spend WETH.
        weth.approve(address(pool), _amount);

        uint160 sqrtPriceLimitX96 = 0;
        bool zeroForOne = true;
        IUniswapV3Pool(pool).swap(
           address(this),
            zeroForOne,
            int256(_amount),
            sqrtPriceLimitX96,
            abi.encode(msg.sender)
        );
    }

     /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        IUniswapV3SwapCallback.SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));

        emit decodedData(true);
        
        address tokenIn = address(weth);
        address tokenOut = address(usdc);
        uint24 fee = 500; //%0.05
        CallbackValidation.verifyCallback(factory, address(weth), address(usdc), fee);

        (bool isExactInput, uint256 amountToPay) =
            amount0Delta > 0
                ? (tokenIn < tokenOut, uint256(amount0Delta))
                : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) {
            pay(tokenIn, data.payer, msg.sender, amountToPay);
        }
    }

    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (payer == address(this)) {
            IERC20(token).transfer(recipient, value);
        } else {
            IERC20(token).transferFrom(payer, recipient, value);
        }
    }
}
