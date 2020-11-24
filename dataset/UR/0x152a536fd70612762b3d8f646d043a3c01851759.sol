 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
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

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
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
    owner = 0x6C25AbD85AD13Bea51Ae93D04d89Af87475a961C;
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



 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address _who) external view returns (uint256);

  function allowance(address _owner, address _spender)
    external view returns (uint256);

  function transfer(address _to, uint256 _value) external returns (bool);

  function approve(address _spender, uint256 _value)
    external returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    external returns (bool);

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
}



 
contract ERC20 is IERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private balances_;

  mapping (address => mapping (address => uint256)) private allowed_;
  
  uint256 private totalSupply_;
  uint256 public tokensSold;
  
  address public fundsWallet = 0x1defDc87eF32479928eeB933891907Fb56818821;
  
  constructor() public {
      totalSupply_ = 10000000000e18;
      balances_[address(this)] = 10000000000e18;
      emit Transfer(address(0), address(this), totalSupply_);
      tokensSold = 0;
  }


   
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

    balances_[msg.sender] = balances_[msg.sender].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  
   
  function withdrawXPI(uint256 _value) public onlyOwner returns(bool){
    require(_value <= balances_[address(this)]);
    balances_[owner] = balances_[owner].add(_value);
    balances_[address(this)] = balances_[address(this)].sub(_value);
    emit Transfer(address(this), owner, _value);
    return true;
  }
  
  
   
  function() public payable {
      buyTokens(msg.sender);
  }
  

  function buyTokens(address _investor) public payable returns(bool) {
    require(_investor != address(0));
    require(msg.value >= 5e15 && msg.value <= 5e18);
    require(tokensSold < 6000000000e18);
    uint256 XPiToTransfer = msg.value.mul(20000000);
    if(msg.value < 5e16) {
        dispatchTokens(_investor, XPiToTransfer);
        return true;
    } else if(msg.value < 1e17) {
        XPiToTransfer = XPiToTransfer.add((XPiToTransfer.mul(20)).div(100));
        dispatchTokens(_investor, XPiToTransfer);
        return true;
    } else if(msg.value < 5e17) {
        XPiToTransfer = XPiToTransfer.add((XPiToTransfer.mul(30)).div(100));
        dispatchTokens(_investor, XPiToTransfer);
        return true;
    } else if(msg.value < 1e18) {
        XPiToTransfer = XPiToTransfer.add((XPiToTransfer.mul(50)).div(100));
        dispatchTokens(_investor, XPiToTransfer);
        return true;
    } else if(msg.value >= 1e18) {
        XPiToTransfer = XPiToTransfer.mul(2);
        dispatchTokens(_investor, XPiToTransfer);
        return true;
    }
  }
  
  function dispatchTokens(address _investor, uint256 _XPiToTransfer) internal {
      balances_[address(this)] = balances_[address(this)].sub(_XPiToTransfer);
      balances_[_investor] = balances_[_investor].add(_XPiToTransfer);
      emit Transfer(address(this), _investor, _XPiToTransfer);
      tokensSold = tokensSold.add(_XPiToTransfer);
      fundsWallet.transfer(msg.value);
  }
  

   
  function approve(address _spender, uint256 _value) public returns (bool) {
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
    require(_account != 0);
    require(_amount <= balances_[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances_[_account] = balances_[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

   
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed_[_account][msg.sender]);

     
     
    allowed_[_account][msg.sender] = allowed_[_account][msg.sender].sub(
      _amount);
    _burn(_account, _amount);
  }
}



 
contract ERC20Burnable is ERC20 {

  event TokensBurned(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

   
  function burnFrom(address _from, uint256 _value) public {
    _burnFrom(_from, _value);
  }

   
  function _burn(address _who, uint256 _value) internal {
    super._burn(_who, _value);
    emit TokensBurned(_who, _value);
  }
}


contract XPiBlock is ERC20Burnable {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    
    constructor() public {
        name = "XPiBlock";
        symbol = "XPI";
        decimals = 18;
    }
}