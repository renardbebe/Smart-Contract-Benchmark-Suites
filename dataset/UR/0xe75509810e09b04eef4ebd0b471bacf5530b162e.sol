 

 
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
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

  modifier stopInEmergency {
    if (halted) throw;
    _;
  }

  modifier onlyInEmergency {
    if (!halted) throw;
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}



 
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
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

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}



 
contract PaymentForwarder is Haltable, SafeMath {

   
  address public teamMultisig;

   
  uint public totalTransferred;

   
  uint public customerCount;

   
  mapping(uint128 => uint) public paymentsByCustomer;

   
  mapping(address => uint) public paymentsByBenefactor;

   
  event PaymentForwarded(address source, uint amount, uint128 customerId, address benefactor);

   
  function PaymentForwarder(address _owner, address _teamMultisig) {
    teamMultisig = _teamMultisig;
    owner = _owner;
  }

   
  function pay(uint128 customerId, address benefactor) public stopInEmergency payable {

    uint weiAmount = msg.value;

    if(weiAmount == 0) {
      throw;  
    }

    if(customerId == 0) {
      throw;  
    }

    if(benefactor == 0) {
      throw;  
    }

    PaymentForwarded(msg.sender, weiAmount, customerId, benefactor);

    totalTransferred = safeAdd(totalTransferred, weiAmount);

    if(paymentsByCustomer[customerId] == 0) {
      customerCount++;
    }

    paymentsByCustomer[customerId] = safeAdd(paymentsByCustomer[customerId], weiAmount);

     
     
     
    paymentsByBenefactor[benefactor] = safeAdd(paymentsByBenefactor[benefactor], weiAmount);

     
    if(!teamMultisig.send(weiAmount)) throw;
  }

   
  function payForMyself(uint128 customerId) public payable {
    pay(customerId, msg.sender);
  }

}