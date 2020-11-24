 

pragma solidity ^0.4.21;

 
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
     
     
     
    return a / b;
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

 
contract ERC20Token {
  using SafeMath for uint256;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  mapping(address => uint256) internal balances_;
  mapping (address => mapping (address => uint256)) internal allowed_;

  uint256 internal totalSupply_;
  string public name;
  string public symbol;
  uint8 public decimals;

  function ERC20Token(
    string tokenName,
    string tokenSymbol,
    uint8 tokenDecimals,
    uint256 tokenSupply,
    address initAddress,
    uint256 initBalance
  ) public {
    name = tokenName;
    symbol = tokenSymbol;
    decimals = tokenDecimals;
    totalSupply_ = tokenSupply * 10 ** uint256(decimals);
    if (initBalance > 0) {
        uint256 ib = initBalance * 10 ** uint256(decimals);
        require(ib <= totalSupply_);
        balances_[initAddress] = ib;
        if (ib < totalSupply_) {
            balances_[msg.sender] = totalSupply_.sub(ib);
        }
    } else {
        balances_[msg.sender] = totalSupply_;
    }
  }

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances_[_owner];
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed_[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances_[msg.sender]);

    balances_[msg.sender] = balances_[msg.sender].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances_[_from]);
    require(_value <= allowed_[_from][msg.sender]);

    balances_[_from] = balances_[_from].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed_[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
}