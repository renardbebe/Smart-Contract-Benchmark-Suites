 

pragma solidity ^0.4.18;

 

 
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

 

library Discounts {
  using SafeMath for uint256;

   

   
  struct Collection {
    Tier[] tiers;

     
    uint256 baseRate;
  }

   
  struct Tier {
     
     
    uint256 discount;

     
    uint256 available;
  }

   
  uint256 public constant MAX_DISCOUNT = 10000;


   

   
  function addTier(
    Collection storage self,
    uint256 _discount,
    uint256 _available
  )
    internal
  {
    self.tiers.push(Tier({
      discount: _discount,
      available: _available
    }));
  }


   

   
  function purchaseTokens(
    Collection storage self,
    uint256 _amount,
    uint256 _funds,
    uint256 _minimumTier
  )
    internal
    returns (
      uint256 purchased,
      uint256 remaining
    )
  {
    uint256 issue = 0;  
    remaining = _funds;

    uint256 available;   
    uint256 spend;  
    uint256 affordable;   
    uint256 purchase;  

     
     
    for (var i = _minimumTier; i < self.tiers.length && issue < _amount; i++) {
       
      available = self.tiers[i].available;

       
      affordable = _computeTokensPurchasedAtTier(self, i, remaining);

       
       
      if (affordable < available) {
        purchase = affordable;
      } else {
        purchase = available;
      }

       
       
      if (purchase.add(issue) > _amount) {
        purchase = _amount.sub(issue);
      }

      spend = _computeCostForTokensAtTier(self, i, purchase);

       
      self.tiers[i].available -= purchase;

       
      issue += purchase;

       
      remaining -= spend;
    }

    return (issue, remaining);
  }


   

   
  function _computeTokensPurchasedAtTier(
    Collection storage self,
    uint256 _tier,
    uint256 _wei
  )
    private
    view
    returns (uint256)
  {
    var paidBasis = MAX_DISCOUNT.sub(self.tiers[_tier].discount);

    return _wei.mul(self.baseRate).mul(MAX_DISCOUNT) / paidBasis;
  }

   
  function _computeCostForTokensAtTier(
    Collection storage self,
    uint256 _tier,
    uint256 _tokens
  )
    private
    view
    returns (uint256)
  {
    var paidBasis = MAX_DISCOUNT.sub(self.tiers[_tier].discount);

    var numerator = _tokens.mul(paidBasis);
    var denominator = MAX_DISCOUNT.mul(self.baseRate);

    var floor = _tokens.mul(paidBasis).div(
      MAX_DISCOUNT.mul(self.baseRate)
    );

     
    if (numerator % denominator != 0) {
      floor = floor + 1;
    }

    return floor;
  }
}

 

library Limits {
  using SafeMath for uint256;

  struct PurchaseRecord {
    uint256 blockNumber;
    uint256 amount;
  }

  struct Window {
    uint256 amount;   
    uint256 duration;   

    mapping (address => PurchaseRecord) purchases;
  }

   
  function recordPurchase(
    Window storage self,
    address _participant,
    uint256 _amount
  )
    internal
  {
    var blocksLeft = getBlocksUntilReset(self, _participant);
    var record = self.purchases[_participant];

    if (blocksLeft == 0) {
      record.amount = _amount;
      record.blockNumber = block.number;
    } else {
      record.amount = record.amount.add(_amount);
    }
  }

   
  function getLimit(Window storage self, address _participant)
    public
    view
    returns (uint256 _amount)
  {
    var blocksLeft = getBlocksUntilReset(self, _participant);

    if (blocksLeft == 0) {
      return self.amount;
    } else {
      return self.amount.sub(self.purchases[_participant].amount);
    }
  }

  function getBlocksUntilReset(Window storage self, address _participant)
    public
    view
    returns (uint256 _blocks)
  {
    var expires = self.purchases[_participant].blockNumber + self.duration;
    if (block.number > expires) {
      return 0;
    } else {
      return expires - block.number;
    }
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

 

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

 
contract SeeToken is Claimable {
  using SafeMath for uint256;

  string public constant name = "See Presale Token";
  string public constant symbol = "SEE";
  uint8 public constant decimals = 18;

  uint256 public totalSupply;
  mapping (address => uint256) balances;

  event Issue(address to, uint256 amount);

   
  function issue(address _to, uint256 _amount) onlyOwner public {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);

    Issue(_to, _amount);
  }

   
  function balanceOf(address _holder) public view returns (uint256 balance) {
    balance = balances[_holder];
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

contract Presale is Claimable, Pausable {
  using Discounts for Discounts.Collection;
  using Limits for Limits.Window;

  struct Participant {
    bool authorized;

    uint256 minimumTier;
  }


   

  SeeToken token;
  Discounts.Collection discounts;
  Limits.Window cap;

  mapping (address => Participant) participants;


  event Tier(uint256 discount, uint256 available);


   

  function Presale(address _token)
    public
  {
    token = SeeToken(_token);

    paused = true;
  }

   
  function claimToken() public {
    token.claimOwnership();
  }

   
  function unpause()
    onlyOwner
    whenPaused
    whenRateSet
    whenCapped
    whenOwnsToken
    public
  {
    super.unpause();
  }


   

   
  function setRate(uint256 _purchaseRate)
    onlyOwner
    whenPaused
    public
  {
    discounts.baseRate = _purchaseRate;
  }

   
  function limitPurchasing(uint256 _amount, uint256 _duration)
    onlyOwner
    whenPaused
    public
  {
    cap.amount = _amount;
    cap.duration = _duration;
  }

   
  function addTier(uint256 _discount, uint256 _available)
    onlyOwner
    whenPaused
    public
  {
    discounts.addTier(_discount, _available);

    Tier(_discount, _available);
  }

   
  function authorizeForTier(uint256 _minimumTier, address[] _authorized)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _authorized.length; i++) {
      participants[_authorized[i]] = Participant({
        authorized: true,
        minimumTier: _minimumTier
      });
    }
  }

   
  function withdraw()
    onlyOwner
    public
  {
    owner.transfer(this.balance);
  }


   

   
  function ()
    public
    payable
  {
    purchaseTokens();
  }

   
  function purchaseTokens()
    onlyAuthorized
    whenNotPaused
    public
    payable
  {
    var limit = cap.getLimit(msg.sender);

    var (purchased, refund) = discounts.purchaseTokens(
      limit,
      msg.value,
      participants[msg.sender].minimumTier
    );

    cap.recordPurchase(msg.sender, purchased);

     
    token.issue(msg.sender, purchased);

     
    if (refund > 0) {
      msg.sender.transfer(refund);
    }
  }


   

   
  function getPurchaseLimit()
    public
    view
    returns (uint256 _amount, uint256 _duration)
  {
    _amount = cap.amount;
    _duration = cap.duration;
  }

   
  function getTiers()
    public
    view
    returns (uint256[2][])
  {
    var records = discounts.tiers;
    uint256[2][] memory tiers = new uint256[2][](records.length);

    for (uint256 i = 0; i < records.length; i++) {
      tiers[i][0] = records[i].discount;
      tiers[i][1] = records[i].available;
    }

    return tiers;
  }

   
  function getAvailability(address _participant)
    public
    view
    returns (uint256[])
  {
    var participant = participants[_participant];
    uint256 minimumTier = participant.minimumTier;

     
     
    if (!participant.authorized) {
      minimumTier = discounts.tiers.length;
    }

    uint256[] memory tiers = new uint256[](discounts.tiers.length);

    for (uint256 i = minimumTier; i < tiers.length; i++) {
      tiers[i] = discounts.tiers[i].available;
    }

    return tiers;
  }


   

   
  modifier onlyAuthorized() {
    require(participants[msg.sender].authorized);
    _;
  }

   
  modifier whenRateSet() {
    require(discounts.baseRate != 0);
    _;
  }

   
  modifier whenCapped() {
    require(cap.amount != 0);
    _;
  }

   
  modifier whenOwnsToken() {
    require(token.owner() == address(this));
    _;
  }
}