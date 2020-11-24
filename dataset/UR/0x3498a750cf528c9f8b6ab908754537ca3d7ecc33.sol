 

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
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is owned {
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
interface ERC20Token {

  

     
     
    function balanceOf(address _owner) constant external returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
}



contract StandardToken is ERC20Token, Pausable {
 using SafeMath for uint;
  modifier onlyPayloadSize(uint size) {
     assert(msg.data.length == size.add(4));
     _;
   } 

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) whenNotPaused external returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(2 * 32) whenNotPaused external returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant external returns (uint256 balance) {
        return balances[_owner];
    }
    
     
     
     
     
    function approve(address _spender, uint256 _value) whenNotPaused public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


   
     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public _totalSupply;
}


 
contract Solarex is StandardToken{
 using SafeMath for uint;


     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'V1.0';        
    uint256 private fulltoken;
     
    event Burn(address indexed from, uint256 value);
    
 
 
 

 

    function Solarex(
        ) public{
        fulltoken = 2400000000;       
        decimals = 6;                             
        _totalSupply = fulltoken.mul(10 ** uint256(decimals));  
        balances[msg.sender] = _totalSupply;                
        name = "Solarex";                                    
        symbol = "SRX";                                
    }
     function() public {
          
          revert();
    }
         
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
           }
    }
    
       
    function totalSupply() constant public returns (uint256 supply){
        
        return _totalSupply;
    }

     
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] = balances[msg.sender].sub(_value);             
        _totalSupply = _totalSupply.sub(_value);                       
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balances[_from] >= _value);                 
        require(_value <= allowed[_from][msg.sender]);     
        balances[_from] = balances[_from].sub(_value);                          
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);              
        _totalSupply = _totalSupply.sub(_value);                               
        emit Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }
     function onlyPayForFuel() public payable onlyOwner{
         
        
    }
    function withdrawEtherFromcontract(uint _amountInwei) public onlyOwner{
        require(address(this).balance > _amountInwei);
      require(msg.sender == owner);
      owner.transfer(_amountInwei);
     
    }
	 function withdrawTokensFromContract(uint _amountOfTokens) public onlyOwner{
        require(balances[this] >= _amountOfTokens);
        require(msg.sender == owner);
	    balances[msg.sender] = balances[msg.sender].add(_amountOfTokens);                         
        balances[this] = balances[this].sub(_amountOfTokens);                   
		emit Transfer(this, msg.sender, _amountOfTokens);                
     
    }
      
}