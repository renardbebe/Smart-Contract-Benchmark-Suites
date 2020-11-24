 

pragma solidity ^0.4.11;

contract IERC20 {
      function totalSupply() constant returns (uint256 totalSupply);
      function balanceOf(address _owner) constant returns (uint balance);
      function transfer(address _to, uint _value) returns (bool success);
      function transferFrom(address _from, address _to, uint _value) returns (bool success);
      function approve(address _spender, uint _value) returns (bool success);
      function allowance(address _owner, address _spender) constant returns (uint remaining);
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }
pragma solidity ^0.4.11;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

contract E93Token is IERC20 {
    
        modifier onlyOwner {
        
         
        
        require(msg.sender == 0x3a31AC87092909AF0e01B4d8fC6E03157E91F4bb || msg.sender == 0x44fc32c2a5d18700284cc9e0e2da3ad83e9a6c5d);
            _;
        }
    
       using SafeMath for uint256;
       
       uint public totalSupply;  
       
       uint public maxSupply;  
       
       bool public optionsSet;  
       
       address public owner = 0x44fc32c2a5d18700284cc9e0e2da3ad83e9a6c5d;
       string public symbol = "E93";
       string public name = "ETH93";
       uint8 public decimals = 18;
       uint256 public RATE;
       
       bool public open;
       
       address public e93Contract;
       
       mapping(address => uint256) balances;
       mapping(address => mapping(address => uint256)) allowed;
       
       function start (uint _maxSupply, uint _RATE) onlyOwner {
            
           if (optionsSet == false) {
               maxSupply = _maxSupply;
               RATE = _RATE;
               optionsSet = true;
           }
           open = true;
       }
       
       function close() onlyOwner {
            
           open = false;
       }
       
       function setE93ContractAddress(address _e93Contract) onlyOwner {
            
           e93Contract = _e93Contract;
       }
       
       function() payable {
           
         
        if (msg.sender != e93Contract) {
            createTokens();
            }
       }
       
       function contractBalance() public constant returns (uint256) {
           return this.balance;
       }
       
       function withdraw() {
            
           uint256 usersPortion = (balances[msg.sender].mul(this.balance)).div(maxSupply);
           totalSupply = totalSupply.sub(balances[msg.sender]);
           balances[msg.sender] = 0;
           msg.sender.transfer(usersPortion);
       }
       
       function checkPayout() constant returns (uint usersPortion) {
            
           usersPortion = (balances[msg.sender].mul(this.balance)).div(maxSupply);
           return usersPortion;
       }
       
       function topup() payable {
            
       }
       
       function createTokens() payable {
           require(msg.value > 0);
           if (open != true) revert();
           uint256 tokens = msg.value.mul(RATE);
           if (totalSupply.add(tokens) > maxSupply) {
                
               uint256 amountOver = totalSupply.add(tokens).sub(maxSupply);
               balances[msg.sender] = balances[msg.sender].add(maxSupply-totalSupply);
               totalSupply = maxSupply;
               msg.sender.transfer(amountOver.div(RATE));
               owner.transfer(msg.value.sub(amountOver.div(RATE)));
           } else {
               totalSupply = totalSupply.add(tokens);
               balances[msg.sender] = balances[msg.sender].add(tokens);
               owner.transfer(msg.value);  
           }
       }
       
       function totalSupply() constant returns (uint256) {
           return totalSupply;
       }
       
       function balanceOf (address _owner) constant returns (uint256) {
           return balances[_owner];
       }
       
       function transfer(address _to, uint256 _value) returns (bool) {
           require(balances[msg.sender] >= _value && _value > 0);
           balances[msg.sender] = balances[msg.sender].sub(_value);
           balances[_to] = balances[_to].add(_value);
           Transfer(msg.sender, _to, _value);
           return true;
       }
       
       function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
           require (allowed[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0);
           balances[_from] = balances[_from].sub(_value);
           balances[_to] = balances[_to].add(_value);
           allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
           Transfer(_from, _to, _value);
           return true;
       }
       
       function approve (address _spender, uint256 _value) returns (bool) {
           allowed[msg.sender][_spender] = _value;
           Approval(msg.sender, _spender, _value);
           return true;
       }
       
       function allowance(address _owner, address _spender) constant returns (uint256) {
           return allowed[_owner][_spender];
       }
       
       event Transfer(address indexed _from, address indexed _to, uint256 _value);
       event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}