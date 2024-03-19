//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import {CustomChanIbcApp} from './CustomChanIbcApp.sol';
import {
  IbcUtils, IbcPacket, AckPacket, UniversalPacket
} from '@open-ibc/vibc-core-smart-contracts/contracts/libs/Ibc.sol';

import {XERC20} from './XERC20.sol';

contract ICS20Bridge is CustomChanIbcApp {
  event TokenMint(address indexed token, address indexed receiver, uint64 amount);
  event InvalidSender(address indexed sender);
  event InvalidSrcPortId(string indexed srcPortId, string indexed destPortId, string indexed expectedPortId);
  event BridgeSuccess();
  event BridgeFailure();

  constructor() CustomChanIbcApp() {}

  /**
   * @dev Sends a packet with the caller address over a specified channel.
   * @param channelId The ID of the channel (locally) to send the packet to.
   * @param timeoutSeconds The timeout in seconds (relative).
   */
  function bridge(XERC20 xerc20, uint64 amount, bytes32 channelId, uint64 timeoutSeconds) public {
    xerc20.burn(msg.sender, amount);
    bytes memory payload = abi.encode(msg.sender, xerc20, amount);

    uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1_000_000_000);

    dispatcher.sendPacket(channelId, payload, timeoutTimestamp);
  }

  /**
   * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
   *      MUST be overriden by the inheriting contract.
   *
   * @param packet the IBC packet encoded by the source and relayed by the relayer.
   */
  function onRecvPacket(IbcPacket memory packet)
    external
    override
    onlyIbcDispatcher
    returns (AckPacket memory ackPacket)
  {
    (address sender, address tokenAddress, uint64 amount) = abi.decode(packet.data, (address, address, uint64));

    XERC20(tokenAddress).mint(sender, amount);
    emit TokenMint(tokenAddress, sender, amount);

    return AckPacket(true, abi.encode(address(this)));
  }

  /**
   * @dev Packet lifecycle callback that implements packet acknowledgment logic.
   *      MUST be overriden by the inheriting contract.
   *
   * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
   */
  function onAcknowledgementPacket(
    IbcPacket calldata packet,
    AckPacket calldata ack
  ) external override onlyIbcDispatcher {
    (address sender, address tokenAddress, uint64 amount) = abi.decode(packet.data, (address, address, uint64));

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
   * @param packet the IBC packet encoded by the counterparty and relayed by the relayer
   */
  function onTimeoutPacket(IbcPacket calldata packet) external override onlyIbcDispatcher {}
}
