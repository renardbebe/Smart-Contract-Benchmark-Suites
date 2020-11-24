 

 

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

interface Comptroller {
    function enterMarkets(address[] calldata _cTokens) external returns (uint[] memory);
    function exitMarket(address _cToken) external returns (uint);
    function getAssetsIn(address _account) external view returns (address[] memory);
    function getAccountLiquidity(address _account) external view returns (uint, uint, uint);
    function checkMembership(address account, CToken cToken) external view returns (bool);
}

interface CToken {
    function comptroller() external view returns (address);
    function underlying() external view returns (address);
    function symbol() external view returns (string memory);
    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function borrowBalanceCurrent(address _account) external returns (uint256);
    function borrowBalanceStored(address _account) external view returns (uint256);
}

 
contract CompoundRegistry {
    function addCToken(address _underlying, address _cToken) external;
    function removeCToken(address _underlying) external;
    function getCToken(address _underlying) external view returns (address);
    function listUnderlyings() external view returns (address[] memory);
}

 
interface Invest {

    event InvestmentAdded(address indexed _wallet, address _token, uint256 _invested, uint256 _period);
    event InvestmentRemoved(address indexed _wallet, address _token, uint256 _fraction);

     
    function addInvestment(
        BaseWallet _wallet, 
        address _token, 
        uint256 _amount, 
        uint256 _period
    ) 
        external
        returns (uint256 _invested);

     
    function removeInvestment(
        BaseWallet _wallet, 
        address _token, 
        uint256 _fraction
    ) 
        external;

     
    function getInvestment(
        BaseWallet _wallet,
        address _token
    )
        external
        view
        returns (uint256 _tokenValue, uint256 _periodEnd);
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

 
contract CompoundManager is Loan, Invest, BaseModule, RelayerModule, OnlyOwnerModule {

    bytes32 constant NAME = "CompoundManager";

     
    GuardianStorage public guardianStorage;
     
    Comptroller public comptroller;
     
    CompoundRegistry public compoundRegistry;

     
    address constant internal ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    using SafeMath for uint256;

     
    modifier onlyWhenUnlocked(BaseWallet _wallet) {
         
        require(!guardianStorage.isLocked(_wallet), "CompoundManager: wallet must be unlocked");
        _;
    }

    constructor(
        ModuleRegistry _registry,
        GuardianStorage _guardianStorage,
        Comptroller _comptroller,
        CompoundRegistry _compoundRegistry
    )
        BaseModule(_registry, NAME)
        public
    {
        guardianStorage = _guardianStorage;
        comptroller = _comptroller;
        compoundRegistry = _compoundRegistry;
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
        address[] memory markets = new address[](2);
        markets[0] = compoundRegistry.getCToken(_collateral);
        markets[1] = compoundRegistry.getCToken(_debtToken);
        _wallet.invoke(address(comptroller), 0, abi.encodeWithSignature("enterMarkets(address[])", markets));
        mint(_wallet, markets[0], _collateral, _collateralAmount);
        borrow(_wallet, markets[1], _debtAmount);
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
        address[] memory markets = comptroller.getAssetsIn(address(_wallet));
        for(uint i = 0; i < markets.length; i++) {
            address cToken = markets[i];
            uint debt = CToken(cToken).borrowBalanceCurrent(address(_wallet));
            if(debt > 0) {
                repayBorrow(_wallet, cToken, debt);
                uint collateral = CToken(cToken).balanceOf(address(_wallet));
                if(collateral == 0) {
                    _wallet.invoke(address(comptroller), 0, abi.encodeWithSignature("exitMarket(address)", address(cToken)));
                }
            }
        }
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
        address cToken = compoundRegistry.getCToken(_collateral);
        enterMarketIfNeeded(_wallet, cToken, address(comptroller));
        mint(_wallet, cToken, _collateral, _collateralAmount);
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
        address cToken = compoundRegistry.getCToken(_collateral);
        redeemUnderlying(_wallet, cToken, _collateralAmount);
        exitMarketIfNeeded(_wallet, cToken, address(comptroller));
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
        address dToken = compoundRegistry.getCToken(_debtToken);
        enterMarketIfNeeded(_wallet, dToken, address(comptroller));
        borrow(_wallet, dToken, _debtAmount);
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
        address dToken = compoundRegistry.getCToken(_debtToken);
        repayBorrow(_wallet, dToken, _debtAmount);
        exitMarketIfNeeded(_wallet, dToken, address(comptroller));
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
        (uint error, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(address(_wallet));
        require(error == 0, "Compound: failed to get account liquidity");
        if(liquidity > 0) {
            return (1, liquidity);
        }
        if(shortfall > 0) {
            return (2, shortfall);
        }
        return (0,0);
    }

     

     
    function addInvestment(
        BaseWallet _wallet, 
        address _token, 
        uint256 _amount, 
        uint256 _period
    ) 
        external 
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
        returns (uint256 _invested)
    {
        address cToken = compoundRegistry.getCToken(_token);
        mint(_wallet, cToken, _token, _amount);
        _invested = _amount;
        emit InvestmentAdded(address(_wallet), _token, _amount, _period);
    }

     
    function removeInvestment(
        BaseWallet _wallet, 
        address _token, 
        uint256 _fraction
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(_fraction <= 10000, "CompoundV2: invalid fraction value");
        address cToken = compoundRegistry.getCToken(_token);
        uint shares = CToken(cToken).balanceOf(address(_wallet));
        redeem(_wallet, cToken, shares.mul(_fraction).div(10000));
        emit InvestmentRemoved(address(_wallet), _token, _fraction);
    }

     
    function getInvestment(
        BaseWallet _wallet, 
        address _token
    ) 
        external 
        view
        returns (uint256 _tokenValue, uint256 _periodEnd) 
    {
        address cToken = compoundRegistry.getCToken(_token);
        uint amount = CToken(cToken).balanceOf(address(_wallet));
        uint exchangeRateMantissa = CToken(cToken).exchangeRateStored();
        _tokenValue = amount.mul(exchangeRateMantissa).div(10 ** 18);
        _periodEnd = 0;
    }

     

     
    function mint(BaseWallet _wallet, address _cToken, address _token, uint256 _amount) internal {
        require(_cToken != address(0), "Compound: No market for target token");
        require(_amount > 0, "Compound: amount cannot be 0");
        if(_token == ETH_TOKEN_ADDRESS) {
            _wallet.invoke(_cToken, _amount, abi.encodeWithSignature("mint()"));
        }
        else {
            _wallet.invoke(_token, 0, abi.encodeWithSignature("approve(address,uint256)", _cToken, _amount));
            _wallet.invoke(_cToken, 0, abi.encodeWithSignature("mint(uint256)", _amount));
        }
    }

     
    function redeem(BaseWallet _wallet, address _cToken, uint256 _amount) internal {     
        require(_cToken != address(0), "Compound: No market for target token");   
        require(_amount > 0, "Compound: amount cannot be 0");
        _wallet.invoke(_cToken, 0, abi.encodeWithSignature("redeem(uint256)", _amount));
    }

     
    function redeemUnderlying(BaseWallet _wallet, address _cToken, uint256 _amount) internal {     
        require(_cToken != address(0), "Compound: No market for target token");   
        require(_amount > 0, "Compound: amount cannot be 0");
        _wallet.invoke(_cToken, 0, abi.encodeWithSignature("redeemUnderlying(uint256)", _amount));
    }

     
    function borrow(BaseWallet _wallet, address _cToken, uint256 _amount) internal {
        require(_cToken != address(0), "Compound: No market for target token");
        require(_amount > 0, "Compound: amount cannot be 0");
        _wallet.invoke(_cToken, 0, abi.encodeWithSignature("borrow(uint256)", _amount));
    }

     
    function repayBorrow(BaseWallet _wallet, address _cToken, uint256 _amount) internal {
        require(_cToken != address(0), "Compound: No market for target token");
        require(_amount > 0, "Compound: amount cannot be 0");
        string memory symbol = CToken(_cToken).symbol();
        if(keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("cETH"))) {
            _wallet.invoke(_cToken, _amount, abi.encodeWithSignature("repayBorrow()"));
        }
        else { 
            address token = CToken(_cToken).underlying();
            _wallet.invoke(token, 0, abi.encodeWithSignature("approve(address,uint256)", _cToken, _amount));
            _wallet.invoke(_cToken, 0, abi.encodeWithSignature("repayBorrow(uint256)", _amount));
        }
    }

     
    function enterMarketIfNeeded(BaseWallet _wallet, address _cToken, address _comptroller) internal {
        bool isEntered = Comptroller(_comptroller).checkMembership(address(_wallet), CToken(_cToken));
        if(!isEntered) {
            address[] memory market = new address[](1);
            market[0] = _cToken;
            _wallet.invoke(_comptroller, 0, abi.encodeWithSignature("enterMarkets(address[])", market));
        }
    }

     
    function exitMarketIfNeeded(BaseWallet _wallet, address _cToken, address _comptroller) internal {
        uint collateral = CToken(_cToken).balanceOf(address(_wallet));
        uint debt = CToken(_cToken).borrowBalanceStored(address(_wallet));
        if(collateral == 0 && debt == 0) {
            _wallet.invoke(_comptroller, 0, abi.encodeWithSignature("exitMarket(address)", _cToken));
        }
    }
}