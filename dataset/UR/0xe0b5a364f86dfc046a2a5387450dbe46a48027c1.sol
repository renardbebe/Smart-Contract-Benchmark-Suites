 

pragma solidity ^0.4.25;


 

contract ERC223ReceivingContract {
   
  function tokenFallback(address _from, uint _value, bytes _data) public;
}


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}


 
contract ERC223Burnable is BurnableToken {

   
  event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

  string public name;
  string public symbol;
  uint8 public decimals;


   
   
   
  function transfer(address _to, uint _value) public returns (bool) {

     
     
    bytes memory empty;
    if (isContract(_to)) {
      return transferToContract(_to, _value, empty);
    } else {
      return transferToAddress(_to, _value, empty);
    }
  }


   
   
  function transfer(address _to, uint _value, bytes _data) public returns (bool) {

    if (isContract(_to)) {
      return transferToContract(_to, _value, _data);
    } else {
      return transferToAddress(_to, _value, _data);
    }
  }

   
  function isContract(address _addr) internal view returns (bool) {
    uint length;
    assembly {
     
      length := extcodesize(_addr)
    }
    return (length > 0);
  }

   
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }

   
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }
}


contract UniGoldToken is ERC223Burnable {
  address public minter;
  string public name = "UniGoldCoin";
  string public symbol = "UGCС";
  uint8 public decimals = 0;

  event Mint(address indexed to, uint256 amount);

   
  constructor(address _minter) public {
    minter = _minter;
  }

   
  modifier onlyMinter() {
    require(msg.sender == minter);
    _;
  }

   
  function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

}