 

pragma solidity 0.4.24;

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
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
    require(value <= _balances[from]);
    require(to != address(0));

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

 

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

 

 
contract ERC20Mintable is ERC20, MinterRole {
   
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}

 

 
contract ERC20Burnable is ERC20 {

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

 

 
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

   
  function name() public view returns(string) {
    return _name;
  }

   
  function symbol() public view returns(string) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

 

contract XRT is ERC20Mintable, ERC20Burnable, ERC20Detailed {
    constructor() public ERC20Detailed("Robonomics Beta 3", "XRT", 9) {
        uint256 INITIAL_SUPPLY = 1000 * (10 ** 9);
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}

 

 


contract RobotLiabilityAPI {
    bytes   public model;
    bytes   public objective;
    bytes   public result;

    ERC20   public token;
    uint256 public cost;
    uint256 public lighthouseFee;
    uint256 public validatorFee;

    bytes32 public demandHash;
    bytes32 public offerHash;

    address public promisor;
    address public promisee;
    address public lighthouse;
    address public validator;

    bool    public isSuccess;
    bool    public isFinalized;

    LiabilityFactory public factory;

    event Finalized(bool indexed success, bytes result);
}

 

contract LightContract {
     
    address lib;

    constructor(address _library) public {
        lib = _library;
    }

    function() public {
        require(lib.delegatecall(msg.data));
    }
}

 

 
contract RobotLiability is RobotLiabilityAPI, LightContract {
    constructor(address _lib) public LightContract(_lib)
    { factory = LiabilityFactory(msg.sender); }
}

 

contract SingletonHash {
    event HashConsumed(bytes32 indexed hash);

     
    mapping(bytes32 => bool) public isHashConsumed;

     
    function singletonHash(bytes32 _hash) internal {
        require(!isHashConsumed[_hash]);
        isHashConsumed[_hash] = true;
        emit HashConsumed(_hash);
    }
}

 

 
 
 
contract DutchAuction {

     
    event BidSubmission(address indexed sender, uint256 amount);

     
    uint constant public MAX_TOKENS_SOLD = 800 * 10**9;  
    uint constant public WAITING_PERIOD = 0;  

     
    XRT     public xrt;
    address public ambix;
    address public wallet;
    address public owner;
    uint public ceiling;
    uint public priceFactor;
    uint public startBlock;
    uint public endTime;
    uint public totalReceived;
    uint public finalPrice;
    mapping (address => uint) public bids;
    Stages public stage;

     
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TradingStarted
    }

     
    modifier atStage(Stages _stage) {
         
        require(stage == _stage);
        _;
    }

    modifier isOwner() {
         
        require(msg.sender == owner);
        _;
    }

    modifier isWallet() {
         
        require(msg.sender == wallet);
        _;
    }

    modifier isValidPayload() {
        require(msg.data.length == 4 || msg.data.length == 36);
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stages.AuctionEnded && now > endTime + WAITING_PERIOD)
            stage = Stages.TradingStarted;
        _;
    }

     
     
     
     
     
    constructor(address _wallet, uint _ceiling, uint _priceFactor)
        public
    {
        require(_wallet != 0 && _ceiling > 0 && _priceFactor > 0);

        owner = msg.sender;
        wallet = _wallet;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        stage = Stages.AuctionDeployed;
    }

     
     
     
    function setup(address _xrt, address _ambix)
        public
        isOwner
        atStage(Stages.AuctionDeployed)
    {
         
        require(_xrt != 0 && _ambix != 0);

        xrt = XRT(_xrt);
        ambix = _ambix;

         
        require(xrt.balanceOf(this) == MAX_TOKENS_SOLD);

        stage = Stages.AuctionSetUp;
    }

     
    function startAuction()
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        stage = Stages.AuctionStarted;
        startBlock = block.number;
    }

     
     
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint)
    {
        if (stage == Stages.AuctionEnded || stage == Stages.TradingStarted)
            return finalPrice;
        return calcTokenPrice();
    }

     
     
    function updateStage()
        public
        timedTransitions
        returns (Stages)
    {
        return stage;
    }

     
     
    function bid(address receiver)
        public
        payable
        isValidPayload
        timedTransitions
        atStage(Stages.AuctionStarted)
        returns (uint amount)
    {
        require(msg.value > 0);
        amount = msg.value;

         
        if (receiver == 0)
            receiver = msg.sender;

         
        uint maxWei = MAX_TOKENS_SOLD * calcTokenPrice() / 10**9 - totalReceived;
        uint maxWeiBasedOnTotalReceived = ceiling - totalReceived;
        if (maxWeiBasedOnTotalReceived < maxWei)
            maxWei = maxWeiBasedOnTotalReceived;

         
        if (amount > maxWei) {
            amount = maxWei;
             
            receiver.transfer(msg.value - amount);
        }

         
        wallet.transfer(amount);

        bids[receiver] += amount;
        totalReceived += amount;
        emit BidSubmission(receiver, amount);

         
        if (amount == maxWei)
            finalizeAuction();
    }

     
     
    function claimTokens(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stages.TradingStarted)
    {
        if (receiver == 0)
            receiver = msg.sender;
        uint tokenCount = bids[receiver] * 10**9 / finalPrice;
        bids[receiver] = 0;
        require(xrt.transfer(receiver, tokenCount));
    }

     
     
    function calcStopPrice()
        view
        public
        returns (uint)
    {
        return totalReceived * 10**9 / MAX_TOKENS_SOLD + 1;
    }

     
     
    function calcTokenPrice()
        view
        public
        returns (uint)
    {
        return priceFactor * 10**18 / (block.number - startBlock + 7500) + 1;
    }

     
    function finalizeAuction()
        private
    {
        stage = Stages.AuctionEnded;
        finalPrice = totalReceived == ceiling ? calcTokenPrice() : calcStopPrice();
        uint soldTokens = totalReceived * 10**9 / finalPrice;

        if (totalReceived == ceiling) {
             
            require(xrt.transfer(ambix, MAX_TOKENS_SOLD - soldTokens));
        } else {
             
            xrt.burn(MAX_TOKENS_SOLD - soldTokens);
        }

        endTime = now;
    }
}

 

 


contract LighthouseAPI {
    address[] public members;

    function membersLength() public view returns (uint256)
    { return members.length; }

    mapping(address => uint256) indexOf;

    mapping(address => uint256) public balances;

    uint256 public minimalFreeze;
    uint256 public timeoutBlocks;

    LiabilityFactory public factory;
    XRT              public xrt;

    uint256 public keepaliveBlock = 0;
    uint256 public marker = 0;
    uint256 public quota = 0;

    function quotaOf(address _member) public view returns (uint256)
    { return balances[_member] / minimalFreeze; }
}

 

contract Lighthouse is LighthouseAPI, LightContract {
    constructor(
        address _lib,
        uint256 _minimalFreeze,
        uint256 _timeoutBlocks
    ) 
        public
        LightContract(_lib)
    {
        require(_minimalFreeze > 0 && _timeoutBlocks > 0);

        minimalFreeze = _minimalFreeze;
        timeoutBlocks = _timeoutBlocks;
        factory = LiabilityFactory(msg.sender);
        xrt = factory.xrt();
    }
}

 

contract AbstractENS {
    function owner(bytes32 node) constant returns(address);
    function resolver(bytes32 node) constant returns(address);
    function ttl(bytes32 node) constant returns(uint64);
    function setOwner(bytes32 node, address owner);
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner);
    function setResolver(bytes32 node, address resolver);
    function setTTL(bytes32 node, uint64 ttl);

     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);
}

 

 
contract ENS is AbstractENS {
    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32=>Record) records;

     
    modifier only_owner(bytes32 node) {
        if(records[node].owner != msg.sender) throw;
        _;
    }

     
    function ENS() {
        records[0].owner = msg.sender;
    }

     
    function owner(bytes32 node) constant returns (address) {
        return records[node].owner;
    }

     
    function resolver(bytes32 node) constant returns (address) {
        return records[node].resolver;
    }

     
    function ttl(bytes32 node) constant returns (uint64) {
        return records[node].ttl;
    }

     
    function setOwner(bytes32 node, address owner) only_owner(node) {
        Transfer(node, owner);
        records[node].owner = owner;
    }

     
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) only_owner(node) {
        var subnode = sha3(node, label);
        NewOwner(node, label, owner);
        records[subnode].owner = owner;
    }

     
    function setResolver(bytes32 node, address resolver) only_owner(node) {
        NewResolver(node, resolver);
        records[node].resolver = resolver;
    }

     
    function setTTL(bytes32 node, uint64 ttl) only_owner(node) {
        NewTTL(node, ttl);
        records[node].ttl = ttl;
    }
}

 

 
contract PublicResolver {
    AbstractENS ens;
    mapping(bytes32=>address) addresses;
    mapping(bytes32=>bytes32) hashes;

    modifier only_owner(bytes32 node) {
        if(ens.owner(node) != msg.sender) throw;
        _;
    }

     
    function PublicResolver(AbstractENS ensAddr) {
        ens = ensAddr;
    }

     
    function() {
        throw;
    }

     
    function has(bytes32 node, bytes32 kind) constant returns (bool) {
        return (kind == "addr" && addresses[node] != 0) || (kind == "hash" && hashes[node] != 0);
    }

     
    function supportsInterface(bytes4 interfaceID) constant returns (bool) {
        return interfaceID == 0x3b3b57de || interfaceID == 0xd8389dc5;
    }

     
    function addr(bytes32 node) constant returns (address ret) {
        ret = addresses[node];
    }

     
    function setAddr(bytes32 node, address addr) only_owner(node) {
        addresses[node] = addr;
    }

     
    function content(bytes32 node) constant returns (bytes32 ret) {
        ret = hashes[node];
    }

     
    function setContent(bytes32 node, bytes32 hash) only_owner(node) {
        hashes[node] = hash;
    }
}

 

 
library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
     
     
     
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

 

contract LiabilityFactory is SingletonHash {
    constructor(
        address _robot_liability_lib,
        address _lighthouse_lib,
        DutchAuction _auction,
        XRT _xrt,
        ENS _ens
    ) public {
        robotLiabilityLib = _robot_liability_lib;
        lighthouseLib = _lighthouse_lib;
        auction = _auction;
        xrt = _xrt;
        ens = _ens;
    }

    using SafeERC20 for XRT;
    using SafeERC20 for ERC20;

     
    event NewLiability(address indexed liability);

     
    event NewLighthouse(address indexed lighthouse, string name);

     
    DutchAuction public auction;

     
    XRT public xrt;

     
    ENS public ens;

     
    uint256 public totalGasUtilizing = 0;

     
    mapping(address => uint256) public gasUtilizing;

     
    uint256 public constant gasEpoch = 347 * 10**10;

     
    function smma(uint256 _prePrice, uint256 _price) internal returns (uint256) {
        return (_prePrice * (smmaPeriod - 1) + _price) / smmaPeriod;
    }

     
    uint256 public constant smmaPeriod = 100;

     
    uint256 public gasPrice = 10 * 10**9;

     
    mapping(address => bool) public isLighthouse;

     
    address public robotLiabilityLib;

     
    address public lighthouseLib;

     
    function wnFromGas(uint256 _gas) view returns (uint256) {
         
        if (auction.finalPrice() == 0)
            return _gas;

         
        uint256 epoch = totalGasUtilizing / gasEpoch;

         
        uint256 wn = _gas * 10**9 * gasPrice * 2**epoch / 3**epoch / auction.finalPrice();

         
        return wn < _gas ? _gas : wn;
    }

     
    modifier onlyLighthouse {
        require(isLighthouse[msg.sender]);
        _;
    }

    modifier gasPriceEstimated {
        gasPrice = smma(gasPrice, tx.gasprice);
        _;
    }


     
    function createLiability(
        bytes _demand,
        bytes _offer
    )
        external 
        onlyLighthouse
        gasPriceEstimated
        returns (RobotLiability liability) {  
        uint256 gasinit = gasleft();

         
        liability = new RobotLiability(robotLiabilityLib);
        emit NewLiability(liability);

         
        require(liability.call(abi.encodePacked(bytes4(0xd9ff764a), _demand)));  
        singletonHash(liability.demandHash());

        require(liability.call(abi.encodePacked(bytes4(0xd5056962), _offer)));  
        singletonHash(liability.offerHash());

         
        if (liability.lighthouseFee() > 0)
            xrt.safeTransferFrom(liability.promisor(),
                                 tx.origin,
                                 liability.lighthouseFee());

         
        ERC20 token = liability.token();
        if (liability.cost() > 0)
            token.safeTransferFrom(liability.promisee(),
                                   liability,
                                   liability.cost());

         
        if (address(liability.validator()) != 0 && liability.validatorFee() > 0)
            xrt.safeTransferFrom(liability.promisee(),
                                 liability,
                                 liability.validatorFee());

         
        uint256 gas = gasinit - gasleft() + 110525;  
        totalGasUtilizing       += gas;
        gasUtilizing[liability] += gas;
     }

     
    function createLighthouse(
        uint256 _minimalFreeze,
        uint256 _timeoutBlocks,
        string  _name
    )
        external
        returns (address lighthouse)
    {
        bytes32 lighthouseNode
             
            = 0x87bd923a85f096b00a4a347fb56cef68e95319b3d9dae1dff59259db094afd02;

         
        bytes32 subnode = keccak256(abi.encodePacked(lighthouseNode, keccak256(_name)));
        require(ens.resolver(subnode) == 0);

         
        lighthouse = new Lighthouse(lighthouseLib, _minimalFreeze, _timeoutBlocks);
        emit NewLighthouse(lighthouse, _name);
        isLighthouse[lighthouse] = true;

         
        ens.setSubnodeOwner(lighthouseNode, keccak256(_name), this);

         
        PublicResolver resolver = PublicResolver(ens.resolver(lighthouseNode));
        ens.setResolver(subnode, resolver);
        resolver.setAddr(subnode, lighthouse);
    }

     
    function liabilityFinalized(
        uint256 _gas
    )
        external
        gasPriceEstimated
        returns (bool)
    {
        require(gasUtilizing[msg.sender] > 0);

        uint256 gas = _gas - gasleft();
        require(_gas > gas);

        totalGasUtilizing        += gas;
        gasUtilizing[msg.sender] += gas;

        require(xrt.mint(tx.origin, wnFromGas(gasUtilizing[msg.sender])));
        return true;
    }
}