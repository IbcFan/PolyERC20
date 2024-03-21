// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {Script} from 'forge-std/Script.sol';
import {stdJson} from 'forge-std/StdJson.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';
import '../contracts/ICS20UCBridge.sol';
import './XERC20Deploy.sol';
import '../contracts/ICS20Bridge.sol';
import '../contracts/PolyERC20.sol';

contract TransferPolyTokens is Script, ScriptingLibrary {
  using stdJson for string;

  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');

  function salt() internal returns (bytes32) {
    return keccak256(bytes(vm.envString('SALT')));
  }

  function run() public {
    string memory _json = vm.readFile('./solidity/scripts/xerc20-deployment-config.json');
    DeploymentConfig memory _data = abi.decode(_json.parseRaw('.'), (DeploymentConfig));

    vm.startBroadcast(deployer);

    bytes memory creationCode = abi.encodePacked(type(PolyERC20).creationCode, abi.encode(_data.name, _data.symbol));
    address token = vm.computeCreate2Address(salt(), hashInitCode(creationCode));

    // solhint-disable-next-line no-console
    console.log('Token address: ', token);

    PolyERC20 erc20 = PolyERC20(payable(token));
    erc20.mint(vm.addr(deployer), 1000);
    erc20.transferFrom(token, 100, IbcUtils.toBytes32('channel-10'), 60 * 10);

    vm.stopBroadcast();
  }
}
