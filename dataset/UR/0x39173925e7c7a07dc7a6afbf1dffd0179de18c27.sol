 

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


 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract reclaimTokens is Ownable {

   
  function reclaimToken(address tokenAddr) external onlyOwner {
    ERC20Basic tokenInst = ERC20Basic(tokenAddr);
    uint256 balance = tokenInst.balanceOf(this);
    tokenInst.transfer(owner, balance);
  }
}

contract ExperimentalPreICO is reclaimTokens, HasNoContracts {
  using SafeMath for uint256;

  address public beneficiary;
  bool public fundingGoalReached = false;
  bool public crowdsaleClosed = false;
  ERC20Basic public rewardToken;
  uint256 public fundingGoal;
  uint256 public fundingCap;
  uint256 public paymentMin;
  uint256 public paymentMax;
  uint256 public amountRaised;
  uint256 public rate;

  mapping(address => uint256) public balanceOf;
  mapping(address => bool) public whitelistedAddresses;
  event GoalReached(address beneficiaryAddress, uint256 amount);
  event FundTransfer(address backer, uint256 amount, bool isContribution);

   
  function ExperimentalPreICO(address _wallet,
                              uint256 _goalInEthers,
                              uint256 _capInEthers,
                              uint256 _minPaymentInEthers,
                              uint256 _maxPaymentInEthers,
                              uint256 _rate,
                              address _rewardToken) {
    require(_goalInEthers > 0);
    require(_capInEthers >= _goalInEthers);
    require(_minPaymentInEthers > 0);
    require(_maxPaymentInEthers > _minPaymentInEthers);
    require(_rate > 0);
    require(_wallet != 0x0);
    beneficiary = _wallet;
    fundingGoal = _goalInEthers.mul(1 ether);
    fundingCap = _capInEthers.mul(1 ether);
    paymentMin = _minPaymentInEthers.mul(1 ether);
    paymentMax = _maxPaymentInEthers.mul(1 ether);
    rate = _rate;
    rewardToken = ERC20Basic(_rewardToken);
  }

   
  function () external payable crowdsaleActive {
    require(validPurchase());

    uint256 amount = msg.value;
    balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
    amountRaised = amountRaised.add(amount);
    rewardToken.transfer(msg.sender, amount.mul(rate));
    FundTransfer(msg.sender, amount, true);
  }

   
  modifier crowdsaleEnded() {
    require(crowdsaleClosed == true);
    _;
  }

   
  modifier crowdsaleActive() {
    require(crowdsaleClosed == false);
    _;
  }

   
  function validPurchase() internal returns (bool) {
    bool whitelisted = whitelistedAddresses[msg.sender] == true;
    bool validAmmount = msg.value >= paymentMin && msg.value <= paymentMax;
    bool availableFunding = fundingCap >= amountRaised.add(msg.value);
    return whitelisted && validAmmount && availableFunding;
  }

   
  function checkGoal() external onlyOwner {
    if (amountRaised >= fundingGoal){
      fundingGoalReached = true;
      GoalReached(beneficiary, amountRaised);
    }
  }

   
  function endCrowdsale() external onlyOwner {
    crowdsaleClosed = true;
  }

   
  function safeWithdrawal() external crowdsaleEnded {
    if (!fundingGoalReached) {
      uint256 amount = balanceOf[msg.sender];
      balanceOf[msg.sender] = 0;
      if (amount > 0) {
        if (msg.sender.send(amount)) {
          FundTransfer(msg.sender, amount, false);
        } else {
          balanceOf[msg.sender] = amount;
        }
      }
    }

    if (fundingGoalReached && owner == msg.sender) {
      if (beneficiary.send(amountRaised)) {
        FundTransfer(beneficiary, amountRaised, false);
      } else {
         
        fundingGoalReached = false;
      }
    }
  }

   
  function whitelistAddress (address[] addresses) external onlyOwner crowdsaleActive {
    for (uint i = 0; i < addresses.length; i++) {
      whitelistedAddresses[addresses[i]] = true;
    }
  }

}