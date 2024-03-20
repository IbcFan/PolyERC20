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
import '@open-ibc/vibc-core-smart-contracts/contracts/core/Dispatcher.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract TransferTokens is Script, ScriptingLibrary {
  using stdJson for string;

  XERC20 private token = XERC20(vm.envAddress('XERC20_ADDRESS'));
  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');

  function salt() internal returns (bytes32) {
    return keccak256(bytes(vm.envString('SALT')));
  }

  function toStr(bytes32 b) public pure returns (string memory outStr) {
    uint8 i = 0;
    while (i < 32 && b[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (uint8 j = 0; j < i; j++) {
      bytesArray[j] = b[j];
    }
    outStr = string(bytesArray);
  }

  function run() public {
    vm.startBroadcast(deployer);

    bytes memory creationCode = abi.encodePacked(type(ICS20Bridge).creationCode);
    address bridge = vm.computeCreate2Address(salt(), hashInitCode(creationCode));

    // solhint-disable-next-line no-console
    console.log('Bridge address: ', bridge);

    ICS20Bridge opBridge = ICS20Bridge(payable(bridge));
    CustomChanIbcApp.ChannelMapping[] memory channels = opBridge.getConnectedChannels();

    require(channels.length > 0, 'No channels found');
    for (uint256 i = 0; i < channels.length; i++) {
      // solhint-disable-next-line no-console
      console.log('Found channel: ', toStr(channels[i].channelId));
    }

    token.setLimits(vm.addr(deployer), 1e6, 1e6);
    token.setLimits(address(opBridge), 1e6, 1e6);
    token.approve(address(opBridge), 100);
    opBridge.bridge(token, 100, channels[0].channelId, 60 * 10);

    vm.stopBroadcast();
  }

  function substring(string memory str, uint256 startIndex, uint256 endIndex) public pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex - startIndex);
    for (uint256 i = startIndex; i < endIndex; i++) {
      result[i - startIndex] = strBytes[i];
    }
    return string(result);
  }
}
