 

pragma solidity ^0.4.24;
 
 
 
 
 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract ReentrancyGuard {

   
  uint256 private _guardCounter;

  constructor() internal {
     
     
    _guardCounter = 1;
  }

   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Presale is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  struct ReferralData {
    uint256 referrals;  
    uint256 bonusSum;   
    address[] children;  
  }

  uint256 public currentPrice = 0;

  bool public isActive = false;

  uint256 public currentDiscountSum = 0;                        
  uint256 public overallDiscountSum = 0;                        

  bool public referralsEnabled = true;                       

  mapping(address => uint) private referralBonuses;

  uint256 public referralBonusMaxDepth = 3;                                   
  mapping(uint256 => uint) public currentReferralCommissionPercentages;       
  uint256 public currentReferralBuyerDiscountPercentage = 5;                  

  mapping(address => address) private parentReferrals;     
  mapping(address => ReferralData) private referralData;   
  mapping(address => uint) private nodesBought;            

  mapping(address => bool) private manuallyAddedReferrals;  

  event MasternodeSold(address buyer, uint256 price, string coinsTargetAddress, bool referral);
  event MasternodePriceChanged(uint256 price);
  event ReferralAdded(address buyer, address parent);

  constructor() public {
    currentReferralCommissionPercentages[0] = 10;
    currentReferralCommissionPercentages[1] = 5;
    currentReferralCommissionPercentages[2] = 3;
  }

  function () external payable {
       
  }

  function buyMasternode(string memory coinsTargetAddress) public nonReentrant payable {
    _buyMasternode(coinsTargetAddress, false, owner());
  }

  function buyMasternodeReferral(string memory coinsTargetAddress, address referral) public nonReentrant payable {
    _buyMasternode(coinsTargetAddress, referralsEnabled, referral);
  }

  function _buyMasternode(string memory coinsTargetAddress, bool useReferral, address referral) internal {
    require(isActive, "Buying is currently deactivated.");
    require(currentPrice > 0, "There was no MN price set so far.");

    uint256 nodePrice = currentPrice;

     
    if (useReferral && isValidReferralAddress(referral)) {
      nodePrice = getDiscountedNodePrice();
    }

    require(msg.value >= nodePrice, "Sent amount of ETH was too low.");

     
    uint256 length = bytes(coinsTargetAddress).length;
    require(length >= 30 && length <= 42 , "Coins target address invalid");

    if (useReferral && isValidReferralAddress(referral)) {

      require(msg.sender != referral, "You can't be your own referral.");

       
       
      address parent = parentReferrals[msg.sender];
      if (referralData[parent].referrals == 0) {
        referralData[referral].referrals = referralData[referral].referrals.add(1);
        referralData[referral].children.push(msg.sender);
        parentReferrals[msg.sender] = referral;
      }

       
      uint256 discountSumForThisPayment = 0;
      address currentReferral = referral;

      for (uint256 level=0; level < referralBonusMaxDepth; level++) {
         
        if(isValidReferralAddress(currentReferral)) {

          require(msg.sender != currentReferral, "Invalid referral structure (you can't be in your own tree)");

           
          uint256 referralBonus = currentPrice.div(100).mul(currentReferralCommissionPercentages[level]);

           
          referralBonuses[currentReferral] = referralBonuses[currentReferral].add(referralBonus);

           
          referralData[currentReferral].bonusSum = referralData[currentReferral].bonusSum.add(referralBonus);
          discountSumForThisPayment = discountSumForThisPayment.add(referralBonus);

           
          currentReferral = parentReferrals[currentReferral];
        } else {
           
          break;
        }
      }

      require(discountSumForThisPayment < nodePrice, "Wrong calculation of bonuses/discounts - would be higher than the price itself");

      currentDiscountSum = currentDiscountSum.add(discountSumForThisPayment);
      overallDiscountSum = overallDiscountSum.add(discountSumForThisPayment);
    }

     
    nodesBought[msg.sender] = nodesBought[msg.sender].add(1);

    emit MasternodeSold(msg.sender, currentPrice, coinsTargetAddress, useReferral);
  }

  function setActiveState(bool active) public onlyOwner {
    isActive = active;
  }

  function setPrice(uint256 price) public onlyOwner {
    require(price > 0, "Price has to be greater than zero.");

    currentPrice = price;

    emit MasternodePriceChanged(price);
  }

  function setReferralsEnabledState(bool _referralsEnabled) public onlyOwner {
    referralsEnabled = _referralsEnabled;
  }

  function setReferralCommissionPercentageLevel(uint256 level, uint256 percentage) public onlyOwner {
    require(percentage >= 0 && percentage <= 20, "Percentage has to be between 0 and 20.");
    require(level >= 0 && level < referralBonusMaxDepth, "Invalid depth level");

    currentReferralCommissionPercentages[level] = percentage;
  }

  function setReferralBonusMaxDepth(uint256 depth) public onlyOwner {
    require(depth >= 0 && depth <= 10, "Referral bonus depth too high.");

    referralBonusMaxDepth = depth;
  }

  function setReferralBuyerDiscountPercentage(uint256 percentage) public onlyOwner {
    require(percentage >= 0 && percentage <= 20, "Percentage has to be between 0 and 20.");

    currentReferralBuyerDiscountPercentage = percentage;
  }

  function addReferralAddress(address addr) public onlyOwner {
    manuallyAddedReferrals[addr] = true;
  }

  function removeReferralAddress(address addr) public onlyOwner {
    manuallyAddedReferrals[addr] = false;
  }

  function withdraw(uint256 amount) public onlyOwner {
    owner().transfer(amount);
  }

  function withdrawReferralBonus() public nonReentrant returns (bool) {
    uint256 amount = referralBonuses[msg.sender];

    if (amount > 0) {
        referralBonuses[msg.sender] = 0;
        currentDiscountSum = currentDiscountSum.sub(amount);

        if (!msg.sender.send(amount)) {
            referralBonuses[msg.sender] = amount;
            currentDiscountSum = currentDiscountSum.add(amount);

            return false;
        }
    }

    return true;
  }

  function checkReferralBonusHeight(address addr) public view returns (uint) {
      return referralBonuses[addr];
  }

  function getNrOfReferrals(address addr) public view returns (uint) {
      return referralData[addr].referrals;
  }

  function getReferralBonusSum(address addr) public view returns (uint) {
      return referralData[addr].bonusSum;
  }

  function getReferralChildren(address addr) public view returns (address[] memory) {
      return referralData[addr].children;
  }

  function getReferralChild(address addr, uint256 idx) public view returns (address) {
      return referralData[addr].children[idx];
  }

  function isValidReferralAddress(address addr) public view returns (bool) {
      return nodesBought[addr] > 0 || manuallyAddedReferrals[addr] == true;
  }

  function getNodesBoughtCountForAddress(address addr) public view returns (uint256) {
      return nodesBought[addr];
  }

  function getDiscountedNodePrice() public view returns (uint256) {
      return currentPrice.sub(currentPrice.div(100).mul(currentReferralBuyerDiscountPercentage));
  }
}