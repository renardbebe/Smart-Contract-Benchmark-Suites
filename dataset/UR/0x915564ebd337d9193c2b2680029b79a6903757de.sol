 

pragma solidity ^0.4.24;

 

 
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
    require(msg.sender == owner, "msg.sender not owner");
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
    require(_newOwner != address(0), "_newOwner == 0");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused, "The contract is paused");
    _;
  }

   
  modifier whenPaused() {
    require(paused, "The contract is not paused");
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

 
contract Destructible is Ownable {
   
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

 

 
contract ERC20Supplier is
  Pausable,
  Destructible
{
  using SafeMath for uint;

  ERC20 public token;
  
  address public wallet;
  address public reserve;
  
  uint public rate;

  event LogWithdrawAirdrop(address indexed _from, address indexed _token, uint amount);
  event LogReleaseTokensTo(address indexed _from, address indexed _to, uint _amount);
  event LogSetWallet(address indexed _wallet);
  event LogSetReserve(address indexed _reserve);
  event LogSetToken(address indexed _token);
  event LogSetrate(uint _rate);

   
  constructor(
    address _wallet,
    address _reserve,
    address _token,
    uint _rate
  )
    public
  {
    require(_wallet != address(0), "_wallet == address(0)");
    require(_reserve != address(0), "_reserve == address(0)");
    require(_token != address(0), "_token == address(0)");
    require(_rate != 0, "_rate == 0");
    wallet = _wallet;
    reserve = _reserve;
    token = ERC20(_token);
    rate = _rate;
  }

  function() public payable {
    releaseTokensTo(msg.sender);
  }

   
  function releaseTokensTo(address _receiver)
    internal
    whenNotPaused
    returns (bool) 
  {
    uint amount = msg.value.mul(rate);
    wallet.transfer(msg.value);
    require(
      token.transferFrom(reserve, _receiver, amount),
      "transferFrom reserve to _receiver failed"
    );
    return true;
  }

   
  function setWallet(address _wallet) public onlyOwner returns (bool) {
    require(_wallet != address(0), "_wallet == 0");
    require(_wallet != wallet, "_wallet == wallet");
    wallet = _wallet;
    emit LogSetWallet(wallet);
    return true;
  }

   
  function setReserve(address _reserve) public onlyOwner returns (bool) {
    require(_reserve != address(0), "_reserve == 0");
    require(_reserve != reserve, "_reserve == reserve");
    reserve = _reserve;
    emit LogSetReserve(reserve);
    return true;
  }

   
  function setToken(address _token) public onlyOwner returns (bool) {
    require(_token != address(0), "_token == 0");
    require(_token != address(token), "_token == token");
    token = ERC20(_token);
    emit LogSetToken(token);
    return true;
  }

   
  function setRate(uint _rate) public onlyOwner returns (bool) {
    require(_rate != 0, "_rate == 0");
    require(_rate != rate, "_rate == rate");
    rate = _rate;
    emit LogSetrate(rate);
    return true;
  }

   
  function withdrawAirdrop(ERC20 _token)
    public
    onlyOwner
    returns(bool)
  {
    require(address(_token) != 0, "_token address == 0");
    require(
      _token.balanceOf(this) > 0,
      "dropped token balance == 0"
    );
    uint256 airdroppedTokenAmount = _token.balanceOf(this);
    _token.transfer(msg.sender, airdroppedTokenAmount);
    emit LogWithdrawAirdrop(msg.sender, _token, airdroppedTokenAmount);
    return true;
  }
}