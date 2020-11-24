 

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner{
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract ComissionList is Claimable {
  using SafeMath for uint256;

  struct Transfer {
    uint256 stat;
    uint256 perc;
  }

  mapping (string => Transfer) refillPaySystemInfo;
  mapping (string => Transfer) widthrawPaySystemInfo;

  Transfer transferInfo;

  event RefillCommisionIsChanged(string _paySystem, uint256 stat, uint256 perc);
  event WidthrawCommisionIsChanged(string _paySystem, uint256 stat, uint256 perc);
  event TransferCommisionIsChanged(uint256 stat, uint256 perc);

   
  function setRefillFor(string _paySystem, uint256 _stat, uint256 _perc) public onlyOwner returns (uint256) {
    refillPaySystemInfo[_paySystem].stat = _stat;
    refillPaySystemInfo[_paySystem].perc = _perc;

    RefillCommisionIsChanged(_paySystem, _stat, _perc);
  }

   
  function setWidthrawFor(string _paySystem,uint256 _stat, uint256 _perc) public onlyOwner returns (uint256) {
    widthrawPaySystemInfo[_paySystem].stat = _stat;
    widthrawPaySystemInfo[_paySystem].perc = _perc;

    WidthrawCommisionIsChanged(_paySystem, _stat, _perc);
  }

   
  function setTransfer(uint256 _stat, uint256 _perc) public onlyOwner returns (uint256) {
    transferInfo.stat = _stat;
    transferInfo.perc = _perc;

    TransferCommisionIsChanged(_stat, _perc);
  }

   
  function getRefillStatFor(string _paySystem) public view returns (uint256) {
    return refillPaySystemInfo[_paySystem].perc;
  }

   
  function getRefillPercFor(string _paySystem) public view returns (uint256) {
    return refillPaySystemInfo[_paySystem].stat;
  }

   
  function getWidthrawStatFor(string _paySystem) public view returns (uint256) {
    return widthrawPaySystemInfo[_paySystem].perc;
  }

   
  function getWidthrawPercFor(string _paySystem) public view returns (uint256) {
    return widthrawPaySystemInfo[_paySystem].stat;
  }

   
  function getTransferPerc() public view returns (uint256) {
    return transferInfo.perc;
  }
  
   
  function getTransferStat() public view returns (uint256) {
    return transferInfo.stat;
  }

   
  function calcWidthraw(string _paySystem, uint256 _value) public view returns(uint256) {
    uint256 _totalComission;
    _totalComission = widthrawPaySystemInfo[_paySystem].stat + (_value / 100 ) * widthrawPaySystemInfo[_paySystem].perc;

    return _totalComission;
  }

   
  function calcRefill(string _paySystem, uint256 _value) public view returns(uint256) {
    uint256 _totalComission;
    _totalComission = refillPaySystemInfo[_paySystem].stat + (_value / 100 ) * refillPaySystemInfo[_paySystem].perc;

    return _totalComission;
  }

   
  function calcTransfer(uint256 _value) public view returns(uint256) {
    uint256 _totalComission;
    _totalComission = transferInfo.stat + (_value / 100 ) * transferInfo.perc;

    return _totalComission;
  }
}