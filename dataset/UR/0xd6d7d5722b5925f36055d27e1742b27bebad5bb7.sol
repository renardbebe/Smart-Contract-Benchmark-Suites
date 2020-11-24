 

pragma solidity ^0.4.16;

contract FooToken {

     
      string public constant name = "TEN FOOLS";
  string public constant symbol = "TEFOO";
    uint8 public decimals = 1;
     
	uint256 _totalSupply = 100000;

     
    mapping (address => uint256) public balanceOf;
   
     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function FooToken (
        
        
    ) public {
          balanceOf[msg.sender] = _totalSupply;                 
        
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

   
}