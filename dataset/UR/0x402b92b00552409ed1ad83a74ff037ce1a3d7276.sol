 

pragma solidity ^0.4.18;

 
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


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping(address => bool) locks;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    
    require(!locks[msg.sender] && !locks[_to]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
  
   
  function setLock(address _toLock, bool _setTo) onlyOwner {
      locks[_toLock] = _setTo;
  }

   
  function lockOf(address _owner) public constant returns (bool lock) {
    return locks[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    
    require(!locks[_from] && !locks[_to]);

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


 

contract MintableToken is StandardToken {
  string public constant name = "CryptoTask";
  string public constant symbol = "CTF";
  uint8 public constant decimals = 18; 
    
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(!locks[_to]);
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}


contract Crowdsale is Ownable {
    using SafeMath for uint;
    
    uint public fundingGoal = 1000 * 1 ether;
    uint public hardCap;
    uint public amountRaisedPreSale = 0;
    uint public amountRaisedICO = 0;
    uint public contractDeployedTime;
     
    uint presaleDuration = 30 * 1 days;
     
    uint countdownDuration = 45 * 1 days;
     
    uint icoDuration = 20 * 1 days;
    uint public presaleEndTime;
    uint public deadline;
    uint public price = 1000;
    MintableToken public token;
    mapping(address => uint) public balanceOf;
    bool public icoSuccess = false;
    bool public crowdsaleClosed = false;
     
    address vault1;
    address vault2 = 0xC0776D495f9Ed916C87c8C48f34f08E2B9506342;
     
    uint public stage = 0;
     
    uint public against = 0;
    uint public lastVoteTime;
    uint minVoteTime = 180 * 1 days;

    event GoalReached(uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function Crowdsale() {
        contractDeployedTime = now;
        vault1 = msg.sender;
        token = new MintableToken();
    }

     
    function () payable {
        require(!token.lockOf(msg.sender) && !crowdsaleClosed && stage<2 && msg.value >= 1 * (1 ether)/10);
        if(stage==1 && (now < presaleEndTime.add(countdownDuration) || amountRaisedPreSale+amountRaisedICO+msg.value > hardCap)) {
            throw;
        }
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        if(stage==0) {   
            amountRaisedPreSale += amount;
            token.mint(msg.sender, amount.mul(2) * price);
        } else {
            amountRaisedICO += amount;
            token.mint(msg.sender, amount * price);
        }
        FundTransfer(msg.sender, amount, true);
    }
    
     
    function forward(uint amount) internal {
        vault1.transfer(amount.mul(67)/100);
        vault2.transfer(amount.sub(amount.mul(67)/100));
    }

    modifier afterDeadline() { if (stage > 0 && now >= deadline) {_;} }

     
    function checkGoalReached() afterDeadline {
        require(stage==1 && !crowdsaleClosed);
        if (amountRaisedPreSale+amountRaisedICO >= fundingGoal) {
            uint amount = amountRaisedICO/3;
            if(!icoSuccess) {
                amount += amountRaisedPreSale/3;     
            }
            uint amountToken1 = token.totalSupply().mul(67)/(100*4);
            uint amountToken2 = token.totalSupply().mul(33)/(100*4);
            forward(amount);
            icoSuccess = true;
            token.mint(vault1, amountToken1);     
            token.mint(vault2, amountToken2);     
            stage=2;
            lastVoteTime = now;
            GoalReached(amountRaisedPreSale+amountRaisedICO);
        }
        crowdsaleClosed = true;
        token.finishMinting();
    }

     
    function closePresale() {
        require((msg.sender == owner || now.sub(contractDeployedTime) > presaleDuration) && stage==0);
        stage = 1;
        presaleEndTime = now;
        deadline = now.add(icoDuration.add(countdownDuration));
        if(amountRaisedPreSale.mul(5) > 10000 * 1 ether) {
            hardCap = amountRaisedPreSale.mul(5);
        } else {
            hardCap = 10000 * 1 ether;
        }
        if(amountRaisedPreSale >= fundingGoal) {
            uint amount = amountRaisedPreSale/3;
            forward(amount);
            icoSuccess = true;
            GoalReached(amountRaisedPreSale);
        }
    }

     
    function safeWithdrawal() {
        require(crowdsaleClosed && !icoSuccess);
        
        uint amount;
        if(stage==1) {
            amount = balanceOf[msg.sender];
        } else if(stage==2) {
            amount = balanceOf[msg.sender].mul(2)/3;     
        } else if(stage==3) {
            amount = balanceOf[msg.sender]/3;     
        }
        balanceOf[msg.sender] = 0;
        if (amount > 0) {
            msg.sender.transfer(amount);
            FundTransfer(msg.sender, amount, false);
        }
    }
    
     
    function voteAgainst()
    {
        require((stage==2 || stage==3) && !token.lockOf(msg.sender));    
        token.setLock(msg.sender, true);
        uint voteWeight = token.balanceOf(msg.sender);
        against = against.add(voteWeight);
    }
    
     
    function voteRelease()
    {
        require((stage==2 || stage==3 || stage==4) && token.lockOf(msg.sender));
        token.setLock(msg.sender, false);
        uint voteWeight = token.balanceOf(msg.sender);
        against = against.sub(voteWeight);
    }
    
     
    function countVotes()
    {
        require(icoSuccess && (stage==2 || stage==3) && now.sub(lastVoteTime) > minVoteTime);
        lastVoteTime = now;
        
        if(against > token.totalSupply()/2) {
            icoSuccess = false;
        } else {
            uint amount = amountRaisedICO/3 + amountRaisedPreSale/3;
            forward(amount);
            stage++;
        }
    }
    
}