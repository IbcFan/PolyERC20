//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import {
  IbcUtils,
  IbcPacket,
  AckPacket,
  ChannelOrder,
  CounterParty,
  UniversalPacket
} from '@open-ibc/vibc-core-smart-contracts/contracts/libs/Ibc.sol';
import {
  IbcReceiver, IbcChannelReceiver
} from '@open-ibc/vibc-core-smart-contracts/contracts/interfaces/IbcReceiver.sol';
import {IbcDispatcher} from '@open-ibc/vibc-core-smart-contracts/contracts/interfaces/IbcDispatcher.sol';
import {Ics23Proof} from '@open-ibc/vibc-core-smart-contracts/contracts/interfaces/ProofVerifier.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {
  IbcUniversalPacketReceiver,
  IbcUniversalPacketSender
} from '@open-ibc/vibc-core-smart-contracts/contracts/interfaces/IbcMiddleware.sol';

// UniversalChanIbcApp is a contract that can be used as a base contract
// for IBC-enabled contracts that send packets over the universal channel.
contract UniversalChanIbcApp is IbcUniversalPacketReceiver, Ownable {
  struct UcPacketWithChannel {
    bytes32 channelId;
    UniversalPacket packet;
  }

  struct UcAckWithChannel {
    bytes32 channelId;
    UniversalPacket packet;
    AckPacket ack;
  }

  // default middleware
  address public mw;
  mapping(address => bool) public authorizedMws;

  /**
   * @dev Constructor function that takes an IbcMiddleware address and grants the IBC_ROLE to the Polymer IBC Dispatcher.
   */
  constructor() Ownable() {
    transferOwnership(tx.origin);
  }

  /**
   * @dev Set the default IBC middleware contract in the MW stack.
   * When sending packets, the default middleware is the next middleware in the MW stack.
   * When receiving packets, the default middleware is the previous middleware in the MW stack.
   * @param _middleware The address of the IbcMiddleware contract.
   * @notice The default middleware is authorized automatically.
   */
  function setDefaultMw(address _middleware) external onlyOwner {
    _authorizeMiddleware(_middleware);
    mw = _middleware;
  }

  /**
   * @dev register an authorized middleware so that modifier onlyIbcMw can be used to restrict access to only authorized middleware.
   * Only the address with the IBC_ROLE can execute the function.
   * @notice Should add this modifier to all IBC-related callback functions.
   */
  function authorizeMiddleware(address middleware) external onlyOwner {
    _authorizeMiddleware(middleware);
  }

  function _authorizeMiddleware(address middleware) internal {
    authorizedMws[address(middleware)] = true;
  }

  /// This function is called for plain Ether transfers, i.e. for every call with empty calldata.
  // An empty function body is sufficient to receive packet fee refunds.
  receive() external payable {}

  /**
   * @dev Modifier to restrict access to only the IBC middleware.
   * Only the address with the IBC_ROLE can execute the function.
   * Should add this modifier to all IBC-related callback functions.
   */
  modifier onlyIbcMw() {
    require(authorizedMws[msg.sender], 'unauthorized IBC middleware');
    _;
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
  ) external virtual onlyIbcMw returns (AckPacket memory ackPacket) {
    return AckPacket(
      true, abi.encodePacked(address(this), IbcUtils.toAddress(packet.srcPortAddr), channelId, 'ack-', packet.appData)
    );
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
  ) external virtual onlyIbcMw {}

  /**
   * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
   *      MUST be overriden by the inheriting contract.
   *      NOT SUPPORTED YET
   *
   * @param channelId the ID of the channel (locally) the timeout was submitted on.
   * @param packet the Universal packet encoded by the counterparty and relayed by the relayer
   */
  function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external virtual onlyIbcMw {}
}
