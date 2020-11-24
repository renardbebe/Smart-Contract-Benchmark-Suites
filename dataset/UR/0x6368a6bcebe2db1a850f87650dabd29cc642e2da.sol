 

pragma solidity ^0.4.18;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}

contract Cryptonationz is DetailedERC20, StandardToken, BurnableToken {

    uint256 public publicAllocation;
    uint256 public companyAllocation;
    uint256 public devAllocation;
    uint256 public advisorsAllocation;
    uint256 public reservedAllocation;

    function Cryptonationz
    (
        string _name,
        string _symbol,
        uint8 _decimals,
        address _pubAddress,
        address _compAddress,
        address _devAddress,
        address _advAddress,
        address _reserveAddress
    ) 
    DetailedERC20(_name, _symbol, _decimals)
    public
    {
        require(_pubAddress != address(0) && _compAddress != address(0) && _devAddress != address(0));
        require(_advAddress != address(0) && _reserveAddress != address(0));

        totalSupply_ = 400000000 * (10 ** uint256(_decimals));

        publicAllocation = (70 * totalSupply_) / 100;
        companyAllocation = (10 * totalSupply_) / 100;
        devAllocation = (10 * totalSupply_) / 100;
        advisorsAllocation = (5 * totalSupply_) / 100;
        reservedAllocation = (5 * totalSupply_) / 100;

        _allocation(_pubAddress, _compAddress, _devAddress, _advAddress, _reserveAddress);

    }

    function _allocation(address _pubAddress, address _compAddress, address _devAddress, address _advAddress, address _reserveAddress) internal {
        balances[_pubAddress] = balances[_pubAddress].add(publicAllocation);
        balances[_compAddress] = balances[_compAddress].add(companyAllocation);
        balances[_devAddress] = balances[_devAddress].add(devAllocation);
        balances[_advAddress] = balances[_advAddress].add(advisorsAllocation);
        balances[_reserveAddress] = balances[_reserveAddress].add(reservedAllocation);

        Transfer(address(0), _pubAddress, publicAllocation);
        Transfer(address(0), _compAddress, companyAllocation);
        Transfer(address(0), _devAddress, devAllocation);
        Transfer(address(0), _advAddress, advisorsAllocation);
        Transfer(address(0), _reserveAddress, reservedAllocation);
    }


}