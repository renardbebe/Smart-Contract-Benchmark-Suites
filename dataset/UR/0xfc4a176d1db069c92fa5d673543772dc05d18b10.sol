 

pragma solidity ^0.4.21;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 



 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}














 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}



 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}









 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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


 
contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}



contract CQSToken is StandardBurnableToken {
     
    string  public constant name = "CQS";
    string  public constant symbol = "CQS";
    uint8   public constant decimals = 18;
    address public owner;
    string  public website = "www.cqsexchange.io"; 
    uint256 public constant INITIAL_SUPPLY      =  2000000000 * (10 ** uint256(decimals));
    uint256 public constant CROWDSALE_ALLOWANCE =  1600000000 * (10 ** uint256(decimals));
    uint256 public constant ADMIN_ALLOWANCE     =   400000000 * (10 ** uint256(decimals));

     
     
    uint256 public crowdSaleAllowance;       
    uint256 public adminAllowance;           
    address public crowdSaleAddr;            
    address public adminAddr;                
    bool public icoStart = false;
    mapping(address => uint256) public tokensTransferred;

     
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    modifier validDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        require(_to != owner);
         
         
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _admin) public {
         
         
         
         
        require(msg.sender != _admin);

        owner = msg.sender;

         
        totalSupply_ = INITIAL_SUPPLY;
        crowdSaleAllowance = CROWDSALE_ALLOWANCE;
        adminAllowance = ADMIN_ALLOWANCE;

         
        balances[msg.sender] = totalSupply_.sub(adminAllowance);
        emit Transfer(address(0x0), msg.sender, totalSupply_.sub(adminAllowance));

        balances[_admin] = adminAllowance;
        emit Transfer(address(0x0), _admin, adminAllowance);

        adminAddr = _admin;
        approve(adminAddr, adminAllowance);
    }

     
    function startICO() external onlyOwner {
        icoStart = true;
    }

     
    function stopICO() external onlyOwner {
        icoStart = false;
    }


    function setCrowdsale(address _crowdSaleAddr, uint256 _amountForSale) external onlyOwner {
        require(_amountForSale <= crowdSaleAllowance);

         
        uint amount = (_amountForSale == 0) ? crowdSaleAllowance : _amountForSale;

         
        approve(crowdSaleAddr, 0);
        approve(_crowdSaleAddr, amount);

        crowdSaleAddr = _crowdSaleAddr;
         
    }


    function transfer(address _to, uint256 _value) public validDestination(_to) returns (bool) {
        if(icoStart && (msg.sender != owner || msg.sender != adminAddr)){
            require((tokensTransferred[msg.sender].add(_value)).mul(2)<=balances[msg.sender].add(tokensTransferred[msg.sender]));
            tokensTransferred[msg.sender] = tokensTransferred[msg.sender].add(_value);
            return super.transfer(_to, _value);
        }else
            return super.transfer(_to, _value);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }


    function burn(uint256 _value) public {
        require(msg.sender==owner || msg.sender==adminAddr);
        _burn(msg.sender, _value);
    }


    function burnFromAdmin(uint256 _value) external onlyOwner {
        _burn(adminAddr, _value);
    }

    function changeWebsite(string _website) external onlyOwner {website = _website;}


}

contract CQSSale {

    using SafeMath for uint256;

     
    address public beneficiary;

     
    uint public fundingGoal;
    uint public fundingCap;
    uint public minContribution;
    bool public fundingGoalReached = false;
    bool public fundingCapReached = false;
    bool public saleClosed = false;

     
    uint public startTime;
    uint public endTime;
    address public owner;

     
    uint public amountRaised;

     
    uint public refundAmount;

     
    uint public rate = 50000;
    uint public constant LOW_RANGE_RATE = 1;
    uint public constant HIGH_RANGE_RATE = 500000;

     
    bool private rentrancy_lock = false;
    bool public paused = false;

     
    CQSToken public tokenReward;

     
    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) public contributions;
     
     

     
    event GoalReached(address _beneficiary, uint _amountRaised);
    event CapReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);
    event Pause();
    event Unpause();

     
    modifier beforeDeadline()   {require (currentTime() < endTime); _;}
    modifier afterDeadline()    {require (currentTime() >= endTime); _;}
    modifier afterStartTime()    {require (currentTime() >= startTime); _;}

    modifier saleNotClosed()    {require (!saleClosed); _;}

    modifier nonReentrant() {
        require(!rentrancy_lock);
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    
     
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
        tokenReward.stopICO();
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        tokenReward.startICO();
        emit Unpause();
    }


    constructor(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint fundingCapInEthers,
        uint minimumContributionInWei,
        uint start,
        uint end,
        uint rateCQSToEther,
        address addressOfTokenUsedAsReward
    ) public {
        require(ifSuccessfulSendTo != address(0) && ifSuccessfulSendTo != address(this));
        require(addressOfTokenUsedAsReward != address(0) && addressOfTokenUsedAsReward != address(this));
        require(fundingGoalInEthers <= fundingCapInEthers);
        require(end > 0);
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        fundingCap = fundingCapInEthers * 1 ether;
        minContribution = minimumContributionInWei;
        startTime = start;
        endTime = end;  
        rate = rateCQSToEther;
        tokenReward = CQSToken(addressOfTokenUsedAsReward);
        owner = msg.sender;
    }


    function () external payable whenNotPaused beforeDeadline afterStartTime saleNotClosed nonReentrant {
        require(msg.value >= minContribution);
         

         
        uint amount = msg.value;
        uint currentBalance = balanceOf[msg.sender];
        balanceOf[msg.sender] = currentBalance.add(amount);
        amountRaised = amountRaised.add(amount);

         
         
         
        uint numTokens = amount.mul(rate);

         
        if (tokenReward.transferFrom(tokenReward.owner(), msg.sender, numTokens)) {
            emit FundTransfer(msg.sender, amount, true);
            contributions[msg.sender] = contributions[msg.sender].add(amount);
             
             
             
             
            checkFundingGoal();
            checkFundingCap();
        }
        else {
            revert();
        }
    }

    function terminate() external onlyOwner {
        saleClosed = true;
        tokenReward.stopICO();
    }

    function setRate(uint _rate) external onlyOwner {
        require(_rate >= LOW_RANGE_RATE && _rate <= HIGH_RANGE_RATE);
        rate = _rate;
    }

    function ownerAllocateTokens(address _to, uint amountWei, uint amountMiniCQS) external
            onlyOwner nonReentrant
    {
        if (!tokenReward.transferFrom(tokenReward.owner(), _to, amountMiniCQS)) {
            revert();
        }
        balanceOf[_to] = balanceOf[_to].add(amountWei);
        amountRaised = amountRaised.add(amountWei);
        emit FundTransfer(_to, amountWei, true);
        checkFundingGoal();
        checkFundingCap();
    }

    function ownerSafeWithdrawal() external onlyOwner nonReentrant {
        require(fundingGoalReached);
        uint balanceToSend = address(this).balance;
        beneficiary.transfer(balanceToSend);
        emit FundTransfer(beneficiary, balanceToSend, false);
    }

    function ownerUnlockFund() external afterDeadline onlyOwner {
        fundingGoalReached = false;
    }

    function safeWithdrawal() external afterDeadline nonReentrant {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false);
                refundAmount = refundAmount.add(amount);
            }
        }
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

    function currentTime() public view returns (uint _currentTime) {
        return block.timestamp;
    }

    function convertToMiniCQS(uint amount) internal view returns (uint) {
        return amount * (10 ** uint(tokenReward.decimals()));
    }

    function changeStartTime(uint256 _startTime) external onlyOwner {startTime = _startTime;}
    function changeEndTime(uint256 _endTime) external onlyOwner {endTime = _endTime;}

}