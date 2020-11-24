 

pragma solidity ^0.4.17;

 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract SimpleTGE is Ownable {
  using SafeMath for uint256;

   
  uint256 public publicTGEStartBlockTimeStamp;

  uint256 public publicTGEEndBlockTimeStamp;

   
  address public fundsWallet;

   
  uint256 public weiRaised;

   
  uint256 public totalCapInWei;

   
  uint256 public individualCapInWei;

   
  uint256 public TRSOffset = 5 days;

  mapping (address => bool) public whitelist;

  address[] public contributors;
  struct Contribution {
    bool hasVested;
    uint256 weiContributed;
  }

  mapping (address => Contribution)  public contributions;

  modifier whilePublicTGEIsActive() {
    require(block.timestamp >= publicTGEStartBlockTimeStamp && block.timestamp <= publicTGEEndBlockTimeStamp);
    _;
  }

  modifier isWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  function blacklistAddresses(address[] addrs) external onlyOwner returns(bool) {
    require(addrs.length <= 100);
    for (uint i = 0; i < addrs.length; i++) {
      require(addrs[i] != address(0));
      whitelist[addrs[i]] = false;
    }
    return true;
  }

  function whitelistAddresses(address[] addrs) external onlyOwner returns(bool) {
    require(addrs.length <= 100);
    for (uint i = 0; i < addrs.length; i++) {
      require(addrs[i] != address(0));
      whitelist[addrs[i]] = true;
    }
    return true;
  }

   
  function reclaimEther(address _beneficiary) external onlyOwner {
    _beneficiary.transfer(this.balance);
  }

  function SimpleTGE (
    address _fundsWallet,
    uint256 _publicTGEStartBlockTimeStamp,
    uint256 _publicTGEEndBlockTimeStamp,
    uint256 _individualCapInWei,
    uint256 _totalCapInWei
  ) public 
  {
    require(_publicTGEStartBlockTimeStamp >= block.timestamp);
    require(_publicTGEEndBlockTimeStamp > _publicTGEStartBlockTimeStamp);
    require(_fundsWallet != address(0));
    require(_individualCapInWei > 0);
    require(_individualCapInWei <= _totalCapInWei);
    require(_totalCapInWei > 0);

    fundsWallet = _fundsWallet;
    publicTGEStartBlockTimeStamp = _publicTGEStartBlockTimeStamp;
    publicTGEEndBlockTimeStamp = _publicTGEEndBlockTimeStamp;
    individualCapInWei = _individualCapInWei;
    totalCapInWei = _totalCapInWei;
  }

   
  function changeIndividualCapInWei(uint256 _individualCapInWei) onlyOwner external returns(bool) {
      require(_individualCapInWei > 0);
      require(_individualCapInWei < totalCapInWei);
      individualCapInWei = _individualCapInWei;
      return true;
  }

   
  function contribute(bool _vestingDecision) internal {
     
    require(msg.sender != address(0));
    require(msg.value != 0);
    require(weiRaised.add(msg.value) <= totalCapInWei);
    require(contributions[msg.sender].weiContributed.add(msg.value) <= individualCapInWei);
     
    if (contributions[msg.sender].weiContributed == 0) {
      contributors.push(msg.sender);
    }
    contributions[msg.sender].weiContributed = contributions[msg.sender].weiContributed.add(msg.value);
    weiRaised = weiRaised.add(msg.value);
    contributions[msg.sender].hasVested = _vestingDecision;
    fundsWallet.transfer(msg.value);
  }

  function contributeAndVest() external whilePublicTGEIsActive isWhitelisted payable {
    contribute(true);
  }

  function contributeWithoutVesting() public whilePublicTGEIsActive isWhitelisted payable {
    contribute(false);
  }

   
  function () external payable {
    contributeWithoutVesting();
  }

   
   
  function vest(bool _vestingDecision) external isWhitelisted returns(bool) {
    bool existingDecision = contributions[msg.sender].hasVested;
    require(existingDecision != _vestingDecision);
    require(block.timestamp >= publicTGEStartBlockTimeStamp);
    require(contributions[msg.sender].weiContributed > 0);
     
    if (block.timestamp > publicTGEEndBlockTimeStamp) {
      require(block.timestamp.sub(publicTGEEndBlockTimeStamp) <= TRSOffset);
    }
    contributions[msg.sender].hasVested = _vestingDecision;
    return true;
  }
}