 

pragma solidity ^0.4.18;
 
 
contract Ownable {
  address public owner;
 
   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
}

 
interface IERC20 {
  function totalSupply() public constant returns (uint256 );
  function balanceOf(address _owner) public constant returns (uint256 );
  function transfer(address _to, uint256 _value) public returns (bool );
  function decimals() public constant returns (uint8 decimals);
   
   
   
   
   
}
 
contract Airdropper is Ownable {
    
    function batchTransfer(address[] _recipients, uint[] _values, address _tokenAddress) onlyOwner public returns (bool) {
        require( _recipients.length > 0 && _recipients.length == _values.length);
 
        IERC20 token = IERC20(_tokenAddress);
         

         
         
         
         
         
        
        for(uint j = 0; j < _recipients.length; j++){
            token.transfer(_recipients[j], _values[j]  );
        }
 
        return true;
    }
 
     function withdrawalToken(address _tokenAddress) onlyOwner public { 
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(owner, token.balanceOf(this)));
    }

}