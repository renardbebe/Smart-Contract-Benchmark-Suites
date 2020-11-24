 

pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) public;
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

contract Crowdsale {
    using SafeMath for uint256;

    address public owner;
    uint256 public amountRaised;
    uint256 public amountRaisedPhase;
    uint256 public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;

    event FundTransfer(address backer, uint amount, bool isContribution);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function Crowdsale(
        address ownerAddress,
        uint256 weiCostPerToken,
        address rewardTokenAddress
    ) public {
        owner = ownerAddress;
        price = weiCostPerToken;
        tokenReward = token(rewardTokenAddress);
    }

     
    function () public payable {
        uint256 amount = msg.value;
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        amountRaised = amountRaised.add(amount);
        amountRaisedPhase = amountRaisedPhase.add(amount);
        tokenReward.transfer(msg.sender, amount.mul(10**4).div(price));
        FundTransfer(msg.sender, amount, true);
    }

     
    function safeWithdrawal() public onlyOwner {
        uint256 withdraw = amountRaisedPhase;
        amountRaisedPhase = 0;
        FundTransfer(owner, withdraw, false);
        owner.transfer(withdraw);
    }

     
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
    function destroyAndSend(address _recipient) public onlyOwner {
        selfdestruct(_recipient);
    }
}