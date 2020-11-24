 

pragma solidity ^0.4.24;

 

 
contract ERC20 {

  using SafeMath for uint256;

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
  
  mapping (address => uint256) private balances_;

  mapping (address => mapping (address => uint256)) private allowed_;

  uint256 private totalSupply_;

   
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
    external
    view
    returns (uint256)
  {
    return allowed_[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) external returns (bool) {
    require(_value <= balances_[msg.sender]);
    require(_to != address(0));

    balances_[msg.sender] = balances_[msg.sender].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) external returns (bool) {
    allowed_[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    external
    returns (bool)
  {
    require(_value <= balances_[_from]);
    require(_value <= allowed_[_from][msg.sender]);
    require(_to != address(0));

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
    external
    returns (bool)
  {
    allowed_[msg.sender][_spender] = (
      allowed_[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    external
    returns (bool)
  {
    uint256 oldValue = allowed_[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed_[msg.sender][_spender] = 0;
    } else {
      allowed_[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

   
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);
    totalSupply_ = totalSupply_.add(_amount);
    balances_[_account] = balances_[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

   
  function _burn(address _account, uint256 _amount) internal {
    require(_account != 0);
    require(_amount <= balances_[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances_[_account] = balances_[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

}

contract DonutChain is ERC20 {
    
  event TokensBurned(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  uint8  public constant decimals = 0;
  string public constant name = "donutchain.io token #1";
  string public constant symbol = "DNT1";
  bool public flag = true;
  uint256 public endBlock;
  uint256 public mainGift;
  uint256 public amount = 0.001 ether;
  uint256 public increment = 0.000001 ether;
  address public donee;

  constructor() public {
    endBlock = block.number + 24 * 60 * 4;
  }
  function() external payable {
    require(flag);
    flag = false;
    if (endBlock > block.number) {
      require(msg.value >= amount);
      uint256 tokenAmount =  msg.value / amount;
      uint256 change = msg.value - tokenAmount * amount;
        if (change > 0 )
          msg.sender.transfer(change);
        if (msg.data.length == 20) {
          address refAddress = bToAddress(bytes(msg.data));
          refAddress.transfer(msg.value / 10);  
        } 
          mainGift += msg.value / 5;  
          donee = msg.sender;
          endBlock = block.number + 24 * 60 * 4;  
          amount += increment * tokenAmount;
          _mint(msg.sender, tokenAmount);
          emit Mint(msg.sender, tokenAmount);
          flag = true;
        } else {
          msg.sender.transfer(msg.value);
          emit MintFinished();
          selfdestruct(donee);
        }
  }
   

  function etherPerToken() public view returns (uint256) {
    uint256 sideETH = address(this).balance - mainGift;
    if (totalSupply() == 0)
        return 0;
    return sideETH / totalSupply();
  }

   
  function giftAmount(address _who) external view returns (uint256) {
    return etherPerToken() * balanceOf(_who);
  }
  
   
  function transferGift(uint256 _amount) external {
    require(balanceOf(msg.sender) >= _amount);
    uint256 ept = etherPerToken();
    _burn(msg.sender, _amount);
    emit TokensBurned(msg.sender, _amount);
    msg.sender.transfer(_amount * ept);
  }

  function bToAddress(
    bytes _bytesData
  )
    internal
    pure
    returns(address _refAddress) 
  {
    assembly {
      _refAddress := mload(add(_bytesData,0x14))
    }
    return _refAddress;
  }

}

 
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