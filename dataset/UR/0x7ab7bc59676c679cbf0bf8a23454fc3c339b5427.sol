 

pragma solidity >0.4.99 <0.6.0;

contract Username {
  string public constant version = '0.3.0';
  event Updated(address indexed user, string indexed username);

  mapping(address => string) public username;
  mapping(string => address) public owner;
  mapping(string => string) public caseMap;

  string constant availableChrs = 'abcdefghijklmnopqrstuvwxyz0123456789';
  string constant symbols = "_-.";

  bytes bAvailableChrs = bytes(availableChrs);
  bytes bSymbols = bytes(symbols);

  function getUsername(address addr) public view returns (string memory) {
    return caseMap[username[addr]];
  }

  function getOwner(string memory username) public view returns (address) {
    return owner[toLower(username)];
  }

  function isSymbol(bytes1 chr) internal view returns (bool result) {
    for (uint8 i = 0; i < bSymbols.length; i++) {
      if (chr == bSymbols[i]) {
        return true;
      }
    }
    return false;
  }

  function isAlphaNumeric(bytes1 chr) internal view returns (bool result) {
    for (uint8 i = 0; i < bAvailableChrs.length; i++) {
      if (chr == bAvailableChrs[i]) {
        return true;
      }
    }
    return false;
  }

  function toLower(string memory str) public view returns (string memory) {
    bytes memory bStr = bytes(str);
		bytes memory bLower = new bytes(bStr.length);
    for (uint8 i = 0; i < bStr.length; i++) {
      if (uint8(bStr[i]) > 65 && uint8(bStr[i]) <= 90) {
        bLower[i] = bytes1(uint8(bStr[i]) + 32);
      } else {
        bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }

  function validate(string memory str) public view returns (bool result) {
    bytes memory bStr = bytes(str);
    if (bStr.length < 1 || bStr.length > 20) {
      return false;
    }
    bool continuousFlag = false;
    for (uint8 i = 0; i < bStr.length; i++) {
      if (isSymbol(bStr[i])) {
        if (i == 0 || i == bStr.length - 1 || continuousFlag) {
          return false;
        }
        continuousFlag = true;
      } else if (isAlphaNumeric(bStr[i])) {
        continuousFlag = false;
      } else  {
        return false;
      }
    }
    return true;
  }

  function update(string memory _username) public {
    string memory lowerUsername = toLower(_username);
    if (owner[lowerUsername] != address(0) && owner[lowerUsername] != msg.sender) {
      revert("Username already used");
    }

    require(validate(lowerUsername));

    string memory oldUserName = username[msg.sender];

    owner[oldUserName] = address(0);
    owner[lowerUsername] = msg.sender;

    username[msg.sender] = lowerUsername;

    caseMap[oldUserName] = "";
    caseMap[lowerUsername] = _username;

    emit Updated(msg.sender, _username);
  }
}