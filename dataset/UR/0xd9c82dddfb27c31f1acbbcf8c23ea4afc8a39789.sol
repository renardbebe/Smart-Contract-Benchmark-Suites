 

pragma solidity ^0.4.19;

 

interface token {
    function transfer(address receiver, uint amount) public;
}

 
contract withdrawToken {
    function transfer(address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external constant returns (uint balance);
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

 
contract Crowdsale {
    using SafeMath for uint256;

    address public owner;  
    address public operations;  
    address public index;  
    uint256 public amountRaised;  
    uint256 public amountRaisedPhase;  
    uint256 public tokensSold;  
    uint256 public softCap;  
    uint256 public softCapLimit;  
    uint256 public discountPrice;  
    uint256 public fullPrice;  
    uint256 public startTime;  
    token public tokenReward;  
    mapping(address => uint256) public contributionByAddress;

    event FundTransfer(address backer, uint amount, bool isContribution);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Crowdsale(
        uint saleStartTime,
        address ownerAddress,
        address operationsAddress,
        address indexAddress,
        address rewardTokenAddress

    ) public {
        startTime = saleStartTime;  
        owner = ownerAddress;  
        operations = operationsAddress;  
        index = indexAddress;  
        softCap = 750000000000000000000000;  
        softCapLimit = 4500 ether;  
        discountPrice = 0.006 ether;  
        fullPrice = 0.00667 ether;  
        tokenReward = token(rewardTokenAddress);  
    }

     
    function () public payable {
        uint256 amount = msg.value;
        require(now > startTime);

        if(now < startTime.add(24 hours) && amountRaised < softCapLimit) {  
            require(amount.add(contributionByAddress[msg.sender]) > 1 ether && amount.add(contributionByAddress[msg.sender]) <= 5 ether);  
            require(amount.mul(10**18).div(discountPrice) <= softCap.sub(tokensSold));  
            contributionByAddress[msg.sender] = contributionByAddress[msg.sender].add(amount);
            amountRaised = amountRaised.add(amount);
            amountRaisedPhase = amountRaisedPhase.add(amount);
            tokensSold = tokensSold.add(amount.mul(10**18).div(discountPrice));
            tokenReward.transfer(msg.sender, amount.mul(10**18).div(discountPrice));
            FundTransfer(msg.sender, amount, true);

        }

        else {  
            require(amount <= 1000 ether);
            contributionByAddress[msg.sender] = contributionByAddress[msg.sender].add(amount);
            amountRaised = amountRaised.add(amount);
            amountRaisedPhase = amountRaisedPhase.add(amount);
            tokensSold = tokensSold.add(amount.mul(10**18).div(fullPrice));
            tokenReward.transfer(msg.sender, amount.mul(10**18).div(fullPrice));
            FundTransfer(msg.sender, amount, true);
        }

    }

     
    function withdrawTokens(address tokenContract) external onlyOwner {
        withdrawToken tc = withdrawToken(tokenContract);

        tc.transfer(owner, tc.balanceOf(this));
    }
    
     
    function withdrawEther() external onlyOwner {
        uint256 total = this.balance;
        uint256 operationsSplit = 40;
        uint256 indexSplit = 60;
        operations.transfer(total * operationsSplit / 100);
        index.transfer(total * indexSplit / 100);
    }
}