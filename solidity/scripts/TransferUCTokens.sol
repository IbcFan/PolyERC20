// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {Test} from 'forge-std/Test.sol';
import {Script} from 'forge-std/Script.sol';
import {stdJson} from 'forge-std/StdJson.sol';
import {XERC20} from '../contracts/XERC20.sol';
import {XERC20Lockbox} from '../contracts/XERC20Lockbox.sol';
import {XERC20Factory, IXERC20Factory} from '../contracts/XERC20Factory.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';
import '../contracts/ICS20UCBridge.sol';
import './XERC20Deploy.sol';
import '../contracts/ICS20Bridge.sol';

contract TransferUCTokens is Script, ScriptingLibrary {
  using stdJson for string;

  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');
  XERC20 private token = XERC20(vm.envAddress('XERC20_ADDRESS'));

  function salt() internal returns (bytes32) {
    return keccak256(bytes(vm.envString('SALT')));
  }

  function run() public {
    vm.startBroadcast(deployer);

    bytes memory creationCode = abi.encodePacked(type(ICS20UCBridge).creationCode);
    address bridge = vm.computeCreate2Address(salt(), hashInitCode(creationCode));

    // solhint-disable-next-line no-console
    console.log('Bridge address: ', bridge);

    ICS20UCBridge opBridge = ICS20UCBridge(payable(bridge));
    token.setLimits(vm.addr(deployer), 1e6, 1e6);
    token.setLimits(address(bridge), 1e6, 1e6);
    token.approve(address(bridge), 100);
    opBridge.bridge(address(opBridge), token, 100, IbcUtils.toBytes32('channel-10'), 60 * 10);

    vm.stopBroadcast();
  }
}
