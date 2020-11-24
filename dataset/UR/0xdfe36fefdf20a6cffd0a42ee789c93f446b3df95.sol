 

pragma solidity ^0.4.16;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function toUINT112(uint256 a) internal constant returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal constant returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal constant returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}

contract HelloToken {
    using SafeMath for uint256;
     
    string public constant name    = "Hello Token";   
    uint8 public constant decimals = 18;                
    string public constant symbol  = "HelloT";             
     
    
     
    struct Supplies {
         
         
        uint128 totalSupply;
    }
    
    Supplies supplies;
    
     
    struct Account {
         
         
        uint112 balance;
    }
    

     
    mapping (address => Account) public balanceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function HelloToken() public {
        supplies.totalSupply = 1*(10**10) * (10 ** 18);   
        balanceOf[msg.sender].balance = uint112(supplies.totalSupply);                 
    }
    
     
    function () {
        revert();
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from].balance >= _value);
         
        require(balanceOf[_to].balance + _value >= balanceOf[_to].balance);
         
        uint previousBalances = balanceOf[_from].balance + balanceOf[_to].balance;
         
        balanceOf[_from].balance -= uint112(_value);
         
        balanceOf[_to].balance = _value.add(balanceOf[_to].balance).toUINT112();
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from].balance + balanceOf[_to].balance == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    
     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender].balance >= _value);    
        balanceOf[msg.sender].balance -= uint112(_value);             
        supplies.totalSupply -= uint128(_value);                       
        emit Burn(msg.sender, _value);
        return true;
    }
    
     
    function totalSupply() public constant returns (uint256 supply){
        return supplies.totalSupply;
    }
}