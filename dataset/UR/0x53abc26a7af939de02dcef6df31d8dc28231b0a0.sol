 

pragma solidity ^0.4.12;

 

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b > 0);  
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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

   
}


 

contract BingoToken is StandardToken, Ownable {
 
    string public constant name = "BINGO TOKEN"; 
    string public constant symbol = "BGT"; 
    uint public constant decimals = 18;  
    uint256 public constant initialSupply = 300000000 * (10 ** uint256(decimals)); 
    
    uint256 public startAt;
    uint256 public priceInWei ;
    

     
    function BingoToken(uint256 startat, uint256 priceinWei) {
        
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;  
        startAt = startat;
        priceInWei=priceinWei;
    }
    
    
    function() payable{
        
        buy();
    }
    
    function buy()  payable returns(bool){
        
        require(now > startAt && now <=startAt + 45 days);
       
        
        uint256 weiAmount = msg.value;
        
        uint256 tokenAmount = weiAmount.mul(priceInWei).div(10 ** uint256(decimals));   
        
        
       
        if(now > startAt && now <= startAt + 10 days){
            
            balances[owner] = balances[owner].sub(tokenAmount.mul(2));
            
            balances[msg.sender] = balances[msg.sender].add(tokenAmount.mul(2));
            
            owner.transfer(weiAmount);
    
            Transfer(owner, msg.sender, tokenAmount.mul(2));
            
        }else if(now > startAt + 10 days && now <= startAt+ 20 days){
            
            tokenAmount =tokenAmount + tokenAmount.mul(3).div(4);
            
            balances[owner] = balances[owner].sub(tokenAmount);
            
            balances[msg.sender] = balances[msg.sender].add(tokenAmount);
            
            owner.transfer(weiAmount);
            
            Transfer(owner, msg.sender, tokenAmount);
    
        }else if(now > startAt + 20 days && now <= startAt+ 30 days){
            
            tokenAmount = tokenAmount + tokenAmount.div(2);
            
            balances[owner] = balances[owner].sub(tokenAmount);
            
            balances[msg.sender] = balances[msg.sender].add(tokenAmount);
            
            owner.transfer(weiAmount);
        
            Transfer(owner, msg.sender, tokenAmount);
            
        }else if(now > startAt + 30 days && now <= startAt + 40 days){
            
            tokenAmount = tokenAmount + tokenAmount.div(4);
             
            balances[owner] = balances[owner].sub(tokenAmount);
            
            balances[msg.sender] = balances[msg.sender].add(tokenAmount);
            
            owner.transfer(weiAmount);
            
            Transfer(owner, msg.sender, tokenAmount);
            
        }else if(now > startAt + 40 days && now <= startAt+ 45 days){
           
              
            balances[owner] = balances[owner].sub(tokenAmount);
            
            balances[msg.sender] = balances[msg.sender].add(tokenAmount);
            
            owner.transfer(weiAmount);
    
            Transfer(owner, msg.sender, tokenAmount);
            
        } 
        
        return true;
        
    }
    
    function allocate(address addr, uint256 amount) onlyOwner returns(bool){
        
        require(addr != address(0));
        
        transfer(addr, amount);
        
        return true;
    }
    
    
     
    
    
    
}