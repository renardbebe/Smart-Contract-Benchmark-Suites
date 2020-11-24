 

pragma solidity ^0.4.24;

 


 
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


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
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


 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}


 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}


 
contract Superuser is Ownable, RBAC {
  string public constant ROLE_SUPERUSER = "superuser";

  constructor () public {
    addRole(msg.sender, ROLE_SUPERUSER);
  }

   
  modifier onlySuperuser() {
    checkRole(msg.sender, ROLE_SUPERUSER);
    _;
  }

  modifier onlyOwnerOrSuperuser() {
    require(msg.sender == owner || isSuperuser(msg.sender));
    _;
  }

   
  function isSuperuser(address _addr)
    public
    view
    returns (bool)
  {
    return hasRole(_addr, ROLE_SUPERUSER);
  }

   
  function transferSuperuser(address _newSuperuser) public onlySuperuser {
    require(_newSuperuser != address(0));
    removeRole(msg.sender, ROLE_SUPERUSER);
    addRole(_newSuperuser, ROLE_SUPERUSER);
  }

   
  function transferOwnership(address _newOwner) public onlyOwnerOrSuperuser {
    _transferOwnership(_newOwner);
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


 

interface IAirdrop {

  function isVerifiedUser(address user) external view returns (bool);
  function isCollected(address user, bytes32 airdropId) external view returns (bool);
  function getAirdropIds()external view returns(bytes32[]);
  function getAirdropIdsByContractAddress(address contractAddress)external view returns(bytes32[]);
  function getUser(address userAddress) external view returns (
    address,
    string,
    uint256,
    uint256
  );
  function getAirdrop(
    bytes32 airdropId
    ) external view returns (address, uint256, bool);
  function updateVeifyFee(uint256 fee) external;
  function verifyUser(string name) external payable;
  function addAirdrop (address contractAddress, uint256 countPerUser, bool needVerifiedUser) external;
  function claim(bytes32 airdropId) external;
  function withdrawToken(address contractAddress, address to) external;
  function withdrawEth(address to) external;

  
  

   

  event UpdateVeifyFee (
    uint256 indexed fee
  );

  event VerifyUser (
    address indexed user
  );

  event AddAirdrop (
    address indexed contractAddress,
    uint256 countPerUser,
    bool needVerifiedUser
  );

  event Claim (
    bytes32 airdropId,
    address user
  );

  event WithdrawToken (
    address indexed contractAddress,
    address to,
    uint256 count
  );

  event WithdrawEth (
    address to,
    uint256 count
  );
}







contract ERC20Interface {
  function transfer(address to, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
  function balanceOf(address tokenOwner) public view returns (uint balance);
}
contract Airdrop is Superuser, Pausable, IAirdrop {

  using SafeMath for *;

  struct User {
    address user;
    string name;
    uint256 verifytime;
    uint256 verifyFee;
  }

  struct Airdrop {
    address contractAddress;
    uint256 countPerUser;  
    bool needVerifiedUser;
  }

  uint256 public verifyFee = 2e16;  
  bytes32[] public airdropIds;  

  mapping (address => User) public userAddressToUser;
  mapping (address => bytes32[]) contractAddressToAirdropId;
  mapping (bytes32 => Airdrop) airdropIdToAirdrop;
  mapping (bytes32 => mapping (address => bool)) airdropIdToUserAddress;
  mapping (address => uint256) contractAddressToAirdropCount;


  function isVerifiedUser(address user) external view returns (bool){
    return userAddressToUser[user].user == user;
  }

  function isCollected(address user, bytes32 airdropId) external view returns (bool) {
    return airdropIdToUserAddress[airdropId][user];
  }

  function getAirdropIdsByContractAddress(address contractAddress)external view returns(bytes32[]){
    return contractAddressToAirdropId[contractAddress];
  }
  function getAirdropIds()external view returns(bytes32[]){
    return airdropIds;
  }

  function tokenTotalClaim(address contractAddress)external view returns(uint256){
    return contractAddressToAirdropCount[contractAddress];
  }

  function getUser(
    address userAddress
    ) external view returns (address, string, uint256 ,uint256){
    User storage user = userAddressToUser[userAddress];
    return (user.user, user.name, user.verifytime, user.verifyFee);
  }

  function getAirdrop(
    bytes32 airdropId
    ) external view returns (address, uint256, bool){
    Airdrop storage airdrop = airdropIdToAirdrop[airdropId];
    return (airdrop.contractAddress, airdrop.countPerUser, airdrop.needVerifiedUser);
  }
  
  function updateVeifyFee(uint256 fee) external onlyOwnerOrSuperuser{
    verifyFee = fee;
    emit UpdateVeifyFee(fee);
  }

  function verifyUser(string name) external payable whenNotPaused {
    address sender = msg.sender;
    require(!this.isVerifiedUser(sender), "Is Verified User");
    uint256 _ethAmount = msg.value;
    require(_ethAmount >= verifyFee, "LESS FEE");
    uint256 payExcess = _ethAmount.sub(verifyFee);
    if(payExcess > 0) {
      sender.transfer(payExcess);
    }
    
    User memory _user = User(
      sender,
      name,
      block.timestamp,
      verifyFee
    );

    userAddressToUser[sender] = _user;
    emit VerifyUser(msg.sender);
  }

  function addAirdrop(address contractAddress, uint256 countPerUser, bool needVerifiedUser) external onlyOwnerOrSuperuser{
    bytes32 airdropId = keccak256(
      abi.encodePacked(block.timestamp, contractAddress, countPerUser, needVerifiedUser)
    );

    Airdrop memory _airdrop = Airdrop(
      contractAddress,
      countPerUser,
      needVerifiedUser
    );
    airdropIdToAirdrop[airdropId] = _airdrop;
    airdropIds.push(airdropId);
    contractAddressToAirdropId[contractAddress].push(airdropId);
    emit AddAirdrop(contractAddress, countPerUser, needVerifiedUser);
  }

  function claim(bytes32 airdropId) external whenNotPaused {

    Airdrop storage _airdrop = airdropIdToAirdrop[airdropId];
    if (_airdrop.needVerifiedUser) {
      require(this.isVerifiedUser(msg.sender));
    }
    
    require(!this.isCollected(msg.sender, airdropId), "The same Airdrop can only be collected once per address.");
    ERC20Interface erc20 = ERC20Interface(_airdrop.contractAddress);
    erc20.transfer(msg.sender, _airdrop.countPerUser);
    airdropIdToUserAddress[airdropId][msg.sender] = true;
     
    contractAddressToAirdropCount[_airdrop.contractAddress] = 
      contractAddressToAirdropCount[_airdrop.contractAddress].add(_airdrop.countPerUser);
    emit Claim(airdropId, msg.sender);
  }

  function withdrawToken(address contractAddress, address to) external onlyOwnerOrSuperuser {
    ERC20Interface erc20 = ERC20Interface(contractAddress);
    uint256 balance = erc20.balanceOf(address(this));
    erc20.transfer(to, balance);
    emit WithdrawToken(contractAddress, to, balance);
  }

  function withdrawEth(address to) external onlySuperuser {
    uint256 balance = address(this).balance;
    to.transfer(balance);
    emit WithdrawEth(to, balance);
  }

}