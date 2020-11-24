 

pragma solidity ^0.4.24;

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

 

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

 

 
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

interface IBounty {

  function packageBounty(
    address owner,
    uint256 needHopsAmount,
    address[] tokenAddress,
    uint256[] tokenAmount)
    external returns (bool);
  
  function openBounty(uint256 bountyId)
    external returns (bool);
  
  function checkBounty(uint256 bountyId)
    external view returns (address, uint256, address[], uint256[]);

   
  event BountyEvt (
    uint256 bountyId,
    address owner,
    uint256 needHopsAmount,
    address[] tokenAddress,
    uint256[] tokenAmount
  );

  event OpenBountyEvt (
    uint256 bountyId,
    address sender,
    uint256 needHopsAmount,
    address[] tokenAddress,
    uint256[] tokenAmount
  );
}

 

 
contract WhitelistAdminRole {
  using Roles for Roles.Role;

  event WhitelistAdminAdded(address indexed account);
  event WhitelistAdminRemoved(address indexed account);

  Roles.Role private _whitelistAdmins;

  constructor () internal {
    _addWhitelistAdmin(msg.sender);
  }

  modifier onlyWhitelistAdmin() {
    require(isWhitelistAdmin(msg.sender));
    _;
  }

  function isWhitelistAdmin(address account) public view returns (bool) {
    return _whitelistAdmins.has(account);
  }

  function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
    _addWhitelistAdmin(account);
  }

  function renounceWhitelistAdmin() public {
    _removeWhitelistAdmin(msg.sender);
  }

  function _addWhitelistAdmin(address account) internal {
    _whitelistAdmins.add(account);
    emit WhitelistAdminAdded(account);
  }

  function _removeWhitelistAdmin(address account) internal {
    _whitelistAdmins.remove(account);
    emit WhitelistAdminRemoved(account);
  }
}

 

 
contract WhitelistedRole is WhitelistAdminRole {
  using Roles for Roles.Role;

  event WhitelistedAdded(address indexed account);
  event WhitelistedRemoved(address indexed account);

  Roles.Role private _whitelisteds;

  modifier onlyWhitelisted() {
    require(isWhitelisted(msg.sender));
    _;
  }

  function isWhitelisted(address account) public view returns (bool) {
    return _whitelisteds.has(account);
  }

  function addWhitelisted(address account) public onlyWhitelistAdmin {
    _addWhitelisted(account);
  }

  function removeWhitelisted(address account) public onlyWhitelistAdmin {
    _removeWhitelisted(account);
  }

  function renounceWhitelisted() public {
    _removeWhitelisted(msg.sender);
  }

  function _addWhitelisted(address account) internal {
    _whitelisteds.add(account);
    emit WhitelistedAdded(account);
  }

  function _removeWhitelisted(address account) internal {
    _whitelisteds.remove(account);
    emit WhitelistedRemoved(account);
  }
}

 

 
library SafeMath {
   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function mul(uint256 a, uint256 b) 
      internal 
      pure 
      returns (uint256 c) 
  {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b, "SafeMath mul failed");
    return c;
  }

   
  function sub(uint256 a, uint256 b)
      internal
      pure
      returns (uint256) 
  {
    require(b <= a, "SafeMath sub failed");
    return a - b;
  }

   
  function add(uint256 a, uint256 b)
      internal
      pure
      returns (uint256 c) 
  {
    c = a + b;
    require(c >= a, "SafeMath add failed");
    return c;
  }
  
   
  function sqrt(uint256 x)
      internal
      pure
      returns (uint256 y) 
  {
    uint256 z = ((add(x,1)) / 2);
    y = x;
    while (z < y) 
    {
      y = z;
      z = ((add((x / z),z)) / 2);
    }
  }
  
   
  function sq(uint256 x)
      internal
      pure
      returns (uint256)
  {
    return (mul(x,x));
  }
  
   
  function pwr(uint256 x, uint256 y)
      internal 
      pure 
      returns (uint256)
  {
    if (x==0)
        return (0);
    else if (y==0)
        return (1);
    else 
    {
      uint256 z = x;
      for (uint256 i=1; i < y; i++)
        z = mul(z,x);
      return (z);
    }
  }
}

 

interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address tokenOwner, address spender) external view returns (uint256);
  function burnFrom(address from, uint256 value) external;
}

interface IERC721 {
  function mintTo(address to) external returns (bool, uint256);
  function ownerOf(uint256 tokenId) external view returns (address);
  function burn(uint256 tokenId) external;
  function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract Bounty is WhitelistedRole, IBounty, Pausable {

  using SafeMath for *;

  address public erc20Address;
  address public bountyNFTAddress;

  struct Bounty {
    uint256 needHopsAmount;
    address[] tokenAddress;
    uint256[] tokenAmount;
  }

  bytes32[] public planBaseIds;

  mapping (uint256 => Bounty) bountyIdToBounty;

  constructor (address _erc20Address, address _bountyNFTAddress) {
    erc20Address = _erc20Address;
    bountyNFTAddress = _bountyNFTAddress;
  }

  function packageBounty (
    address owner,
    uint256 needHopsAmount,
    address[] tokenAddress,
    uint256[] tokenAmount
  ) whenNotPaused external returns (bool) {
    require(isWhitelisted(msg.sender)||isWhitelistAdmin(msg.sender));
    Bounty memory bounty = Bounty(needHopsAmount, tokenAddress, tokenAmount);
    (bool success, uint256 bountyId) = IERC721(bountyNFTAddress).mintTo(owner);
    require(success);
    bountyIdToBounty[bountyId] = bounty;
    emit BountyEvt(bountyId, owner, needHopsAmount, tokenAddress, tokenAmount);
  }

  function openBounty(uint256 bountyId)
    whenNotPaused external returns (bool) {
    Bounty storage bounty = bountyIdToBounty[bountyId];
    require(IERC721(bountyNFTAddress).ownerOf(bountyId) == msg.sender);

    require(IERC721(bountyNFTAddress).isApprovedForAll(msg.sender, address(this)));
    require(IERC20(erc20Address).balanceOf(msg.sender) >= bounty.needHopsAmount);
    require(IERC20(erc20Address).allowance(msg.sender, address(this)) >= bounty.needHopsAmount);
    IERC20(erc20Address).burnFrom(msg.sender, bounty.needHopsAmount);

    for (uint8 i = 0; i < bounty.tokenAddress.length; i++) {
      require(IERC20(bounty.tokenAddress[i]).transfer(msg.sender, bounty.tokenAmount[i]));
    }

    IERC721(bountyNFTAddress).burn(bountyId);
    delete bountyIdToBounty[bountyId];

    emit OpenBountyEvt(bountyId, msg.sender, bounty.needHopsAmount, bounty.tokenAddress, bounty.tokenAmount);
  }

  function checkBounty(uint256 bountyId) external view returns (
    address,
    uint256,
    address[],
    uint256[]) {
    Bounty storage bounty = bountyIdToBounty[bountyId];
    address owner = IERC721(bountyNFTAddress).ownerOf(bountyId);
    return (owner, bounty.needHopsAmount, bounty.tokenAddress, bounty.tokenAmount);
  }
}