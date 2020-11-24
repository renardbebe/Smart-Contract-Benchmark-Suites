 

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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

 

contract AifiAsset is Ownable {
  using SafeMath for uint256;

  enum AssetState { Pending, Active, Expired }
  string public assetType;
  uint256 public totalSupply;
  AssetState public state;

  constructor() public {
    state = AssetState.Pending;
  }

  function setState(AssetState _state) public onlyOwner {
    state = _state;
    emit SetStateEvent(_state);
  }

  event SetStateEvent(AssetState indexed state);
}

 

contract AifiToken is StandardToken, Ownable, BurnableToken {
  using SafeMath for uint256;

  string public name = "Test AIFIToken";
  string public symbol = "TAIFI";
  uint8 public decimals = 18;
  uint public initialSupply = 0;
  AifiAsset[] public aifiAssets;

  constructor() public {
    totalSupply_ = initialSupply;
    balances[owner] = initialSupply;
  }

  function _ownerSupply() internal view returns (uint256) {
    return balances[owner];
  }

  function _mint(uint256 _amount) internal onlyOwner {
    totalSupply_ = totalSupply_.add(_amount);
    balances[owner] = balances[owner].add(_amount);
  }

  function addAsset(AifiAsset _asset) public onlyOwner {
    require(_asset.state() == AifiAsset.AssetState.Pending);
    aifiAssets.push(_asset);
    _mint(_asset.totalSupply());
    emit AddAifiAssetEvent(_asset);
  }

  function mint(uint256 _amount) public onlyOwner {
    _mint(_amount);
    emit MintEvent(_amount);
  }

  function mintInterest(uint256 _amount) public onlyOwner {
    _mint(_amount);
    emit MintInterestEvent(_amount);
  }

  function payInterest(address _to, uint256 _amount) public onlyOwner {
    require(_ownerSupply() >= _amount);
    balances[owner] = balances[owner].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit PayInterestEvent(_to, _amount);
  }

  function burn(uint256 _value) public onlyOwner {
    super.burn(_value);
  }

  function setAssetToExpire(uint _index) public onlyOwner {
    AifiAsset asset = aifiAssets[_index];
    super.burn(asset.totalSupply());
    emit SetAssetToExpireEvent(_index, asset);
  }

   
  event AddAifiAssetEvent(AifiAsset indexed assetAddress);
  event MintEvent(uint256 indexed amount);
  event MintInterestEvent(uint256 indexed amount);
  event PayInterestEvent(address indexed to, uint256 indexed amount);
  event SetAssetToExpireEvent(uint indexed index, AifiAsset indexed asset);
}