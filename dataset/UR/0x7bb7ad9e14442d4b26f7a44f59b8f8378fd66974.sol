 

pragma solidity ^0.4.18;

contract STQDistribution {
  address public mintableTokenAddress;
  address public owner;

  function STQDistribution(address _mintableTokenAddress) public {
    mintableTokenAddress = _mintableTokenAddress;
    owner = msg.sender;
  }

   
  function encodeTransfer (uint96 _lotsNumber, address _to)
  public pure returns (uint256 _encodedTransfer) 
  {
    return (_lotsNumber << 160) | uint160 (_to);
  }

   
  function batchSend (Token _token, uint160 _lotSize, uint256[] _transfers) public {
    require(msg.sender == owner);
    MintableToken token = MintableToken(mintableTokenAddress);
    uint256 count = _transfers.length;
    for (uint256 i = 0; i < count; i++) {
      uint256 transfer = _transfers[i];
      uint256 value = (transfer >> 160) * _lotSize;
      address to = address(transfer & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      token.mint(to, value);
    }
  }
}

contract MintableToken {
  function mint(address _to, uint256 _amount) public;
}

 
contract Token {
     
    function totalSupply ()
    public constant returns (uint256 supply);

     
    function balanceOf (address _owner)
    public constant returns (uint256 balance);

     
    function transfer (address _to, uint256 _value)
    public returns (bool success);

     
    function transferFrom (address _from, address _to, uint256 _value)
    public returns (bool success);

     
    function approve (address _spender, uint256 _value)
    public returns (bool success);

     
    function allowance (address _owner, address _spender)
    public constant returns (uint256 remaining);

     
    event Transfer (address indexed _from, address indexed _to, uint256 _value);

     
    event Approval (
        address indexed _owner, address indexed _spender, uint256 _value);
}