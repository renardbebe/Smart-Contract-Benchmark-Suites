 

pragma solidity ^0.4.11;

contract ERC20Basic {
 
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

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
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


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}


contract Whizz is StandardToken,Ownable{
      
      
      string public constant name = "Whizz Coin";
      string public constant symbol = "WHZ";
      uint8 public constant decimals = 3; 
      
     
    
      uint256 public constant maxTokens = 67500000*1000; 
       
      uint256 public constant otherSupply = maxTokens*592/1000;
      uint256 _initialSupply = otherSupply;
      uint256 public constant token_price = 600*10**3; 
      uint public constant ico_start = 1507221000;
      uint public constant ico_finish = 1514851200; 
      uint public constant minValue = 1/10*10**18;
      address public wallet = 0x5F217D83784192d397039Ed6E30e796bFB91B9c4;
      
       
      
      uint256 public constant weicap = 13500*10**18;
      uint256 public weiRaised;
      
      
      
      using SafeMath for uint;      
      
       
 
      function Whizz() {
          balances[owner] = otherSupply;    
      }
      
       
      function() payable {        
          tokens_buy();        
      }
      
      
      function totalSupply() constant returns (uint256 totalSupply) {
          totalSupply = _initialSupply;
      }
   
      
             
      function withdraw() onlyOwner returns (bool result) {
          wallet.transfer(this.balance);
          return true;
      }
   
     
 
       

      
            
      function tokens_buy() payable returns (bool) { 

        if((now < ico_start)||(now > ico_finish)) throw;        
        if(_initialSupply >= maxTokens) throw;
        if(!(msg.value >= token_price)) throw;
        if(!(msg.value >= minValue)) throw;

        uint tokens_buy = ((msg.value*token_price)/10**18);
         
        weiRaised = weiRaised.add(msg.value);

        if(!(tokens_buy > 0)) throw;        

        uint tnow = now;

        if((ico_start + 86400*0 <= tnow)&&(tnow <= ico_start + 86400*28)&&(weiRaised <= weicap)){
          tokens_buy = tokens_buy*120/100;
        } 
        
              
        if(_initialSupply.add(tokens_buy) > maxTokens) throw;
        _initialSupply = _initialSupply.add(tokens_buy);
        balances[msg.sender] = balances[msg.sender].add(tokens_buy);        

      }

      
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