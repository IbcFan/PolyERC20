// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './UniversalChanIbcApp.sol';
import './XERC20.sol';
import {IbcUniversalPacketReceiver} from '@open-ibc/vibc-core-smart-contracts/contracts/interfaces/IbcMiddleware.sol';
import {receiverNotOriginPacketSender} from '@open-ibc/vibc-core-smart-contracts/contracts/libs/Ibc.sol';

library Errors {
  error InvalidCounterPartyBridge();
}

contract ICS20UCBridge is UniversalChanIbcApp {
  event TokenMint(address indexed token, address indexed receiver, uint64 amount);
  event InvalidSender(address indexed sender);
  event BridgeSuccess();
  event BridgeFailure();

  constructor() UniversalChanIbcApp() {}

  function bridge(address destPortAddr, XERC20 xerc20, uint64 amount, bytes32 channelId, uint64 timeoutSeconds) public {
    xerc20.burn(msg.sender, amount);
    bytes memory payload = abi.encode(msg.sender, xerc20, amount);

    uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1_000_000_000);

    IbcUniversalPacketSender(mw).sendUniversalPacket(
      channelId, IbcUtils.toBytes32(destPortAddr), payload, timeoutTimestamp
    );
  }

  /**
   * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
   *      MUST be overriden by the inheriting contract.
   *
   * @param channelId the ID of the channel (locally) the packet was received on.
   * @param packet the Universal packet encoded by the source and relayed by the relayer.
   */
  function onRecvUniversalPacket(
    bytes32 channelId,
    UniversalPacket calldata packet
  ) external override onlyIbcMw returns (AckPacket memory ackPacket) {
    if (packet.srcPortAddr != packet.destPortAddr) {
      revert receiverNotOriginPacketSender();
    }

    (address sender, address tokenAddress, uint64 amount) = abi.decode(packet.appData, (address, address, uint64));

    XERC20(tokenAddress).mint(sender, amount);
    emit TokenMint(tokenAddress, sender, amount);

    return AckPacket(true, abi.encode(address(this)));
  }

  /**
   * @dev Packet lifecycle callback that implements packet acknowledgment logic.
   *      MUST be overriden by the inheriting contract.
   *
   * @param channelId the ID of the channel (locally) the ack was received on.
   * @param packet the Universal packet encoded by the source and relayed by the relayer.
   * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
   */
  function onUniversalAcknowledgement(
    bytes32 channelId,
    UniversalPacket memory packet,
    AckPacket calldata ack
  ) external override onlyIbcMw {
    if (packet.srcPortAddr != packet.destPortAddr) {
      revert receiverNotOriginPacketSender();
    }

    (address sender, address tokenAddress, uint64 amount) = abi.decode(packet.appData, (address, address, uint64));

    if (ack.success) {
      emit BridgeSuccess();
      (address receiver) = abi.decode(ack.data, (address));
    } else {
      emit BridgeFailure();
      XERC20(tokenAddress).mint(sender, amount);
    }
  }

  /**
   * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
   *      MUST be overriden by the inheriting contract.
   *      NOT SUPPORTED YET
   *
   * @param channelId the ID of the channel (locally) the timeout was submitted on.
   * @param packet the Universal packet encoded by the counterparty and relayed by the relayer
   */
  function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override onlyIbcMw {
    if (packet.srcPortAddr != packet.destPortAddr) {
      revert receiverNotOriginPacketSender();
    }

    (address sender, address tokenAddress, uint64 amount) = abi.decode(packet.appData, (address, address, uint64));
    XERC20(tokenAddress).mint(sender, amount);
  }
}
