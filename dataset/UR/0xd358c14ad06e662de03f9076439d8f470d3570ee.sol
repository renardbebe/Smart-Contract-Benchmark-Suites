 

pragma solidity ^0.4.11;

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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
 
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  
   
  event Approval(address indexed _owner, address indexed _spender, uint _value);
   
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;
  
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

     
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
     
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

contract JOP is StandardToken, Ownable {
    string public constant name = "JopCoin";
    string public constant symbol = "JOP";
    uint public constant decimals = 18;
    
    uint public price ;
    uint public mintTimes;
    address public receiver;
    
    mapping(address=>bool) public freezeList;
    
     
    event DoMint(uint n,uint number);
    event Burn(address indexed from, uint256 value);
    
    function JOP(uint _price){
        receiver = msg.sender;
        price =_price;  
        totalSupply=500*(10**4)*10**decimals;  
         
        balances[msg.sender] = totalSupply; 
        Transfer(address(0x0), msg.sender, totalSupply);
    }
    
    modifier validUser(address addr){
        if(freezeList[addr] || addr ==address(0x0)) throw;
        _;
    }
    
    function addFreezeList(address addr) onlyOwner returns(bool)  {
        if(!freezeList[addr]){
            freezeList[addr] =true;
            return true;
        }else{
            return false;
        }
    }
    
     
    function deleteFreezeList(address addr) onlyOwner returns(bool){
        if(freezeList[addr]){
            delete freezeList[addr];
            return true;
        }else{
            return false;
        }
    }
    
    function setPrice(uint _price) onlyOwner{
        require( _price > 0);
        price= _price;
    }
    
    function destroy() onlyOwner{
        suicide(owner);
    }
    
    function transfer(address _to, uint _value) validUser(msg.sender) returns (bool){
        if(_value <= 10**decimals/10) throw;  
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value - 10**decimals/10);
        balances[receiver] = balances[receiver].add(10**decimals/10);
        Transfer(msg.sender, _to, _value - 10**decimals/10);
        return true;
    }
    
    function mint(uint num) onlyOwner{
        balances[owner] = balances[owner].add(num*(10**decimals));
        totalSupply = totalSupply.add(num*(10**decimals));
        DoMint(mintTimes++,num*(10**decimals));
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value); 
        balances[msg.sender] -= _value; 
        totalSupply -= _value;   
        Transfer(msg.sender, address(0x0), _value);
        Burn(msg.sender, _value);
        return true;
    }
    
    function changeReceiver(address _receiver) onlyOwner{
        if(_receiver == address(0x0)) throw;
        receiver = _receiver;
    }
    
    function () payable{
        uint tokens = price.mul(msg.value);
        if(tokens <= balances[owner]){
            balances[owner] = balances[owner].sub(tokens);
            balances[msg.sender] = balances[msg.sender].add(tokens);
            receiver.transfer(msg.value);
            Transfer(owner, msg.sender, tokens);
        }else{
            throw;
        }
    }
}