 

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

 
contract ModuleStorage {

     
    constructor (address _securityToken, address _polyAddress) public {
        securityToken = _securityToken;
        factory = msg.sender;
        polyToken = IERC20(_polyAddress);
    }
    
    address public factory;

    address public securityToken;

    bytes32 public constant FEE_ADMIN = "FEE_ADMIN";

    IERC20 public polyToken;

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

 
contract Module is IModule, ModuleStorage {

     
    constructor (address _securityToken, address _polyAddress) public
    ModuleStorage(_securityToken, _polyAddress)
    {
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

 
interface ISTO {
     
    function getTokensSold() external view returns (uint256);
}

 
contract STOStorage {

    mapping (uint8 => bool) public fundRaiseTypes;
    mapping (uint8 => uint256) public fundsRaised;

     
    uint256 public startTime;
     
    uint256 public endTime;
     
    uint256 public pausedTime;
     
    uint256 public investorCount;
     
    address public wallet;
      
    uint256 public totalTokensSold;

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

 
contract STO is ISTO, STOStorage, Module, Pausable  {
    using SafeMath for uint256;

    enum FundRaiseType { ETH, POLY, SC }

     
    event SetFundRaiseTypes(FundRaiseType[] _fundRaiseTypes);

     
    function getRaised(FundRaiseType _fundRaiseType) public view returns (uint256) {
        return fundsRaised[uint8(_fundRaiseType)];
    }

     
    function pause() public onlyOwner {
         
        require(now < endTime, "STO has been finalized");
        super._pause();
    }

     
    function unpause() public onlyOwner {
        super._unpause();
    }

    function _setFundRaiseType(FundRaiseType[] _fundRaiseTypes) internal {
         
        require(_fundRaiseTypes.length > 0 && _fundRaiseTypes.length <= 3, "Raise type is not specified");
        fundRaiseTypes[uint8(FundRaiseType.ETH)] = false;
        fundRaiseTypes[uint8(FundRaiseType.POLY)] = false;
        fundRaiseTypes[uint8(FundRaiseType.SC)] = false;
        for (uint8 j = 0; j < _fundRaiseTypes.length; j++) {
            fundRaiseTypes[uint8(_fundRaiseTypes[j])] = true;
        }
        emit SetFundRaiseTypes(_fundRaiseTypes);
    }

     
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "Transfer failed");
    }

     
    function reclaimETH() external onlyOwner {
        msg.sender.transfer(address(this).balance);
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

 
contract CappedSTO is STO, ReentrancyGuard {
    using SafeMath for uint256;

     
    bool public allowBeneficialInvestments = false;
     
     
    uint256 public rate;
     
     
    uint256 public cap;

    mapping (address => uint256) public investors;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event SetAllowBeneficialInvestments(bool _allowed);

    constructor (address _securityToken, address _polyAddress) public
    Module(_securityToken, _polyAddress)
    {
    }

     
     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function configure(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _cap,
        uint256 _rate,
        FundRaiseType[] _fundRaiseTypes,
        address _fundsReceiver
    )
    public
    onlyFactory
    {
        require(endTime == 0, "Already configured");
        require(_rate > 0, "Rate of token should be greater than 0");
        require(_fundsReceiver != address(0), "Zero address is not permitted");
         
        require(_startTime >= now && _endTime > _startTime, "Date parameters are not valid");
        require(_cap > 0, "Cap should be greater than 0");
        require(_fundRaiseTypes.length == 1, "It only selects single fund raise type");
        startTime = _startTime;
        endTime = _endTime;
        cap = _cap;
        rate = _rate;
        wallet = _fundsReceiver;
        _setFundRaiseType(_fundRaiseTypes);
    }

     
    function getInitFunction() public pure returns (bytes4) {
        return bytes4(keccak256("configure(uint256,uint256,uint256,uint256,uint8[],address)"));
    }

     
    function changeAllowBeneficialInvestments(bool _allowBeneficialInvestments) public onlyOwner {
        require(_allowBeneficialInvestments != allowBeneficialInvestments, "Does not change value");
        allowBeneficialInvestments = _allowBeneficialInvestments;
        emit SetAllowBeneficialInvestments(allowBeneficialInvestments);
    }

     
    function buyTokens(address _beneficiary) public payable nonReentrant {
        if (!allowBeneficialInvestments) {
            require(_beneficiary == msg.sender, "Beneficiary address does not match msg.sender");
        }

        require(!paused, "Should not be paused");
        require(fundRaiseTypes[uint8(FundRaiseType.ETH)], "Mode of investment is not ETH");

        uint256 weiAmount = msg.value;
        uint256 refund = _processTx(_beneficiary, weiAmount);
        weiAmount = weiAmount.sub(refund);

        _forwardFunds(refund);
    }

     
    function buyTokensWithPoly(uint256 _investedPOLY) public nonReentrant{
        require(!paused, "Should not be paused");
        require(fundRaiseTypes[uint8(FundRaiseType.POLY)], "Mode of investment is not POLY");
        uint256 refund = _processTx(msg.sender, _investedPOLY);
        _forwardPoly(msg.sender, wallet, _investedPOLY.sub(refund));
    }

     
    function capReached() public view returns (bool) {
        return totalTokensSold >= cap;
    }

     
    function getTokensSold() public view returns (uint256) {
        return totalTokensSold;
    }

     
    function getPermissions() public view returns(bytes32[]) {
        bytes32[] memory allPermissions = new bytes32[](0);
        return allPermissions;
    }

     
    function getSTODetails() public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (
            startTime,
            endTime,
            cap,
            rate,
            (fundRaiseTypes[uint8(FundRaiseType.POLY)]) ? fundsRaised[uint8(FundRaiseType.POLY)]: fundsRaised[uint8(FundRaiseType.ETH)],
            investorCount,
            totalTokensSold,
            (fundRaiseTypes[uint8(FundRaiseType.POLY)])
        );
    }

     
     
     
     
    function _processTx(address _beneficiary, uint256 _investedAmount) internal returns(uint256 refund) {

        _preValidatePurchase(_beneficiary, _investedAmount);
         
        uint256 tokens;
        (tokens, refund) = _getTokenAmount(_investedAmount);
        _investedAmount = _investedAmount.sub(refund);

         
        if (fundRaiseTypes[uint8(FundRaiseType.POLY)]) {
            fundsRaised[uint8(FundRaiseType.POLY)] = fundsRaised[uint8(FundRaiseType.POLY)].add(_investedAmount);
        } else {
            fundsRaised[uint8(FundRaiseType.ETH)] = fundsRaised[uint8(FundRaiseType.ETH)].add(_investedAmount);
        }
        totalTokensSold = totalTokensSold.add(tokens);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, _investedAmount, tokens);
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _investedAmount) internal view {
        require(_beneficiary != address(0), "Beneficiary address should not be 0x");
        require(_investedAmount != 0, "Amount invested should not be equal to 0");
         
        require(now >= startTime && now <= endTime, "Offering is closed/Not yet started");
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        require(ISecurityToken(securityToken).mint(_beneficiary, _tokenAmount), "Error in minting the tokens");
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        if (investors[_beneficiary] == 0) {
            investorCount = investorCount + 1;
        }
        investors[_beneficiary] = investors[_beneficiary].add(_tokenAmount);

        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _getTokenAmount(uint256 _investedAmount) internal view returns (uint256 tokens, uint256 refund) {
        tokens = _investedAmount.mul(rate);
        tokens = tokens.div(uint256(10) ** 18);
        if (totalTokensSold.add(tokens) > cap) {
            tokens = cap.sub(totalTokensSold);
        }
        uint256 granularity = ISecurityToken(securityToken).granularity();
        tokens = tokens.div(granularity);
        tokens = tokens.mul(granularity);
        require(tokens > 0, "Cap reached");
        refund = _investedAmount.sub((tokens.mul(uint256(10) ** 18)).div(rate));
    }

     
    function _forwardFunds(uint256 _refund) internal {
        wallet.transfer(msg.value.sub(_refund));
        msg.sender.transfer(_refund);
    }

     
    function _forwardPoly(address _beneficiary, address _to, uint256 _fundsAmount) internal {
        polyToken.transferFrom(_beneficiary, _to, _fundsAmount);
    }

}