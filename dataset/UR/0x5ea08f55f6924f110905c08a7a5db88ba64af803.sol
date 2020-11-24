 

pragma solidity ^0.4.23;
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
}


contract owned {
    address public owner;
    
    constructor () public {
      owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != 0x0);
        require(newOwner != owner);
        owner = newOwner;
    }
    
   
}


contract TokenERC20 {
    
    using SafeMath for uint256;
    
     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);


     
    constructor () public {}

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] =allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        require(_spender != 0x0);    
        allowance[msg.sender][_spender] = _value;
        return true;
    }

   
}

 
 
 

contract INVToken is owned,TokenERC20 {

    string public name = "INVESTACOIN";
    string public symbol = "INV";
    uint8 public decimals = 18;
    address private paymentAddress = 0x75B42A1AB0e23e24284c8E0E8B724472CF8623Cd;
    
    
    uint256 public buyPrice;
    uint256 public totalSupply = 50000000e18;  
    
    
    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
   constructor () public owned() TokenERC20()  {
        balanceOf[msg.sender] = totalSupply;
        
    }
    
    
    function () payable {
        buy();
    }
    
     
  function transferFrom(address _from, address _to, uint256 _value)
    returns (bool success) {
	require(!frozenAccount[_from]);
    return TokenERC20.transferFrom(_from, _to, _value);
  }
  
   
  function transfer(address _to, uint256 _value) public {
    require(!frozenAccount[msg.sender]);
    return TokenERC20.transfer(_to, _value);
  }


     
     
     
    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
     
    function setbuyPrice( uint256 newBuyPrice) onlyOwner public {
        require(newBuyPrice > 0);
        buyPrice = newBuyPrice;
    }
    
    function transferPaymentAddress(address newPaymentAddress) onlyOwner public {
        require(newPaymentAddress != 0x0);
        require(newPaymentAddress != paymentAddress);
        paymentAddress = newPaymentAddress;
    }
    
	
     
    function buy() payable public {
        require(msg.value > 0);
        require(buyPrice > 0);
        paymentAddress.transfer(msg.value);      
     
    }


}