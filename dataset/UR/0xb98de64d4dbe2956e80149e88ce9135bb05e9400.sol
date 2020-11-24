 

pragma solidity ^0.4.21;


contract RealEstateCryptoFund {
  function transfer(address to, uint256 value) public returns (bool);
  function balanceOf(address who) public constant returns (uint256);
}


 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract Bounty is Ownable {
  uint256 public BountyAmount;

  RealEstateCryptoFund public token;

  mapping(address=>bool) public participated;

  event TokenBounty(address indexed beneficiary, uint256 amount);

  event BountyAmountUpdate(uint256 BountyAmount);
  
  function Bounty(address _tokenAddress) public {
    token = RealEstateCryptoFund (_tokenAddress);
  }

  function () external payable {
    getTokens(msg.sender);
  }

  function setBountyAmount(uint256 _BountyAmount) public onlyOwner {
    require(_BountyAmount > 0);
    BountyAmount = _BountyAmount;
    emit BountyAmountUpdate(BountyAmount);
  }

  function getTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase(beneficiary));
    
    token.transfer(beneficiary, BountyAmount);

    emit TokenBounty(beneficiary, BountyAmount);

    participated[beneficiary] = true;
  }

  
  function validPurchase(address beneficiary) internal view returns (bool) {
    bool hasParticipated = participated[beneficiary];
    return !hasParticipated;
  }
}


contract RealEstateCryptoFundBounty is Bounty {
  function RealEstateCryptoFundBounty (address _tokenAddress) public
    Bounty(_tokenAddress)
  {

  }

  function drainRemainingTokens () public onlyOwner {
    token.transfer(owner, token.balanceOf(this));
  }
}