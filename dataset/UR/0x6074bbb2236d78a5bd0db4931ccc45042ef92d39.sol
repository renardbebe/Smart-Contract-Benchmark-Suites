 

pragma solidity ^0.4.24;

 
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

contract BabyOnChain is
    Ownable
{
    string public name = "Who are you?";
    string public birthday = "20181018";
    uint256 public timestamp = 1539871627;
    uint256 public weight = 35;
    uint256 public height = 51;
    string public sex = "girl";
    string public fatherName = "熊炜";
    string public motherName = "沈雨婷";

    constructor () public {
        owner = msg.sender;
    }

    function named(string yourName) public onlyOwner {
        name = yourName;
    }
}