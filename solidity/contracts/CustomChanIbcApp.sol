//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import {
  IbcUtils,
  IbcPacket,
  AckPacket,
  ChannelOrder,
  CounterParty,
  invalidCounterPartyPortId
} from '@open-ibc/vibc-core-smart-contracts/contracts/libs/Ibc.sol';
import {
  IbcReceiver, IbcChannelReceiver
} from '@open-ibc/vibc-core-smart-contracts/contracts/interfaces/IbcReceiver.sol';
import {IbcDispatcher} from '@open-ibc/vibc-core-smart-contracts/contracts/interfaces/IbcDispatcher.sol';
import {Ics23Proof} from '@open-ibc/vibc-core-smart-contracts/contracts/interfaces/ProofVerifier.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

struct BridgeCounterParty {
  string destPrefix;
  address destAddress;
  bytes32 channelId;
  string version;
}

library StringUtils {
  // Function to check if `str` ends with `suffix`
  function endsWith(string memory str, string memory suffix) internal pure returns (bool) {
    bytes memory strBytes = bytes(str);
    bytes memory suffixBytes = bytes(suffix);

    if (suffixBytes.length > strBytes.length) {
      return false;
    }

    for (uint256 i = 0; i < suffixBytes.length; i++) {
      if (strBytes[strBytes.length - i - 1] != suffixBytes[suffixBytes.length - i - 1]) {
        return false;
      }
    }

    return true;
  }
}

// CustomChanIbcApp is a contract that can be used as a base contract
// for IBC-enabled contracts that send packets over a custom IBC channel.
contract CustomChanIbcApp is IbcReceiver, Ownable {
  event Counterparty(string indexed portId);
  event CounterpartyAddress(address indexed portId);

  struct ChannelMapping {
    bytes32 channelId;
    bytes32 cpChannelId;
  }

  // ChannelMapping array with the channel IDs of the connected channels
  ChannelMapping[] public connectedChannels;

  // add supported versions (format to be negotiated between apps)
  string[] supportedVersions = ['1.0'];

  IbcDispatcher public dispatcher;

  constructor() Ownable() {
    transferOwnership(tx.origin);
  }

  /// This function is called for plain Ether transfers, i.e. for every call with empty calldata.
  // An empty function body is sufficient to receive packet fee refunds.
  receive() external payable {}

  /**
   * @dev Modifier to restrict access to only the IBC dispatcher.
   * Only the address with the IBC_ROLE can execute the function.
   * Should add this modifier to all IBC-related callback functions.
   */
  modifier onlyIbcDispatcher() {
    require(msg.sender == address(dispatcher), 'only IBC dispatcher');
    _;
  }

  function updateDispatcher(IbcDispatcher _dispatcher) external onlyOwner {
    dispatcher = _dispatcher;
  }

  function getConnectedChannels() external view returns (ChannelMapping[] memory) {
    return connectedChannels;
  }

  function updateSupportedVersions(string[] memory _supportedVersions) external onlyOwner {
    supportedVersions = _supportedVersions;
  }

  /**
   * @dev Implement a function to send a packet that calls the dispatcher.sendPacket function
   *      It has the following function handle:
   *          function sendPacket(bytes32 channelId, bytes calldata payload, uint64 timeoutTimestamp) external;
   */

  /**
   * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
   *      MUST be overriden by the inheriting contract.
   *
   * @param packet the IBC packet encoded by the source and relayed by the relayer.
   */
  function onRecvPacket(IbcPacket memory packet)
    external
    virtual
    onlyIbcDispatcher
    returns (AckPacket memory ackPacket)
  {
    return AckPacket(true, abi.encodePacked('{ "account": "account", "reply": "got the message" }'));
  }

  /**
   * @dev Packet lifecycle callback that implements packet acknowledgment logic.
   *      MUST be overriden by the inheriting contract.
   *
   * @param packet the IBC packet encoded by the source and relayed by the relayer.
   * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
   */
  function onAcknowledgementPacket(
    IbcPacket calldata packet,
    AckPacket calldata ack
  ) external virtual onlyIbcDispatcher {}

  /**
   * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
   *      MUST be overriden by the inheriting contract.
   *      NOT SUPPORTED YET
   *
   * @param packet the IBC packet encoded by the counterparty and relayed by the relayer
   */
  function onTimeoutPacket(IbcPacket calldata packet) external virtual onlyIbcDispatcher {}

  /**
   * @dev Create a custom channel between two IbcReceiver contracts
   * @param local a CounterParty struct with the local chain's portId and version (channelId can be empty)
   * @param ordering the channel ordering (NONE, UNORDERED, ORDERED) equivalent to (0, 1, 2)
   * @param feeEnabled in production, you'll want to enable this to avoid spamming create channel calls (costly for relayers)
   * @param connectionHops 2 connection hops to connect to the destination via Polymer
   * @param counterparty the address of the destination chain contract you want to connect to
   * @param proof ICS23 proof struct with dummy data (only needed on ChanOpenTry)
   */
  function createChannel(
    BridgeCounterParty calldata local,
    uint8 ordering,
    bool feeEnabled,
    string[] calldata connectionHops,
    BridgeCounterParty calldata counterparty,
    Ics23Proof calldata proof
  ) external virtual onlyOwner {
    if (counterparty.destAddress != address(this)) {
      revert('Invalid counterparty address');
    }

    dispatcher.openIbcChannel(
      IbcChannelReceiver(address(this)),
      CounterParty(IbcUtils.addressToPortId(local.destPrefix, local.destAddress), local.channelId, local.version),
      ChannelOrder(ordering),
      feeEnabled,
      connectionHops,
      CounterParty(
        IbcUtils.addressToPortId(counterparty.destPrefix, counterparty.destAddress),
        counterparty.channelId,
        counterparty.version
      ),
      proof
    );
  }

  function portIdToAddress(string calldata portId) internal pure returns (address addr) {
    bytes memory portSuffix = bytes(portId)[bytes(portId).length - 40:];

    if (bytes(portSuffix).length != 40) {
      revert('invalidHexStringLength');
    }

    bytes memory strBytes = portSuffix;
    bytes memory addrBytes = new bytes(20);

    for (uint256 i = 0; i < 20; i++) {
      uint8 high = uint8(strBytes[i * 2]);
      uint8 low = uint8(strBytes[1 + i * 2]);
      // Convert to lowercase if the character is in uppercase
      if (high >= 65 && high <= 90) {
        high += 32;
      }
      if (low >= 65 && low <= 90) {
        low += 32;
      }
      uint8 digit = (high - (high >= 97 ? 87 : 48)) * 16 + (low - (low >= 97 ? 87 : 48));
      addrBytes[i] = bytes1(digit);
    }

    assembly {
      addr := mload(add(addrBytes, 20))
    }
  }

  function onOpenIbcChannel(
    string calldata version,
    ChannelOrder,
    bool,
    string[] calldata,
    CounterParty calldata counterparty
  ) external virtual onlyIbcDispatcher returns (string memory selectedVersion) {
    if (bytes(counterparty.portId).length <= 8) {
      revert invalidCounterPartyPortId();
    }

    if (portIdToAddress(counterparty.portId) != address(this)) {
      revert invalidCounterPartyPortId();
    }

    /**
     * Version selection is determined by if the callback is invoked on behalf of ChanOpenInit or ChanOpenTry.
     * ChanOpenInit: self version should be provided whereas the counterparty version is empty.
     * ChanOpenTry: counterparty version should be provided whereas the self version is empty.
     * In both cases, the selected version should be in the supported versions list.
     */
    bool foundVersion = false;
    selectedVersion =
      keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked('')) ? counterparty.version : version;
    for (uint256 i = 0; i < supportedVersions.length; i++) {
      if (keccak256(abi.encodePacked(selectedVersion)) == keccak256(abi.encodePacked(supportedVersions[i]))) {
        foundVersion = true;
        break;
      }
    }
    require(foundVersion, 'Unsupported version');
    // if counterpartyVersion is not empty, then it must be the same foundVersion
    if (keccak256(abi.encodePacked(counterparty.version)) != keccak256(abi.encodePacked(''))) {
      require(
        keccak256(abi.encodePacked(counterparty.version)) == keccak256(abi.encodePacked(selectedVersion)),
        'Version mismatch'
      );
    }

    return selectedVersion;
  }

  function onConnectIbcChannel(
    bytes32 channelId,
    bytes32 counterpartyChannelId,
    string calldata counterpartyVersion
  ) external virtual onlyIbcDispatcher {
    // ensure negotiated version is supported
    bool foundVersion = false;
    for (uint256 i = 0; i < supportedVersions.length; i++) {
      if (keccak256(abi.encodePacked(counterpartyVersion)) == keccak256(abi.encodePacked(supportedVersions[i]))) {
        foundVersion = true;
        break;
      }
    }
    require(foundVersion, 'Unsupported version');

    // do logic

    ChannelMapping memory channelMapping = ChannelMapping({channelId: channelId, cpChannelId: counterpartyChannelId});
    connectedChannels.push(channelMapping);
  }

  function onCloseIbcChannel(bytes32 _channelId, string calldata, bytes32) external virtual onlyIbcDispatcher {
    // logic to determine if the channel should be closed
    bool channelFound = false;
    for (uint256 i = 0; i < connectedChannels.length; i++) {
      if (connectedChannels[i].channelId == _channelId) {
        for (uint256 j = i; j < connectedChannels.length - 1; j++) {
          connectedChannels[j] = connectedChannels[j + 1];
        }
        connectedChannels.pop();
        channelFound = true;
        break;
      }
    }
    require(channelFound, 'Channel not found');
  }

  /**
   * This func triggers channel closure from the dApp.
   * Func args can be arbitary, as long as dispatcher.closeIbcChannel is invoked propperly.
   */
  function triggerChannelClose(bytes32 channelId) external virtual onlyOwner {
    dispatcher.closeIbcChannel(channelId);
  }
}
