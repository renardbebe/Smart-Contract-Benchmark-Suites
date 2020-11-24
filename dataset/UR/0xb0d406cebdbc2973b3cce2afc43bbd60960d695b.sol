 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
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
  
}

 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
    
  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

 

contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
     
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}

contract ANWTokenCoin is MintableToken {
    
    string public constant name = "Animal Welfare Token Contract";
    
    string public constant symbol = "ANW";
    
    uint32 public constant decimals = 18;
    
}




contract ANWCrowdsale is Ownable {
    using SafeMath for uint;
    
    address manager = 0xD87060B9c16a099ac7D76A3Ff275D4c80e732118;
    address public multisig = 0x99FDbd0d52ba6fcd49b4B5c149D37E4e1326BE7d; 
    ANWTokenCoin public token = new ANWTokenCoin(); 
    uint public tokenDec = 1000000000000000000;
    uint public tokenPrice = 10000000000000000;
    bool ifInit = false;


    
    
    function ANWCrowdsale(){
        owner = msg.sender; 
    }
    
    function initMinting() onlyOwner returns (bool) {
        require(!ifInit);
        require(token.mint(manager, tokenDec.mul(10000000)));
        require(token.mint(address(this), tokenDec.mul(10000000)));
         
        token.transferOwnership(manager);
        transferOwnership(manager);
        
        ifInit = true;
        return true;
    } 
    
    function tokenBalance() constant returns (uint256) {
        return token.balanceOf(address(this));
    }        
    
    
    function transferToken(address _to, uint _value) onlyOwner returns (bool) {
        return token.transfer(_to,  _value);
    }
    
    function() payable {
        doPurchase();
    }

    function doPurchase() payable {

        require(msg.value > 0); 
        
        uint tokensAmount = msg.value.mul(tokenDec).div(tokenPrice);
        
        require(token.transfer(msg.sender, tokensAmount));
        multisig.transfer(msg.value);
        
        
    }
    
    
 
}