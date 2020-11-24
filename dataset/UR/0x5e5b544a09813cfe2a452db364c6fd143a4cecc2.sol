 

pragma solidity ^0.4.19;

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

contract Traznite is Ownable{

using SafeMath for uint256;

   
   
   
event Transfer(address indexed from, address indexed to, uint256 value);  

 mapping(address => uint256) balances;

 string public name = "Traznite";
 uint256 totalSupply_;
 uint256 public RATE = 3 * 10 ** 18 wei;
 string public symbol = "TRZN";                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
 uint8 public decimals = 5;
 uint public INITIAL_SUPPLY = 20000000000 * 10 ** uint256(decimals);
 uint public totalSold_ = 0;
 bool public FirstTimeTransfer = false;
 
 constructor() public {
   totalSupply_ = INITIAL_SUPPLY;
   balances[msg.sender] = INITIAL_SUPPLY;
 }

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }


  
   
  function transfer(address _to, uint256 _value) onlyOwner public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    totalSold_ = totalSold_.add(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  modifier canTrans () {
    require(!FirstTimeTransfer);
    _;
  }
  
  
  
  function transfer_byFirstOwner(address _to, uint256 _value) onlyOwner canTrans public returns (bool) {
   require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    FirstTimeTransfer = true;
    return true; 
    
    
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function balanceEth(address _owner) public view returns (uint256) {
    return _owner.balance;
   }

  
}