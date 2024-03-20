// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {Script} from 'forge-std/Script.sol';
import {stdJson} from 'forge-std/StdJson.sol';
import {XERC20} from '../contracts/XERC20.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';
import '../contracts/ICS20Bridge.sol';
import './XERC20Deploy.sol';
import '@open-ibc/vibc-core-smart-contracts/contracts/core/Dispatcher.sol';
import '@openzeppelin/contracts/utils/Create2.sol';
import {BridgeCounterParty} from './../contracts/CustomChanIbcApp.sol';

contract ICS20CreateChannel is Script, ScriptingLibrary {
  using stdJson for string;

  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');
  XERC20 private token = XERC20(vm.envAddress('XERC20_ADDRESS'));
  Ics23Proof private proof;

  constructor() {
    proof.height = 10;
  }

  function salt() internal returns (bytes32) {
    return keccak256(bytes(vm.envString('SALT')));
  }

  function run() public {
    Dispatcher baseDispatcher = Dispatcher(payable(vm.envAddress('BASE_DISPATCHER_SIM')));
    Dispatcher opDispatcher = Dispatcher(payable(vm.envAddress('OP_DISPATCHER_SIM')));

    uint256 opFork = vm.createFork(vm.rpcUrl(vm.envString('OPTIMISM_SEPOLIA_RPC')));
    uint256 baseFork = vm.createFork(vm.rpcUrl(vm.envString('BASE_SEPOLIA_RPC')));

    bytes memory creationCode = abi.encodePacked(type(ICS20Bridge).creationCode);
    address bridge = vm.computeCreate2Address(salt(), hashInitCode(creationCode));
    // solhint-disable-next-line no-console
    console.log('Bridge address: ', bridge);

    ICS20Bridge opBridge = ICS20Bridge(payable(bridge));
    ICS20Bridge baseBridge = ICS20Bridge(payable(bridge));

    vm.selectFork(baseFork);
    vm.startBroadcast(deployer);
    string memory basePortPrefix = baseDispatcher.portPrefix();

    // solhint-disable-next-line no-console
    console.log('Base port prefix: ', basePortPrefix);
    vm.stopBroadcast();

    vm.selectFork(opFork);
    vm.startBroadcast(deployer);

    uint8 unorderedChannelOrder = uint8(ChannelOrder.UNORDERED);
    string[] memory connections = new string[](2);
    connections[0] = 'connection-0';
    connections[1] = 'connection-5';

    opBridge.createChannel(
      BridgeCounterParty(opDispatcher.portPrefix(), address(opBridge), IbcUtils.toBytes32(''), '1.0'),
      unorderedChannelOrder,
      true,
      connections,
      BridgeCounterParty(basePortPrefix, address(baseBridge), IbcUtils.toBytes32(''), ''),
      proof
    );
    vm.stopBroadcast();
  }
}
