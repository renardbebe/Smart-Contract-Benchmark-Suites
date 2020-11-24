 

pragma solidity ^0.4.4;


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

 
 
contract ERC20 
{
 
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256);

 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract Owned {
     
    address public owner;

     
    function setOwner(address _owner) onlyOwner
    { owner = _owner; }

     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }
}


contract ArbitrageCtCrowdsale is Owned {
    event Print(string _name, uint _value);
    
    using SafeMath for uint;
    
    address public multisig = 0xe98bdde8edbfc6ff6bb8804077b6be9d4401a71d; 

    address public addressOfERC20Tocken = 0x1245ef80F4d9e02ED9425375e8F649B9221b31D8;
    ERC20 public token;
    
    
    uint public startICO = now; 
    uint public endICO = 1515974400;  
    
    uint public tokenETHAmount = 75000 * 100000000;
   
    function tokenBalance() constant returns (uint256) {
        return token.balanceOf(address(this));
    } 
    
    function ArbitrageCtCrowdsale(){ 
        owner = msg.sender;
        token = ERC20(addressOfERC20Tocken);
         
    }
    
     
    
    
    function transferToken(address _to, uint _value) onlyOwner returns (bool) {
        return token.transfer(_to,  _value);
    }
    
    function() payable {
        doPurchase();
    }

    function doPurchase() payable {
        require(now >= startICO && now < endICO);

        require(msg.value >= 10000000000000000);  
        
        uint sum = msg.value;
        
        uint tokensAmount;
        
        tokensAmount = sum.mul(tokenETHAmount).div(1000000000000000000); 

        
         
        if(sum >= 100 * 1000000000000000000){
           tokensAmount = tokensAmount.mul(110).div(100);
        } else if(sum >= 50 * 1000000000000000000){
           tokensAmount = tokensAmount.mul(109).div(100);
        } else if(sum >= 30 * 1000000000000000000){
           tokensAmount = tokensAmount.mul(108).div(100);
        } else if(sum >= 20 * 1000000000000000000){
           tokensAmount = tokensAmount.mul(107).div(100);
        } else if(sum >= 10 * 1000000000000000000){
           tokensAmount = tokensAmount.mul(106).div(100);
        } else if(sum >= 7 * 1000000000000000000){
           tokensAmount = tokensAmount.mul(105).div(100);
        } else if(sum >= 5 * 1000000000000000000){
           tokensAmount = tokensAmount.mul(104).div(100);
        } else if(sum >= 3 * 1000000000000000000){
           tokensAmount = tokensAmount.mul(103).div(100);
        } else if(sum >= 2 * 1000000000000000000){
           tokensAmount = tokensAmount.mul(102).div(100);
        } else if(sum >= 1 * 1000000000000000000){
           tokensAmount = tokensAmount.mul(101).div(100);
        } else if(sum >=  500000000000000000){
           tokensAmount = tokensAmount.mul(1005).div(1000);
        }

        require(tokenBalance() > tokensAmount);
        
        require(token.transfer(msg.sender, tokensAmount));
        multisig.transfer(msg.value);
        
        
    }
    
    
}