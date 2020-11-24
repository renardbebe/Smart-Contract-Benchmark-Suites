 

pragma solidity ^0.4.25;

library SafeMath {

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);
    
    return c;
  }
}

 
contract KamaGamesToken {
  using SafeMath for uint256;

  mapping (address => uint256) private balances_;

  mapping (address => mapping (address => uint256)) private allowed_;

  uint256 private totalSupply_;
  
  event Chips(
    address indexed _payee,
    address indexed _to,
    uint256 _value
  );
  
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  event TokensBurned(
    address indexed burner,
    uint256 value
  );

  address private constant address_prefix = address(~uint256(0xFFFFFFFF));

  constructor() public {
    totalSupply_ = 31250000000000;
    balances_[msg.sender] = totalSupply_;
  }
  
  function name() public pure returns (string) { return("KamaGames Token"); }
  function symbol() public pure returns (string) { return("KGT"); }
  function decimals() public pure returns (uint8) {return 6;}
  
   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances_[_owner];
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed_[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances_[msg.sender]);
    require(_to != address(0));
    
    if(_to > address_prefix){
      _burn(msg.sender, _value);
      emit Chips(msg.sender, _to, _value);
      return true;
    }
    balances_[msg.sender] = balances_[msg.sender].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));

    allowed_[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances_[_from]);
    require(_value <= allowed_[_from][msg.sender]);
    require(_to != address(0));

    if(_to > address_prefix){
      _burn(_from,_value);
      emit Chips(msg.sender, _to, _value);
      return true;
    }

    balances_[_from] = balances_[_from].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    require(_spender != address(0));

    allowed_[msg.sender][_spender] = (
      allowed_[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    require(_spender != address(0));

    uint256 oldValue = allowed_[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed_[msg.sender][_spender] = 0;
    } else {
      allowed_[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

   
  function _burn(address _account, uint256 _amount) internal {
    require(_account != address(0));
    require(_amount <= balances_[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances_[_account] = balances_[_account].sub(_amount);
  }

   
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed_[_account][msg.sender]);

     
     
    allowed_[_account][msg.sender] = allowed_[_account][msg.sender].sub(
      _amount);
    _burn(_account, _amount);
  }
  
   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
    emit TokensBurned(msg.sender, _value);
  }

   
  function burnFrom(address _from, uint256 _value) public {
    _burnFrom(_from, _value);
    emit TokensBurned(_from, _value);
  }

}