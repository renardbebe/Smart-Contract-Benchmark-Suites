 

pragma solidity ^0.4.25;

 

 
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

 

contract AbstractENS {
    function owner(bytes32 _node) public view returns(address);
    function resolver(bytes32 _node) public view returns(address);
    function ttl(bytes32 _node) public view returns(uint64);
    function setOwner(bytes32 _node, address _owner) public;
    function setSubnodeOwner(bytes32 _node, bytes32 _label, address _owner) public;
    function setResolver(bytes32 _node, address _resolver) public;
    function setTTL(bytes32 _node, uint64 _ttl) public;

     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);
}

 

contract AbstractResolver {
    function supportsInterface(bytes4 _interfaceID) public view returns (bool);
    function addr(bytes32 _node) public view returns (address ret);
    function setAddr(bytes32 _node, address _addr) public;
    function hash(bytes32 _node) public view returns (bytes32 ret);
    function setHash(bytes32 _node, bytes32 _hash) public;
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

 

contract SignerRole {
  using Roles for Roles.Role;

  event SignerAdded(address indexed account);
  event SignerRemoved(address indexed account);

  Roles.Role private signers;

  constructor() internal {
    _addSigner(msg.sender);
  }

  modifier onlySigner() {
    require(isSigner(msg.sender));
    _;
  }

  function isSigner(address account) public view returns (bool) {
    return signers.has(account);
  }

  function addSigner(address account) public onlySigner {
    _addSigner(account);
  }

  function renounceSigner() public {
    _removeSigner(msg.sender);
  }

  function _addSigner(address account) internal {
    signers.add(account);
    emit SignerAdded(account);
  }

  function _removeSigner(address account) internal {
    signers.remove(account);
    emit SignerRemoved(account);
  }
}

 

 

library ECDSA {

   
  function recover(bytes32 hash, bytes signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (signature.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

 

 
contract SignatureBouncer is SignerRole {
  using ECDSA for bytes32;

   
   
  uint256 private constant _METHOD_ID_SIZE = 4;
   
  uint256 private constant _SIGNATURE_SIZE = 96;

  constructor() internal {}

   
  modifier onlyValidSignature(bytes signature)
  {
    require(_isValidSignature(msg.sender, signature));
    _;
  }

   
  modifier onlyValidSignatureAndMethod(bytes signature)
  {
    require(_isValidSignatureAndMethod(msg.sender, signature));
    _;
  }

   
  modifier onlyValidSignatureAndData(bytes signature)
  {
    require(_isValidSignatureAndData(msg.sender, signature));
    _;
  }

   
  function _isValidSignature(address account, bytes signature)
    internal
    view
    returns (bool)
  {
    return _isValidDataHash(
      keccak256(abi.encodePacked(address(this), account)),
      signature
    );
  }

   
  function _isValidSignatureAndMethod(address account, bytes signature)
    internal
    view
    returns (bool)
  {
    bytes memory data = new bytes(_METHOD_ID_SIZE);
    for (uint i = 0; i < data.length; i++) {
      data[i] = msg.data[i];
    }
    return _isValidDataHash(
      keccak256(abi.encodePacked(address(this), account, data)),
      signature
    );
  }

   
  function _isValidSignatureAndData(address account, bytes signature)
    internal
    view
    returns (bool)
  {
    require(msg.data.length > _SIGNATURE_SIZE);
    bytes memory data = new bytes(msg.data.length - _SIGNATURE_SIZE);
    for (uint i = 0; i < data.length; i++) {
      data[i] = msg.data[i];
    }
    return _isValidDataHash(
      keccak256(abi.encodePacked(address(this), account, data)),
      signature
    );
  }

   
  function _isValidDataHash(bytes32 hash, bytes signature)
    internal
    view
    returns (bool)
  {
    address signer = hash
      .toEthSignedMessageHash()
      .recover(signature);

    return signer != address(0) && isSigner(signer);
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

 

 
contract ERC20Burnable is ERC20 {

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

 

 
 
 
contract DutchAuction is SignatureBouncer {
    using SafeERC20 for ERC20Burnable;

     
    event BidSubmission(address indexed sender, uint256 amount);

     
    uint constant public WAITING_PERIOD = 0;  

     
    ERC20Burnable public token;
    address public ambix;
    address public wallet;
    address public owner;
    uint public maxTokenSold;
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
        require(msg.data.length == 4 || msg.data.length == 164);
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stages.AuctionEnded && now > endTime + WAITING_PERIOD)
            stage = Stages.TradingStarted;
        _;
    }

     
     
     
     
     
     
    constructor(address _wallet, uint _maxTokenSold, uint _ceiling, uint _priceFactor)
        public
    {
        require(_wallet != 0 && _ceiling > 0 && _priceFactor > 0);

        owner = msg.sender;
        wallet = _wallet;
        maxTokenSold = _maxTokenSold;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        stage = Stages.AuctionDeployed;
    }

     
     
     
    function setup(ERC20Burnable _token, address _ambix)
        public
        isOwner
        atStage(Stages.AuctionDeployed)
    {
         
        require(address(_token) != 0 && _ambix != 0);

        token = _token;
        ambix = _ambix;

         
        require(token.balanceOf(this) == maxTokenSold);

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

     
     
    function bid(bytes signature)
        public
        payable
        isValidPayload
        timedTransitions
        atStage(Stages.AuctionStarted)
        onlyValidSignature(signature)
        returns (uint amount)
    {
        require(msg.value > 0);
        amount = msg.value;

        address receiver = msg.sender;

         
        uint maxWei = maxTokenSold * calcTokenPrice() / 10**9 - totalReceived;
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

     
    function claimTokens()
        public
        isValidPayload
        timedTransitions
        atStage(Stages.TradingStarted)
    {
        address receiver = msg.sender;
        uint tokenCount = bids[receiver] * 10**9 / finalPrice;
        bids[receiver] = 0;
        token.safeTransfer(receiver, tokenCount);
    }

     
     
    function calcStopPrice()
        view
        public
        returns (uint)
    {
        return totalReceived * 10**9 / maxTokenSold + 1;
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
             
            token.safeTransfer(ambix, maxTokenSold - soldTokens);
        } else {
             
            token.burn(maxTokenSold - soldTokens);
        }

        endTime = now;
    }
}

 

 
library SharedCode {
     
    function proxy(address _shared) internal returns (address instance) {
        bytes memory code = abi.encodePacked(
            hex"603160008181600b9039f3600080808080368092803773",
            _shared, hex"5af43d828181803e808314603057f35bfd"
        );
        assembly {
            instance := create(0, add(code, 0x20), 60)
            if iszero(extcodesize(instance)) {
                revert(0, 0)
            }
        }
    }
}

 

 
contract ILiability {
     
    event Finalized(bool indexed success, bytes result);

     
    bytes public model;

     
    bytes public objective;

     
    bytes public result;

     
    address public token;

     
    uint256 public cost;

     
    uint256 public lighthouseFee;

     
    uint256 public validatorFee;

     
    bytes32 public demandHash;

     
    bytes32 public offerHash;

     
    address public promisor;

     
    address public promisee;

     
    address public lighthouse;

     
    address public validator;

     
    bool public isSuccess;

     
    bool public isFinalized;

     
    function demand(
        bytes   _model,
        bytes   _objective,

        address _token,
        uint256 _cost,

        address _lighthouse,

        address _validator,
        uint256 _validator_fee,

        uint256 _deadline,
        bytes32 _nonce,
        bytes   _signature
    ) external returns (bool);

     
    function offer(
        bytes   _model,
        bytes   _objective,
        
        address _token,
        uint256 _cost,

        address _validator,

        address _lighthouse,
        uint256 _lighthouse_fee,

        uint256 _deadline,
        bytes32 _nonce,
        bytes   _signature
    ) external returns (bool);

     
    function finalize(bytes _result, bool  _success, bytes _signature) external returns (bool);
}

 

 
contract ILighthouse {
     
    event Online(address indexed provider);

     
    event Offline(address indexed provider);

     
    event Current(address indexed provider, uint256 indexed quota);

     
    address[] public providers;

     
    function providersLength() public view returns (uint256)
    { return providers.length; }

     
    mapping(address => uint256) public stakes;

     
    uint256 public minimalStake;

     
    uint256 public timeoutInBlocks;

     
    uint256 public keepAliveBlock;

     
    uint256 public marker;

     
    uint256 public quota;

     
    function quotaOf(address _provider) public view returns (uint256)
    { return stakes[_provider] / minimalStake; }

     
    function refill(uint256 _value) external returns (bool);

     
    function withdraw(uint256 _value) external returns (bool);

     
    function createLiability(bytes _demand, bytes _offer) external returns (bool);

     
    function finalizeLiability(address _liability, bytes _result, bool _success, bytes _signature) external returns (bool);
}

 

 
contract IFactory {
     
    event NewLiability(address indexed liability);

     
    event NewLighthouse(address indexed lighthouse, string name);

     
    mapping(address => bool) public isLighthouse;

     
    uint256 public totalGasConsumed = 0;

     
    mapping(address => uint256) public gasConsumedOf;

     
    uint256 public constant gasEpoch = 347 * 10**10;

     
    uint256 public gasPrice = 10 * 10**9;

     
    function wnFromGas(uint256 _gas) public view returns (uint256);

     
    function createLighthouse(uint256 _minimalStake, uint256 _timeoutInBlocks, string _name) external returns (ILighthouse);

     
    function createLiability(bytes _demand, bytes _offer) external returns (ILiability);

     
    function liabilityCreated(ILiability _liability, uint256 _start_gas) external returns (bool);

     
    function liabilityFinalized(ILiability _liability, uint256 _start_gas) external returns (bool);
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
    constructor(uint256 _initial_supply) public ERC20Detailed("Robonomics Beta 4", "XRT", 9) {
        _mint(msg.sender, _initial_supply);
    }
}

 

contract Lighthouse is ILighthouse {
    using SafeERC20 for XRT;

    IFactory public factory;
    XRT      public xrt;

    function setup(XRT _xrt, uint256 _minimalStake, uint256 _timeoutInBlocks) external returns (bool) {
        require(address(factory) == 0 && _minimalStake > 0 && _timeoutInBlocks > 0);

        minimalStake    = _minimalStake;
        timeoutInBlocks = _timeoutInBlocks;
        factory         = IFactory(msg.sender);
        xrt             = _xrt;

        return true;
    }

     
    mapping(address => uint256) public indexOf;

    function refill(uint256 _value) external returns (bool) {
        xrt.safeTransferFrom(msg.sender, this, _value);

        if (stakes[msg.sender] == 0) {
            require(_value >= minimalStake);
            providers.push(msg.sender);
            indexOf[msg.sender] = providers.length;
            emit Online(msg.sender);
        }

        stakes[msg.sender] += _value;
        return true;
    }

    function withdraw(uint256 _value) external returns (bool) {
        require(stakes[msg.sender] >= _value);

        stakes[msg.sender] -= _value;
        xrt.safeTransfer(msg.sender, _value);

         
        if (quotaOf(msg.sender) == 0) {
            uint256 balance = stakes[msg.sender];
            stakes[msg.sender] = 0;
            xrt.safeTransfer(msg.sender, balance);
            
            uint256 senderIndex = indexOf[msg.sender] - 1;
            uint256 lastIndex = providers.length - 1;
            if (senderIndex < lastIndex)
                providers[senderIndex] = providers[lastIndex];

            providers.length -= 1;
            indexOf[msg.sender] = 0;

            emit Offline(msg.sender);
        }
        return true;
    }

    function keepAliveTransaction() internal {
        if (timeoutInBlocks < block.number - keepAliveBlock) {
             
            marker = indexOf[msg.sender];

             
            require(marker > 0 && marker <= providers.length);

             
            quota = quotaOf(providers[marker - 1]);

             
            emit Current(providers[marker - 1], quota);
        }

         
        keepAliveBlock = block.number;
    }

    function quotedTransaction() internal {
         
        require(providers.length > 0);

         
         
        require(quota > 0);

         
        require(msg.sender == providers[marker - 1]);

         
        if (quota > 1) {
            quota -= 1;
        } else {
             
            marker = marker % providers.length + 1;

             
            quota = quotaOf(providers[marker - 1]);

             
            emit Current(providers[marker - 1], quota);
        }
    }

    function startGas() internal view returns (uint256 gas) {
         
         
        gas = gasleft();
         
        gas += 21000;
         
        for (uint256 i = 0; i < msg.data.length; ++i)
            gas += msg.data[i] == 0 ? 4 : 68;
    }

    function createLiability(
        bytes _demand,
        bytes _offer
    )
        external
        returns (bool)
    {
         
        uint256 gas = startGas() + 20311;

        keepAliveTransaction();
        quotedTransaction();

        ILiability liability = factory.createLiability(_demand, _offer);
        require(address(liability) != 0);
        require(factory.liabilityCreated(liability, gas - gasleft()));
        return true;
    }

    function finalizeLiability(
        address _liability,
        bytes _result,
        bool _success,
        bytes _signature
    )
        external
        returns (bool)
    {
         
        uint256 gas = startGas() + 23441;

        keepAliveTransaction();
        quotedTransaction();

        ILiability liability = ILiability(_liability);
        require(factory.gasConsumedOf(_liability) > 0);
        require(liability.finalize(_result, _success, _signature));
        require(factory.liabilityFinalized(liability, gas - gasleft()));
        return true;
    }
}

 

 
contract IValidator {
     
    event Decision(address indexed liability, bool indexed success);

     
    mapping(address => bool) public hasDecision;

     
    function decision() external returns (bool);
}

 

contract Liability is ILiability {
    using ECDSA for bytes32;
    using SafeERC20 for XRT;
    using SafeERC20 for ERC20;

    address public factory;
    XRT     public xrt;

    function setup(XRT _xrt) external returns (bool) {
        require(factory == 0);

        factory = msg.sender;
        xrt     = _xrt;

        return true;
    }

    function demand(
        bytes   _model,
        bytes   _objective,

        address _token,
        uint256 _cost,

        address _lighthouse,

        address _validator,
        uint256 _validator_fee,

        uint256 _deadline,
        bytes32 _nonce,
        bytes   _signature
    )
        external
        returns (bool)
    {
        require(msg.sender == factory);
        require(block.number < _deadline);

        model        = _model;
        objective    = _objective;
        token        = _token;
        cost         = _cost;
        lighthouse   = _lighthouse;
        validator    = _validator;
        validatorFee = _validator_fee;

        demandHash = keccak256(abi.encodePacked(
            _model
          , _objective
          , _token
          , _cost
          , _lighthouse
          , _validator
          , _validator_fee
          , _deadline
          , _nonce
        ));

        promisee = demandHash
            .toEthSignedMessageHash()
            .recover(_signature);
        return true;
    }

    function offer(
        bytes   _model,
        bytes   _objective,
        
        address _token,
        uint256 _cost,

        address _validator,

        address _lighthouse,
        uint256 _lighthouse_fee,

        uint256 _deadline,
        bytes32 _nonce,
        bytes   _signature
    )
        external
        returns (bool)
    {
        require(msg.sender == factory);
        require(block.number < _deadline);
        require(keccak256(model) == keccak256(_model));
        require(keccak256(objective) == keccak256(_objective));
        require(_token == token);
        require(_cost == cost);
        require(_lighthouse == lighthouse);
        require(_validator == validator);

        lighthouseFee = _lighthouse_fee;

        offerHash = keccak256(abi.encodePacked(
            _model
          , _objective
          , _token
          , _cost
          , _validator
          , _lighthouse
          , _lighthouse_fee
          , _deadline
          , _nonce
        ));

        promisor = offerHash
            .toEthSignedMessageHash()
            .recover(_signature);
        return true;
    }

    function finalize(
        bytes _result,
        bool  _success,
        bytes _signature
    )
        external
        returns (bool)
    {
        require(msg.sender == lighthouse);
        require(!isFinalized);

        address resultSender = keccak256(abi.encodePacked(this, _result, _success))
            .toEthSignedMessageHash()
            .recover(_signature);
        require(resultSender == promisor);

        isFinalized = true;
        result      = _result;

        if (validator == 0) {
             
            isSuccess = _success;
        } else {
             
            xrt.safeApprove(validator, validatorFee);
             
            isSuccess = _success && IValidator(validator).decision();
        }

        if (cost > 0)
            ERC20(token).safeTransfer(isSuccess ? promisor : promisee, cost);

        emit Finalized(isSuccess, result);
        return true;
    }
}

 

contract Factory is IFactory, SingletonHash {
    constructor(
        address _liability,
        address _lighthouse,
        DutchAuction _auction,
        AbstractENS _ens,
        XRT _xrt
    ) public {
        liabilityCode = _liability;
        lighthouseCode = _lighthouse;
        auction = _auction;
        ens = _ens;
        xrt = _xrt;
    }

    address public liabilityCode;
    address public lighthouseCode;

    using SafeERC20 for XRT;
    using SafeERC20 for ERC20;
    using SharedCode for address;

     
    DutchAuction public auction;

     
    AbstractENS public ens;

     
    XRT public xrt;

     
    function smma(uint256 _prePrice, uint256 _price) internal pure returns (uint256) {
        return (_prePrice * (smmaPeriod - 1) + _price) / smmaPeriod;
    }

     
    uint256 private constant smmaPeriod = 100;

     
    function wnFromGas(uint256 _gas) public view returns (uint256) {
         
        if (auction.finalPrice() == 0)
            return _gas;

         
        uint256 epoch = totalGasConsumed / gasEpoch;

         
        uint256 wn = _gas * 10**9 * gasPrice * 2**epoch / 3**epoch / auction.finalPrice();

         
        return wn < _gas ? _gas : wn;
    }

    modifier onlyLighthouse {
        require(isLighthouse[msg.sender]);

        _;
    }

    modifier gasPriceEstimate {
        gasPrice = smma(gasPrice, tx.gasprice);

        _;
    }

    function createLighthouse(
        uint256 _minimalStake,
        uint256 _timeoutInBlocks,
        string  _name
    )
        external
        returns (ILighthouse lighthouse)
    {
        bytes32 LIGHTHOUSE_NODE
             
            = 0xbb02fe616f0926339902db4d17f52c2dfdb337f2a010da2743a8dbdac12d56f9;
        bytes32 hname = keccak256(bytes(_name));

         
        bytes32 subnode = keccak256(abi.encodePacked(LIGHTHOUSE_NODE, hname));
        require(ens.resolver(subnode) == 0);

         
        lighthouse = ILighthouse(lighthouseCode.proxy());
        require(Lighthouse(lighthouse).setup(xrt, _minimalStake, _timeoutInBlocks));

        emit NewLighthouse(lighthouse, _name);
        isLighthouse[lighthouse] = true;

         
        ens.setSubnodeOwner(LIGHTHOUSE_NODE, hname, this);

         
        AbstractResolver resolver = AbstractResolver(ens.resolver(LIGHTHOUSE_NODE));
        ens.setResolver(subnode, resolver);
        resolver.setAddr(subnode, lighthouse);
    }

    function createLiability(
        bytes _demand,
        bytes _offer
    )
        external
        onlyLighthouse
        returns (ILiability liability)
    {
         
        liability = ILiability(liabilityCode.proxy());
        require(Liability(liability).setup(xrt));

        emit NewLiability(liability);

         
        require(address(liability).call(abi.encodePacked(bytes4(0xd9ff764a), _demand)));  
        singletonHash(liability.demandHash());

        require(address(liability).call(abi.encodePacked(bytes4(0xd5056962), _offer)));  
        singletonHash(liability.offerHash());

         
        require(isLighthouse[liability.lighthouse()]);

         
        if (liability.lighthouseFee() > 0)
            xrt.safeTransferFrom(liability.promisor(),
                                 tx.origin,
                                 liability.lighthouseFee());

         
        ERC20 token = ERC20(liability.token());
        if (liability.cost() > 0)
            token.safeTransferFrom(liability.promisee(),
                                   liability,
                                   liability.cost());

         
        if (liability.validator() != 0 && liability.validatorFee() > 0)
            xrt.safeTransferFrom(liability.promisee(),
                                 liability,
                                 liability.validatorFee());
     }

    function liabilityCreated(
        ILiability _liability,
        uint256 _gas
    )
        external
        onlyLighthouse
        gasPriceEstimate
        returns (bool)
    {
        totalGasConsumed          += _gas;
        gasConsumedOf[_liability] += _gas;
        return true;
    }

    function liabilityFinalized(
        ILiability _liability,
        uint256 _gas
    )
        external
        onlyLighthouse
        gasPriceEstimate
        returns (bool)
    {
        totalGasConsumed          += _gas;
        gasConsumedOf[_liability] += _gas;
        require(xrt.mint(tx.origin, wnFromGas(gasConsumedOf[_liability])));
        return true;
    }
}