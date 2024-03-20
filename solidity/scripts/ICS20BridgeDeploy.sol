// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {Test} from 'forge-std/Test.sol';
import {Script} from 'forge-std/Script.sol';
import {stdJson} from 'forge-std/StdJson.sol';
import {XERC20} from '../contracts/XERC20.sol';
import {XERC20Factory, IXERC20Factory} from '../contracts/XERC20Factory.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';
import '../contracts/ICS20Bridge.sol';
import './XERC20Deploy.sol';
import '@open-ibc/vibc-core-smart-contracts/contracts/core/Dispatcher.sol';

contract ICS20BridgeDeploy is Script, ScriptingLibrary {
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

  function deployBridge(address dispatcher) public returns (ICS20Bridge) {
    ICS20Bridge bridge = new ICS20Bridge{salt: salt()}();
    bridge.updateDispatcher(IbcDispatcher(dispatcher));

    // solhint-disable-next-line no-console
    console.log('Bridge deployed to:', address(bridge));
    token.setLimits(vm.addr(deployer), 1e6, 1e6);
    token.setLimits(address(bridge), 1e6, 1e6);
    token.mint(vm.addr(deployer), 100);
    token.approve(address(bridge), 100);
    return ICS20Bridge(payable(bridge));
  }

  function run() public {
    uint256 baseFork = vm.createFork(vm.rpcUrl(vm.envString('BASE_SEPOLIA_RPC')));
    uint256 opFork = vm.createFork(vm.rpcUrl(vm.envString('OPTIMISM_SEPOLIA_RPC')));

    uint256 chainId = vm.envUint('CHAIN_ID');

    if (chainId == 11_155_420) {
      vm.selectFork(opFork);
      vm.startBroadcast(deployer);
      Dispatcher opDispatcher = Dispatcher(payable(vm.envAddress('OP_DISPATCHER_SIM')));
      deployBridge(address(opDispatcher));
      vm.stopBroadcast();
    }

    if (chainId == 84_532) {
      vm.selectFork(baseFork);
      vm.startBroadcast(deployer);
      Dispatcher baseDispatcher = Dispatcher(payable(vm.envAddress('BASE_DISPATCHER_SIM')));
      deployBridge(address(baseDispatcher));
      vm.stopBroadcast();
    }
  }
}
