 

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




contract Whitelist is Ownable {

  mapping(address => bool) public isAddressWhitelist;

  event LogWhitelistAdded(address indexed participant, uint256 timestamp);
  event LogWhitelistDeleted(address indexed participant, uint256 timestamp);

  constructor() public {}

  function isWhite(address participant) public view returns (bool) {
    return isAddressWhitelist[participant];
  }

  function addWhitelist(address[] participants) public onlyOwner returns (bool) {
    for (uint256 i = 0; i < participants.length; i++) {
      isAddressWhitelist[participants[i]] = true;

      emit LogWhitelistAdded(participants[i], now);
    }

    return true;
  }

  function delWhitelist(address[] participants) public onlyOwner returns (bool) {
    for (uint256 i = 0; i < participants.length; i++) {
      isAddressWhitelist[participants[i]] = false;

      emit LogWhitelistDeleted(participants[i], now);
    }

    return true;
  }
}