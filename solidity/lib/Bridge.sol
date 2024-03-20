function portIdToAddress(string calldata portId) returns (address addr) {
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
