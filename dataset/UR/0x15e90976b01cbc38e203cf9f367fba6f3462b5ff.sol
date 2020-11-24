 

pragma solidity 0.4.24;

 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
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
      "\x19Ethereum Signed Message:\n32",
      hash
    );
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

contract XRT is MintableToken, BurnableToken {
    string public constant name     = "Robonomics Beta";
    string public constant symbol   = "XRT";
    uint   public constant decimals = 9;

    uint256 public constant INITIAL_SUPPLY = 1000 * (10 ** uint256(decimals));

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}


 

 
 
 
contract DutchAuction {

     
    event BidSubmission(address indexed sender, uint256 amount);

     
    uint constant public MAX_TOKENS_SOLD = 8000 * 10**9;  
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
        require(_wallet != 0 && _ceiling != 0 && _priceFactor != 0);
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

     
     
     
    function changeSettings(uint _ceiling, uint _priceFactor)
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        ceiling = _ceiling;
        priceFactor = _priceFactor;
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
        BidSubmission(receiver, amount);

         
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

 

interface ENS {

     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
    function setResolver(bytes32 node, address resolver) public;
    function setOwner(bytes32 node, address owner) public;
    function setTTL(bytes32 node, uint64 ttl) public;
    function owner(bytes32 node) public view returns (address);
    function resolver(bytes32 node) public view returns (address);
    function ttl(bytes32 node) public view returns (uint64);

}

 

 
contract PublicResolver {

    bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant CONTENT_INTERFACE_ID = 0xd8389dc5;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;
    bytes4 constant ABI_INTERFACE_ID = 0x2203ab56;
    bytes4 constant PUBKEY_INTERFACE_ID = 0xc8690233;
    bytes4 constant TEXT_INTERFACE_ID = 0x59d1d43c;
    bytes4 constant MULTIHASH_INTERFACE_ID = 0xe89401a1;

    event AddrChanged(bytes32 indexed node, address a);
    event ContentChanged(bytes32 indexed node, bytes32 hash);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexedKey, string key);
    event MultihashChanged(bytes32 indexed node, bytes hash);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    struct Record {
        address addr;
        bytes32 content;
        string name;
        PublicKey pubkey;
        mapping(string=>string) text;
        mapping(uint256=>bytes) abis;
        bytes multihash;
    }

    ENS ens;

    mapping (bytes32 => Record) records;

    modifier only_owner(bytes32 node) {
        require(ens.owner(node) == msg.sender);
        _;
    }

     
    function PublicResolver(ENS ensAddr) public {
        ens = ensAddr;
    }

     
    function setAddr(bytes32 node, address addr) public only_owner(node) {
        records[node].addr = addr;
        AddrChanged(node, addr);
    }

     
    function setContent(bytes32 node, bytes32 hash) public only_owner(node) {
        records[node].content = hash;
        ContentChanged(node, hash);
    }

     
    function setMultihash(bytes32 node, bytes hash) public only_owner(node) {
        records[node].multihash = hash;
        MultihashChanged(node, hash);
    }
    
     
    function setName(bytes32 node, string name) public only_owner(node) {
        records[node].name = name;
        NameChanged(node, name);
    }

     
    function setABI(bytes32 node, uint256 contentType, bytes data) public only_owner(node) {
         
        require(((contentType - 1) & contentType) == 0);
        
        records[node].abis[contentType] = data;
        ABIChanged(node, contentType);
    }
    
     
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) public only_owner(node) {
        records[node].pubkey = PublicKey(x, y);
        PubkeyChanged(node, x, y);
    }

     
    function setText(bytes32 node, string key, string value) public only_owner(node) {
        records[node].text[key] = value;
        TextChanged(node, key, key);
    }

     
    function text(bytes32 node, string key) public view returns (string) {
        return records[node].text[key];
    }

     
    function pubkey(bytes32 node) public view returns (bytes32 x, bytes32 y) {
        return (records[node].pubkey.x, records[node].pubkey.y);
    }

     
    function ABI(bytes32 node, uint256 contentTypes) public view returns (uint256 contentType, bytes data) {
        Record storage record = records[node];
        for (contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && record.abis[contentType].length > 0) {
                data = record.abis[contentType];
                return;
            }
        }
        contentType = 0;
    }

     
    function name(bytes32 node) public view returns (string) {
        return records[node].name;
    }

     
    function content(bytes32 node) public view returns (bytes32) {
        return records[node].content;
    }

     
    function multihash(bytes32 node) public view returns (bytes) {
        return records[node].multihash;
    }

     
    function addr(bytes32 node) public view returns (address) {
        return records[node].addr;
    }

     
    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == ADDR_INTERFACE_ID ||
        interfaceID == CONTENT_INTERFACE_ID ||
        interfaceID == NAME_INTERFACE_ID ||
        interfaceID == ABI_INTERFACE_ID ||
        interfaceID == PUBKEY_INTERFACE_ID ||
        interfaceID == TEXT_INTERFACE_ID ||
        interfaceID == MULTIHASH_INTERFACE_ID ||
        interfaceID == INTERFACE_META_ID;
    }
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

contract LighthouseABI {
    function refill(uint256 _value) external;
    function withdraw(uint256 _value) external;
    function to(address _to, bytes _data) external;
    function () external;
}

contract LighthouseAPI {
    address[] public members;
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

contract LighthouseLib is LighthouseAPI, LighthouseABI {

    function refill(uint256 _value) external {
        require(xrt.transferFrom(msg.sender, this, _value));
        require(_value >= minimalFreeze);

        if (balances[msg.sender] == 0) {
            indexOf[msg.sender] = members.length;
            members.push(msg.sender);
        }
        balances[msg.sender] += _value;
    }

    function withdraw(uint256 _value) external {
        require(balances[msg.sender] >= _value);

        balances[msg.sender] -= _value;
        require(xrt.transfer(msg.sender, _value));

         
        if (quotaOf(msg.sender) == 0) {
            uint256 balance = balances[msg.sender];
            balances[msg.sender] = 0;
            require(xrt.transfer(msg.sender, balance)); 
            
            uint256 senderIndex = indexOf[msg.sender];
            uint256 lastIndex = members.length - 1;
            if (senderIndex < lastIndex)
                members[senderIndex] = members[lastIndex];
            members.length -= 1;
        }
    }

    function nextMember() internal
    { marker = (marker + 1) % members.length; }

    modifier quoted {
        if (quota == 0) {
             
            nextMember();

             
            quota = quotaOf(members[marker]);
        }

         
        assert(quota > 0);
        quota -= 1;

        _;
    }

    modifier keepalive {
        if (timeoutBlocks < block.number - keepaliveBlock) {
             
            while (msg.sender != members[marker])
                nextMember();

             
            quota = quotaOf(members[marker]);
        }

        _;
    }

    modifier member {
         
        require(members.length > 0);

         
        require(msg.sender == members[marker]);

         
        keepaliveBlock = block.number;

        _;
    }

    function to(address _to, bytes _data) external keepalive quoted member {
        require(factory.gasUtilizing(_to) > 0);
        require(_to.call(_data));
    }

    function () external keepalive quoted member
    { require(factory.call(msg.data)); }
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
        minimalFreeze = _minimalFreeze;
        timeoutBlocks = _timeoutBlocks;
        factory = LiabilityFactory(msg.sender);
        xrt = factory.xrt();
    }
}

contract RobotLiabilityABI {
    function ask(
        bytes   _model,
        bytes   _objective,

        ERC20   _token,
        uint256 _cost,

        address _validator,
        uint256 _validator_fee,

        uint256 _deadline,
        bytes32 _nonce,
        bytes   _signature
    ) external returns (bool);

    function bid(
        bytes   _model,
        bytes   _objective,
        
        ERC20   _token,
        uint256 _cost,

        uint256 _lighthouse_fee,

        uint256 _deadline,
        bytes32 _nonce,
        bytes   _signature
    ) external returns (bool);

    function finalize(
        bytes _result,
        bytes _signature,
        bool  _agree
    ) external returns (bool);
}

contract RobotLiabilityAPI {
    bytes   public model;
    bytes   public objective;
    bytes   public result;

    ERC20   public token;
    uint256 public cost;
    uint256 public lighthouseFee;
    uint256 public validatorFee;

    bytes32 public askHash;
    bytes32 public bidHash;

    address public promisor;
    address public promisee;
    address public validator;

    bool    public isConfirmed;
    bool    public isFinalized;

    LiabilityFactory public factory;
}

contract RobotLiabilityLib is RobotLiabilityABI
                            , RobotLiabilityAPI {
    using ECRecovery for bytes32;

    function ask(
        bytes   _model,
        bytes   _objective,

        ERC20   _token,
        uint256 _cost,

        address _validator,
        uint256 _validator_fee,

        uint256 _deadline,
        bytes32 _nonce,
        bytes   _signature
    )
        external
        returns (bool)
    {
        require(msg.sender == address(factory));
        require(block.number < _deadline);

        model        = _model;
        objective    = _objective;
        token        = _token;
        cost         = _cost;
        validator    = _validator;
        validatorFee = _validator_fee;

        askHash = keccak256(abi.encodePacked(
            _model
          , _objective
          , _token
          , _cost
          , _validator
          , _validator_fee
          , _deadline
          , _nonce
        ));

        promisee = askHash
            .toEthSignedMessageHash()
            .recover(_signature);
        return true;
    }

    function bid(
        bytes   _model,
        bytes   _objective,
        
        ERC20   _token,
        uint256 _cost,

        uint256 _lighthouse_fee,

        uint256 _deadline,
        bytes32 _nonce,
        bytes   _signature
    )
        external
        returns (bool)
    {
        require(msg.sender == address(factory));
        require(block.number < _deadline);
        require(keccak256(model) == keccak256(_model));
        require(keccak256(objective) == keccak256(_objective));
        require(_token == token);
        require(_cost == cost);

        lighthouseFee = _lighthouse_fee;

        bidHash = keccak256(abi.encodePacked(
            _model
          , _objective
          , _token
          , _cost
          , _lighthouse_fee
          , _deadline
          , _nonce
        ));

        promisor = bidHash
            .toEthSignedMessageHash()
            .recover(_signature);
        return true;
    }

     
    function finalize(
        bytes _result,
        bytes _signature,
        bool  _agree
    )
        external
        returns (bool)
    {
        uint256 gasinit = gasleft();
        require(!isFinalized);

        address resultSender = keccak256(abi.encodePacked(this, _result))
            .toEthSignedMessageHash()
            .recover(_signature);
        require(resultSender == promisor);

        result = _result;
        isFinalized = true;

        if (validator == 0) {
            require(factory.isLighthouse(msg.sender));
            require(token.transfer(promisor, cost));
        } else {
            require(msg.sender == validator);

            isConfirmed = _agree;
            if (isConfirmed)
                require(token.transfer(promisor, cost));
            else
                require(token.transfer(promisee, cost));

            if (validatorFee > 0)
                require(factory.xrt().transfer(validator, validatorFee));
        }

        require(factory.liabilityFinalized(gasinit));
        return true;
    }
}

 
contract RobotLiability is RobotLiabilityAPI, LightContract {
    constructor(address _lib) public LightContract(_lib)
    { factory = LiabilityFactory(msg.sender); }
}

contract LiabilityFactory {
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

     
    event NewLiability(address indexed liability);

     
    event NewLighthouse(address indexed lighthouse, string name);

     
    DutchAuction public auction;

     
    XRT public xrt;

     
    ENS public ens;

     
    uint256 public totalGasUtilizing = 0;

     
    mapping(address => uint256) public gasUtilizing;

     
    uint256 public constant gasEpoch = 347 * 10**10;

     
    uint256 public constant gasPrice = 10 * 10**9;

     
    mapping(bytes32 => bool) public usedHash;

     
    mapping(address => bool) public isLighthouse;

     
    address public robotLiabilityLib;

     
    address public lighthouseLib;

     
    function wnFromGas(uint256 _gas) public view returns (uint256) {
         
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

     
    function usedHashGuard(bytes32 _hash) internal {
        require(!usedHash[_hash]);
        usedHash[_hash] = true;
    }

     
    function createLiability(
        bytes _ask,
        bytes _bid
    )
        external 
        onlyLighthouse
        returns (RobotLiability liability)
    {
         
        uint256 gasinit = gasleft();

         
        liability = new RobotLiability(robotLiabilityLib);
        emit NewLiability(liability);

         
        require(liability.call(abi.encodePacked(bytes4(0x82fbaa25), _ask)));  
        usedHashGuard(liability.askHash());

        require(liability.call(abi.encodePacked(bytes4(0x66193359), _bid)));  
        usedHashGuard(liability.bidHash());

         
        require(xrt.transferFrom(liability.promisor(),
                                 tx.origin,
                                 liability.lighthouseFee()));

         
        ERC20 token = liability.token();
        require(token.transferFrom(liability.promisee(),
                                   liability,
                                   liability.cost()));

         
        if (address(liability.validator()) != 0 && liability.validatorFee() > 0)
            require(xrt.transferFrom(liability.promisee(),
                                     liability,
                                     liability.validatorFee()));

         
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
             
            = 0x3662a5d633e9a5ca4b4bd25284e1b343c15a92b5347feb9b965a2b1ef3e1ea1a;

         
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
        returns (bool)
    {
        require(gasUtilizing[msg.sender] > 0);

        uint256 gas = _gas - gasleft();
        totalGasUtilizing        += gas;
        gasUtilizing[msg.sender] += gas;
        require(xrt.mint(tx.origin, wnFromGas(gasUtilizing[msg.sender])));
        return true;
    }
}