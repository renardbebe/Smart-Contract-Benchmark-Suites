 

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

    function owned() public {
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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    
    using SafeMath for uint256;
    
     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20() public {}

     
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

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

}

 
 
 

contract BNDToken is owned, TokenERC20 {

    string public name = "Bind Network";
    string public symbol = "BND";
    uint8 public decimals = 18;
    
    
    uint256 public buyPrice;
    uint256 public totalSupply = 149000000e18;  
    
    
    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    function BNDToken () public {
        balanceOf[msg.sender] = totalSupply;
    }
    function () payable {
        buy();
    }
     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require(!frozenAccount[msg.sender]);
        require (balanceOf[_from] > _value);                 
        require (balanceOf[_to].add(_value) > balanceOf[_to]);  
        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        balanceOf[_to] = balanceOf[_to].add(_value);                            
        emit Transfer(_from, _to, _value);
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
    
    function withdrawEther() onlyOwner {
       require(address(this).balance >= 0 ether);
       owner.transfer(address(this).balance);
    }
   
	
     
    function buy() payable public {
        require(msg.value > 0);
        require(buyPrice > 0);
         uint amount = msg.value.mul(buyPrice); 
        _transfer(owner, msg.sender, amount);               
    }


}