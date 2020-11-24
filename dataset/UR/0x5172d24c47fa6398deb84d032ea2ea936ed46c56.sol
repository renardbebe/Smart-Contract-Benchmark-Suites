 

pragma solidity ^0.4.25;

 
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

 
 
 
contract RBACMixin {
   
  string constant FORBIDDEN = "Haven't enough right to access";
   
  mapping (address => bool) public owners;
   
  mapping (address => bool) public minters;

   
   
  event AddOwner(address indexed who);
   
   
  event DeleteOwner(address indexed who);

   
   
  event AddMinter(address indexed who);
   
   
  event DeleteMinter(address indexed who);

  constructor () public {
    _setOwner(msg.sender, true);
  }

   
  modifier onlyOwner() {
    require(isOwner(msg.sender), FORBIDDEN);
    _;
  }

   
  modifier onlyMinter() {
    require(isMinter(msg.sender), FORBIDDEN);
    _;
  }

   
   
   
  function isOwner(address _who) public view returns (bool) {
    return owners[_who];
  }

   
   
   
  function isMinter(address _who) public view returns (bool) {
    return minters[_who];
  }

   
   
   
   
  function addOwner(address _who) public onlyOwner returns (bool) {
    _setOwner(_who, true);
  }

   
   
   
   
  function deleteOwner(address _who) public onlyOwner returns (bool) {
    _setOwner(_who, false);
  }

   
   
   
   
  function addMinter(address _who) public onlyOwner returns (bool) {
    _setMinter(_who, true);
  }

   
   
   
   
  function deleteMinter(address _who) public onlyOwner returns (bool) {
    _setMinter(_who, false);
  }

   
   
   
   
  function _setOwner(address _who, bool _flag) private returns (bool) {
    require(owners[_who] != _flag);
    owners[_who] = _flag;
    if (_flag) {
      emit AddOwner(_who);
    } else {
      emit DeleteOwner(_who);
    }
    return true;
  }

   
   
   
   
  function _setMinter(address _who, bool _flag) private returns (bool) {
    require(minters[_who] != _flag);
    minters[_who] = _flag;
    if (_flag) {
      emit AddMinter(_who);
    } else {
      emit DeleteMinter(_who);
    }
    return true;
  }
}

interface IMintableToken {
  function mint(address _to, uint256 _amount) external returns (bool);
}


 
 
 
 
contract TokenBucket is RBACMixin, IMintableToken {
  using SafeMath for uint;
  
   
   
  uint256 public size;
   
   
  uint256 public rate;
   
   
  uint256 public lastMintTime;
   
  uint256 public leftOnLastMint;

   
   
  IMintableToken public token;

   
   
   
  event Leak(address indexed to, uint256 left);

   
   
   
  constructor (address _token, uint256 _size, uint256 _rate) public {
    token = IMintableToken(_token);
    size = _size;
    rate = _rate;
    leftOnLastMint = _size;
  }

   
   
   
   
  function setSize(uint256 _size) public onlyOwner returns (bool) {
    size = _size;
    return true;
  }

   
   
   
   
  function setRate(uint256 _rate) public onlyOwner returns (bool) {
    rate = _rate;
    return true;
  }

   
   
   
   
   
  function setSizeAndRate(uint256 _size, uint256 _rate) public onlyOwner returns (bool) {
    return setSize(_size) && setRate(_rate);
  }

   
   
   
   
  function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {
    uint256 available = availableTokens();
    require(_amount <= available);
    leftOnLastMint = available.sub(_amount);
    lastMintTime = now;  
    require(token.mint(_to, _amount));
    return true;
  }

   
   
  function availableTokens() public view returns (uint) {
      
    uint256 timeAfterMint = now.sub(lastMintTime);
    uint256 refillAmount = rate.mul(timeAfterMint).add(leftOnLastMint);
    return size < refillAmount ? size : refillAmount;
  }
}