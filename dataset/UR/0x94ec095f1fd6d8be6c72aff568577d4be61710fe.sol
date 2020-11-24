 

pragma solidity ^0.4.23;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

 

contract AifiAsset is Ownable {
  using SafeMath for uint256;

  enum AssetState { Pending, Active, Expired }
  string public assetType;
  uint256 public totalSupply;
  AssetState public state;

  constructor() public {
    state = AssetState.Pending;
  }

  function setState(AssetState _state) public onlyOwner {
    state = _state;
    emit SetStateEvent(_state);
  }

  event SetStateEvent(AssetState indexed state);
}

 

contract InitAifiAsset is AifiAsset {
  string public assetType = "DEBT";
  uint public initialSupply = 1000 * 10 ** 18;
  string[] public subjectMatters;
  
  constructor() public {
    totalSupply = initialSupply;
  }

  function addSubjectMatter(string _subjectMatter) public onlyOwner {
    subjectMatters.push(_subjectMatter);
  }

  function updateSubjectMatter(uint _index, string _subjectMatter) public onlyOwner {
    require(_index <= subjectMatters.length);
    subjectMatters[_index] = _subjectMatter;
  }

  function getSubjectMattersSize() public view returns(uint) {
    return subjectMatters.length;
  }
}