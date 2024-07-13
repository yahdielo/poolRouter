// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "../interfaces/IERC20.sol";

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