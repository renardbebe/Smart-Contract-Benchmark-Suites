 

pragma solidity ^0.4.23;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

contract Registry {
    struct AttributeData {
        uint256 value;
        bytes32 notes;
        address adminAddr;
        uint256 timestamp;
    }
    
    address public owner;
    address public pendingOwner;
    bool public initialized;

     
     
     
     
     
     
    mapping(address => mapping(bytes32 => AttributeData)) public attributes;
     
     

    bytes32 public constant WRITE_PERMISSION = keccak256("canWriteTo-");
    bytes32 public constant IS_BLACKLISTED = "isBlacklisted";
    bytes32 public constant IS_DEPOSIT_ADDRESS = "isDepositAddress"; 
    bytes32 public constant IS_REGISTERED_CONTRACT = "isRegisteredContract"; 
    bytes32 public constant HAS_PASSED_KYC_AML = "hasPassedKYC/AML";
    bytes32 public constant CAN_BURN = "canBurn";

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SetAttribute(address indexed who, bytes32 attribute, uint256 value, bytes32 notes, address indexed adminAddr);
    event SetManager(address indexed oldManager, address indexed newManager);


    function initialize() public {
        require(!initialized, "already initialized");
        owner = msg.sender;
        initialized = true;
    }

    function writeAttributeFor(bytes32 _attribute) public pure returns (bytes32) {
        return keccak256(WRITE_PERMISSION ^ _attribute);
    }

     
     
     
    function confirmWrite(bytes32 _attribute, address _admin) public view returns (bool) {
        return (_admin == owner || hasAttribute(_admin, keccak256(WRITE_PERMISSION ^ _attribute)));
    }

     
    function setAttribute(address _who, bytes32 _attribute, uint256 _value, bytes32 _notes) public {
        require(confirmWrite(_attribute, msg.sender));
        attributes[_who][_attribute] = AttributeData(_value, _notes, msg.sender, block.timestamp);
        emit SetAttribute(_who, _attribute, _value, _notes, msg.sender);
    }

    function setAttributeValue(address _who, bytes32 _attribute, uint256 _value) public {
        require(confirmWrite(_attribute, msg.sender));
        attributes[_who][_attribute] = AttributeData(_value, "", msg.sender, block.timestamp);
        emit SetAttribute(_who, _attribute, _value, "", msg.sender);
    }

     
    function hasAttribute(address _who, bytes32 _attribute) public view returns (bool) {
        return attributes[_who][_attribute].value != 0;
    }

    function hasBothAttributes(address _who, bytes32 _attribute1, bytes32 _attribute2) public view returns (bool) {
        return attributes[_who][_attribute1].value != 0 && attributes[_who][_attribute2].value != 0;
    }

    function hasEitherAttribute(address _who, bytes32 _attribute1, bytes32 _attribute2) public view returns (bool) {
        return attributes[_who][_attribute1].value != 0 || attributes[_who][_attribute2].value != 0;
    }

    function hasAttribute1ButNotAttribute2(address _who, bytes32 _attribute1, bytes32 _attribute2) public view returns (bool) {
        return attributes[_who][_attribute1].value != 0 && attributes[_who][_attribute2].value == 0;
    }

    function bothHaveAttribute(address _who1, address _who2, bytes32 _attribute) public view returns (bool) {
        return attributes[_who1][_attribute].value != 0 && attributes[_who2][_attribute].value != 0;
    }
    
    function eitherHaveAttribute(address _who1, address _who2, bytes32 _attribute) public view returns (bool) {
        return attributes[_who1][_attribute].value != 0 || attributes[_who2][_attribute].value != 0;
    }

    function haveAttributes(address _who1, bytes32 _attribute1, address _who2, bytes32 _attribute2) public view returns (bool) {
        return attributes[_who1][_attribute1].value != 0 && attributes[_who2][_attribute2].value != 0;
    }

    function haveEitherAttribute(address _who1, bytes32 _attribute1, address _who2, bytes32 _attribute2) public view returns (bool) {
        return attributes[_who1][_attribute1].value != 0 || attributes[_who2][_attribute2].value != 0;
    }

    function isDepositAddress(address _who) public view returns (bool) {
        return attributes[address(uint256(_who) >> 20)][IS_DEPOSIT_ADDRESS].value != 0;
    }

    function getDepositAddress(address _who) public view returns (address) {
        return address(attributes[address(uint256(_who) >> 20)][IS_DEPOSIT_ADDRESS].value);
    }

    function requireCanTransfer(address _from, address _to) public view returns (address, bool) {
        require (attributes[_from][IS_BLACKLISTED].value == 0, "blacklisted");
        uint256 depositAddressValue = attributes[address(uint256(_to) >> 20)][IS_DEPOSIT_ADDRESS].value;
        if (depositAddressValue != 0) {
            _to = address(depositAddressValue);
        }
        require (attributes[_to][IS_BLACKLISTED].value == 0, "blacklisted");
        return (_to, attributes[_to][IS_REGISTERED_CONTRACT].value != 0);
    }

    function requireCanTransferFrom(address _sender, address _from, address _to) public view returns (address, bool) {
        require (attributes[_sender][IS_BLACKLISTED].value == 0, "blacklisted");
        return requireCanTransfer(_from, _to);
    }

    function requireCanMint(address _to) public view returns (address, bool) {
        require (attributes[_to][HAS_PASSED_KYC_AML].value != 0);
        require (attributes[_to][IS_BLACKLISTED].value == 0, "blacklisted");
        uint256 depositAddressValue = attributes[address(uint256(_to) >> 20)][IS_DEPOSIT_ADDRESS].value;
        if (depositAddressValue != 0) {
            _to = address(depositAddressValue);
        }
        return (_to, attributes[_to][IS_REGISTERED_CONTRACT].value != 0);
    }

    function requireCanBurn(address _from) public view {
        require (attributes[_from][CAN_BURN].value != 0);
        require (attributes[_from][IS_BLACKLISTED].value == 0);
    }

     
    function getAttribute(address _who, bytes32 _attribute) public view returns (uint256, bytes32, address, uint256) {
        AttributeData memory data = attributes[_who][_attribute];
        return (data.value, data.notes, data.adminAddr, data.timestamp);
    }

    function getAttributeValue(address _who, bytes32 _attribute) public view returns (uint256) {
        return attributes[_who][_attribute].value;
    }

    function getAttributeAdminAddr(address _who, bytes32 _attribute) public view returns (address) {
        return attributes[_who][_attribute].adminAddr;
    }

    function getAttributeTimestamp(address _who, bytes32 _attribute) public view returns (uint256) {
        return attributes[_who][_attribute].timestamp;
    }

    function reclaimEther(address _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    function reclaimToken(ERC20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.transfer(_to, balance);
    }

     
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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

 

 
contract BalanceSheet is Claimable {
    using SafeMath for uint256;

    mapping (address => uint256) public balanceOf;

    function addBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].add(_value);
    }

    function subBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].sub(_value);
    }

    function setBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = _value;
    }
}

 

 
contract AllowanceSheet is Claimable {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) public allowanceOf;

    function addAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].add(_value);
    }

    function subAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].sub(_value);
    }

    function setAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = _value;
    }
}

 

 
contract ProxyStorage {
    address public owner;
    address public pendingOwner;

    bool public initialized;
    
    BalanceSheet public balances;
    AllowanceSheet public allowances;

    uint256 totalSupply_;
    
    bool private paused_Deprecated = false;
    address private globalPause_Deprecated;

    uint256 public burnMin = 0;
    uint256 public burnMax = 0;

    Registry public registry;

    string public name = "UniversalUSD";
    string public symbol = "UUSD";

    uint[] public gasRefundPool;
    uint256 private redemptionAddressCount_Deprecated;
    uint256 public minimumGasPriceForFutureRefunds;
}

 

 
contract HasOwner is ProxyStorage {

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 

 
 
 
contract ModularBasicToken is HasOwner {
    using SafeMath for uint256;

    event BalanceSheetSet(address indexed sheet);
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function setBalanceSheet(address _sheet) public onlyOwner returns (bool) {
        balances = BalanceSheet(_sheet);
        balances.claimOwnership();
        emit BalanceSheetSet(_sheet);
        return true;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transferAllArgs(msg.sender, _to, _value);
        return true;
    }


    function _transferAllArgs(address _from, address _to, uint256 _value) internal {
         
        balances.subBalance(_from, _value);
        balances.addBalance(_to, _value);
        emit Transfer(_from, _to, _value);
    }
    

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances.balanceOf(_owner);
    }
}

 

 
contract ModularStandardToken is ModularBasicToken {
    
    event AllowanceSheetSet(address indexed sheet);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
     
    function setAllowanceSheet(address _sheet) public onlyOwner returns(bool) {
        allowances = AllowanceSheet(_sheet);
        allowances.claimOwnership();
        emit AllowanceSheetSet(_sheet);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _transferFromAllArgs(_from, _to, _value, msg.sender);
        return true;
    }

    function _transferFromAllArgs(address _from, address _to, uint256 _value, address _spender) internal {
        _transferAllArgs(_from, _to, _value);
        allowances.subAllowance(_from, _spender, _value);
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        _approveAllArgs(_spender, _value, msg.sender);
        return true;
    }

    function _approveAllArgs(address _spender, uint256 _value, address _tokenHolder) internal {
        allowances.setAllowance(_tokenHolder, _spender, _value);
        emit Approval(_tokenHolder, _spender, _value);
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances.allowanceOf(_owner, _spender);
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        _increaseApprovalAllArgs(_spender, _addedValue, msg.sender);
        return true;
    }

    function _increaseApprovalAllArgs(address _spender, uint256 _addedValue, address _tokenHolder) internal {
        allowances.addAllowance(_tokenHolder, _spender, _addedValue);
        emit Approval(_tokenHolder, _spender, allowances.allowanceOf(_tokenHolder, _spender));
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        _decreaseApprovalAllArgs(_spender, _subtractedValue, msg.sender);
        return true;
    }

    function _decreaseApprovalAllArgs(address _spender, uint256 _subtractedValue, address _tokenHolder) internal {
        uint256 oldValue = allowances.allowanceOf(_tokenHolder, _spender);
        if (_subtractedValue > oldValue) {
            allowances.setAllowance(_tokenHolder, _spender, 0);
        } else {
            allowances.subAllowance(_tokenHolder, _spender, _subtractedValue);
        }
        emit Approval(_tokenHolder,_spender, allowances.allowanceOf(_tokenHolder, _spender));
    }
}

 

 
contract ModularBurnableToken is ModularStandardToken {
    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        _burnAllArgs(msg.sender, _value);
    }

    function _burnAllArgs(address _burner, uint256 _value) internal {
         
         
         
        balances.subBalance(_burner, _value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_burner, _value);
        emit Transfer(_burner, address(0), _value);
    }
}

 

 
contract ModularMintableToken is ModularBurnableToken {
    event Mint(address indexed to, uint256 value);

     
    function mint(address _to, uint256 _value) public onlyOwner {
        require(_to != address(0), "to address cannot be zero");
        totalSupply_ = totalSupply_.add(_value);
        balances.addBalance(_to, _value);
        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
    }
}

 

 
contract BurnableTokenWithBounds is ModularMintableToken {

    event SetBurnBounds(uint256 newMin, uint256 newMax);

    function _burnAllArgs(address _burner, uint256 _value) internal {
        require(_value >= burnMin, "below min burn bound");
        require(_value <= burnMax, "exceeds max burn bound");
        super._burnAllArgs(_burner, _value);
    }

     
     
     
     
     
     
    function setBurnBounds(uint256 _min, uint256 _max) public onlyOwner {
        require(_min <= _max, "min > max");
        burnMin = _min;
        burnMax = _max;
        emit SetBurnBounds(_min, _max);
    }
}

 

contract CompliantToken is ModularMintableToken {
     
     
     
    bytes32 public constant HAS_PASSED_KYC_AML = "hasPassedKYC/AML";
     
     
    bytes32 public constant CAN_BURN = "canBurn";
     
     
     
    bytes32 public constant IS_BLACKLISTED = "isBlacklisted";

    event WipeBlacklistedAccount(address indexed account, uint256 balance);
    event SetRegistry(address indexed registry);
    
     
    function setRegistry(Registry _registry) public onlyOwner {
        registry = _registry;
        emit SetRegistry(registry);
    }

    function _burnAllArgs(address _burner, uint256 _value) internal {
        registry.requireCanBurn(_burner);
        super._burnAllArgs(_burner, _value);
    }

     
    function wipeBlacklistedAccount(address _account) public onlyOwner {
        require(registry.hasAttribute(_account, IS_BLACKLISTED), "_account is not blacklisted");
        uint256 oldValue = balanceOf(_account);
        balances.setBalance(_account, 0);
        totalSupply_ = totalSupply_.sub(oldValue);
        emit WipeBlacklistedAccount(_account, oldValue);
        emit Transfer(_account, address(0), oldValue);
    }
}

 

 
contract DepositToken is ModularMintableToken {
    
    bytes32 public constant IS_DEPOSIT_ADDRESS = "isDepositAddress"; 

}

 

contract TrueCoinReceiver {
    function tokenFallback( address from, uint256 value ) external;
}

 

 
contract TokenWithHook is ModularMintableToken {
    
    bytes32 public constant IS_REGISTERED_CONTRACT = "isRegisteredContract"; 

}

 

contract CompliantDepositTokenWithHook is CompliantToken, DepositToken, TokenWithHook {

    function _transferFromAllArgs(address _from, address _to, uint256 _value, address _sender) internal {
        bool hasHook;
        address originalTo = _to;
        (_to, hasHook) = registry.requireCanTransferFrom(_sender, _from, _to);
        allowances.subAllowance(_from, _sender, _value);
        balances.subBalance(_from, _value);
        balances.addBalance(_to, _value);
        emit Transfer(_from, originalTo, _value);
        if (originalTo != _to) {
            emit Transfer(originalTo, _to, _value);
            if (hasHook) {
                TrueCoinReceiver(_to).tokenFallback(originalTo, _value);
            }
        } else {
            if (hasHook) {
                TrueCoinReceiver(_to).tokenFallback(_from, _value);
            }
        }
    }

    function _transferAllArgs(address _from, address _to, uint256 _value) internal {
        bool hasHook;
        address originalTo = _to;
        (_to, hasHook) = registry.requireCanTransfer(_from, _to);
        balances.subBalance(_from, _value);
        balances.addBalance(_to, _value);
        emit Transfer(_from, originalTo, _value);
        if (originalTo != _to) {
            emit Transfer(originalTo, _to, _value);
            if (hasHook) {
                TrueCoinReceiver(_to).tokenFallback(originalTo, _value);
            }
        } else {
            if (hasHook) {
                TrueCoinReceiver(_to).tokenFallback(_from, _value);
            }
        }
    }

    function mint(address _to, uint256 _value) public onlyOwner {
        require(_to != address(0), "to address cannot be zero");
        bool hasHook;
        address originalTo = _to;
        (_to, hasHook) = registry.requireCanMint(_to);
        totalSupply_ = totalSupply_.add(_value);
        emit Mint(originalTo, _value);
        emit Transfer(address(0), originalTo, _value);
        if (_to != originalTo) {
            emit Transfer(originalTo, _to, _value);
        }
        balances.addBalance(_to, _value);
        if (hasHook) {
            if (_to != originalTo) {
                TrueCoinReceiver(_to).tokenFallback(originalTo, _value);
            } else {
                TrueCoinReceiver(_to).tokenFallback(address(0), _value);
            }
        }
    }
}

 

 
contract RedeemableToken is ModularMintableToken {

    event RedemptionAddress(address indexed addr);

    uint256 public constant REDEMPTION_ADDRESS_COUNT = 0x100000;

    function _transferAllArgs(address _from, address _to, uint256 _value) internal {
        if (_to == address(0)) {
            revert("_to address is 0x0");
        } else if (uint(_to) < REDEMPTION_ADDRESS_COUNT) {
             
            super._transferAllArgs(_from, _to, _value);
            _burnAllArgs(_to, _value);
        } else {
            super._transferAllArgs(_from, _to, _value);
        }
    }

    function _transferFromAllArgs(address _from, address _to, uint256 _value, address _sender) internal {
        if (_to == address(0)) {
            revert("_to address is 0x0");
        } else if (uint(_to) < REDEMPTION_ADDRESS_COUNT) {
             
            super._transferFromAllArgs(_from, _to, _value, _sender);
            _burnAllArgs(_to, _value);
        } else {
            super._transferFromAllArgs(_from, _to, _value, _sender);
        }
    }
}

 

 
contract GasRefundToken is ModularMintableToken {

    function sponsorGas() external {
        uint256 len = gasRefundPool.length;
        uint256 refundPrice = minimumGasPriceForFutureRefunds;
        require(refundPrice > 0);
        gasRefundPool.length = len + 9;
        gasRefundPool[len] = refundPrice;
        gasRefundPool[len + 1] = refundPrice;
        gasRefundPool[len + 2] = refundPrice;
        gasRefundPool[len + 3] = refundPrice;
        gasRefundPool[len + 4] = refundPrice;
        gasRefundPool[len + 5] = refundPrice;
        gasRefundPool[len + 6] = refundPrice;
        gasRefundPool[len + 7] = refundPrice;
        gasRefundPool[len + 8] = refundPrice;
    }

    function minimumGasPriceForRefund() public view returns (uint256) {
        uint256 len = gasRefundPool.length;
        if (len > 0) {
          return gasRefundPool[len - 1] + 1;
        }
        return uint256(-1);
    }

     
    modifier gasRefund {
        uint256 len = gasRefundPool.length;
        if (len > 2 && tx.gasprice > gasRefundPool[len-1]) {
            gasRefundPool.length = len - 3;
        }
        _;
    }

     
    function remainingGasRefundPool() public view returns (uint) {
        return gasRefundPool.length;
    }

    function remainingSponsoredTransactions() public view returns (uint) {
        return gasRefundPool.length / 3;
    }

    function _transferAllArgs(address _from, address _to, uint256 _value) internal gasRefund {
        super._transferAllArgs(_from, _to, _value);
    }

    function _transferFromAllArgs(address _from, address _to, uint256 _value, address _sender) internal gasRefund {
        super._transferFromAllArgs(_from, _to, _value, _sender);
    }

    function mint(address _to, uint256 _value) public onlyOwner gasRefund {
        super.mint(_to, _value);
    }

    bytes32 public constant CAN_SET_FUTURE_REFUND_MIN_GAS_PRICE = "canSetFutureRefundMinGasPrice";

    function setMinimumGasPriceForFutureRefunds(uint256 _minimumGasPriceForFutureRefunds) public {
        require(registry.hasAttribute(msg.sender, CAN_SET_FUTURE_REFUND_MIN_GAS_PRICE));
        minimumGasPriceForFutureRefunds = _minimumGasPriceForFutureRefunds;
    }
}

 

 
contract DelegateERC20 is ModularStandardToken {

    address public constant DELEGATE_FROM = 0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;
    
    modifier onlyDelegateFrom() {
        require(msg.sender == DELEGATE_FROM);
        _;
    }

    function delegateTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    function delegateBalanceOf(address who) public view returns (uint256) {
        return balanceOf(who);
    }

    function delegateTransfer(address to, uint256 value, address origSender) public onlyDelegateFrom returns (bool) {
        _transferAllArgs(origSender, to, value);
        return true;
    }

    function delegateAllowance(address owner, address spender) public view returns (uint256) {
        return allowance(owner, spender);
    }

    function delegateTransferFrom(address from, address to, uint256 value, address origSender) public onlyDelegateFrom returns (bool) {
        _transferFromAllArgs(from, to, value, origSender);
        return true;
    }

    function delegateApprove(address spender, uint256 value, address origSender) public onlyDelegateFrom returns (bool) {
        _approveAllArgs(spender, value, origSender);
        return true;
    }

    function delegateIncreaseApproval(address spender, uint addedValue, address origSender) public onlyDelegateFrom returns (bool) {
        _increaseApprovalAllArgs(spender, addedValue, origSender);
        return true;
    }

    function delegateDecreaseApproval(address spender, uint subtractedValue, address origSender) public onlyDelegateFrom returns (bool) {
        _decreaseApprovalAllArgs(spender, subtractedValue, origSender);
        return true;
    }
}

 

 
contract UniversalUSD is 
ModularMintableToken, 
CompliantDepositTokenWithHook,
BurnableTokenWithBounds, 
RedeemableToken,
DelegateERC20,
GasRefundToken {
    using SafeMath for *;

    uint8 public constant DECIMALS = 18;
    uint8 public constant ROUNDING = 2;

    event ChangeTokenName(string newName, string newSymbol);

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function rounding() public pure returns (uint8) {
        return ROUNDING;
    }

    function changeTokenName(string _name, string _symbol) external onlyOwner {
        name = _name;
        symbol = _symbol;
        emit ChangeTokenName(_name, _symbol);
    }

     
    function reclaimEther(address _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

     
    function reclaimToken(ERC20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.transfer(_to, balance);
    }

    function paused() public pure returns (bool) {
        return false;
    }

     
    function reclaimContract(Ownable _ownable) external onlyOwner {
        _ownable.transferOwnership(owner);
    }

    function _burnAllArgs(address _burner, uint256 _value) internal {
         
        uint burnAmount = _value.div(10 ** uint256(DECIMALS - ROUNDING)).mul(10 ** uint256(DECIMALS - ROUNDING));
        super._burnAllArgs(_burner, burnAmount);
    }
}