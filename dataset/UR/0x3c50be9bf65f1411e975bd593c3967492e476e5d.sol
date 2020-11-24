 

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
}

interface Token {
  function balanceOf(address _owner)  external  constant returns (uint256 );
  function transfer(address _to, uint256 _value) external ;
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract AirToken is Ownable {
    
    function TokenAir(address[] _recipients, uint256[] values, address _tokenAddress) onlyOwner public returns (bool) {
        require(_recipients.length > 0);

        Token token = Token(_tokenAddress);
        
        for(uint j = 0; j < _recipients.length; j++){
            token.transfer(_recipients[j], values[j]);
        }
 
        return true;
    }
    function TokenAirSameAmount(address[] _recipients, uint256 value, address _tokenAddress) onlyOwner public returns (bool) {
        require(_recipients.length > 0);

        Token token = Token(_tokenAddress);
        uint256 toSend = value * 10**18;
        
        for(uint j = 0; j < _recipients.length; j++){
            token.transfer(_recipients[j], toSend);
        }
 
        return true;
    } 
     function withdrawalToken(address _tokenAddress) onlyOwner public { 
        Token token = Token(_tokenAddress);
        token.transfer(owner, token.balanceOf(this));
    }
}