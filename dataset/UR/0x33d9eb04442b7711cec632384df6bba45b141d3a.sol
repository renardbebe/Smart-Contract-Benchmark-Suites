 

pragma solidity 0.4.25;

 

contract Ownable {

    address public ownerField;

    constructor() public {
        ownerField = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerField, "Calling address not an owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        ownerField = newOwner;
    }

    function owner() public view returns(address) {
        return ownerField;
    }

}

 
library SafeMath {
   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);
    return c;

  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     
    return c;

  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }

}

interface IERC20 {

  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

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

contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   

  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);

    return true;

  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)

  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

    return true;
  }

   

  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from], "Insignificant balance in from address");
    require(to != address(0), "Invalid to address specified [0x0]");

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);

    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);

    emit Transfer(address(0), account, value);
  }



   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);

    emit Transfer(account, address(0), value);
  }

   

  function _burnFrom(address account, uint256 value) internal {

    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }

}

contract Pausable is Ownable {
    bool public paused;

    modifier ifNotPaused {
        require(!paused, "Contract is paused");
        _;
    }

    modifier ifPaused {
        require(paused, "Contract is not paused");
        _;
    }

     
    function pause() external onlyOwner {
        paused = true;
    }

     
    function resume() external onlyOwner ifPaused {
        paused = false;
    }
}

contract AirDropWinners is Ownable, Pausable {
using SafeMath for uint256;

  struct Contribution {  
    uint256 tokenAmount;
    bool    wasClaimed;
    bool    isValid;
  }


  address public tokenAddress;        
  uint256 public totalTokensClaimed;  
  uint256 public startTime;           
   

  mapping (address => Contribution) contributions;

  constructor (address _token) 
  Ownable() 
  public {
    tokenAddress = _token;
    startTime = now;
  }

   
  function getTotalTokensRemaining()
  ifNotPaused
  public
  view
  returns (uint256)
  {
    return ERC20(tokenAddress).balanceOf(this);
  }

   
  function isAddressInAirdropList(address _addressToLookUp)
  ifNotPaused
  public
  view
  returns (bool)
  {
    Contribution storage contrib = contributions[_addressToLookUp];
    return contrib.isValid;
  }

   
  function bulkAddAddressesToAirDrop(address[] _addressesToAdd)
  ifNotPaused
  public
  {
    require(_addressesToAdd.length > 0);
    for (uint i = 0; i < _addressesToAdd.length; i++) {
      _addAddressToAirDrop(_addressesToAdd[i]);
    }
    
  }

   
  function bulkAddAddressesToAirDropWithAward(address[] _addressesToAdd, uint256 _tokenAward)
  ifNotPaused
  public
  {
    require(_addressesToAdd.length > 0);
    require(_tokenAward > 0);
    for (uint i = 0; i < _addressesToAdd.length; i++) {
      _addAddressToAirdropWithAward(_addressesToAdd[i], _tokenAward);
    }
    
  }

   
  function _addAddressToAirdropWithAward(address _addressToAdd, uint256 _tokenAward)
  onlyOwner
  internal
  {
      require(_addressToAdd != 0);
      require(!isAddressInAirdropList(_addressToAdd));
      require(_tokenAward > 0);
      Contribution storage contrib = contributions[_addressToAdd];
      contrib.tokenAmount = _tokenAward.mul(10e7);
      contrib.wasClaimed = false;
      contrib.isValid = true;
  }

   
  function _addAddressToAirDrop(address _addressToAdd)
  onlyOwner
  internal
  {
      require(_addressToAdd != 0);
      require(!isAddressInAirdropList(_addressToAdd));
      Contribution storage contrib = contributions[_addressToAdd];
      contrib.tokenAmount = 30 * 10e7;
      contrib.wasClaimed = false;
      contrib.isValid = true;
  }

   
  function bulkRemoveAddressesFromAirDrop(address[] _addressesToRemove)
  ifNotPaused
  public
  {
    require(_addressesToRemove.length > 0);
    for (uint i = 0; i < _addressesToRemove.length; i++) {
      _removeAddressFromAirDrop(_addressesToRemove[i]);
    }

  }

   
  function _removeAddressFromAirDrop(address _addressToRemove)
  onlyOwner
  internal
  {
      require(_addressToRemove != 0);
      require(isAddressInAirdropList(_addressToRemove));
      Contribution storage contrib = contributions[_addressToRemove];
      contrib.tokenAmount = 0;
      contrib.wasClaimed = false;
      contrib.isValid = false;
  }

function setAirdropAddressWasClaimed(address _addressToChange, bool _newWasClaimedValue)
  ifNotPaused
  onlyOwner
  public
  {
    require(_addressToChange != 0);
    require(isAddressInAirdropList(_addressToChange));
    Contribution storage contrib = contributions[ _addressToChange];
    require(contrib.isValid);
    contrib.wasClaimed = _newWasClaimedValue;
  }

   
  function claimTokens() 
  ifNotPaused
  public {
    Contribution storage contrib = contributions[msg.sender];
    require(contrib.isValid, "Address not found in airdrop list");
    require(contrib.tokenAmount > 0, "There are currently no tokens to claim.");
    uint256 tempPendingTokens = contrib.tokenAmount;
    contrib.tokenAmount = 0;
    totalTokensClaimed = totalTokensClaimed.add(tempPendingTokens);
    contrib.wasClaimed = true;
    ERC20(tokenAddress).transfer(msg.sender, tempPendingTokens);
  }

   
  function() payable public {
    revert("ETH not accepted");
  }

}

contract SparkleAirDrop is AirDropWinners {
  using SafeMath for uint256;

  address initTokenContractAddress = 0x4b7aD3a56810032782Afce12d7d27122bDb96efF;
  
  constructor()
  AirDropWinners(initTokenContractAddress)
  public  
  {}

}