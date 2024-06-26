// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './UniversalChanIbcApp.sol';
import {PolyERC20} from './PolyERC20.sol';
import {receiverNotOriginPacketSender} from '@open-ibc/vibc-core-smart-contracts/contracts/libs/Ibc.sol';

contract PolyERC20FixedSupply is PolyERC20 {
  constructor(string memory _name, string memory _symbol, uint256 tokenSupply) PolyERC20(_name, _symbol) {
    _mint(msg.sender, tokenSupply);
  }

  function mint(address account, uint256 amount) public virtual override onlyOwner {
    revert('minting disabled');
  }

  function burn(address account, uint256 amount) public virtual override onlyOwner {
    revert('burning disabled');
  }
}

contract PolyERC20Factory is UniversalChanIbcApp {
  event TokenMint(address indexed token, address indexed receiver, uint256 amount);
  event BridgeSuccess(bytes32 indexed channelId);
  event BridgeFailure(bytes32 indexed channelId);

  constructor() UniversalChanIbcApp() {}

  function salt(string memory _salt) internal returns (bytes32) {
    return keccak256(bytes(_salt));
  }

  function deployXPolyERC20(
    string[] memory channels,
    string memory _name,
    string memory _symbol,
    uint256 _tokenSupply,
    string memory _salt
  ) external returns (PolyERC20FixedSupply token) {
    return this.deployXPolyERC20(channels, _name, _symbol, _tokenSupply, _salt, 60);
  }

  function deployXPolyERC20(
    string[] memory channels,
    string memory _name,
    string memory _symbol,
    uint256 _tokenSupply,
    string memory _salt,
    uint64 timeoutSeconds
  ) external returns (PolyERC20FixedSupply token) {
    // deploy on the current chain
    token = this.deployPolyERC20(_name, _symbol, _tokenSupply, _salt);

    // deploy to other chains
    for (uint256 i = 0; i < channels.length; i++) {
      bytes memory payload = abi.encode(msg.sender, _name, _symbol, _tokenSupply, _salt);

      uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1_000_000_000);

      IbcUniversalPacketSender(mw).sendUniversalPacket(
        IbcUtils.toBytes32(channels[i]), IbcUtils.toBytes32(address(this)), payload, timeoutTimestamp
      );
    }
    return token;
  }

  function deployPolyERC20(
    string memory _name,
    string memory _symbol,
    uint256 _tokenSupply,
    string memory _salt
  ) external returns (PolyERC20FixedSupply token) {
    token = new PolyERC20FixedSupply{salt: salt(_salt)}(_name, _symbol, _tokenSupply);
    return token;
  }

  function onRecvUniversalPacket(
    bytes32 channelId,
    UniversalPacket calldata packet
  ) external override onlyIbcMw returns (AckPacket memory ackPacket) {
    if (packet.srcPortAddr != packet.destPortAddr) {
      revert receiverNotOriginPacketSender();
    }

    (address sender, string memory _name, string memory _symbol, uint256 _tokenSupply, string memory _salt) =
      abi.decode(packet.appData, (address, string, string, uint256, string));

    PolyERC20FixedSupply token = this.deployPolyERC20(_name, _symbol, _tokenSupply, _salt);
    emit TokenMint(address(token), sender, _tokenSupply);

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

    (address sender, string memory _name, string memory _symbol, uint256 _tokenSupply, string memory _salt) =
      abi.decode(packet.appData, (address, string, string, uint256, string));

    if (ack.success) {
      emit BridgeSuccess(channelId);
      (address receiver) = abi.decode(ack.data, (address));
    } else {
      emit BridgeFailure(channelId);
    }
  }

  function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override onlyIbcMw {
    if (packet.srcPortAddr != packet.destPortAddr) {
      revert receiverNotOriginPacketSender();
    }

    (address sender, string memory _name, string memory _symbol, uint256 _tokenSupply, string memory _salt) =
      abi.decode(packet.appData, (address, string, string, uint256, string));
    emit BridgeFailure(channelId);
  }
}
