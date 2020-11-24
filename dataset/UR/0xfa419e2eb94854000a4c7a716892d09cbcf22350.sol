 

pragma solidity ^0.4.16;

contract Ownable {

  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

interface Token {
  function transfer(address _to, uint256 _value) returns (bool);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract AirDrop is Ownable {

  Token token;

  event TransferredToken(address indexed to, uint256 value);
  event FailedTransfer(address indexed to, uint256 value);
  
  function sendTokens(address tokenAddr, address[] dests, uint256[] values) onlyOwner external {
    uint256 i = 0;

    while (i < dests.length) {
        uint256 toSend = values[i] * 10**18;
        sendInternally(tokenAddr, dests[i] , toSend, values[i]);
        i++;
    }
  }

  function sendTokensSingleValue(address tokenAddr, address[] dests, uint256 value) onlyOwner external {
    uint256 i = 0;
    uint256 toSend = value * 10**18;
    
    while (i < dests.length) {
        sendInternally(tokenAddr, dests[i] , toSend, value);
        i++;
    }
  }  

  function sendInternally(address tokenAddr, address recipient, uint256 tokensToSend, uint256 valueToPresent) internal {
    if(recipient == address(0)) return;

    if(tokensAvailable(tokenAddr) >= tokensToSend) {
      Token(tokenAddr).transfer(recipient, tokensToSend);
      TransferredToken(recipient, valueToPresent);
    } else {
      FailedTransfer(recipient, valueToPresent); 
    }
  }   

  function tokensAvailable(address tokenAddr) constant returns (uint256) {
    return Token(tokenAddr).balanceOf(this);
  }
}