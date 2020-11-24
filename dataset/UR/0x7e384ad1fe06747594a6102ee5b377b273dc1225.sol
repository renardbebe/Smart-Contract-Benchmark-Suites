 

 

pragma solidity ^0.5.0;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;



 
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

 

pragma solidity ^0.5.0;

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

 

pragma solidity ^0.5.0;

contract AbstractResolver {
    function supportsInterface(bytes4 _interfaceID) public view returns (bool);
    function addr(bytes32 _node) public view returns (address ret);
    function setAddr(bytes32 _node, address _addr) public;
    function hash(bytes32 _node) public view returns (bytes32 ret);
    function setHash(bytes32 _node, bytes32 _hash) public;
}

 

pragma solidity ^0.5.0;

contract SingletonHash {
    event HashConsumed(bytes32 indexed hash);

     
    mapping(bytes32 => bool) public isHashConsumed;

     
    function singletonHash(bytes32 _hash) internal {
        require(!isHashConsumed[_hash]);
        isHashConsumed[_hash] = true;
        emit HashConsumed(_hash);
    }
}

 

pragma solidity ^0.5.0;

 
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

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;


contract SignerRole {
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    constructor () internal {
        _addSigner(msg.sender);
    }

    modifier onlySigner() {
        require(isSigner(msg.sender));
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function addSigner(address account) public onlySigner {
        _addSigner(account);
    }

    function renounceSigner() public {
        _removeSigner(msg.sender);
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }
}

 

pragma solidity ^0.5.0;

 

library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
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

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 

pragma solidity ^0.5.0;



 
contract SignatureBouncer is SignerRole {
    using ECDSA for bytes32;

     
     
    uint256 private constant _METHOD_ID_SIZE = 4;
     
    uint256 private constant _SIGNATURE_SIZE = 96;

    constructor () internal {
         
    }

     
    modifier onlyValidSignature(bytes memory signature) {
        require(_isValidSignature(msg.sender, signature));
        _;
    }

     
    modifier onlyValidSignatureAndMethod(bytes memory signature) {
        require(_isValidSignatureAndMethod(msg.sender, signature));
        _;
    }

     
    modifier onlyValidSignatureAndData(bytes memory signature) {
        require(_isValidSignatureAndData(msg.sender, signature));
        _;
    }

     
    function _isValidSignature(address account, bytes memory signature) internal view returns (bool) {
        return _isValidDataHash(keccak256(abi.encodePacked(address(this), account)), signature);
    }

     
    function _isValidSignatureAndMethod(address account, bytes memory signature) internal view returns (bool) {
        bytes memory data = new bytes(_METHOD_ID_SIZE);
        for (uint i = 0; i < data.length; i++) {
            data[i] = msg.data[i];
        }
        return _isValidDataHash(keccak256(abi.encodePacked(address(this), account, data)), signature);
    }

     
    function _isValidSignatureAndData(address account, bytes memory signature) internal view returns (bool) {
        require(msg.data.length > _SIGNATURE_SIZE);

        bytes memory data = new bytes(msg.data.length - _SIGNATURE_SIZE);
        for (uint i = 0; i < data.length; i++) {
            data[i] = msg.data[i];
        }

        return _isValidDataHash(keccak256(abi.encodePacked(address(this), account, data)), signature);
    }

     
    function _isValidDataHash(bytes32 hash, bytes memory signature) internal view returns (bool) {
        address signer = hash.toEthSignedMessageHash().recover(signature);

        return signer != address(0) && isSigner(signer);
    }
}

 

pragma solidity ^0.5.0;



 
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

     
    function allowance(address owner, address spender) public view returns (uint256) {
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

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
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

 

pragma solidity ^0.5.0;






 
 
 
contract DutchAuction is SignatureBouncer, Ownable {
    using SafeERC20 for ERC20Burnable;

     
    event BidSubmission(address indexed sender, uint256 amount);

     
    uint constant public WAITING_PERIOD = 0;  

     
    ERC20Burnable public token;
    address public ambix;
    address payable public wallet;
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

     
     
     
     
     
     
    constructor(address payable _wallet, uint _maxTokenSold, uint _ceiling, uint _priceFactor)
        public
    {
        require(_wallet != address(0) && _ceiling > 0 && _priceFactor > 0);

        wallet = _wallet;
        maxTokenSold = _maxTokenSold;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        stage = Stages.AuctionDeployed;
    }

     
     
     
    function setup(ERC20Burnable _token, address _ambix)
        public
        onlyOwner
        atStage(Stages.AuctionDeployed)
    {
         
        require(_token != ERC20Burnable(0) && _ambix != address(0));

        token = _token;
        ambix = _ambix;

         
        require(token.balanceOf(address(this)) == maxTokenSold);

        stage = Stages.AuctionSetUp;
    }

     
    function startAuction()
        public
        onlyOwner
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

     
     
    function bid(bytes calldata signature)
        external
        payable
        isValidPayload
        timedTransitions
        atStage(Stages.AuctionStarted)
        onlyValidSignature(signature)
        returns (uint amount)
    {
        require(msg.value > 0);
        amount = msg.value;

        address payable receiver = msg.sender;

         
        uint maxWei = maxTokenSold * calcTokenPrice() / 10**9 - totalReceived;
        uint maxWeiBasedOnTotalReceived = ceiling - totalReceived;
        if (maxWeiBasedOnTotalReceived < maxWei)
            maxWei = maxWeiBasedOnTotalReceived;

         
        if (amount > maxWei) {
            amount = maxWei;
             
            receiver.transfer(msg.value - amount);
        }

         
        (bool success,) = wallet.call.value(amount)("");
        require(success);

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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
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
        bytes   calldata _model,
        bytes   calldata _objective,

        address _token,
        uint256 _cost,

        address _lighthouse,

        address _validator,
        uint256 _validator_fee,

        uint256 _deadline,
        address _sender,
        bytes   calldata _signature
    ) external returns (bool);

     
    function offer(
        bytes   calldata _model,
        bytes   calldata _objective,
        
        address _token,
        uint256 _cost,

        address _validator,

        address _lighthouse,
        uint256 _lighthouse_fee,

        uint256 _deadline,
        address _sender,
        bytes   calldata _signature
    ) external returns (bool);

     
    function finalize(
        bytes calldata _result,
        bool  _success,
        bytes calldata _signature
    ) external returns (bool);
}

 

pragma solidity ^0.5.0;

 
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

     
    function createLiability(
        bytes calldata _demand,
        bytes calldata _offer
    ) external returns (bool);

     
    function finalizeLiability(
        address _liability,
        bytes calldata _result,
        bool _success,
        bytes calldata _signature
    ) external returns (bool);
}

 

pragma solidity ^0.5.0;



 
contract IFactory {
     
    event NewLiability(address indexed liability);

     
    event NewLighthouse(address indexed lighthouse, string name);

     
    mapping(address => bool) public isLighthouse;

     
    mapping(address => uint256) public nonceOf;

     
    uint256 public totalGasConsumed = 0;

     
    mapping(address => uint256) public gasConsumedOf;

     
    uint256 public constant gasEpoch = 347 * 10**10;

     
    uint256 public gasPrice = 10 * 10**9;

     
    function wnFromGas(uint256 _gas) public view returns (uint256);

     
    function createLighthouse(
        uint256 _minimalStake,
        uint256 _timeoutInBlocks,
        string calldata _name
    ) external returns (ILighthouse);

     
    function createLiability(
        bytes calldata _demand,
        bytes calldata _offer
    ) external returns (ILiability);

     
    function liabilityCreated(ILiability _liability, uint256 _start_gas) external returns (bool);

     
    function liabilityFinalized(ILiability _liability, uint256 _start_gas) external returns (bool);
}

 

pragma solidity ^0.5.0;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 

pragma solidity ^0.5.0;




contract XRT is ERC20Mintable, ERC20Burnable, ERC20Detailed {
    constructor(uint256 _initial_supply) public ERC20Detailed("Robonomics", "XRT", 9) {
        _mint(msg.sender, _initial_supply);
    }
}

 

pragma solidity ^0.5.0;





contract Lighthouse is ILighthouse {
    using SafeERC20 for XRT;

    IFactory public factory;
    XRT      public xrt;

    function setup(XRT _xrt, uint256 _minimalStake, uint256 _timeoutInBlocks) external returns (bool) {
        require(factory == IFactory(0) && _minimalStake > 0 && _timeoutInBlocks > 0);

        minimalStake    = _minimalStake;
        timeoutInBlocks = _timeoutInBlocks;
        factory         = IFactory(msg.sender);
        xrt             = _xrt;

        return true;
    }

     
    mapping(address => uint256) public indexOf;

    function refill(uint256 _value) external returns (bool) {
        xrt.safeTransferFrom(msg.sender, address(this), _value);

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
        bytes calldata _demand,
        bytes calldata _offer
    )
        external
        returns (bool)
    {
         
        uint256 gas = startGas() + 4887;

        keepAliveTransaction();
        quotedTransaction();

        ILiability liability = factory.createLiability(_demand, _offer);
        require(liability != ILiability(0));
        require(factory.liabilityCreated(liability, gas - gasleft()));
        return true;
    }

    function finalizeLiability(
        address _liability,
        bytes calldata _result,
        bool _success,
        bytes calldata _signature
    )
        external
        returns (bool)
    {
         
        uint256 gas = startGas() + 22335;

        keepAliveTransaction();
        quotedTransaction();

        ILiability liability = ILiability(_liability);
        require(factory.gasConsumedOf(_liability) > 0);
        require(liability.finalize(_result, _success, _signature));
        require(factory.liabilityFinalized(liability, gas - gasleft()));
        return true;
    }
}

 

pragma solidity ^0.5.0;

 
contract IValidator {
     
    function isValidator(address _validator) external returns (bool);
}

 

pragma solidity ^0.5.0;







contract Liability is ILiability {
    using ECDSA for bytes32;
    using SafeERC20 for XRT;
    using SafeERC20 for ERC20;

    address public factory;
    XRT     public xrt;

    function setup(XRT _xrt) external returns (bool) {
        require(factory == address(0));

        factory = msg.sender;
        xrt     = _xrt;

        return true;
    }

    function demand(
        bytes   calldata _model,
        bytes   calldata _objective,

        address _token,
        uint256 _cost,

        address _lighthouse,

        address _validator,
        uint256 _validator_fee,

        uint256 _deadline,
        address _sender,
        bytes   calldata _signature
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
          , IFactory(factory).nonceOf(_sender)
          , _sender
        ));

        promisee = demandHash
            .toEthSignedMessageHash()
            .recover(_signature);
        require(promisee == _sender);
        return true;
    }

    function offer(
        bytes   calldata _model,
        bytes   calldata _objective,
        
        address _token,
        uint256 _cost,

        address _validator,

        address _lighthouse,
        uint256 _lighthouse_fee,

        uint256 _deadline,
        address _sender,
        bytes   calldata _signature
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
          , IFactory(factory).nonceOf(_sender)
          , _sender
        ));

        promisor = offerHash
            .toEthSignedMessageHash()
            .recover(_signature);
        require(promisor == _sender);
        return true;
    }

    function finalize(
        bytes calldata _result,
        bool  _success,
        bytes calldata _signature
    )
        external
        returns (bool)
    {
        require(msg.sender == lighthouse);
        require(!isFinalized);

        isFinalized = true;
        result      = _result;
        isSuccess   = _success;

        address resultSender = keccak256(abi.encodePacked(this, _result, _success))
            .toEthSignedMessageHash()
            .recover(_signature);

        if (validator == address(0)) {
            require(resultSender == promisor);
        } else {
            require(IValidator(validator).isValidator(resultSender));
             
            if (validatorFee > 0)
                xrt.safeTransfer(validator, validatorFee);

        }

        if (cost > 0)
            ERC20(token).safeTransfer(isSuccess ? promisor : promisee, cost);

        emit Finalized(isSuccess, result);
        return true;
    }
}

 

pragma solidity ^0.5.0;











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

     
    uint256 private constant smmaPeriod = 1000;

     
    function wnFromGas(uint256 _gas) public view returns (uint256) {
         
        if (auction.finalPrice() == 0)
            return _gas * 150;

         
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
        string  calldata _name
    )
        external
        returns (ILighthouse lighthouse)
    {
        bytes32 LIGHTHOUSE_NODE
             
            = 0x8d6c004b56cbe83bbfd9dcbd8f45d1f76398267bbb130a4629d822abc1994b96;
        bytes32 hname = keccak256(bytes(_name));

         
        bytes32 subnode = keccak256(abi.encodePacked(LIGHTHOUSE_NODE, hname));
        require(ens.resolver(subnode) == address(0));

         
        lighthouse = ILighthouse(lighthouseCode.proxy());
        require(Lighthouse(address(lighthouse)).setup(xrt, _minimalStake, _timeoutInBlocks));

        emit NewLighthouse(address(lighthouse), _name);
        isLighthouse[address(lighthouse)] = true;

         
        ens.setSubnodeOwner(LIGHTHOUSE_NODE, hname, address(this));

         
        AbstractResolver resolver = AbstractResolver(ens.resolver(LIGHTHOUSE_NODE));
        ens.setResolver(subnode, address(resolver));
        resolver.setAddr(subnode, address(lighthouse));
    }

    function createLiability(
        bytes calldata _demand,
        bytes calldata _offer
    )
        external
        onlyLighthouse
        returns (ILiability liability)
    {
         
        liability = ILiability(liabilityCode.proxy());
        require(Liability(address(liability)).setup(xrt));

        emit NewLiability(address(liability));

         
        (bool success, bytes memory returnData)
            = address(liability).call(abi.encodePacked(bytes4(0x48a984e4), _demand));  
        require(success);
        singletonHash(liability.demandHash());
        nonceOf[liability.promisee()] += 1;

        (success, returnData)
            = address(liability).call(abi.encodePacked(bytes4(0x413781d2), _offer));  
        require(success);
        singletonHash(liability.offerHash());
        nonceOf[liability.promisor()] += 1;

         
        require(isLighthouse[liability.lighthouse()]);

         
        if (liability.lighthouseFee() > 0)
            xrt.safeTransferFrom(liability.promisor(),
                                 tx.origin,
                                 liability.lighthouseFee());

         
        ERC20 token = ERC20(liability.token());
        if (liability.cost() > 0)
            token.safeTransferFrom(liability.promisee(),
                                   address(liability),
                                   liability.cost());

         
        if (liability.validator() != address(0) && liability.validatorFee() > 0)
            xrt.safeTransferFrom(liability.promisee(),
                                 address(liability),
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
        address liability = address(_liability);
        totalGasConsumed         += _gas;
        gasConsumedOf[liability] += _gas;
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
        address liability = address(_liability);
        totalGasConsumed         += _gas;
        gasConsumedOf[liability] += _gas;
        require(xrt.mint(tx.origin, wnFromGas(gasConsumedOf[liability])));
        return true;
    }
}