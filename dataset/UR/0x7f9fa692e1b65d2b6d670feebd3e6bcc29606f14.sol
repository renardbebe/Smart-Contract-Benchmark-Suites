 

 


 




 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}


 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    if (halted) throw;
    _;
  }

  modifier stopNonOwnersInEmergency {
    if (halted && msg.sender != owner) throw;
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


 
contract PaymentForwarder is Haltable {

   
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

  function payWithoutChecksum(uint128 customerId, address benefactor) public stopInEmergency payable {

    uint weiAmount = msg.value;

    PaymentForwarded(msg.sender, weiAmount, customerId, benefactor);

     
    totalTransferred += weiAmount;

    if(paymentsByCustomer[customerId] == 0) {
      customerCount++;
    }

    paymentsByCustomer[customerId] += weiAmount;

     
     
     
    paymentsByBenefactor[benefactor] += weiAmount;

     
    if(!teamMultisig.send(weiAmount)) throw;
  }

   
   function pay(uint128 customerId, address benefactor, bytes1 checksum) public stopInEmergency payable {
     
     if (bytes1(sha3(customerId, benefactor)) != checksum) throw;
     payWithoutChecksum(customerId, benefactor);
   }

   
  function payForMyselfWithChecksum(uint128 customerId, bytes1 checksum) public payable {
     
    if (bytes1(sha3(customerId)) != checksum) throw;
    payWithoutChecksum(customerId, msg.sender);
  }

   
  function payForMyself(uint128 customerId) public payable {
    payWithoutChecksum(customerId, msg.sender);
  }

}