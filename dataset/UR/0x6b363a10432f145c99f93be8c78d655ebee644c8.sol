 

pragma solidity ^0.4.24;

 
contract Pausable {

    event Pause(uint256 _timestammp);
    event Unpause(uint256 _timestamp);

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

     
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    
    function _pause() internal whenNotPaused {
        paused = true;
         
        emit Pause(now);
    }

     
    function _unpause() internal whenPaused {
        paused = false;
         
        emit Unpause(now);
    }

}

 
interface IModule {

     
    function getInitFunction() external pure returns (bytes4);

     
    function getPermissions() external view returns(bytes32[]);

     
    function takeFee(uint256 _amount) external returns(bool);

}

 
interface ISecurityToken {

     
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool);
    function increaseApproval(address _spender, uint _addedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function verifyTransfer(address _from, address _to, uint256 _value) external returns (bool success);

     
    function mint(address _investor, uint256 _value) external returns (bool success);

     
    function mintWithData(address _investor, uint256 _value, bytes _data) external returns (bool success);

     
    function burnFromWithData(address _from, uint256 _value, bytes _data) external;

     
    function burnWithData(uint256 _value, bytes _data) external;

    event Minted(address indexed _to, uint256 _value);
    event Burnt(address indexed _burner, uint256 _value);

     
     
     
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns (bool);

     
    function getModule(address _module) external view returns(bytes32, address, address, bool, uint8, uint256, uint256);

     
    function getModulesByName(bytes32 _name) external view returns (address[]);

     
    function getModulesByType(uint8 _type) external view returns (address[]);

     
    function totalSupplyAt(uint256 _checkpointId) external view returns (uint256);

     
    function balanceOfAt(address _investor, uint256 _checkpointId) external view returns (uint256);

     
    function createCheckpoint() external returns (uint256);

     
    function getInvestors() external view returns (address[]);

     
    function getInvestorsAt(uint256 _checkpointId) external view returns(address[]);

     
    function iterateInvestors(uint256 _start, uint256 _end) external view returns(address[]);
    
     
    function currentCheckpointId() external view returns (uint256);

     
    function investors(uint256 _index) external view returns (address);

    
    function withdrawERC20(address _tokenContract, uint256 _value) external;

     
    function changeModuleBudget(address _module, uint256 _budget) external;

     
    function updateTokenDetails(string _newTokenDetails) external;

     
    function changeGranularity(uint256 _granularity) external;

     
    function pruneInvestors(uint256 _start, uint256 _iters) external;

     
    function freezeTransfers() external;

     
    function unfreezeTransfers() external;

     
    function freezeMinting() external;

     
    function mintMulti(address[] _investors, uint256[] _values) external returns (bool success);

     
    function addModule(
        address _moduleFactory,
        bytes _data,
        uint256 _maxCost,
        uint256 _budget
    ) external;

     
    function archiveModule(address _module) external;

     
    function unarchiveModule(address _module) external;

     
    function removeModule(address _module) external;

     
    function setController(address _controller) external;

     
    function forceTransfer(address _from, address _to, uint256 _value, bytes _data, bytes _log) external;

     
    function forceBurn(address _from, uint256 _value, bytes _data, bytes _log) external;

     
     function disableController() external;

      
     function getVersion() external view returns(uint8[]);

      
     function getInvestorCount() external view returns(uint256);

      
     function transferWithData(address _to, uint256 _value, bytes _data) external returns (bool success);

      
     function transferFromWithData(address _from, address _to, uint256 _value, bytes _data) external returns(bool);

      
     function granularity() external view returns(uint256);
}

 
interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool);
    function increaseApproval(address _spender, uint _addedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract Module is IModule {

    address public factory;

    address public securityToken;

    bytes32 public constant FEE_ADMIN = "FEE_ADMIN";

    IERC20 public polyToken;

     
    constructor (address _securityToken, address _polyAddress) public {
        securityToken = _securityToken;
        factory = msg.sender;
        polyToken = IERC20(_polyAddress);
    }

     
    modifier withPerm(bytes32 _perm) {
        bool isOwner = msg.sender == Ownable(securityToken).owner();
        bool isFactory = msg.sender == factory;
        require(isOwner||isFactory||ISecurityToken(securityToken).checkPermission(msg.sender, address(this), _perm), "Permission check failed");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == Ownable(securityToken).owner(), "Sender is not owner");
        _;
    }

    modifier onlyFactory {
        require(msg.sender == factory, "Sender is not factory");
        _;
    }

    modifier onlyFactoryOwner {
        require(msg.sender == Ownable(factory).owner(), "Sender is not factory owner");
        _;
    }

    modifier onlyFactoryOrOwner {
        require((msg.sender == Ownable(securityToken).owner()) || (msg.sender == factory), "Sender is not factory or owner");
        _;
    }

     
    function takeFee(uint256 _amount) public withPerm(FEE_ADMIN) returns(bool) {
        require(polyToken.transferFrom(securityToken, Ownable(factory).owner(), _amount), "Unable to take fee");
        return true;
    }
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ISTO is Module, Pausable  {
    using SafeMath for uint256;

    enum FundRaiseType { ETH, POLY, DAI }
    mapping (uint8 => bool) public fundRaiseTypes;
    mapping (uint8 => uint256) public fundsRaised;

     
    uint256 public startTime;
     
    uint256 public endTime;
     
    uint256 public pausedTime;
     
    uint256 public investorCount;
     
    address public wallet;
      
    uint256 public totalTokensSold;

     
    event SetFundRaiseTypes(FundRaiseType[] _fundRaiseTypes);

     
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "Transfer failed");
    }

     
    function getRaised(FundRaiseType _fundRaiseType) public view returns (uint256) {
        return fundsRaised[uint8(_fundRaiseType)];
    }

     
    function getTokensSold() public view returns (uint256);

     
    function pause() public onlyOwner {
         
        require(now < endTime, "STO has been finalized");
        super._pause();
    }

     
    function unpause() public onlyOwner {
        super._unpause();
    }

    function _setFundRaiseType(FundRaiseType[] _fundRaiseTypes) internal {
         
        require(_fundRaiseTypes.length > 0, "Raise type is not specified");
        fundRaiseTypes[uint8(FundRaiseType.ETH)] = false;
        fundRaiseTypes[uint8(FundRaiseType.POLY)] = false;
        fundRaiseTypes[uint8(FundRaiseType.DAI)] = false;
        for (uint8 j = 0; j < _fundRaiseTypes.length; j++) {
            fundRaiseTypes[uint8(_fundRaiseTypes[j])] = true;
        }
        emit SetFundRaiseTypes(_fundRaiseTypes);
    }

}

interface IOracle {

     
    function getCurrencyAddress() external view returns(address);

     
    function getCurrencySymbol() external view returns(bytes32);

     
    function getCurrencyDenominated() external view returns(bytes32);

     
    function getPrice() external view returns(uint256);

}

 
contract ReclaimTokens is Ownable {

     
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance), "Transfer failed");
    }
}

 
contract PolymathRegistry is ReclaimTokens {

    mapping (bytes32 => address) public storedAddresses;

    event ChangeAddress(string _nameKey, address indexed _oldAddress, address indexed _newAddress);

     
    function getAddress(string _nameKey) external view returns(address) {
        bytes32 key = keccak256(bytes(_nameKey));
        require(storedAddresses[key] != address(0), "Invalid address key");
        return storedAddresses[key];
    }

     
    function changeAddress(string _nameKey, address _newAddress) external onlyOwner {
        bytes32 key = keccak256(bytes(_nameKey));
        emit ChangeAddress(_nameKey, storedAddresses[key], _newAddress);
        storedAddresses[key] = _newAddress;
    }


}

contract RegistryUpdater is Ownable {

    address public polymathRegistry;
    address public moduleRegistry;
    address public securityTokenRegistry;
    address public featureRegistry;
    address public polyToken;

    constructor (address _polymathRegistry) public {
        require(_polymathRegistry != address(0), "Invalid address");
        polymathRegistry = _polymathRegistry;
    }

    function updateFromRegistry() public onlyOwner {
        moduleRegistry = PolymathRegistry(polymathRegistry).getAddress("ModuleRegistry");
        securityTokenRegistry = PolymathRegistry(polymathRegistry).getAddress("SecurityTokenRegistry");
        featureRegistry = PolymathRegistry(polymathRegistry).getAddress("FeatureRegistry");
        polyToken = PolymathRegistry(polymathRegistry).getAddress("PolyToken");
    }

}

library DecimalMath {

    using SafeMath for uint256;

      
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), (10 ** 18) / 2) / (10 ** 18);
    }

     
    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, (10 ** 18)), y / 2) / y;
    }

}

 
contract ReentrancyGuard {

   
  bool private reentrancyLock = false;

   
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

 
contract USDTieredSTO is ISTO, ReentrancyGuard {
    using SafeMath for uint256;

     
     
     

    string public POLY_ORACLE = "PolyUsdOracle";
    string public ETH_ORACLE = "EthUsdOracle";
    mapping (bytes32 => mapping (bytes32 => string)) oracleKeys;

    IERC20 public usdToken;

     
    bool public allowBeneficialInvestments = false;

     
    address public wallet;

     
    address public reserveWallet;

     
    uint256[] public ratePerTier;

     
    uint256[] public ratePerTierDiscountPoly;

     
    uint256[] public tokensPerTierTotal;

     
    uint256[] public tokensPerTierDiscountPoly;

     
    uint256[] public mintedPerTierTotal;

     
    mapping (uint8 => uint256[]) public mintedPerTier;

     
    uint256[] public mintedPerTierDiscountPoly;

     
    uint8 public currentTier;

     
    uint256 public fundsRaisedUSD;

     
    mapping (address => uint256) public investorInvestedUSD;

     
    mapping (address => mapping (uint8 => uint256)) public investorInvested;

     
    mapping (address => bool) public accredited;

     
    uint256 public nonAccreditedLimitUSD;

     
    mapping (address => uint256) public nonAccreditedLimitUSDOverride;

     
    uint256 public minimumInvestmentUSD;

     
    bool public isFinalized;

     
    uint256 public finalAmountReturned;

     
     
     

    event SetAllowBeneficialInvestments(bool _allowed);
    event SetNonAccreditedLimit(address _investor, uint256 _limit);
    event SetAccredited(address _investor, bool _accredited);
    event TokenPurchase(
        address indexed _purchaser,
        address indexed _beneficiary,
        uint256 _tokens,
        uint256 _usdAmount,
        uint256 _tierPrice,
        uint8 _tier
    );
    event FundsReceived(
        address indexed _purchaser,
        address indexed _beneficiary,
        uint256 _usdAmount,
        FundRaiseType _fundRaiseType,
        uint256 _receivedValue,
        uint256 _spentValue,
        uint256 _rate
    );
    event FundsReceivedPOLY(
        address indexed _purchaser,
        address indexed _beneficiary,
        uint256 _usdAmount,
        uint256 _receivedValue,
        uint256 _spentValue,
        uint256 _rate
    );
    event ReserveTokenMint(address indexed _owner, address indexed _wallet, uint256 _tokens, uint8 _latestTier);

    event SetAddresses(
        address indexed _wallet,
        address indexed _reserveWallet,
        address indexed _usdToken
    );
    event SetLimits(
        uint256 _nonAccreditedLimitUSD,
        uint256 _minimumInvestmentUSD
    );
    event SetTimes(
        uint256 _startTime,
        uint256 _endTime
    );
    event SetTiers(
        uint256[] _ratePerTier,
        uint256[] _ratePerTierDiscountPoly,
        uint256[] _tokensPerTierTotal,
        uint256[] _tokensPerTierDiscountPoly
    );

     
     
     

    modifier validETH {
        require(_getOracle(bytes32("ETH"), bytes32("USD")) != address(0), "Invalid ETHUSD Oracle");
        require(fundRaiseTypes[uint8(FundRaiseType.ETH)], "Fund raise in ETH should be allowed");
        _;
    }

    modifier validPOLY {
        require(_getOracle(bytes32("POLY"), bytes32("USD")) != address(0), "Invalid POLYUSD Oracle");
        require(fundRaiseTypes[uint8(FundRaiseType.POLY)], "Fund raise in POLY should be allowed");
        _;
    }

    modifier validDAI {
        require(fundRaiseTypes[uint8(FundRaiseType.DAI)], "Fund raise in DAI should be allowed");
        _;
    }

     
     
     

    constructor (address _securityToken, address _polyAddress, address _factory) public Module(_securityToken, _polyAddress) {
        oracleKeys[bytes32("ETH")][bytes32("USD")] = ETH_ORACLE;
        oracleKeys[bytes32("POLY")][bytes32("USD")] = POLY_ORACLE;
        require(_factory != address(0), "In-valid address");
        factory = _factory;
    }

     
    function configure(
        uint256 _startTime,
        uint256 _endTime,
        uint256[] _ratePerTier,
        uint256[] _ratePerTierDiscountPoly,
        uint256[] _tokensPerTierTotal,
        uint256[] _tokensPerTierDiscountPoly,
        uint256 _nonAccreditedLimitUSD,
        uint256 _minimumInvestmentUSD,
        FundRaiseType[] _fundRaiseTypes,
        address _wallet,
        address _reserveWallet,
        address _usdToken
    ) public onlyFactory {
        modifyTimes(_startTime, _endTime);
         
        modifyTiers(_ratePerTier, _ratePerTierDiscountPoly, _tokensPerTierTotal, _tokensPerTierDiscountPoly);
         
        modifyFunding(_fundRaiseTypes);
        modifyAddresses(_wallet, _reserveWallet, _usdToken);
        modifyLimits(_nonAccreditedLimitUSD, _minimumInvestmentUSD);
    }

    function modifyFunding(FundRaiseType[] _fundRaiseTypes) public onlyFactoryOrOwner {
         
        require(now < startTime, "STO shouldn't be started");
        _setFundRaiseType(_fundRaiseTypes);
        uint256 length = getNumberOfTiers();
        mintedPerTierTotal = new uint256[](length);
        mintedPerTierDiscountPoly = new uint256[](length);
        for (uint8 i = 0; i < _fundRaiseTypes.length; i++) {
            mintedPerTier[uint8(_fundRaiseTypes[i])] = new uint256[](length);
        }
    }

    function modifyLimits(
        uint256 _nonAccreditedLimitUSD,
        uint256 _minimumInvestmentUSD
    ) public onlyFactoryOrOwner {
         
        require(now < startTime, "STO shouldn't be started");
        minimumInvestmentUSD = _minimumInvestmentUSD;
        nonAccreditedLimitUSD = _nonAccreditedLimitUSD;
        emit SetLimits(minimumInvestmentUSD, nonAccreditedLimitUSD);
    }

    function modifyTiers(
        uint256[] _ratePerTier,
        uint256[] _ratePerTierDiscountPoly,
        uint256[] _tokensPerTierTotal,
        uint256[] _tokensPerTierDiscountPoly
    ) public onlyFactoryOrOwner {
         
        require(now < startTime, "STO shouldn't be started");
        require(_tokensPerTierTotal.length > 0, "Length should be > 0");
        require(_ratePerTier.length == _tokensPerTierTotal.length, "Mismatch b/w rates & tokens / tier");
        require(_ratePerTierDiscountPoly.length == _tokensPerTierTotal.length, "Mismatch b/w discount rates & tokens / tier");
        require(_tokensPerTierDiscountPoly.length == _tokensPerTierTotal.length, "Mismatch b/w discount tokens / tier & tokens / tier");
        for (uint8 i = 0; i < _ratePerTier.length; i++) {
            require(_ratePerTier[i] > 0, "Rate > 0");
            require(_tokensPerTierTotal[i] > 0, "Tokens per tier > 0");
            require(_tokensPerTierDiscountPoly[i] <= _tokensPerTierTotal[i], "Discounted tokens / tier <= tokens / tier");
            require(_ratePerTierDiscountPoly[i] <= _ratePerTier[i], "Discounted rate / tier <= rate / tier");
        }
        ratePerTier = _ratePerTier;
        ratePerTierDiscountPoly = _ratePerTierDiscountPoly;
        tokensPerTierTotal = _tokensPerTierTotal;
        tokensPerTierDiscountPoly = _tokensPerTierDiscountPoly;
        emit SetTiers(_ratePerTier, _ratePerTierDiscountPoly, _tokensPerTierTotal, _tokensPerTierDiscountPoly);
    }

    function modifyTimes(
        uint256 _startTime,
        uint256 _endTime
    ) public onlyFactoryOrOwner {
         
        require((startTime == 0) || (now < startTime), "Invalid startTime");
         
        require((_endTime > _startTime) && (_startTime > now), "Invalid times");
        startTime = _startTime;
        endTime = _endTime;
        emit SetTimes(_startTime, _endTime);
    }

    function modifyAddresses(
        address _wallet,
        address _reserveWallet,
        address _usdToken
    ) public onlyFactoryOrOwner {
         
        require(now < startTime, "STO shouldn't be started");
        require(_wallet != address(0) && _reserveWallet != address(0), "Invalid address");
        if (fundRaiseTypes[uint8(FundRaiseType.DAI)]) {
            require(_usdToken != address(0), "Invalid address");
        }
        wallet = _wallet;
        reserveWallet = _reserveWallet;
        usdToken = IERC20(_usdToken);
        emit SetAddresses(_wallet, _reserveWallet, _usdToken);
    }

     
     
     

     
    function finalize() public onlyOwner {
        require(!isFinalized, "STO is already finalized");
        isFinalized = true;
        uint256 tempReturned;
        uint256 tempSold;
        uint256 remainingTokens;
        for (uint8 i = 0; i < tokensPerTierTotal.length; i++) {
            remainingTokens = tokensPerTierTotal[i].sub(mintedPerTierTotal[i]);
            tempReturned = tempReturned.add(remainingTokens);
            tempSold = tempSold.add(mintedPerTierTotal[i]);
            if (remainingTokens > 0) {
                mintedPerTierTotal[i] = tokensPerTierTotal[i];
            }
        }
        require(ISecurityToken(securityToken).mint(reserveWallet, tempReturned), "Error in minting");
        emit ReserveTokenMint(msg.sender, reserveWallet, tempReturned, currentTier);
        finalAmountReturned = tempReturned;
        totalTokensSold = tempSold;
    }

     
    function changeAccredited(address[] _investors, bool[] _accredited) public onlyOwner {
        require(_investors.length == _accredited.length, "Array length mismatch");
        for (uint256 i = 0; i < _investors.length; i++) {
            accredited[_investors[i]] = _accredited[i];
            emit SetAccredited(_investors[i], _accredited[i]);
        }
    }

     
    function changeNonAccreditedLimit(address[] _investors, uint256[] _nonAccreditedLimit) public onlyOwner {
         
        require(_investors.length == _nonAccreditedLimit.length, "Array length mismatch");
        for (uint256 i = 0; i < _investors.length; i++) {
            require(_nonAccreditedLimit[i] > 0, "Limit can not be 0");
            nonAccreditedLimitUSDOverride[_investors[i]] = _nonAccreditedLimit[i];
            emit SetNonAccreditedLimit(_investors[i], _nonAccreditedLimit[i]);
        }
    }

     
    function changeAllowBeneficialInvestments(bool _allowBeneficialInvestments) public onlyOwner {
        require(_allowBeneficialInvestments != allowBeneficialInvestments, "Value unchanged");
        allowBeneficialInvestments = _allowBeneficialInvestments;
        emit SetAllowBeneficialInvestments(allowBeneficialInvestments);
    }

     
     
     

     
    function () external payable {
        buyWithETH(msg.sender);
    }

     
    function buyWithETH(address _beneficiary) public payable validETH {
        uint256 rate = getRate(FundRaiseType.ETH);
        (uint256 spentUSD, uint256 spentValue) = _buyTokens(_beneficiary, msg.value, rate, FundRaiseType.ETH);
         
        investorInvested[_beneficiary][uint8(FundRaiseType.ETH)] = investorInvested[_beneficiary][uint8(FundRaiseType.ETH)].add(spentValue);
        fundsRaised[uint8(FundRaiseType.ETH)] = fundsRaised[uint8(FundRaiseType.ETH)].add(spentValue);
         
        wallet.transfer(spentValue);
         
        msg.sender.transfer(msg.value.sub(spentValue));
        emit FundsReceived(msg.sender, _beneficiary, spentUSD, FundRaiseType.ETH, msg.value, spentValue, rate);
    }

     
    function buyWithPOLY(address _beneficiary, uint256 _investedPOLY) public validPOLY {
        _buyWithTokens(_beneficiary, _investedPOLY, FundRaiseType.POLY);
    }

     
    function buyWithUSD(address _beneficiary, uint256 _investedDAI) public validDAI {
        _buyWithTokens(_beneficiary, _investedDAI, FundRaiseType.DAI);
    }

    function _buyWithTokens(address _beneficiary, uint256 _tokenAmount, FundRaiseType _fundRaiseType) internal {
        require(_fundRaiseType == FundRaiseType.POLY || _fundRaiseType == FundRaiseType.DAI, "POLY & DAI supported");
        uint256 rate = getRate(_fundRaiseType);
        (uint256 spentUSD, uint256 spentValue) = _buyTokens(_beneficiary, _tokenAmount, rate, _fundRaiseType);
         
        investorInvested[_beneficiary][uint8(_fundRaiseType)] = investorInvested[_beneficiary][uint8(_fundRaiseType)].add(spentValue);
        fundsRaised[uint8(_fundRaiseType)] = fundsRaised[uint8(_fundRaiseType)].add(spentValue);
         
        IERC20 token = _fundRaiseType == FundRaiseType.POLY ? polyToken : usdToken;
        require(token.transferFrom(msg.sender, wallet, spentValue), "Transfer failed");
        emit FundsReceived(msg.sender, _beneficiary, spentUSD, _fundRaiseType, _tokenAmount, spentValue, rate);
    }

     
    function _buyTokens(
        address _beneficiary,
        uint256 _investmentValue,
        uint256 _rate,
        FundRaiseType _fundRaiseType
    )
        internal
        nonReentrant
        whenNotPaused
        returns(uint256, uint256)
    {
        if (!allowBeneficialInvestments) {
            require(_beneficiary == msg.sender, "Beneficiary does not match funder");
        }

        require(isOpen(), "STO is not open");
        require(_investmentValue > 0, "No funds were sent");

        uint256 investedUSD = DecimalMath.mul(_rate, _investmentValue);
        uint256 originalUSD = investedUSD;

         
        require(investedUSD.add(investorInvestedUSD[_beneficiary]) >= minimumInvestmentUSD, "Total investment < minimumInvestmentUSD");

         
        if (!accredited[_beneficiary]) {
            uint256 investorLimitUSD = (nonAccreditedLimitUSDOverride[_beneficiary] == 0) ? nonAccreditedLimitUSD : nonAccreditedLimitUSDOverride[_beneficiary];
            require(investorInvestedUSD[_beneficiary] < investorLimitUSD, "Non-accredited investor has reached limit");
            if (investedUSD.add(investorInvestedUSD[_beneficiary]) > investorLimitUSD)
                investedUSD = investorLimitUSD.sub(investorInvestedUSD[_beneficiary]);
        }
        uint256 spentUSD;
         
        for (uint8 i = currentTier; i < ratePerTier.length; i++) {
             
            if (currentTier != i)
                currentTier = i;
             
            if (mintedPerTierTotal[i] < tokensPerTierTotal[i])
                spentUSD = spentUSD.add(_calculateTier(_beneficiary, i, investedUSD.sub(spentUSD), _fundRaiseType));
             
            if (investedUSD == spentUSD)
                break;
        }

         
        if (spentUSD > 0) {
            if (investorInvestedUSD[_beneficiary] == 0)
                investorCount = investorCount + 1;
            investorInvestedUSD[_beneficiary] = investorInvestedUSD[_beneficiary].add(spentUSD);
            fundsRaisedUSD = fundsRaisedUSD.add(spentUSD);
        }

         
        uint256 spentValue;
        if (spentUSD == 0) {
            spentValue = 0;
        } else {
            spentValue = DecimalMath.mul(DecimalMath.div(spentUSD, originalUSD), _investmentValue);
        }

         
        return (spentUSD, spentValue);
    }

    function _calculateTier(
        address _beneficiary,
        uint8 _tier,
        uint256 _investedUSD,
        FundRaiseType _fundRaiseType
    ) 
        internal
        returns(uint256)
     {
         
        uint256 spentUSD;
        uint256 tierSpentUSD;
        uint256 tierPurchasedTokens;
        uint256 investedUSD = _investedUSD;
         
        if ((_fundRaiseType == FundRaiseType.POLY) && (tokensPerTierDiscountPoly[_tier] > mintedPerTierDiscountPoly[_tier])) {
            uint256 discountRemaining = tokensPerTierDiscountPoly[_tier].sub(mintedPerTierDiscountPoly[_tier]);
            uint256 totalRemaining = tokensPerTierTotal[_tier].sub(mintedPerTierTotal[_tier]);
            if (totalRemaining < discountRemaining)
                (spentUSD, tierPurchasedTokens) = _purchaseTier(_beneficiary, ratePerTierDiscountPoly[_tier], totalRemaining, investedUSD, _tier);
            else
                (spentUSD, tierPurchasedTokens) = _purchaseTier(_beneficiary, ratePerTierDiscountPoly[_tier], discountRemaining, investedUSD, _tier);
            investedUSD = investedUSD.sub(spentUSD);
            mintedPerTierDiscountPoly[_tier] = mintedPerTierDiscountPoly[_tier].add(tierPurchasedTokens);
            mintedPerTier[uint8(FundRaiseType.POLY)][_tier] = mintedPerTier[uint8(FundRaiseType.POLY)][_tier].add(tierPurchasedTokens);
            mintedPerTierTotal[_tier] = mintedPerTierTotal[_tier].add(tierPurchasedTokens);
        }
         
        if ((investedUSD > 0) && (tokensPerTierTotal[_tier].sub(mintedPerTierTotal[_tier]) > 0)) {
            (tierSpentUSD, tierPurchasedTokens) = _purchaseTier(_beneficiary, ratePerTier[_tier], tokensPerTierTotal[_tier].sub(mintedPerTierTotal[_tier]), investedUSD, _tier);
            spentUSD = spentUSD.add(tierSpentUSD);
            mintedPerTier[uint8(_fundRaiseType)][_tier] = mintedPerTier[uint8(_fundRaiseType)][_tier].add(tierPurchasedTokens);
            mintedPerTierTotal[_tier] = mintedPerTierTotal[_tier].add(tierPurchasedTokens);
        }
        return spentUSD;
    }

    function _purchaseTier(
        address _beneficiary,
        uint256 _tierPrice,
        uint256 _tierRemaining,
        uint256 _investedUSD,
        uint8 _tier
    )
        internal
        returns(uint256, uint256)
    {
        uint256 maximumTokens = DecimalMath.div(_investedUSD, _tierPrice);
        uint256 spentUSD;
        uint256 purchasedTokens;
        if (maximumTokens > _tierRemaining) {
            spentUSD = DecimalMath.mul(_tierRemaining, _tierPrice);
             
            if (spentUSD > _investedUSD) {
                spentUSD = _investedUSD;
            }
            purchasedTokens = _tierRemaining;
        } else {
            spentUSD = _investedUSD;
            purchasedTokens = maximumTokens;
        }
        require(ISecurityToken(securityToken).mint(_beneficiary, purchasedTokens), "Error in minting");
        emit TokenPurchase(msg.sender, _beneficiary, purchasedTokens, spentUSD, _tierPrice, _tier);
        return (spentUSD, purchasedTokens);
    }

     
     
     

     
    function isOpen() public view returns(bool) {
        if (isFinalized)
            return false;
         
        if (now < startTime)
            return false;
         
        if (now >= endTime)
            return false;
        if (capReached())
            return false;
        return true;
    }

     
    function capReached() public view returns (bool) {
        if (isFinalized) {
            return (finalAmountReturned == 0);
        }
        return (mintedPerTierTotal[mintedPerTierTotal.length - 1] == tokensPerTierTotal[tokensPerTierTotal.length - 1]);
    }

    function getRate(FundRaiseType _fundRaiseType) public view returns (uint256) {
        if (_fundRaiseType == FundRaiseType.ETH) {
            return IOracle(_getOracle(bytes32("ETH"), bytes32("USD"))).getPrice();
        } else if (_fundRaiseType == FundRaiseType.POLY) {
            return IOracle(_getOracle(bytes32("POLY"), bytes32("USD"))).getPrice();
        } else if (_fundRaiseType == FundRaiseType.DAI) {
            return 1 * 10**18;
        } else {
            revert("Incorrect funding");
        }
    }

     
    function convertToUSD(FundRaiseType _fundRaiseType, uint256 _amount) public view returns(uint256) {
        uint256 rate = getRate(_fundRaiseType);
        return DecimalMath.mul(_amount, rate);
    }

     
    function convertFromUSD(FundRaiseType _fundRaiseType, uint256 _amount) public view returns(uint256) {
        uint256 rate = getRate(_fundRaiseType);
        return DecimalMath.div(_amount, rate);
    }

     
    function getTokensSold() public view returns (uint256) {
        if (isFinalized)
            return totalTokensSold;
        else
            return getTokensMinted();
    }

     
    function getTokensMinted() public view returns (uint256) {
        uint256 tokensMinted;
        for (uint8 i = 0; i < mintedPerTierTotal.length; i++) {
            tokensMinted = tokensMinted.add(mintedPerTierTotal[i]);
        }
        return tokensMinted;
    }

     
    function getTokensSoldFor(FundRaiseType _fundRaiseType) public view returns (uint256) {
        uint256 tokensSold;
        for (uint8 i = 0; i < mintedPerTier[uint8(_fundRaiseType)].length; i++) {
            tokensSold = tokensSold.add(mintedPerTier[uint8(_fundRaiseType)][i]);
        }
        return tokensSold;
    }

     
    function getNumberOfTiers() public view returns (uint256) {
        return tokensPerTierTotal.length;
    }

     
    function getPermissions() public view returns(bytes32[]) {
        bytes32[] memory allPermissions = new bytes32[](0);
        return allPermissions;
    }

     
    function getInitFunction() public pure returns (bytes4) {
        return 0xb0ff041e;
    }

    function _getOracle(bytes32 _currency, bytes32 _denominatedCurrency) internal view returns (address) {
        return PolymathRegistry(RegistryUpdater(securityToken).polymathRegistry()).getAddress(oracleKeys[_currency][_denominatedCurrency]);
    }

}