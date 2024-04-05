// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;
import {Vm} from "forge-std/Vm.sol";
import {Test, console2, stdError} from "forge-std/Test.sol";
import {IOrderBookV3ArbOrderTaker} from "rain.orderbook.interface/interface/IOrderBookV3ArbOrderTaker.sol";
import {IParserV1} from "rain.interpreter.interface/interface/IParserV1.sol";
import {IExpressionDeployerV3} from "rain.interpreter.interface/interface/IExpressionDeployerV3.sol";
import {IInterpreterV2} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {IInterpreterStoreV2} from "rain.interpreter.interface/interface/IInterpreterStoreV2.sol";
import {
    IOrderBookV3,
    IO,
    OrderV2,
    OrderConfigV2,
    TakeOrderConfigV2,
    TakeOrdersConfigV2
} from "rain.orderbook.interface/interface/IOrderBookV3.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

abstract contract OrderBookTestUtils is Test {

    using SafeERC20 for IERC20;
    using Strings for address;

    IParserV1 public PARSER;
    IExpressionDeployerV3 public EXPRESSION_DEPLOYER;
    IInterpreterV2 public INTERPRETER;
    IInterpreterStoreV2 public STORE;
    IOrderBookV3 public ORDERBOOK;
    IOrderBookV3ArbOrderTaker public ARB_INSTANCE;

    function depositTokens(address owner, address token, uint256 vaultId, uint256 amount) internal {
        vm.startPrank(owner);
        IERC20(token).safeApprove(address(ORDERBOOK), amount);
        ORDERBOOK.deposit(address(token), vaultId, amount);
        vm.stopPrank();
    } 

}
