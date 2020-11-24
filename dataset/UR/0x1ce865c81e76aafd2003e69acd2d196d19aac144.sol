 

pragma solidity 0.4.21;




 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value)
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
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



 
 
 
 
contract BiddableEscrow is CanReclaimToken {

  using SafeMath for uint256;

   
  mapping (string => EscrowDeposit) private escrows;

   
   
   
  address public arbitrator;

   
   
   
  uint256 public accumulatedGasFees;

  struct EscrowDeposit {
     
    bool exists;

     
    address bidder;

     
     
     
    bytes data;

     
    uint256 amount;
  }

  modifier onlyArbitrator() {
    require(msg.sender == arbitrator);
    _;
  }

   
   
  function BiddableEscrow(address _arbitrator) public {
    arbitrator = _arbitrator;
    accumulatedGasFees = 0;
  }

   
   
  function setArbitrator(address _newArbitrator) external onlyOwner {
    arbitrator = _newArbitrator;
  }

   
   
   
  event Created(address indexed sender, string id, bytes data);

   
   
   
   
   
   
   
   
   
   
  function deposit(
    string _id,
    uint256 _depositAmount,
    bytes _data,
    uint8 _v,
    bytes32 _r,
    bytes32 _s)
    external payable
  {
     
    require(msg.value == _depositAmount);

     
    require(!escrows[_id].exists);

    bytes32 hash = keccak256(_id, _depositAmount, _data);
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";

    address recoveredAddress = ecrecover(
      keccak256(prefix, hash),
      _v,
      _r,
      _s
    );

     
    require(recoveredAddress == arbitrator);

    escrows[_id] = EscrowDeposit(
      true,
      msg.sender,
      _data,
      msg.value);

    emit Created(msg.sender, _id, _data);
  }

  uint256 public constant RELEASE_GAS_FEES = 45989;

   
   
  event Released(address indexed sender, address indexed bidder, uint256 value, string id);

   
   
  function release(string _id) external onlyArbitrator {
     
    require(escrows[_id].exists);

    EscrowDeposit storage escrowDeposit = escrows[_id];

     
    uint256 gasFees = RELEASE_GAS_FEES.mul(tx.gasprice);
    uint256 amount = escrowDeposit.amount.sub(gasFees);
    address bidder = escrowDeposit.bidder;

     
    delete escrows[_id];

    accumulatedGasFees = accumulatedGasFees.add(gasFees);
    bidder.transfer(amount);

    emit Released(
      msg.sender,
      bidder,
      amount,
      _id);
  }

   
   
  function withdrawAccumulatedFees(address _to) external onlyOwner {
    uint256 transferAmount = accumulatedGasFees;
    accumulatedGasFees = 0;

    _to.transfer(transferAmount);
  }

   
   
   
  function getEscrowDeposit(string _id) external view returns (address bidder, bytes data, uint256 amount) {
     
    require(escrows[_id].exists);

    EscrowDeposit storage escrowDeposit = escrows[_id];

    bidder = escrowDeposit.bidder;
    data = escrowDeposit.data;
    amount = escrowDeposit.amount;
  }
}