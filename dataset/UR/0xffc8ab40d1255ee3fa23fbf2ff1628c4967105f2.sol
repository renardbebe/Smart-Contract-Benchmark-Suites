 

pragma solidity ^0.4.13;

contract AbstractToken {

    function mint(address _to, uint256 _amount) public returns (bool);
    function transferOwnership(address newOwner) public;
    function finishMinting() public returns (bool);

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
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

contract Destructible is Ownable {

  function Destructible() payable { } 

   
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

contract MinimumValueTransfer is Ownable {

  uint256 internal minimumWeiRequired;

   
  modifier minimumWeiMet() {
    require(msg.value >= minimumWeiRequired);
    _;
  }

   
  function updateMinimumWeiRequired(uint256 minimunTransferInWei) public onlyOwner {
    minimumWeiRequired = minimunTransferInWei;
  }


   
  function minimumTransferInWei() public constant returns(uint256) {
    return minimumWeiRequired;
  }

}

contract Crowdsale is MinimumValueTransfer {
  using SafeMath for uint256;

   
  AbstractToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(address _tokenAddress, uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);
    require(_tokenAddress != 0x0);

     
    token = createTokenContract(_tokenAddress);

     
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract(address _tokenAddress) internal returns (AbstractToken) {
    return AbstractToken(_tokenAddress);
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() minimumWeiMet internal constant returns (bool) {
    uint256 current = now;
    bool withinPeriod = current >= startTime && current <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && !hasEnded();
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

   
  function updateCrowdsaleTimeline(uint256 newStartTime, uint256 newEndTime) onlyOwner external {
    require (newStartTime > 0 && newEndTime > newStartTime);
    startTime = newStartTime;
    endTime = newEndTime;
  }

   
  function crowdsaleProgress() external constant returns(uint256){
    return now > endTime ? 100: now.sub(startTime).mul(100).div(endTime.sub(startTime));
  }

   
  function transferTokenOwnership(address newOwner) public onlyOwner {
    token.transferOwnership(newOwner);
  }


}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
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

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract AlloyPresale is Ownable, Destructible, Pausable, CappedCrowdsale {

    using SafeMath for uint256;

    function AlloyPresale(address _tokenAddress, uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, uint256 _cap) CappedCrowdsale(_cap) Crowdsale(_tokenAddress, _startTime, _endTime, _rate, _wallet) {
    }

     
    function hasEnded() public constant returns (bool) {
        return paused || super.hasEnded();
    }

}