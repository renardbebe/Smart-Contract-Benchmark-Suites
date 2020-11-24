 

pragma solidity 0.4.23;

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
 
contract OracleEscrow is Ownable {
  uint256 public expiration;
  bool public contractExecuted;
  address public depositor;
  address public beneficiary;
  IOracle internal oracle;
  

   
   
  bytes32 public constant EXPECTED = "yes";

   
   
  uint256 internal constant TO_EXPIRE = 30 days;

   
  constructor(address _oracle, address _depositor, address _beneficiary) public payable Ownable() {
    oracle = IOracle(_oracle);
    depositor = _depositor;
    beneficiary = _beneficiary;
    contractExecuted = false;
    expiration = now + TO_EXPIRE;
  }

   
  event ContractExecuted(bytes32 message);
  
   
  function() external payable onlyDepositor {
    require(contractExecuted == false);
    require(now < expiration);
  }
  
   
  function executeContract() public checkAuthorizedUser() {
    require(address(this).balance > 0);
    if (oracle.current() == EXPECTED) {
      contractExecuted = true;
      emit ContractExecuted("Payment sent to beneficiary.");
      beneficiary.transfer(address(this).balance);
    } else if (now >= expiration) {
      contractExecuted = true;
      emit ContractExecuted("Payment refunded to depositor.");
      depositor.transfer(address(this).balance);
    }
  }

   
  function requestOracleValue() public view onlyOwner returns(bytes32) {
    return oracle.current();
  }

   
  modifier checkAuthorizedUser() {
    require(msg.sender == owner || msg.sender == depositor || msg.sender == beneficiary, "Only authorized users may call this function.");
    _;
  }
  
   
  modifier onlyDepositor() {
    require(msg.sender == depositor, "Only the depositor may call this function.");
    _;
  }
}

 
interface IOracle{
  function current() view external returns(bytes32);
}