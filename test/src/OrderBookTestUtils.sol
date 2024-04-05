// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {Vm} from "forge-std/Vm.sol";
import {Test, console2, stdError} from "forge-std/Test.sol";
import {IOrderBookV3ArbOrderTaker} from "rain.orderbook.interface/interface/IOrderBookV3ArbOrderTaker.sol";
import {IParserV1} from "rain.interpreter.interface/interface/IParserV1.sol";
import {IExpressionDeployerV3} from "rain.interpreter.interface/interface/IExpressionDeployerV3.sol";
import {IInterpreterV2} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {IInterpreterStoreV2} from "rain.interpreter.interface/interface/IInterpreterStoreV2.sol";
import {EvaluableConfigV3, SignedContextV1} from "rain.interpreter.interface/interface/IInterpreterCallerV2.sol";
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
import {IRouteProcessor} from "src/interface/IRouteProcessor.sol";

abstract contract OrderBookTestUtils is Test {
    using SafeERC20 for IERC20;
    using Strings for address;

    uint256 constant CONTEXT_VAULT_IO_ROWS = 5;
    address public EXTERNAL_EOA = address(0x654FEf5Fb8A1C91ad47Ba192F7AA81dd3C821427);

    IParserV1 public PARSER;
    IExpressionDeployerV3 public EXPRESSION_DEPLOYER;
    IInterpreterV2 public INTERPRETER;
    IInterpreterStoreV2 public STORE;
    IOrderBookV3 public ORDERBOOK;
    IOrderBookV3ArbOrderTaker public ARB_INSTANCE;
    IRouteProcessor public ROUTE_PROCESSOR;

    function depositTokens(address owner, address token, uint256 vaultId, uint256 amount) internal {
        vm.startPrank(owner);
        IERC20(token).safeApprove(address(ORDERBOOK), amount);
        ORDERBOOK.deposit(address(token), vaultId, amount);
        vm.stopPrank();
    }

    function withdrawTokens(address owner, address token, uint256 vaultId, uint256 amount) internal {
        vm.startPrank(owner);
        ORDERBOOK.withdraw(address(token), vaultId, amount);
        vm.stopPrank();
    }

    function getVaultBalance(address owner, address token, uint256 vaultId) internal view returns (uint256) {
        return ORDERBOOK.vaultBalance(owner, token, vaultId);
    }

    function addOrderBookOrder(
        address orderOwner,
        bytes memory bytecode,
        uint256[] memory constants,
        IO[] memory inputs,
        IO[] memory outputs
    ) internal returns (OrderV2 memory order) {
        EvaluableConfigV3 memory evaluableConfig = EvaluableConfigV3(EXPRESSION_DEPLOYER, bytecode, constants);
        OrderConfigV2 memory orderConfig = OrderConfigV2(inputs, outputs, evaluableConfig, "");

        vm.startPrank(orderOwner);
        vm.recordLogs();
        (bool stateChanged) = ORDERBOOK.addOrder(orderConfig);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 3);
        (,, order,) = abi.decode(entries[2].data, (address, address, OrderV2, bytes32));
        assertEq(order.owner, orderOwner);
        assertEq(stateChanged, true);
    }

    function moveExternalPrice(address inputToken, address outputToken, uint256 amountIn, bytes memory encodedRoute)
        public
    {
        vm.startPrank(EXTERNAL_EOA);
        IERC20(inputToken).safeApprove(address(ROUTE_PROCESSOR), amountIn);
        bytes memory decodedRoute = abi.decode(encodedRoute, (bytes));
        ROUTE_PROCESSOR.processRoute(inputToken, amountIn, outputToken, 0, EXTERNAL_EOA, decodedRoute);
        vm.stopPrank();
    }

    function getContextInputOutput(Vm.Log[] memory entries)
        public
        pure
        returns (uint256 input, uint256 output, uint256 ratio)
    {
        for (uint256 j = 0; j < entries.length; j++) {
            if (entries[j].topics[0] == keccak256("Context(address,uint256[][])")) {
                (, uint256[][] memory context) = abi.decode(entries[j].data, (address, uint256[][]));
                ratio = context[2][1];
                input = context[3][4];
                output = context[4][4];
            }
        }
    }
    
    function getOrderContext(uint256 orderHash) internal pure returns (uint256[][] memory context) {
        context = new uint256[][](5);
        {
            {
                uint256[] memory baseContext = new uint256[](2);
                context[0] = baseContext;
            }
            {
                uint256[] memory callingContext = new uint256[](3);
                // order hash
                callingContext[0] = orderHash;
                context[1] = callingContext;
            }
            {
                uint256[] memory calculationsContext = new uint256[](2);
                context[2] = calculationsContext;
            }
            {
                uint256[] memory inputsContext = new uint256[](CONTEXT_VAULT_IO_ROWS);
                context[3] = inputsContext;
            }
            {
                uint256[] memory outputsContext = new uint256[](CONTEXT_VAULT_IO_ROWS);
                context[4] = outputsContext;
            }
        }
    }
}
