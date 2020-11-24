 

pragma solidity ^0.4.13;


 
library SafeMath {

  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    return a / b;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
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

  function assertTrue(bool val) internal {
    assert(val);
  }

  function assertFalse(bool val) internal {
    assert(!val);
  }
}


 
contract Ownable {

  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}


 
contract Haltable is Ownable {

  bool public halted;

  modifier revertIfHalted {
    if (halted) revert();
    _;
  }

  modifier onlyIfHalted {
    if (!halted) revert();
    _;
  }

  function halt() external onlyOwner {
    halted = true;
  }

  function unhalt() external onlyOwner onlyIfHalted {
    halted = false;
  }
}


 
contract ProvideSale is Haltable {
  using SafeMath for uint;

   
  address public multisig;

   
  uint public totalTransferred;

   
  uint public purchaserCount;

   
  mapping (uint128 => uint) public paymentsByPurchaser;

   
  mapping (address => uint) public paymentsByBenefactor;

   
  event PaymentForwarded(address source, uint amount, uint128 identifier, address benefactor);

   
  function ProvideSale(address _owner, address _multisig) {
    owner = _owner;
    multisig = _multisig;
  }

   
  function purchaseFor(uint128 identifier, address benefactor) public revertIfHalted payable {
    uint weiAmount = msg.value;

    if (weiAmount == 0) {
      revert();  
    }

    if (benefactor == 0) {
      revert();  
    }

    PaymentForwarded(msg.sender, weiAmount, identifier, benefactor);

    totalTransferred = totalTransferred.add(weiAmount);

    if (paymentsByPurchaser[identifier] == 0) {
      purchaserCount++;
    }

    paymentsByPurchaser[identifier] = paymentsByPurchaser[identifier].add(weiAmount);
    paymentsByBenefactor[benefactor] = paymentsByBenefactor[benefactor].add(weiAmount);

    if (!multisig.send(weiAmount)) revert();  
  }

   
  function purchase(uint128 identifier) public payable {
    purchaseFor(identifier, msg.sender);
  }

   
  function() public payable {
    purchase(0);
  }
}