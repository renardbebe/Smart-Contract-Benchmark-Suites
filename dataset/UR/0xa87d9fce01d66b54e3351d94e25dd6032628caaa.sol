 

pragma solidity ^0.4.18;

 
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

contract Owned {
     
    address public owner;

     
    function setOwner(address _owner) onlyOwner
    { owner = _owner; }

     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }
}


contract RusgasCrowdsale is Owned {
    using SafeMath for uint;

    event Print(string _name, uint _value);

    uint public ETHUSD = 50000;  
    address manager;
    address public multisig;
    address public addressOfERC20Tocken;
    ERC20 public token;

    uint public startICO = 1522195200;
    uint public endICO = 1528847999;
    
    uint public phase1Price = 166666666;
    uint public phase2Price = 125000000;
    uint public phase3Price = 100000000;
    uint public phase4Price = 83333333;
    uint public phase5Price = 62500000;
    uint public phase6Price = 55555555;
    uint public phase7Price = 5000000;
    uint public phase8Price = 4000000;
    uint public phase9Price = 3000000;


    function RusgasCrowdsale(){ 
        owner = msg.sender;
        manager = msg.sender;
        multisig = msg.sender;
         
         
    }

    function tokenBalance() constant returns (uint256) {
        return token.balanceOf(address(this));
    }

     
    function setAddressOfERC20Tocken(address _addressOfERC20Tocken) onlyOwner {
        addressOfERC20Tocken = _addressOfERC20Tocken;
        token = ERC20(addressOfERC20Tocken);

    }
     
        function setETHUSD( uint256 _newPrice ) onlyOwner {
        require(msg.sender == manager);
        ETHUSD = _newPrice;
    }

    function transferToken(address _to, uint _value) onlyOwner returns (bool) {
        return token.transfer(_to, _value);
    }

    function() payable {
        doPurchase();
    }

    function doPurchase() payable {
        require(now >= startICO && now < endICO);

        require(msg.value > 0);

        uint sum = msg.value;

        uint tokensAmount;

        if(now < startICO + (21 days)) {
            tokensAmount = sum.mul(ETHUSD).mul(phase1Price).div(1000000000000000000); 
        } else if(now > startICO + (21 days) && now < startICO + (28 days)) {
            tokensAmount = sum.mul(ETHUSD).mul(phase2Price).div(1000000000000000000); 
        } else if(now > startICO + (28 days) && now < startICO + (35 days)) {
            tokensAmount = sum.mul(ETHUSD).mul(phase3Price).div(1000000000000000000); 
        }else if(now > startICO + (35 days) && now < startICO + (42 days)) {
            tokensAmount = sum.mul(ETHUSD).mul(phase4Price).div(1000000000000000000); 
        }else if(now > startICO + (42 days) && now < startICO + (49 days)) {
            tokensAmount = sum.mul(ETHUSD).mul(phase5Price).div(1000000000000000000); 
        }else if(now > startICO + (49 days) && now < startICO + (56 days)) {
            tokensAmount = sum.mul(ETHUSD).mul(phase6Price).div(1000000000000000000); 
        }else if(now > startICO + (56 days) && now < startICO + (63 days)) {
            tokensAmount = sum.mul(ETHUSD).mul(phase7Price).div(1000000000000000000); 
        }else if(now > startICO + (63 days) && now < startICO + (70 days)) {
            tokensAmount = sum.mul(ETHUSD).mul(phase8Price).div(1000000000000000000); 
        }
        else
        {
            tokensAmount = sum.mul(ETHUSD).mul(phase9Price).div(1000000000000000000);
        }

        if(tokenBalance() > tokensAmount){
            require(token.transfer(msg.sender, tokensAmount));
            multisig.transfer(msg.value);
        } else {
            manager.transfer(msg.value);
        }
    }
}