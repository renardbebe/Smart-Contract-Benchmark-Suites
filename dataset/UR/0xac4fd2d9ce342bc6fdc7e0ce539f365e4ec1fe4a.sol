 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


library SafeMath16 {
  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint16 a, uint16 b) internal pure returns (uint16) {
     
    uint16 c = a / b;
     
    return c;
  }
  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }
  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}








 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
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







 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}








 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}




 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}




 
contract MDAPPToken is MintableToken {
  using SafeMath16 for uint16;
  using SafeMath for uint256;

  string public constant name = "MillionDollarDapp";
  string public constant symbol = "MDAPP";
  uint8 public constant decimals = 0;

  mapping (address => uint16) locked;

  bool public forceTransferEnable = false;

   

   
  event AllowTransfer();

   

  modifier hasLocked(address _account, uint16 _value) {
    require(_value <= locked[_account], "Not enough locked tokens available.");
    _;
  }

  modifier hasUnlocked(address _account, uint16 _value) {
    require(balanceOf(_account).sub(uint256(locked[_account])) >= _value, "Not enough unlocked tokens available.");
    _;
  }

   
  modifier canTransfer(address _sender, uint256 _value) {
    require(_value <= transferableTokensOf(_sender), "Not enough unlocked tokens available.");
    _;
  }


   

  function lockToken(address _account, uint16 _value) onlyOwner hasUnlocked(_account, _value) public {
    locked[_account] = locked[_account].add(_value);
  }

  function unlockToken(address _account, uint16 _value) onlyOwner hasLocked(_account, _value) public {
    locked[_account] = locked[_account].sub(_value);
  }

   
  function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) public returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
  function transferableTokensOf(address _holder) public view returns (uint16) {
    if (!mintingFinished && !forceTransferEnable) return 0;

    return uint16(balanceOf(_holder)).sub(locked[_holder]);
  }

   
  function lockedTokensOf(address _holder) public view returns (uint16) {
    return locked[_holder];
  }

   
  function unlockedTokensOf(address _holder) public view returns (uint256) {
    return balanceOf(_holder).sub(uint256(locked[_holder]));
  }

   
  function allowTransfer() onlyOwner public {
    require(forceTransferEnable == false, 'Transfer already force-allowed.');

    forceTransferEnable = true;
    emit AllowTransfer();
  }
}




 
contract MDAPP is Ownable, HasNoEther, CanReclaimToken {
  using SafeMath for uint256;
  using SafeMath16 for uint16;

   
  MDAPPToken public token;

   
  address public sale;

   
  uint256 public presaleAdStart;

   
  uint256 public allAdStart;

   
  mapping (address => uint16) presales;

   
  bool[80][125] grid;

   
  struct Ad {
    address owner;
    Rect rect;
  }

   
  struct Rect {
    uint16 x;
    uint16 y;
    uint16 width;
    uint16 height;
  }

   
   
  Ad[] ads;

   
  uint256[] adIds;

   
   
  mapping (uint256 => uint256) adIdToIndex;


   

   
  event Claim(uint256 indexed id, address indexed owner, uint16 x, uint16 y, uint16 width, uint16 height);

   
  event Release(uint256 indexed id, address indexed owner);

   
  event EditAd(uint256 indexed id, address indexed owner, string link, string title, string text, string contact, bool NSFW, bytes32 indexed digest, bytes2 hashFunction, uint8 size, bytes4 storageEngine);

  event ForceNSFW(uint256 indexed id);


   

  modifier coordsValid(uint16 _x, uint16 _y, uint16 _width, uint16 _height) {
    require((_x + _width - 1) < 125, "Invalid coordinates.");
    require((_y + _height - 1) < 80, "Invalid coordinates.");

    _;
  }

  modifier onlyAdOwner(uint256 _id) {
    require(ads[_id].owner == msg.sender, "Access denied.");

    _;
  }

  modifier enoughTokens(uint16 _width, uint16 _height) {
    require(uint16(token.unlockedTokensOf(msg.sender)) >= _width.mul(_height), "Not enough unlocked tokens available.");

    _;
  }

  modifier claimAllowed(uint16 _width, uint16 _height) {
    require(_width > 0 &&_width <= 125 && _height > 0 && _height <= 80, "Invalid dimensions.");
    require(now >= presaleAdStart, "Claim period not yet started.");

    if (now < allAdStart) {
       
      uint16 tokens = _width.mul(_height);
      require(presales[msg.sender] >= tokens, "Not enough unlocked presale tokens available.");

      presales[msg.sender] = presales[msg.sender].sub(tokens);
    }

    _;
  }

  modifier onlySale() {
    require(msg.sender == sale);
    _;
  }

  modifier adExists(uint256 _id) {
    uint256 index = adIdToIndex[_id];
    require(adIds[index] == _id, "Ad does not exist.");

    _;
  }

   

  constructor(uint256 _presaleAdStart, uint256 _allAdStart, address _token) public {
    require(_presaleAdStart >= now);
    require(_allAdStart > _presaleAdStart);

    presaleAdStart = _presaleAdStart;
    allAdStart = _allAdStart;
    token = MDAPPToken(_token);
  }

  function setMDAPPSale(address _mdappSale) onlyOwner external {
    require(sale == address(0));
    sale = _mdappSale;
  }

   

   
  function mint(address _beneficiary, uint256 _tokenAmount, bool isPresale) onlySale external {
    if (isPresale) {
      presales[_beneficiary] = presales[_beneficiary].add(uint16(_tokenAmount));
    }
    token.mint(_beneficiary, _tokenAmount);
  }

   
  function finishMinting() onlySale external {
    token.finishMinting();
  }


   
  function claim(uint16 _x, uint16 _y, uint16 _width, uint16 _height)
    claimAllowed(_width, _height)
    coordsValid(_x, _y, _width, _height)
    external returns (uint)
  {
    Rect memory rect = Rect(_x, _y, _width, _height);
    return claimShortParams(rect);
  }

   
   
  function claimShortParams(Rect _rect)
    enoughTokens(_rect.width, _rect.height)
    internal returns (uint id)
  {
    token.lockToken(msg.sender, _rect.width.mul(_rect.height));

     
    for (uint16 i = 0; i < _rect.width; i++) {
      for (uint16 j = 0; j < _rect.height; j++) {
        uint16 x = _rect.x.add(i);
        uint16 y = _rect.y.add(j);

        if (grid[x][y]) {
          revert("Already claimed.");
        }

         
        grid[x][y] = true;
      }
    }

     
    id = createPlaceholderAd(_rect);

    emit Claim(id, msg.sender, _rect.x, _rect.y, _rect.width, _rect.height);
    return id;
  }

   
  function release(uint256 _id) adExists(_id) onlyAdOwner(_id) external {
    uint16 tokens = ads[_id].rect.width.mul(ads[_id].rect.height);

     
    for (uint16 i = 0; i < ads[_id].rect.width; i++) {
      for (uint16 j = 0; j < ads[_id].rect.height; j++) {
        uint16 x = ads[_id].rect.x.add(i);
        uint16 y = ads[_id].rect.y.add(j);

         
        grid[x][y] = false;
      }
    }

     
    delete ads[_id];
     
    uint256 key = adIdToIndex[_id];
     
    adIds[key] = adIds[adIds.length - 1];
     
    adIdToIndex[adIds[key]] = key;
     
    adIds.length--;

     
    if (now < allAdStart) {
       
      presales[msg.sender] = presales[msg.sender].add(tokens);
    }
    token.unlockToken(msg.sender, tokens);

    emit Release(_id, msg.sender);
  }

   
  function editAd(uint _id, string _link, string _title, string _text, string _contact, bool _NSFW, bytes32 _digest, bytes2 _hashFunction, uint8 _size, bytes4 _storageEnginge) adExists(_id) onlyAdOwner(_id) public {
    emit EditAd(_id, msg.sender, _link, _title, _text, _contact, _NSFW, _digest, _hashFunction, _size,  _storageEnginge);
  }

   
  function forceNSFW(uint256 _id) onlyOwner adExists(_id) external {
    emit ForceNSFW(_id);
  }

   
  function createPlaceholderAd(Rect _rect) internal returns (uint id) {
    Ad memory ad = Ad(msg.sender, _rect);
    id = ads.push(ad) - 1;
    uint256 key = adIds.push(id) - 1;
    adIdToIndex[id] = key;
    return id;
  }

   
  function presaleBalanceOf(address _holder) public view returns (uint16) {
    return presales[_holder];
  }

   
  function getAdIds() external view returns (uint256[]) {
    return adIds;
  }

   

   
  function allowTransfer() onlyOwner external {
    token.allowTransfer();
  }
}