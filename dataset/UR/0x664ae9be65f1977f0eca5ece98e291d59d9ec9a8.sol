 

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
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Burn(address indexed from, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) {
      
    require ( balances[msg.sender] >= _value);            
    require (balances[_to] + _value >= balances[_to]);    

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }
  
   
  function burn(uint256 _value) {
      
    require ( balances[msg.sender] >= _value);            

    balances[msg.sender] = balances[msg.sender].sub(_value);
    Burn(msg.sender, _value);
  }
  

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) {

     
     
     
     
    require ( !((_value != 0) && (allowed[msg.sender][_spender] != 0)));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
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
    require(msg.sender == owner) ;
    
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  string public name = "ICScoin";
  string public symbol = "ICS";
  uint256 public decimals = 10;

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished) ;
    _;
  }

  function MintableToken(){
    mint(msg.sender,5000000000000000);
    finishMinting();
  }
    
   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }
  
   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

}


contract Tokensale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    uint public minimumEntryThreshold;
    address public devAddr;  
    MintableToken public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    bool public devPaid = false;
    
     
    uint256 public startTime;
    uint256 public endTime;


    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function Tokensale(
     
     
     
        address addressOfTokenUsedAsReward
      
      
    ) {
        beneficiary = address(0x7486516460CdDC841ca7293C2a01328D359eB609);
        fundingGoal = 4166 ether;
        startTime = 1506600000;  
        endTime =   1507809600;  
        price = 833 finney;
        minimumEntryThreshold = 1 ether;
        tokenReward = MintableToken(addressOfTokenUsedAsReward);
        devAddr = address(0x45e044ED9Bf130EafafA8095115Eda69FC3b0D20);
    }

     
    function () payable {

        require(validPurchase());
        require(msg.value >= minimumEntryThreshold);
        uint amount = msg.value;
        uint tokens = amount * 10000000000 / price;
        require( tokenReward.balanceOf(this) >= tokens);
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, tokens);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >  endTime) _; }
    
       
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase; 
    }

     
    function hasEnded() public constant returns (bool) {
        return ( now > endTime ); 
    }
    
     
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


     
    function safeWithdrawal() afterDeadline {
        
        checkGoalReached();
        
         
        if ( !devPaid)  {
            uint devReward;
            if ( amountRaised >= 10 ether ) devReward = 10 ether; else devReward = amountRaised;
            devAddr.transfer(devReward);
            FundTransfer(devAddr, devReward, true);
            devPaid = true;
        }
        
        
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised - 10 ether)) {
                FundTransfer(beneficiary, amountRaised - 10 ether, false);
            } else {
                 
                fundingGoalReached = false;
            }
        }
        
    }
}