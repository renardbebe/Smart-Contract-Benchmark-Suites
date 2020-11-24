 

pragma solidity ^0.4.24;

contract Ownable {

  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) constant external returns (uint256 balance);
}

contract VoiceAirdrop is Ownable {

  Token token;

  event TransferredToken(address indexed to, uint256 value);
  event FailedTransfer(address indexed to, uint256 value);

  modifier whenDropIsActive() {
    assert(isActive());

    _;
  }

  constructor() public {
      address _tokenAddr = 0x99637cBdef67d8Ac94af0D5f321Ea37414A3b7B0;  
      token = Token(_tokenAddr);
  }

  function isActive() constant public returns (bool) {
    return (
        tokensAvailable() > 0  
    );
  }
   
  function sendTokens(address[] dests, uint256[] values) whenDropIsActive onlyOwner external {
    uint256 i = 0;
    while (i < dests.length) {
        uint256 toSend = values[i] * 10**18;
        sendInternally(dests[i] , toSend, values[i]);
        i++;
    }
  }

   
  function sendTokensSingleValue(address[] dests, uint256 value) whenDropIsActive onlyOwner external {
    uint256 i = 0;
    uint256 toSend = value * 10**18;
    while (i < dests.length) {
        sendInternally(dests[i] , toSend, value);
        i++;
    }
  }  

  function sendInternally(address recipient, uint256 tokensToSend, uint256 valueToPresent) internal {
    if(recipient == address(0)) return;

    if(tokensAvailable() >= tokensToSend) {
      token.transfer(recipient, tokensToSend);
      emit TransferredToken(recipient, valueToPresent);
    } else {
      emit FailedTransfer(recipient, valueToPresent); 
    }
  }   


  function tokensAvailable() constant public returns (uint256) {
    return token.balanceOf(this);
  }

  function destroy() onlyOwner public{
    uint256 balance = tokensAvailable();
    require (balance > 0);
    token.transfer(owner, balance);
    selfdestruct(owner);
  }
}