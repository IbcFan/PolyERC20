// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './UniversalChanIbcApp.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {receiverNotOriginPacketSender} from '@open-ibc/vibc-core-smart-contracts/contracts/libs/Ibc.sol';

contract PolyERC20 is UniversalChanIbcApp, ERC20 {
  event TokenMint(address indexed receiver, uint256 amount);
  event TransferSuccess();
  event TransferFailure();

  constructor(string memory name, string memory symbol) ERC20(name, symbol) UniversalChanIbcApp() {}

  function mint(address account, uint256 amount) public virtual onlyOwner {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) public virtual onlyOwner {
    _burn(account, amount);
  }

  function transferFrom(address destPortAddr, uint256 amount, bytes32 channelId, uint64 timeoutSeconds) public {
    _burn(msg.sender, amount);
    bytes memory payload = abi.encode(msg.sender, amount);
    uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1_000_000_000);
    IbcUniversalPacketSender(mw).sendUniversalPacket(
      channelId, IbcUtils.toBytes32(destPortAddr), payload, timeoutTimestamp
    );
  }

  function onRecvUniversalPacket(
    bytes32 channelId,
    UniversalPacket calldata packet
  ) external override onlyIbcMw returns (AckPacket memory ackPacket) {
    if (packet.srcPortAddr != packet.destPortAddr) {
      revert receiverNotOriginPacketSender();
    }
    (address sender, uint256 amount) = abi.decode(packet.appData, (address, uint256));
    _mint(sender, amount);
    emit TokenMint(sender, amount);
    return AckPacket(true, abi.encode(address(this)));
  }

  function onUniversalAcknowledgement(
    bytes32 channelId,
    UniversalPacket memory packet,
    AckPacket calldata ack
  ) external override onlyIbcMw {
    if (packet.srcPortAddr != packet.destPortAddr) {
      revert receiverNotOriginPacketSender();
    }
    (address sender, uint256 amount) = abi.decode(packet.appData, (address, uint256));
    if (ack.success) {
      emit TransferSuccess();
    } else {
      emit TransferFailure();
      _mint(sender, amount);
    }
  }

  function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override onlyIbcMw {
    if (packet.srcPortAddr != packet.destPortAddr) {
      revert receiverNotOriginPacketSender();
    }
    (address sender, uint256 amount) = abi.decode(packet.appData, (address, uint256));
    _mint(sender, amount);
  }
}
