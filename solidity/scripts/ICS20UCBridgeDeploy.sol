// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {Test} from 'forge-std/Test.sol';
import {Script} from 'forge-std/Script.sol';
import {stdJson} from 'forge-std/StdJson.sol';
import {XERC20} from '../contracts/XERC20.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';
import '../contracts/ICS20UCBridge.sol';
import './XERC20Deploy.sol';
import {IbcMwUser} from '@open-ibc/vibc-core-smart-contracts/contracts/interfaces/IbcMiddleware.sol';

contract ICS20UCBridgeDeploy is Script, ScriptingLibrary {
  using stdJson for string;

  uint256 private deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');
  XERC20 private token = XERC20(vm.envAddress('XERC20_ADDRESS'));

  function salt() internal returns (bytes32) {
    return keccak256(bytes(vm.envString('SALT')));
  }

  function deployBridge(address middleware) public returns (ICS20UCBridge) {
    ICS20UCBridge bridge = new ICS20UCBridge{salt: salt()}();
    bridge.setDefaultMw(middleware);

    // solhint-disable-next-line no-console
    console.log('Bridge deployed to:', address(bridge));
    token.setLimits(vm.addr(deployer), 1e6, 1e6);
    token.setLimits(address(bridge), 1e6, 1e6);
    token.mint(vm.addr(deployer), 100);
    token.approve(address(bridge), 100);
    return bridge;
  }

  function run() public {
    uint256 baseFork = vm.createFork(vm.rpcUrl(vm.envString('BASE_SEPOLIA_RPC')));
    uint256 opFork = vm.createFork(vm.rpcUrl(vm.envString('OPTIMISM_SEPOLIA_RPC')));

    uint256 chainId = vm.envUint('CHAIN_ID');

    if (chainId == 84_532) {
      vm.selectFork(baseFork);
      vm.startBroadcast(deployer);
      IbcMwUser baseMW = IbcMwUser(payable(vm.envAddress('BASE_UC_MW_SIM')));
      ICS20UCBridge baseBridge = deployBridge(address(baseMW));
      vm.stopBroadcast();
    }

    if (chainId == 11_155_420) {
      vm.selectFork(opFork);
      vm.startBroadcast(deployer);
      IbcMwUser opMW = IbcMwUser(payable(vm.envAddress('OP_UC_MW_SIM')));
      ICS20UCBridge opBridge = deployBridge(address(opMW));
      vm.stopBroadcast();
    }
  }
}
