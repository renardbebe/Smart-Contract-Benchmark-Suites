 

pragma solidity ^0.4.21;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
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
        owner = newOwner;
    }
}

 
contract Pausable is owned {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(false == paused);
    _;
  }

   
  modifier whenPaused {
    require(true == paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused public returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract CustomToken is Pausable{
    using SafeMath for uint256;
    
     
    string public name;
    string public symbol;
    uint8 public decimals;
    
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function CustomToken (
        string tokenName,
        string tokenSymbol
    ) public {
        decimals = 18;
        name = tokenName;                                            
        symbol = tokenSymbol;                                        
    }
    
     
    function transfer(address _to, uint256 _value) whenNotPaused public {
        _transfer(msg.sender, _to, _value);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
}

 
 
 

contract GMCToken is CustomToken {
    string tokenName        = "GMCToken";         
    string tokenSymbol      = "GMC";              
        
    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);
     
    event Burn(address indexed from, uint256 value);

     
    function GMCToken() CustomToken(tokenName, tokenSymbol) public {}

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] = balanceOf[_from].sub(_value);     
        balanceOf[_to] = balanceOf[_to].add(_value);         
        emit Transfer(_from, _to, _value);
    }
    
     
     
    function mintToken(uint256 mintedAmount) onlyOwner public {
        uint256 mintSupply = mintedAmount.mul(10 ** uint256(decimals));
        balanceOf[msg.sender] = balanceOf[msg.sender].add(mintSupply);
        totalSupply = totalSupply.add(mintSupply);
        emit Transfer(0, this, mintSupply);
        emit Transfer(this, msg.sender, mintSupply);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
     
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);                        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);       
        totalSupply = totalSupply.sub(_value);                           
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);                     
        balanceOf[_from] = balanceOf[_from].sub(_value);         
        totalSupply = totalSupply.sub(_value);                   
        emit Burn(_from, _value);
        return true;
    }
}