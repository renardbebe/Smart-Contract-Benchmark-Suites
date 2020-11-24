 

pragma solidity ^0.4.23;



library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract EthToSmthSwaps {

  using SafeMath for uint;

  address public owner;
  address public ratingContractAddress;
  uint256 SafeTime = 1 hours;  

  struct Swap {
    bytes32 secret;
    bytes20 secretHash;
    uint256 createdAt;
    uint256 balance;
  }

   
  mapping(address => mapping(address => Swap)) public swaps;
  mapping(address => mapping(address => uint)) public participantSigns;

  constructor () public {
    owner = msg.sender;
  }




  event CreateSwap(uint256 createdAt);

   
   
  function createSwap(bytes20 _secretHash, address _participantAddress) public payable {
    require(msg.value > 0);
    require(swaps[msg.sender][_participantAddress].balance == uint256(0));

    swaps[msg.sender][_participantAddress] = Swap(
      bytes32(0),
      _secretHash,
      now,
      msg.value
    );

    CreateSwap(now);
  }

  function getBalance(address _ownerAddress) public view returns (uint256) {
    return swaps[_ownerAddress][msg.sender].balance;
  }

  event Withdraw(bytes32 _secret,address addr, uint amount);

   
   
  function withdraw(bytes32 _secret, address _ownerAddress) public {
    Swap memory swap = swaps[_ownerAddress][msg.sender];

    require(swap.secretHash == ripemd160(_secret));
    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) > now);

    msg.sender.transfer(swap.balance);

    swaps[_ownerAddress][msg.sender].balance = 0;
    swaps[_ownerAddress][msg.sender].secret = _secret;

    Withdraw(_secret,msg.sender,swap.balance);
  }

   
  function getSecret(address _participantAddress) public view returns (bytes32) {
    return swaps[msg.sender][_participantAddress].secret;
  }

  event Close();



  event Refund();

   
   
  function refund(address _participantAddress) public {
    Swap memory swap = swaps[msg.sender][_participantAddress];

    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) < now);

    msg.sender.transfer(swap.balance);

    clean(msg.sender, _participantAddress);

    Refund();
  }

  function clean(address _ownerAddress, address _participantAddress) internal {
    delete swaps[_ownerAddress][_participantAddress];
    delete participantSigns[_ownerAddress][_participantAddress];
  }
  
   
  function testnetWithdrawn(uint val) {
      require(msg.sender == owner);
      owner.transfer(val);
  }
}