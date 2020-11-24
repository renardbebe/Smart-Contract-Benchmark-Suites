 

pragma solidity ^0.4.18;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {
    
  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function transferOwnership(address newOwner) internal onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


 
 
contract UnlimitedAllowanceToken is StandardToken {
    
     
    uint256 constant MAX_UINT = 2**256 - 1;
    
      
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value);
        require(allowance >= _value);
        require(balances[_to].add(_value) >= balances[_to]);
        
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        if (allowance < MAX_UINT) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }  
        Transfer(_from, _to, _value);
        
        return true;
    }
}

 
contract EtherToken is UnlimitedAllowanceToken, Ownable{
    using SafeMath for uint256; 
    
    string constant public name = "Ether Token";
    string constant public symbol = "WXETH";
    uint256 constant public decimals = 18; 
    
     
    event Issuance(uint256 _amount);
    
     
    event Destruction(uint256 _amount);
    
     
    bool public enabled;
    
     
    address public safetyWallet; 
    
     
    function EtherToken() public {
        enabled = true;
        safetyWallet = msg.sender;
    }
    
     
    function blockTx(bool _disableTx) public onlyOwner { 
        enabled = !_disableTx;
    }
    
     
    function moveToSafetyWallet() public onlyOwner {
        require(!enabled); 
        require(totalSupply > 0);
        require(safetyWallet != 0x0);
        
         
        uint256 _amount = totalSupply;
        totalSupply = totalSupply.sub(totalSupply); 
        
         
        Transfer(safetyWallet, this, totalSupply);
        Destruction(totalSupply);
        
         
        safetyWallet.transfer(_amount);  
    }
    
     
    function () public payable {
        require(enabled);
        deposit(msg.sender);
    }
    
     
    function deposit(address beneficiary) public payable {
        require(enabled);
        require(beneficiary != 0x0);  
        require(msg.value != 0);  
        
        balances[beneficiary] = balances[beneficiary].add(msg.value);
        totalSupply = totalSupply.add( msg.value);
        
         
        Issuance(msg.value);
        Transfer(this, beneficiary, msg.value);
    }
    
     
    function withdraw(uint256 _amount) public {
        require(enabled);
        withdrawTo(msg.sender, _amount);
    }
    
     
    function withdrawTo(address _to, uint _amount) public { 
        require(enabled);
        require(_to != 0x0);
        require(_amount != 0);  
        require(_amount <= balances[_to]); 
        require(this != _to);
        
        balances[_to] = balances[_to].sub(_amount);
        totalSupply = totalSupply.sub(_amount); 
        
         
        Transfer(msg.sender, this, _amount);
        Destruction(_amount);
        
          
        _to.transfer(_amount);  
    }
}