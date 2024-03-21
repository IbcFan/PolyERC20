// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import 'forge-std/Script.sol';
import {IbcMwUser} from '@open-ibc/vibc-core-smart-contracts/contracts/interfaces/IbcMiddleware.sol';
import '../contracts/PolyERC20.sol';

contract PolyERC20Deploy is Script {
  uint256 private deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');

  function salt() internal returns (bytes32) {
    return keccak256(bytes(vm.envString('SALT')));
  }

  function run() external {
    string memory name = 'PolyToken';
    string memory symbol = 'POLY';

    uint256 baseFork = vm.createFork(vm.rpcUrl(vm.envString('BASE_SEPOLIA_RPC')));
    uint256 opFork = vm.createFork(vm.rpcUrl(vm.envString('OPTIMISM_SEPOLIA_RPC')));
    uint256 chainId = vm.envUint('CHAIN_ID');

    if (chainId == 84_532) {
      vm.selectFork(baseFork);
      vm.startBroadcast(deployer);
      IbcMwUser baseMW = IbcMwUser(payable(vm.envAddress('BASE_UC_MW_SIM')));
      PolyERC20 basePolyToken = new PolyERC20{salt: salt()}(name, symbol);
      basePolyToken.setDefaultMw(address(baseMW));

      // solhint-disable-next-line no-console
      console.log('PolyERC20 token deployed on Base chain at:', address(basePolyToken));
    }

    if (chainId == 11_155_420) {
      vm.selectFork(opFork);
      vm.startBroadcast(deployer);
      IbcMwUser opMW = IbcMwUser(payable(vm.envAddress('OP_UC_MW_SIM')));
      PolyERC20 opPolyToken = new PolyERC20{salt: salt()}(name, symbol);
      opPolyToken.setDefaultMw(address(opMW));

      // solhint-disable-next-line no-console
      console.log('PolyERC20 token deployed on Optimism chain at:', address(opPolyToken));
    }

    vm.stopBroadcast();
  }
}
