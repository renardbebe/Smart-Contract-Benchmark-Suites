 

pragma solidity ^0.4.18;

 

 
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

 

 
contract SaleTracker is Pausable {
  using SafeMath for uint256;

   
  event PurchaseMade (address indexed _from, bytes8 _paymentCode, uint256 _value);

   
  mapping(address => uint256) public purchases;

   
  address[] public purchaserAddresses;

   
  bool public enforceAddressMatch;

   
  function SaleTracker(bool _enforceAddressMatch) public {
    enforceAddressMatch = _enforceAddressMatch;
    pause();
  }

   
  function setEnforceAddressMatch(bool _enforceAddressMatch) onlyOwner public {
    enforceAddressMatch = _enforceAddressMatch;
  }

   
  function purchase(bytes8 paymentCode) whenNotPaused public payable {

     
    require(msg.value != 0);

     
    require(paymentCode != 0);

     
    if (enforceAddressMatch) {

       
      bytes8 calculatedPaymentCode = bytes8(keccak256(msg.sender));

       
      require(calculatedPaymentCode == paymentCode);
    }

     
    uint256 existingPurchaseAmount = purchases[msg.sender];

     
    if (existingPurchaseAmount == 0) {
      purchaserAddresses.push(msg.sender);
    }

     
    purchases[msg.sender] = existingPurchaseAmount.add(msg.value);    

     
    owner.transfer(msg.value);

     
    PurchaseMade(msg.sender, paymentCode, msg.value);
  }

   
  function sweep() onlyOwner public {
    owner.transfer(this.balance);
  }

   
  function getPurchaserAddressCount() public constant returns (uint) {
    return purchaserAddresses.length;
  }

}