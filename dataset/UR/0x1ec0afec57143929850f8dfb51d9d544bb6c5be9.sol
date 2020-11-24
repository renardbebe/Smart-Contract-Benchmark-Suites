 

pragma solidity ^0.4.24;

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract BCEOInterface {
  function owner() public view returns (address);
  function balanceOf(address who) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  
}


contract TransferContract is Ownable {
  address private addressBCEO; 
  address private addressABT; 
  
  BCEOInterface private bCEOInstance;

  function initTransferContract(address _addressBCEO) public onlyOwner returns (bool) {
    require(_addressBCEO != address(0));
    addressBCEO = _addressBCEO;
    bCEOInstance = BCEOInterface(addressBCEO);
    return true;
  }

  function batchTransfer (address sender, address[] _receivers,  uint256[] _amounts) public onlyOwner {
    uint256 cnt = _receivers.length;
    require(cnt > 0);
    require(cnt == _amounts.length);
    for ( uint i = 0 ; i < cnt ; i++ ) {
      uint256 numBitCEO = _amounts[i];
      address receiver = _receivers[i];
      bCEOInstance.transferFrom(sender, receiver, numBitCEO * (10 ** uint256(18)));
    }
  }

}