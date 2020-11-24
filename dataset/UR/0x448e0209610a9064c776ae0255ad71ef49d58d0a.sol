 

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

 

 

interface ILuckyblock{

  function getLuckyblockSpend(
    bytes32 luckyblockId
  ) external view returns (
    address[],
    uint256[],
    uint256
  ); 

  function getLuckyblockEarn(
    bytes32 luckyblockId
    ) external view returns (
    address[],
    uint256[],
    int[],
    uint256,
    int
  );

  function getLuckyblockBase(
    bytes32 luckyblockId
    ) external view returns (
      bool
  );

  function addLuckyblock(uint256 seed) external;

  function start(
    bytes32 luckyblockId
  ) external;

  function stop(
    bytes32 luckyblockId
  ) external;

  function updateLuckyblockSpend(
    bytes32 luckyblockId,
    address[] spendTokenAddresses, 
    uint256[] spendTokenCount,
    uint256 spendEtherCount
  ) external;

  function updateLuckyblockEarn (
    bytes32 luckyblockId,
    address[] earnTokenAddresses,
    uint256[] earnTokenCount,
    int[] earnTokenProbability,  
    uint256 earnEtherCount,
    int earnEtherProbability
  ) external;

  function getLuckyblockIds()external view returns(bytes32[]);
  function play(bytes32 luckyblockId) external payable;
  function withdrawToken(address contractAddress, address to, uint256 balance) external;
  function withdrawEth(address to, uint256 balance) external;

  
  

   

  event Play (
    bytes32 indexed luckyblockId,
    address user,
    uint8 random
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

  event Pay (
    address from,
    uint256 value
  );
}

 




contract ERC20Interface {
  function transfer(address to, uint tokens) public returns (bool);
  function transferFrom(address from, address to, uint tokens) public returns (bool);
  function balanceOf(address tokenOwner) public view returns (uint256);
  function allowance(address tokenOwner, address spender) public view returns (uint);
}
contract Luckyblock is Superuser, Pausable, ILuckyblock {

  using SafeMath for *;

  struct User {
    address user;
    string name;
    uint256 verifytime;
    uint256 verifyFee;
  }

  struct LuckyblockBase {
    bool ended;
  }

  struct LuckyblockSpend {
    address[] spendTokenAddresses;
    uint256[] spendTokenCount;
    uint256 spendEtherCount;
  }

  struct LuckyblockEarn {
    address[] earnTokenAddresses;
    uint256[] earnTokenCount;
    int[] earnTokenProbability;  
    uint256 earnEtherCount;
    int earnEtherProbability;
  }

  bytes32[] public luckyblockIds;  

  mapping (address => bytes32[]) contractAddressToLuckyblockId;

  mapping (bytes32 => LuckyblockEarn) luckyblockIdToLuckyblockEarn;
  mapping (bytes32 => LuckyblockSpend) luckyblockIdToLuckyblockSpend;
  mapping (bytes32 => LuckyblockBase) luckyblockIdToLuckyblockBase;


  mapping (bytes32 => mapping (address => bool)) luckyblockIdToUserAddress;
  mapping (address => uint256) contractAddressToLuckyblockCount;

  function () public payable {
    emit Pay(msg.sender, msg.value);
  }

  function getLuckyblockIds()external view returns(bytes32[]){
    return luckyblockIds;
  }

  function getLuckyblockSpend(
    bytes32 luckyblockId
    ) external view returns (
      address[],
      uint256[],
      uint256
    ) {
    LuckyblockSpend storage _luckyblockSpend = luckyblockIdToLuckyblockSpend[luckyblockId];
    return (
      _luckyblockSpend.spendTokenAddresses,
      _luckyblockSpend.spendTokenCount,
      _luckyblockSpend.spendEtherCount
      );
  }

  function getLuckyblockEarn(
    bytes32 luckyblockId
    ) external view returns (
      address[],
      uint256[],
      int[],
      uint256,
      int
    ) {
    LuckyblockEarn storage _luckyblockEarn = luckyblockIdToLuckyblockEarn[luckyblockId];
    return (
      _luckyblockEarn.earnTokenAddresses,
      _luckyblockEarn.earnTokenCount,
      _luckyblockEarn.earnTokenProbability,
      _luckyblockEarn.earnEtherCount,
      _luckyblockEarn.earnEtherProbability
      );
  }

  function getLuckyblockBase(
    bytes32 luckyblockId
    ) external view returns (
      bool
    ) {
    LuckyblockBase storage _luckyblockBase = luckyblockIdToLuckyblockBase[luckyblockId];
    return (
      _luckyblockBase.ended
      );
  }
  
  function addLuckyblock(uint256 seed) external onlyOwnerOrSuperuser {
    bytes32 luckyblockId = keccak256(
      abi.encodePacked(block.timestamp, seed)
    );
    LuckyblockBase memory _luckyblockBase = LuckyblockBase(
      false
    );
    luckyblockIds.push(luckyblockId);
    luckyblockIdToLuckyblockBase[luckyblockId] = _luckyblockBase;
  }

  function start(bytes32 luckyblockId) external{
    LuckyblockBase storage _luckyblockBase = luckyblockIdToLuckyblockBase[luckyblockId];
    _luckyblockBase.ended = false;
    luckyblockIdToLuckyblockBase[luckyblockId] = _luckyblockBase;
  }

  function stop(bytes32 luckyblockId) external{
    LuckyblockBase storage _luckyblockBase = luckyblockIdToLuckyblockBase[luckyblockId];
    _luckyblockBase.ended = true;
    luckyblockIdToLuckyblockBase[luckyblockId] = _luckyblockBase;
  }

  function updateLuckyblockSpend (
    bytes32 luckyblockId,
    address[] spendTokenAddresses, 
    uint256[] spendTokenCount,
    uint256 spendEtherCount
    ) external onlyOwnerOrSuperuser {
    LuckyblockSpend memory _luckyblockSpend = LuckyblockSpend(
      spendTokenAddresses,
      spendTokenCount,
      spendEtherCount
    );
    luckyblockIdToLuckyblockSpend[luckyblockId] = _luckyblockSpend;
  }

  function updateLuckyblockEarn (
    bytes32 luckyblockId,
    address[] earnTokenAddresses,
    uint256[] earnTokenCount,
    int[] earnTokenProbability,  
    uint256 earnEtherCount,
    int earnEtherProbability
    ) external onlyOwnerOrSuperuser {
    LuckyblockEarn memory _luckyblockEarn = LuckyblockEarn(
      earnTokenAddresses,
      earnTokenCount,
      earnTokenProbability,  
      earnEtherCount,
      earnEtherProbability
    );
    luckyblockIdToLuckyblockEarn[luckyblockId] = _luckyblockEarn;
  }


  function play(bytes32 luckyblockId) external payable whenNotPaused {
    LuckyblockBase storage _luckyblockBase = luckyblockIdToLuckyblockBase[luckyblockId];
    LuckyblockSpend storage _luckyblockSpend = luckyblockIdToLuckyblockSpend[luckyblockId];
    LuckyblockEarn storage _luckyblockEarn = luckyblockIdToLuckyblockEarn[luckyblockId];
    
    require(!_luckyblockBase.ended, "luckyblock is ended");

     
    require(msg.value >= _luckyblockSpend.spendEtherCount, "sender value not enough");

     
    if (_luckyblockSpend.spendTokenAddresses[0] != address(0x0)) {
      for (uint8 i = 0; i < _luckyblockSpend.spendTokenAddresses.length; i++) {

         
        require(
          ERC20Interface(
            _luckyblockSpend.spendTokenAddresses[i]
          ).balanceOf(address(msg.sender)) >= _luckyblockSpend.spendTokenCount[i]
        );

        require(
          ERC20Interface(
            _luckyblockSpend.spendTokenAddresses[i]
          ).allowance(address(msg.sender), address(this)) >= _luckyblockSpend.spendTokenCount[i]
        );

         
        ERC20Interface(_luckyblockSpend.spendTokenAddresses[i])
          .transferFrom(msg.sender, address(this), _luckyblockSpend.spendTokenCount[i]);
        }
    }
    
     
    if (_luckyblockEarn.earnTokenAddresses[0] !=
      address(0x0)) {
      for (uint8 j= 0; j < _luckyblockEarn.earnTokenAddresses.length; j++) {
         
        uint256 earnTokenCount = _luckyblockEarn.earnTokenCount[j];
        require(
          ERC20Interface(_luckyblockEarn.earnTokenAddresses[j])
          .balanceOf(address(this)) >= earnTokenCount
        );
      }
    }
    
     
    require(address(this).balance >= _luckyblockEarn.earnEtherCount, "contract value not enough");

     
    uint8 _random = random();

     
    for (uint8 k = 0; k < _luckyblockEarn.earnTokenAddresses.length; k++){
       
      if (_luckyblockEarn.earnTokenAddresses[0] 
        != address(0x0)){
        if (_random + _luckyblockEarn.earnTokenProbability[k] >= 100) {
          ERC20Interface(_luckyblockEarn.earnTokenAddresses[k])
            .transfer(msg.sender, _luckyblockEarn.earnTokenCount[k]);
        }
      }
    }
    uint256 value = msg.value;
    uint256 payExcess = value.sub(_luckyblockSpend.spendEtherCount);
    
     
    if (_random + _luckyblockEarn.earnEtherProbability >= 100) {
      uint256 balance = _luckyblockEarn.earnEtherCount.add(payExcess);
      if (balance > 0){
        msg.sender.transfer(balance);
      }
    } else if (payExcess > 0) {
      msg.sender.transfer(payExcess);
    }
    
    emit Play(luckyblockId, msg.sender, _random);
  }

  function withdrawToken(address contractAddress, address to, uint256 balance)
    external onlyOwnerOrSuperuser {
    ERC20Interface erc20 = ERC20Interface(contractAddress);
    if (balance == uint256(0x0)){
      erc20.transfer(to, erc20.balanceOf(address(this)));
      emit WithdrawToken(contractAddress, to, erc20.balanceOf(address(this)));
    } else {
      erc20.transfer(to, balance);
      emit WithdrawToken(contractAddress, to, balance);
    }
  }

  function withdrawEth(address to, uint256 balance) external onlySuperuser {
    if (balance == uint256(0x0)) {
      to.transfer(address(this).balance);
      emit WithdrawEth(to, address(this).balance);
    } else {
      to.transfer(balance);
      emit WithdrawEth(to, balance);
    }
  }

  function random() private view returns (uint8) {
    return uint8(uint256(keccak256(block.timestamp, block.difficulty))%100);  
  }

}