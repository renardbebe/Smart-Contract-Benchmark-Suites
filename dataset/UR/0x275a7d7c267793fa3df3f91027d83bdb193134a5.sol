 

 

pragma solidity ^0.5.4;

 
contract ERC20 {
    function totalSupply() public view returns (uint);
    function decimals() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

 
interface Module {
    function init(BaseWallet _wallet) external;
    function addModule(BaseWallet _wallet, Module _module) external;
    function recoverToken(address _token) external;
}

 
contract BaseWallet {
    address public implementation;
    address public owner;
    mapping (address => bool) public authorised;
    mapping (bytes4 => address) public enabled;
    uint public modules;
    function init(address _owner, address[] calldata _modules) external;
    function authoriseModule(address _module, bool _value) external;
    function enableStaticCall(address _module, bytes4 _method) external;
    function setOwner(address _newOwner) external;
    function invoke(address _target, uint _value, bytes calldata _data) external;
    function() external payable;
}

 
contract ModuleRegistry {
    function registerModule(address _module, bytes32 _name) external;
    function deregisterModule(address _module) external;
    function registerUpgrader(address _upgrader, bytes32 _name) external;
    function deregisterUpgrader(address _upgrader) external;
    function recoverToken(address _token) external;
    function moduleInfo(address _module) external view returns (bytes32);
    function upgraderInfo(address _upgrader) external view returns (bytes32);
    function isRegisteredModule(address _module) external view returns (bool);
    function isRegisteredModule(address[] calldata _modules) external view returns (bool);
    function isRegisteredUpgrader(address _upgrader) external view returns (bool);
}

 
contract GuardianStorage {
    function addGuardian(BaseWallet _wallet, address _guardian) external;
    function revokeGuardian(BaseWallet _wallet, address _guardian) external;
    function guardianCount(BaseWallet _wallet) external view returns (uint256);
    function getGuardians(BaseWallet _wallet) external view returns (address[] memory);
    function isGuardian(BaseWallet _wallet, address _guardian) external view returns (bool);
    function setLock(BaseWallet _wallet, uint256 _releaseAfter) external;
    function isLocked(BaseWallet _wallet) external view returns (bool);
    function getLock(BaseWallet _wallet) external view returns (uint256);
    function getLocker(BaseWallet _wallet) external view returns (address);
}

 
contract IMakerCdp {
    IDSValue  public pep;  
    IMakerVox public vox;  

    function sai() external view returns (address);   
    function skr() external view returns (address);   
    function gem() external view returns (address);   
    function gov() external view returns (address);   

    function lad(bytes32 cup) external view returns (address);
    function ink(bytes32 cup) external view returns (uint);
    function tab(bytes32 cup) external returns (uint);
    function rap(bytes32 cup) external returns (uint);

    function tag() public view returns (uint wad);
    function mat() public view returns (uint ray);
    function per() public view returns (uint ray);
    function safe(bytes32 cup) external returns (bool);
    function ask(uint wad) public view returns (uint);
    function bid(uint wad) public view returns (uint);

    function open() external returns (bytes32 cup);
    function join(uint wad) external;  
    function exit(uint wad) external;  
    function give(bytes32 cup, address guy) external;
    function lock(bytes32 cup, uint wad) external;
    function free(bytes32 cup, uint wad) external;
    function draw(bytes32 cup, uint wad) external;
    function wipe(bytes32 cup, uint wad) external;
    function shut(bytes32 cup) external;
    function bite(bytes32 cup) external;
}

interface IMakerVox {
    function par() external returns (uint);
}

interface IDSValue {
    function peek() external view returns (bytes32, bool);
    function read() external view returns (bytes32);
    function poke(bytes32 wut) external;
    function void() external;
} 

interface UniswapFactory {
    function getExchange(address _token) external view returns(address);
}

interface UniswapExchange {
    function getEthToTokenOutputPrice(uint256 _tokens_bought) external view returns (uint256);
    function getEthToTokenInputPrice(uint256 _eth_sold) external view returns (uint256);
    function getTokenToEthOutputPrice(uint256 _eth_bought) external view returns (uint256);
    function getTokenToEthInputPrice(uint256 _tokens_sold) external view returns (uint256);
}

 
interface Loan {

    event LoanOpened(address indexed _wallet, bytes32 indexed _loanId, address _collateral, uint256 _collateralAmount, address _debtToken, uint256 _debtAmount);
    event LoanClosed(address indexed _wallet, bytes32 indexed _loanId);
    event CollateralAdded(address indexed _wallet, bytes32 indexed _loanId, address _collateral, uint256 _collateralAmount);
    event CollateralRemoved(address indexed _wallet, bytes32 indexed _loanId, address _collateral, uint256 _collateralAmount);
    event DebtAdded(address indexed _wallet, bytes32 indexed _loanId, address _debtToken, uint256 _debtAmount);
    event DebtRemoved(address indexed _wallet, bytes32 indexed _loanId, address _debtToken, uint256 _debtAmount);

     
    function openLoan(
        BaseWallet _wallet, 
        address _collateral, 
        uint256 _collateralAmount, 
        address _debtToken, 
        uint256 _debtAmount
    ) 
        external 
        returns (bytes32 _loanId);

     
    function closeLoan(
        BaseWallet _wallet, 
        bytes32 _loanId
    ) 
        external;

     
    function addCollateral(
        BaseWallet _wallet, 
        bytes32 _loanId, 
        address _collateral, 
        uint256 _collateralAmount
    ) 
        external;

     
    function removeCollateral(
        BaseWallet _wallet, 
        bytes32 _loanId, 
        address _collateral, 
        uint256 _collateralAmount
    ) 
        external;

     
    function addDebt(
        BaseWallet _wallet, 
        bytes32 _loanId, 
        address _debtToken, 
        uint256 _debtAmount
    ) 
        external;

     
    function removeDebt(
        BaseWallet _wallet, 
        bytes32 _loanId, 
        address _debtToken, 
        uint256 _debtAmount
    ) 
        external;

     
    function getLoan(
        BaseWallet _wallet, 
        bytes32 _loanId
    ) 
        external 
        view 
        returns (uint8 _status, uint256 _ethValue);
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

     
    function ceil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        if(a % b == 0) {
            return c;
        }
        else {
            return c + 1;
        }
    }

     

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
}

 
contract BaseModule is Module {

     
    ModuleRegistry internal registry;

    event ModuleCreated(bytes32 name);
    event ModuleInitialised(address wallet);

    constructor(ModuleRegistry _registry, bytes32 _name) public {
        registry = _registry;
        emit ModuleCreated(_name);
    }

     
    modifier onlyWallet(BaseWallet _wallet) {
        require(msg.sender == address(_wallet), "BM: caller must be wallet");
        _;
    }

     
    modifier onlyWalletOwner(BaseWallet _wallet) {
        require(msg.sender == address(this) || isOwner(_wallet, msg.sender), "BM: must be an owner for the wallet");
        _;
    }

     
    modifier strictOnlyWalletOwner(BaseWallet _wallet) {
        require(isOwner(_wallet, msg.sender), "BM: msg.sender must be an owner for the wallet");
        _;
    }

     
    function init(BaseWallet _wallet) external onlyWallet(_wallet) {
        emit ModuleInitialised(address(_wallet));
    }

     
    function addModule(BaseWallet _wallet, Module _module) external strictOnlyWalletOwner(_wallet) {
        require(registry.isRegisteredModule(address(_module)), "BM: module is not registered");
        _wallet.authoriseModule(address(_module), true);
    }

     
    function recoverToken(address _token) external {
        uint total = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(address(registry), total);
    }

     
    function isOwner(BaseWallet _wallet, address _addr) internal view returns (bool) {
        return _wallet.owner() == _addr;
    }
}

 
contract RelayerModule is Module {

    uint256 constant internal BLOCKBOUND = 10000;

    mapping (address => RelayerConfig) public relayer; 

    struct RelayerConfig {
        uint256 nonce;
        mapping (bytes32 => bool) executedTx;
    }

    event TransactionExecuted(address indexed wallet, bool indexed success, bytes32 signedHash);

     
    modifier onlyExecute {
        require(msg.sender == address(this), "RM: must be called via execute()");
        _;
    }

     

     
    function getRequiredSignatures(BaseWallet _wallet, bytes memory _data) internal view returns (uint256);

     
    function validateSignatures(BaseWallet _wallet, bytes memory _data, bytes32 _signHash, bytes memory _signatures) internal view returns (bool);

     

     
    function execute(
        BaseWallet _wallet,
        bytes calldata _data, 
        uint256 _nonce, 
        bytes calldata _signatures, 
        uint256 _gasPrice,
        uint256 _gasLimit
    )
        external
        returns (bool success)
    {
        uint startGas = gasleft();
        bytes32 signHash = getSignHash(address(this), address(_wallet), 0, _data, _nonce, _gasPrice, _gasLimit);
        require(checkAndUpdateUniqueness(_wallet, _nonce, signHash), "RM: Duplicate request");
        require(verifyData(address(_wallet), _data), "RM: the wallet authorized is different then the target of the relayed data");
        uint256 requiredSignatures = getRequiredSignatures(_wallet, _data);
        if((requiredSignatures * 65) == _signatures.length) {
            if(verifyRefund(_wallet, _gasLimit, _gasPrice, requiredSignatures)) {
                if(requiredSignatures == 0 || validateSignatures(_wallet, _data, signHash, _signatures)) {
                     
                    (success,) = address(this).call(_data);
                    refund(_wallet, startGas - gasleft(), _gasPrice, _gasLimit, requiredSignatures, msg.sender);
                }
            }
        }
        emit TransactionExecuted(address(_wallet), success, signHash); 
    }

     
    function getNonce(BaseWallet _wallet) external view returns (uint256 nonce) {
        return relayer[address(_wallet)].nonce;
    }

     
    function getSignHash(
        address _from,
        address _to, 
        uint256 _value, 
        bytes memory _data, 
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit
    ) 
        internal 
        pure
        returns (bytes32) 
    {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(byte(0x19), byte(0), _from, _to, _value, _data, _nonce, _gasPrice, _gasLimit))
        ));
    }

     
    function checkAndUpdateUniqueness(BaseWallet _wallet, uint256 _nonce, bytes32 _signHash) internal returns (bool) {
        if(relayer[address(_wallet)].executedTx[_signHash] == true) {
            return false;
        }
        relayer[address(_wallet)].executedTx[_signHash] = true;
        return true;
    }

     
    function checkAndUpdateNonce(BaseWallet _wallet, uint256 _nonce) internal returns (bool) {
        if(_nonce <= relayer[address(_wallet)].nonce) {
            return false;
        }   
        uint256 nonceBlock = (_nonce & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128;
        if(nonceBlock > block.number + BLOCKBOUND) {
            return false;
        }
        relayer[address(_wallet)].nonce = _nonce;
        return true;    
    }

     
    function recoverSigner(bytes32 _signedHash, bytes memory _signatures, uint _index) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
         
         
         
         
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28); 
        return ecrecover(_signedHash, v, r, s);
    }

     
    function refund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _gasLimit, uint _signatures, address _relayer) internal {
        uint256 amount = 29292 + _gasUsed;  
         
        if(_gasPrice > 0 && _signatures > 1 && amount <= _gasLimit) {
            if(_gasPrice > tx.gasprice) {
                amount = amount * tx.gasprice;
            }
            else {
                amount = amount * _gasPrice;
            }
            _wallet.invoke(_relayer, amount, "");
        }
    }

     
    function verifyRefund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _signatures) internal view returns (bool) {
        if(_gasPrice > 0 
            && _signatures > 1 
            && (address(_wallet).balance < _gasUsed * _gasPrice || _wallet.authorised(address(this)) == false)) {
            return false;
        }
        return true;
    }

     
    function verifyData(address _wallet, bytes memory _data) private pure returns (bool) {
        require(_data.length >= 36, "RM: Invalid dataWallet");
        address dataWallet;
         
        assembly {
             
            dataWallet := mload(add(_data, 0x24))
        }
        return dataWallet == _wallet;
    }

     
    function functionPrefix(bytes memory _data) internal pure returns (bytes4 prefix) {
        require(_data.length >= 4, "RM: Invalid functionPrefix");
         
        assembly {
            prefix := mload(add(_data, 0x20))
        }
    }
}

 
contract OnlyOwnerModule is BaseModule, RelayerModule {

     

     
    function checkAndUpdateUniqueness(BaseWallet _wallet, uint256 _nonce, bytes32 _signHash) internal returns (bool) {
        return checkAndUpdateNonce(_wallet, _nonce);
    }

    function validateSignatures(BaseWallet _wallet, bytes memory _data, bytes32 _signHash, bytes memory _signatures) internal view returns (bool) {
        address signer = recoverSigner(_signHash, _signatures, 0);
        return isOwner(_wallet, signer);  
    }

    function getRequiredSignatures(BaseWallet _wallet, bytes memory _data) internal view returns (uint256) {
        return 1;
    }
}

 
contract MakerManager is Loan, BaseModule, RelayerModule, OnlyOwnerModule {

    bytes32 constant NAME = "MakerManager";

     
    GuardianStorage public guardianStorage;
     
    IMakerCdp public makerCdp;
     
    UniswapFactory public uniswapFactory;

     
    address constant internal ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

     
    bytes4 constant internal CDP_DRAW = bytes4(keccak256("draw(bytes32,uint256)"));
    bytes4 constant internal CDP_WIPE = bytes4(keccak256("wipe(bytes32,uint256)"));
    bytes4 constant internal CDP_SHUT = bytes4(keccak256("shut(bytes32)"));
    bytes4 constant internal CDP_JOIN = bytes4(keccak256("join(uint256)"));
    bytes4 constant internal CDP_LOCK = bytes4(keccak256("lock(bytes32,uint256)"));
    bytes4 constant internal CDP_FREE = bytes4(keccak256("free(bytes32,uint256)"));
    bytes4 constant internal CDP_EXIT = bytes4(keccak256("exit(uint256)"));
    bytes4 constant internal WETH_DEPOSIT = bytes4(keccak256("deposit()"));
    bytes4 constant internal WETH_WITHDRAW = bytes4(keccak256("withdraw(uint256)"));
    bytes4 constant internal ERC20_APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 constant internal ETH_TOKEN_SWAP_OUTPUT = bytes4(keccak256("ethToTokenSwapOutput(uint256,uint256)"));
    bytes4 constant internal ETH_TOKEN_SWAP_INPUT = bytes4(keccak256("ethToTokenSwapInput(uint256,uint256)"));
    bytes4 constant internal TOKEN_ETH_SWAP_INPUT = bytes4(keccak256("tokenToEthSwapInput(uint256,uint256,uint256)"));

    using SafeMath for uint256;

     
    modifier onlyWhenUnlocked(BaseWallet _wallet) {
         
        require(!guardianStorage.isLocked(_wallet), "MakerManager: wallet must be unlocked");
        _;
    }

    constructor(
        ModuleRegistry _registry,
        GuardianStorage _guardianStorage,
        IMakerCdp _makerCdp,
        UniswapFactory _uniswapFactory
    )
        BaseModule(_registry, NAME)
        public
    {
        guardianStorage = _guardianStorage;
        makerCdp = _makerCdp;
        uniswapFactory = _uniswapFactory;
    }

     

    
    function openLoan(
        BaseWallet _wallet, 
        address _collateral, 
        uint256 _collateralAmount, 
        address _debtToken, 
        uint256 _debtAmount
    ) 
        external 
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
        returns (bytes32 _loanId)
    {
        require(_collateral == ETH_TOKEN_ADDRESS, "Maker: collateral must be ETH");
        require(_debtToken == makerCdp.sai(), "Maker: debt token must be DAI");
        _loanId = openCdp(_wallet, _collateralAmount, _debtAmount, makerCdp);
        emit LoanOpened(address(_wallet), _loanId, _collateral, _collateralAmount, _debtToken, _debtAmount);
    }

     
    function closeLoan(
        BaseWallet _wallet, 
        bytes32 _loanId
    ) 
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        closeCdp(_wallet, _loanId, makerCdp, uniswapFactory);
        emit LoanClosed(address(_wallet), _loanId);
    }

     
    function addCollateral(
        BaseWallet _wallet, 
        bytes32 _loanId, 
        address _collateral, 
        uint256 _collateralAmount
    ) 
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(_collateral == ETH_TOKEN_ADDRESS, "Maker: collateral must be ETH");
        addCollateral(_wallet, _loanId, _collateralAmount, makerCdp);
        emit CollateralAdded(address(_wallet), _loanId, _collateral, _collateralAmount);
    }

     
    function removeCollateral(
        BaseWallet _wallet, 
        bytes32 _loanId, 
        address _collateral, 
        uint256 _collateralAmount
    ) 
        external 
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(_collateral == ETH_TOKEN_ADDRESS, "Maker: collateral must be ETH");
        removeCollateral(_wallet, _loanId, _collateralAmount, makerCdp);
        emit CollateralRemoved(address(_wallet), _loanId, _collateral, _collateralAmount);
    }

     
    function addDebt(
        BaseWallet _wallet,
        bytes32 _loanId,
        address _debtToken,
        uint256 _debtAmount
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(_debtToken == makerCdp.sai(), "Maker: debt token must be DAI");
        addDebt(_wallet, _loanId, _debtAmount, makerCdp);
        emit DebtAdded(address(_wallet), _loanId, _debtToken, _debtAmount);
    }

     
    function removeDebt(
        BaseWallet _wallet,
        bytes32 _loanId,
        address _debtToken,
        uint256 _debtAmount
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(_debtToken == makerCdp.sai(), "Maker: debt token must be DAI");
        removeDebt(_wallet, _loanId, _debtAmount, makerCdp, uniswapFactory);
        emit DebtRemoved(address(_wallet), _loanId, _debtToken, _debtAmount);
    }

     
    function getLoan(
        BaseWallet _wallet, 
        bytes32 _loanId
    ) 
        external 
        view 
        returns (uint8 _status, uint256 _ethValue)
    {
        if(exists(_loanId, makerCdp)) {
            return (3,0);
        }
        return (0,0);
    }

     

     

     
    function openCdp(
        BaseWallet _wallet, 
        uint256 _pethCollateral, 
        uint256 _daiDebt,
        IMakerCdp _makerCdp
    ) 
        internal 
        returns (bytes32 _cup)
    {
         
        _cup = _makerCdp.open();
         
        _makerCdp.give(_cup, address(_wallet));
         
        lockETH(_wallet, _cup, _pethCollateral, _makerCdp);
         
        if(_daiDebt > 0) {
            invokeWallet(_wallet, address(_makerCdp), 0, abi.encodeWithSelector(CDP_DRAW, _cup, _daiDebt));
        }
    }

     
    function addCollateral(
        BaseWallet _wallet, 
        bytes32 _cup,
        uint256 _amount,
        IMakerCdp _makerCdp
    ) 
        internal
    {
         
        require(address(_wallet) == _makerCdp.lad(_cup), "CM: not CDP owner");
         
        lockETH(_wallet, _cup, _amount, _makerCdp);  
    }

     
    function removeCollateral(
        BaseWallet _wallet, 
        bytes32 _cup,
        uint256 _amount,
        IMakerCdp _makerCdp
    ) 
        internal
    {
         
        freeETH(_wallet, _cup, _amount, _makerCdp);
    }

     
    function addDebt(
        BaseWallet _wallet, 
        bytes32 _cup,
        uint256 _amount,
        IMakerCdp _makerCdp
    ) 
        internal
    {
         
        invokeWallet(_wallet, address(_makerCdp), 0, abi.encodeWithSelector(CDP_DRAW, _cup, _amount));
    }

     
    function removeDebt(
        BaseWallet _wallet, 
        bytes32 _cup,
        uint256 _amount,
        IMakerCdp _makerCdp,
        UniswapFactory _uniswapFactory
    ) 
        internal
    {
         
        require(address(_wallet) == _makerCdp.lad(_cup), "CM: not CDP owner");
         
        uint256 mkrFee = governanceFeeInMKR(_cup, _amount, _makerCdp);
         
        address mkrToken = _makerCdp.gov();
        uint256 mkrBalance = ERC20(mkrToken).balanceOf(address(_wallet));
        if (mkrBalance < mkrFee) {
             
            address mkrUniswap = _uniswapFactory.getExchange(mkrToken);
            uint256 etherValueOfMKR = UniswapExchange(mkrUniswap).getEthToTokenOutputPrice(mkrFee - mkrBalance);
            invokeWallet(_wallet, mkrUniswap, etherValueOfMKR, abi.encodeWithSelector(ETH_TOKEN_SWAP_OUTPUT, mkrFee - mkrBalance, block.timestamp));
        }
        
         
        address daiToken =_makerCdp.sai();
        uint256 daiBalance = ERC20(daiToken).balanceOf(address(_wallet));
        if (daiBalance < _amount) {
             
            address daiUniswap = _uniswapFactory.getExchange(daiToken);
            uint256 etherValueOfDAI = UniswapExchange(daiUniswap).getEthToTokenOutputPrice(_amount - daiBalance);
            invokeWallet(_wallet, daiUniswap, etherValueOfDAI, abi.encodeWithSelector(ETH_TOKEN_SWAP_OUTPUT, _amount - daiBalance, block.timestamp));
        }

         
        invokeWallet(_wallet, daiToken, 0, abi.encodeWithSelector(ERC20_APPROVE, address(_makerCdp), _amount));
         
        invokeWallet(_wallet, mkrToken, 0, abi.encodeWithSelector(ERC20_APPROVE, address(_makerCdp), mkrFee));
         
        invokeWallet(_wallet, address(_makerCdp), 0, abi.encodeWithSelector(CDP_WIPE, _cup, _amount));
    }

     
    function closeCdp(
        BaseWallet _wallet,
        bytes32 _cup,
        IMakerCdp _makerCdp,
        UniswapFactory _uniswapFactory
    ) 
        internal
    {
         
        uint debt = daiDebt(_cup, _makerCdp);
        if(debt > 0) removeDebt(_wallet, _cup, debt, _makerCdp, _uniswapFactory);
         
        uint collateral = pethCollateral(_cup, _makerCdp);
        if(collateral > 0) removeCollateral(_wallet, _cup, collateral, _makerCdp);
         
        invokeWallet(_wallet, address(_makerCdp), 0, abi.encodeWithSelector(CDP_SHUT, _cup));
    }

     

     
    function pethCollateral(bytes32 _cup, IMakerCdp _makerCdp) public view returns (uint256) { 
        return _makerCdp.ink(_cup);
    }

     
    function daiDebt(bytes32 _cup, IMakerCdp _makerCdp) public returns (uint256) { 
        return _makerCdp.tab(_cup);
    }

     
    function isSafe(bytes32 _cup, IMakerCdp _makerCdp) public returns (bool) { 
        return _makerCdp.safe(_cup);
    }

     
    function exists(bytes32 _cup, IMakerCdp _makerCdp) public view returns (bool) { 
        return _makerCdp.lad(_cup) != address(0);
    }

     
    function maxDaiDrawable(bytes32 _cup, IMakerCdp _makerCdp) public returns (uint256) {
        uint256 maxTab = _makerCdp.ink(_cup).rmul(_makerCdp.tag()).rdiv(_makerCdp.vox().par()).rdiv(_makerCdp.mat());
        return maxTab.sub(_makerCdp.tab(_cup));
    }

     
    function minCollateralRequired(bytes32 _cup, IMakerCdp _makerCdp) public returns (uint256) {
        uint256 minInk = _makerCdp.tab(_cup).rmul(_makerCdp.mat()).rmul(_makerCdp.vox().par()).rdiv(_makerCdp.tag());
        return minInk.sub(_makerCdp.ink(_cup));
    }

     
    function governanceFeeInMKR(bytes32 _cup, uint256 _daiRefund, IMakerCdp _makerCdp) public returns (uint256 _fee) { 
        uint debt = daiDebt(_cup, _makerCdp);
        if (debt == 0) return 0;
        uint256 feeInDAI = _daiRefund.rmul(_makerCdp.rap(_cup).rdiv(debt));
        (bytes32 daiPerMKR, bool ok) = _makerCdp.pep().peek();
        if (ok && daiPerMKR != 0) _fee = feeInDAI.wdiv(uint(daiPerMKR));
    }

     
    function totalGovernanceFeeInMKR(bytes32 _cup, IMakerCdp _makerCdp) external returns (uint256 _fee) { 
        return governanceFeeInMKR(_cup, daiDebt(_cup, _makerCdp), _makerCdp);
    }

     
    function minRequiredCollateral(bytes32 _cup, IMakerCdp _makerCdp) public returns (uint256 _minCollateral) { 
        _minCollateral = daiDebt(_cup, _makerCdp)     
            .rmul(_makerCdp.vox().par())          
            .rmul(_makerCdp.mat())                
            .rmul(1010000000000000000000000000)  
            .rdiv(_makerCdp.tag());               
    }

     

     
    function lockETH(
        BaseWallet _wallet, 
        bytes32 _cup,
        uint256 _pethAmount,
        IMakerCdp _makerCdp
    ) 
        internal 
    {
         
        address wethToken = _makerCdp.gem();
         
        uint ethAmount = _makerCdp.ask(_pethAmount);
         
        invokeWallet(_wallet, wethToken, ethAmount, abi.encodeWithSelector(WETH_DEPOSIT));
         
        invokeWallet(_wallet, wethToken, 0, abi.encodeWithSelector(ERC20_APPROVE, address(_makerCdp), ethAmount));
         
        invokeWallet(_wallet, address(_makerCdp), 0, abi.encodeWithSelector(CDP_JOIN, _pethAmount));

         
        address pethToken = _makerCdp.skr();
         
        invokeWallet(_wallet, pethToken, 0, abi.encodeWithSelector(ERC20_APPROVE, address(_makerCdp), _pethAmount));
         
        invokeWallet(_wallet, address(_makerCdp), 0, abi.encodeWithSelector(CDP_LOCK, _cup, _pethAmount));
    }

     
    function freeETH(
        BaseWallet _wallet, 
        bytes32 _cup,
        uint256 _pethAmount,
        IMakerCdp _makerCdp
    ) 
        internal 
    {
         

         
        invokeWallet(_wallet, address(_makerCdp), 0, abi.encodeWithSelector(CDP_FREE, _cup, _pethAmount));

         
        address wethToken = _makerCdp.gem();
        address pethToken = _makerCdp.skr();
         
        invokeWallet(_wallet, pethToken, 0, abi.encodeWithSelector(ERC20_APPROVE, address(_makerCdp), _pethAmount));
         
        invokeWallet(_wallet, address(_makerCdp), 0, abi.encodeWithSelector(CDP_EXIT, _pethAmount));
         
        uint ethAmount = _makerCdp.bid(_pethAmount);
         
        invokeWallet(_wallet, wethToken, 0, abi.encodeWithSelector(WETH_WITHDRAW, ethAmount));
    }

     
    function daiPerMkr(IMakerCdp _makerCdp) internal view returns (uint256 _daiPerMKR) {
        (bytes32 daiPerMKR_, bool ok) = _makerCdp.pep().peek();
        require(ok && daiPerMKR_ != 0, "LM: invalid DAI/MKR rate");
        _daiPerMKR = uint256(daiPerMKR_);
    }

     
    function invokeWallet(BaseWallet _wallet, address _to, uint256 _value, bytes memory _data) internal {
        _wallet.invoke(_to, _value, _data);
    }
}