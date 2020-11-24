 

pragma solidity ^0.4.24;

contract Fog {
  address public owner;

  event OwnershipTransferred(
    address indexed owner,
    address indexed newOwner
  );

  event Winner(address indexed to, uint indexed value);
  event CupCake(address indexed to, uint indexed value);
  event Looser(address indexed from, uint indexed value);

  constructor() public {
    owner = msg.sender;
  }

  function move(uint256 direction) public payable {
    require(tx.origin == msg.sender);

    uint doubleValue = mul(msg.value, 2);
    uint minValue = 10000000000000000;  

     
    require(msg.value >= minValue && doubleValue <= address(this).balance);

     
    uint dice = uint(keccak256(abi.encodePacked(now + uint(msg.sender) + direction))) % 3;

     
    if (dice == 2) {
      msg.sender.transfer(doubleValue);
      emit Winner(msg.sender, doubleValue);

     
    } else {
       
      uint coin = uint(keccak256(abi.encodePacked(now + uint(msg.sender) + direction))) % 2;

       
      if (coin == 1) {
         
        uint eightyPercent = div(mul(msg.value, 80), 100);

        msg.sender.transfer(eightyPercent);
        emit CupCake(msg.sender, eightyPercent);

       
      } else {
        emit Looser(msg.sender, msg.value);
      }
    }
  }

  function drain(uint value) public onlyOwner {
    require(value > 0 && value < address(this).balance);
    owner.transfer(value);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function() public payable { }

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }
}