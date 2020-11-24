 

 

pragma solidity ^0.5.0;

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
    
contract ParadiseToken is StandardToken, Ownable {
    
     
    string public constant symbol = "PDT";
    string public constant name = "Paradise Token";
    uint8 public constant decimals = 18;
    uint256 public constant InitialSupplyCup = 300000000 * (10 ** uint256(decimals));  
    uint256 public constant TokenAllowance = 210000000 * (10 ** uint256(decimals));    
    uint256 public constant AdminAllowance = InitialSupplyCup - TokenAllowance;        
    
     
    address public adminAddr;             
    address public tokenAllowanceAddr = 0x9A4518ad59ac1D0Fc9A77d9083f233cD0b8d77Fa;  
    bool public transferEnabled = false;   
    
    
    modifier onlyWhenTransferAllowed() {
        require(transferEnabled || msg.sender == adminAddr || msg.sender == tokenAllowanceAddr);
        _;
    }

     
    modifier onlyTokenOfferingAddrNotSet() {
        require(tokenAllowanceAddr == address(0x0));
        _;
    }

     
    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        require(to != owner);
        require(to != address(adminAddr));
        require(to != address(tokenAllowanceAddr));
        _;
    }
    
     
    constructor(address admin) public {
        totalSupply = InitialSupplyCup;
        
         
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);

         
        adminAddr = admin;
        approve(adminAddr, AdminAllowance);
    }

     
    function setTokenOffering(address offeringAddr, uint256 amountForSale) external onlyOwner {
        require(!transferEnabled);

        uint256 amount = (amountForSale == 0) ? TokenAllowance : amountForSale;
        require(amount <= TokenAllowance);

        approve(offeringAddr, amount);
        tokenAllowanceAddr = offeringAddr;
        
    }
    
     
    function enableTransfer() external onlyOwner {
        transferEnabled = true;

         
        approve(tokenAllowanceAddr, 0);
    }

     
    function transfer(address to, uint256 value) public onlyWhenTransferAllowed validDestination(to) returns (bool) {
        return super.transfer(to, value);
    }
    
     
    function transferFrom(address from, address to, uint256 value) public onlyWhenTransferAllowed validDestination(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }
    
}

 

contract ParadiseTokenSale is Pausable {

    using SafeMath for uint256;

     
    address public beneficiary = 0x1Bb7390407F7987BD160993dE44d6f2737945436;

     
    uint public fundingGoal = 22700 ether;   
    uint public fundingCap = 53400 ether;    
    uint public minContribution = 10**17;    
    bool public fundingGoalReached = false;
    bool public fundingCapReached = false;
    bool public saleClosed = false;

     
    uint public startTime = 1547031675;  
    uint public endTime = 1552129275;   
   
     
    uint public amountRaised;
     
    uint public refundAmount;

     
    uint public rate;
    uint public constant LOW_RANGE_RATE = 10000;     
    uint public constant HIGH_RANGE_RATE = 14000;    
    
     
    ParadiseToken public tokenReward;

     
    mapping(address => uint256) public balanceOf;
    
     
    event GoalReached(address _beneficiary, uint _amountRaised);
    event CapReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);

     
    modifier beforeDeadline()   { require (currentTime() < endTime); _; }
    modifier afterDeadline()    { require (currentTime() >= endTime); _; }
    modifier afterStartTime()    { require (currentTime() >= startTime); _; }

    modifier saleNotClosed()    { require (!saleClosed); _; }

    
     
    constructor(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint fundingCapInEthers,
        uint minimumContributionInWei,
        uint start,
        uint durationInMinutes,
        uint ratePDTToEther,
        address addressOfTokenUsedAsReward
    ) public {
        require(ifSuccessfulSendTo != address(0) && ifSuccessfulSendTo != address(this));
        require(addressOfTokenUsedAsReward != address(0) && addressOfTokenUsedAsReward != address(this));
        require(fundingGoalInEthers <= fundingCapInEthers);
        require(durationInMinutes > 0);
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        fundingCap = fundingCapInEthers * 1 ether;
        minContribution = minimumContributionInWei;
        startTime = start;
        endTime = start + durationInMinutes * 1 minutes; 
        setRate(ratePDTToEther);
        tokenReward = ParadiseToken(addressOfTokenUsedAsReward);
    }

     
    function () payable external {
        buy();
    }

    function buy ()
        payable public
        whenNotPaused
        beforeDeadline
        afterStartTime
        saleNotClosed
    {
        require(msg.value >= minContribution);
        uint amount = msg.value;
        
         
         
         
        uint numTokens = amount.mul(rate);
        
         
        if (tokenReward.transferFrom(tokenReward.owner(), msg.sender, numTokens)) {
    
         
        amountRaised = amountRaised.add(amount);
     
         
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);

        emit FundTransfer(msg.sender, amount, true);
         
        checkFundingGoal();
        checkFundingCap();
        }
        else {
            revert();
        }
    }
    
     
    function setRate(uint _rate) public onlyOwner {
        require(_rate >= LOW_RANGE_RATE && _rate <= HIGH_RANGE_RATE);
        rate = _rate;
    }
    
      
    function terminate() external onlyOwner {
        saleClosed = true;
    }
    
      
     
     
     function ownerAllocateTokens(address to, uint amountWei, uint amountPDT) public
            onlyOwner 
    {
         
         
        
        if (!tokenReward.transferFrom(tokenReward.owner(), to, amountPDT)) {
            revert();
        }
        amountRaised = amountRaised.add(amountWei);
        balanceOf[to] = balanceOf[to].add(amountWei);
        emit FundTransfer(to, amountWei, true);
        checkFundingGoal();
        checkFundingCap();
    }

     
    function ownerSafeWithdrawal() external onlyOwner  {
        uint balanceToSend = address(this).balance;
        address(0x1Bb7390407F7987BD160993dE44d6f2737945436).transfer(balanceToSend);
        emit FundTransfer(beneficiary, balanceToSend, false);
    }
    
    
    function checkFundingGoal() internal {
        if (!fundingGoalReached) {
            if (amountRaised >= fundingGoal) {
                fundingGoalReached = true;
                emit GoalReached(beneficiary, amountRaised);
            }
        }
    }

     
   function checkFundingCap() internal {
        if (!fundingCapReached) {
            if (amountRaised >= fundingCap) {
                fundingCapReached = true;
                saleClosed = true;
                emit CapReached(beneficiary, amountRaised);
            }
        }
    }

     
    function currentTime() view public returns (uint _currentTime) {
        return now;
    }
}

interface IERC20 {
  function balanceOf(address _owner) external view returns (uint256);
  function allowance(address _owner, address _spender) external view returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function approve(address _spender, uint256 _value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
 
contract PDTDistribution is Ownable {
  
  function drop(IERC20 token, address[] memory recipients, uint256[] memory values) public onlyOwner {
    for (uint256 i = 0; i < recipients.length; i++) {
      token.transfer(recipients[i], values[i]);
    }
  }
}

 