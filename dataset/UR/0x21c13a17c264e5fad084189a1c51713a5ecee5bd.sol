 

pragma solidity ^0.4.18;
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface Token {
  function balanceOf(address _owner) public constant returns (uint256 );
  function transfer(address _to, uint256 _value) public ;
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract Airdropper is Ownable {
    
    function AirTransfer(address[] _recipients, uint _values, address _tokenAddress) onlyOwner public returns (bool) {
        require(_recipients.length > 0);

        Token token = Token(_tokenAddress);
        
        for(uint j = 0; j < _recipients.length; j++){
            token.transfer(_recipients[j], _values);
        }
 
        return true;
    }
 
     function withdrawalToken(address _tokenAddress) onlyOwner public { 
        Token token = Token(_tokenAddress);
        token.transfer(owner, token.balanceOf(this));
    }

}