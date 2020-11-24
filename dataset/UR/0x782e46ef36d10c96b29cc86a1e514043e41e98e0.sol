 

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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

library CheckedERC20 {
    using SafeMath for uint;

    function isContract(address addr) internal view returns(bool result) {
         
        assembly {
            result := gt(extcodesize(addr), 0)
        }
    }

    function handleReturnBool() internal pure returns(bool result) {
         
        assembly {
            switch returndatasize()
            case 0 {  
                result := 1
            }
            case 32 {  
                returndatacopy(0, 0, 32)
                result := mload(0)
            }
            default {  
                revert(0, 0)
            }
        }
    }

    function handleReturnBytes32() internal pure returns(bytes32 result) {
         
        assembly {
            switch eq(returndatasize(), 32)  
            case 1 {
                returndatacopy(0, 0, 32)
                result := mload(0)
            }

            switch gt(returndatasize(), 32)  
            case 1 {
                returndatacopy(0, 64, 32)
                result := mload(0)
            }

            switch lt(returndatasize(), 32)  
            case 1 {
                revert(0, 0)
            }
        }
    }

    function asmTransfer(address token, address to, uint256 value) internal returns(bool) {
        require(isContract(token));
         
        require(token.call(bytes4(keccak256("transfer(address,uint256)")), to, value));
        return handleReturnBool();
    }

    function asmTransferFrom(address token, address from, address to, uint256 value) internal returns(bool) {
        require(isContract(token));
         
        require(token.call(bytes4(keccak256("transferFrom(address,address,uint256)")), from, to, value));
        return handleReturnBool();
    }

    function asmApprove(address token, address spender, uint256 value) internal returns(bool) {
        require(isContract(token));
         
        require(token.call(bytes4(keccak256("approve(address,uint256)")), spender, value));
        return handleReturnBool();
    }

     

    function checkedTransfer(ERC20 token, address to, uint256 value) internal {
        if (value > 0) {
            uint256 balance = token.balanceOf(this);
            asmTransfer(token, to, value);
            require(token.balanceOf(this) == balance.sub(value), "checkedTransfer: Final balance didn't match");
        }
    }

    function checkedTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        if (value > 0) {
            uint256 toBalance = token.balanceOf(to);
            asmTransferFrom(token, from, to, value);
            require(token.balanceOf(to) == toBalance.add(value), "checkedTransfer: Final balance didn't match");
        }
    }

     

    function asmName(address token) internal view returns(bytes32) {
        require(isContract(token));
         
        require(token.call(bytes4(keccak256("name()"))));
        return handleReturnBytes32();
    }

    function asmSymbol(address token) internal view returns(bytes32) {
        require(isContract(token));
         
        require(token.call(bytes4(keccak256("symbol()"))));
        return handleReturnBytes32();
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

 

 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 

 
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

 

contract ERC1003Caller is Ownable {
    function makeCall(address target, bytes data) external payable onlyOwner returns (bool) {
         
        return target.call.value(msg.value)(data);
    }
}


contract ERC1003Token is ERC20 {
    ERC1003Caller private _caller = new ERC1003Caller();
    address[] internal _sendersStack;

    function caller() public view returns(ERC1003Caller) {
        return _caller;
    }

    function approveAndCall(address to, uint256 value, bytes data) public payable returns (bool) {
        _sendersStack.push(msg.sender);
        approve(to, value);
        require(_caller.makeCall.value(msg.value)(to, data));
        _sendersStack.length -= 1;
        return true;
    }

    function transferAndCall(address to, uint256 value, bytes data) public payable returns (bool) {
        transfer(to, value);
        require(_caller.makeCall.value(msg.value)(to, data));
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        address spender = (from != address(_caller)) ? from : _sendersStack[_sendersStack.length - 1];
        return super.transferFrom(spender, to, value);
    }
}

 

contract IBasicMultiToken is ERC20 {
    event Bundle(address indexed who, address indexed beneficiary, uint256 value);
    event Unbundle(address indexed who, address indexed beneficiary, uint256 value);

    function tokensCount() public view returns(uint256);
    function tokens(uint i) public view returns(ERC20);
    function bundlingEnabled() public view returns(bool);
    
    function bundleFirstTokens(address _beneficiary, uint256 _amount, uint256[] _tokenAmounts) public;
    function bundle(address _beneficiary, uint256 _amount) public;

    function unbundle(address _beneficiary, uint256 _value) public;
    function unbundleSome(address _beneficiary, uint256 _value, ERC20[] _tokens) public;

     
    function disableBundling() public;
    function enableBundling() public;

    bytes4 public constant InterfaceId_IBasicMultiToken = 0xd5c368b6;
       
}

 

contract BasicMultiToken is Ownable, StandardToken, DetailedERC20, ERC1003Token, IBasicMultiToken, SupportsInterfaceWithLookup {
    using CheckedERC20 for ERC20;
    using CheckedERC20 for DetailedERC20;

    ERC20[] private _tokens;
    uint private _inLendingMode;
    bool private _bundlingEnabled = true;

    event Bundle(address indexed who, address indexed beneficiary, uint256 value);
    event Unbundle(address indexed who, address indexed beneficiary, uint256 value);
    event BundlingStatus(bool enabled);

    modifier notInLendingMode {
        require(_inLendingMode == 0, "Operation can't be performed while lending");
        _;
    }

    modifier whenBundlingEnabled {
        require(_bundlingEnabled, "Bundling is disabled");
        _;
    }

    constructor()
        public DetailedERC20("", "", 0)
    {
    }

    function init(ERC20[] tokens, string theName, string theSymbol, uint8 theDecimals) public {
        require(decimals == 0, "constructor: decimals should be zero");
        require(theDecimals > 0, "constructor: _decimals should not be zero");
        require(bytes(theName).length > 0, "constructor: name should not be empty");
        require(bytes(theSymbol).length > 0, "constructor: symbol should not be empty");
        require(tokens.length >= 2, "Contract does not support less than 2 inner tokens");

        name = theName;
        symbol = theSymbol;
        decimals = theDecimals;
        _tokens = tokens;

        _registerInterface(InterfaceId_IBasicMultiToken);
    }

    function tokensCount() public view returns(uint) {
        return _tokens.length;
    }

    function tokens(uint i) public view returns(ERC20) {
        return _tokens[i];
    }

    function inLendingMode() public view returns(uint) {
        return _inLendingMode;
    }

    function bundlingEnabled() public view returns(bool) {
        return _bundlingEnabled;
    }

    function bundleFirstTokens(address beneficiary, uint256 amount, uint256[] tokenAmounts) public whenBundlingEnabled notInLendingMode {
        require(totalSupply_ == 0, "bundleFirstTokens: This method can be used with zero total supply only");
        _bundle(beneficiary, amount, tokenAmounts);
    }

    function bundle(address beneficiary, uint256 amount) public whenBundlingEnabled notInLendingMode {
        require(totalSupply_ != 0, "This method can be used with non zero total supply only");
        uint256[] memory tokenAmounts = new uint256[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            tokenAmounts[i] = _tokens[i].balanceOf(this).mul(amount).div(totalSupply_);
        }
        _bundle(beneficiary, amount, tokenAmounts);
    }

    function unbundle(address beneficiary, uint256 value) public notInLendingMode {
        unbundleSome(beneficiary, value, _tokens);
    }

    function unbundleSome(address beneficiary, uint256 value, ERC20[] someTokens) public notInLendingMode {
        _unbundle(beneficiary, value, someTokens);
    }

     

    function disableBundling() public onlyOwner {
        require(_bundlingEnabled, "Bundling is already disabled");
        _bundlingEnabled = false;
        emit BundlingStatus(false);
    }

    function enableBundling() public onlyOwner {
        require(!_bundlingEnabled, "Bundling is already enabled");
        _bundlingEnabled = true;
        emit BundlingStatus(true);
    }

     

    function _bundle(address beneficiary, uint256 amount, uint256[] tokenAmounts) internal {
        require(amount != 0, "Bundling amount should be non-zero");
        require(_tokens.length == tokenAmounts.length, "Lenghts of _tokens and tokenAmounts array should be equal");

        for (uint i = 0; i < _tokens.length; i++) {
            require(tokenAmounts[i] != 0, "Token amount should be non-zero");
            _tokens[i].checkedTransferFrom(msg.sender, this, tokenAmounts[i]);
        }

        totalSupply_ = totalSupply_.add(amount);
        balances[beneficiary] = balances[beneficiary].add(amount);
        emit Bundle(msg.sender, beneficiary, amount);
        emit Transfer(0, beneficiary, amount);
    }

    function _unbundle(address beneficiary, uint256 value, ERC20[] someTokens) internal {
        require(someTokens.length > 0, "Array of someTokens can't be empty");

        uint256 totalSupply = totalSupply_;
        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply_ = totalSupply.sub(value);
        emit Unbundle(msg.sender, beneficiary, value);
        emit Transfer(msg.sender, 0, value);

        for (uint i = 0; i < someTokens.length; i++) {
            for (uint j = 0; j < i; j++) {
                require(someTokens[i] != someTokens[j], "unbundleSome: should not unbundle same token multiple times");
            }
            uint256 tokenAmount = someTokens[i].balanceOf(this).mul(value).div(totalSupply);
            someTokens[i].checkedTransfer(beneficiary, tokenAmount);
        }
    }

     

    function lend(address to, ERC20 token, uint256 amount, address target, bytes data) public payable {
        uint256 prevBalance = token.balanceOf(this);
        token.asmTransfer(to, amount);
        _inLendingMode += 1;
        require(caller().makeCall.value(msg.value)(target, data), "lend: arbitrary call failed");
        _inLendingMode -= 1;
        require(token.balanceOf(this) >= prevBalance, "lend: lended token must be refilled");
    }
}

 

contract FeeBasicMultiToken is Ownable, BasicMultiToken {
    using CheckedERC20 for ERC20;

    uint256 constant public TOTAL_PERCRENTS = 1000000;
    uint256 internal _lendFee;

    function lendFee() public view returns(uint256) {
        return _lendFee;
    }

    function setLendFee(uint256 theLendFee) public onlyOwner {
        require(theLendFee <= 30000, "setLendFee: fee should be not greater than 3%");
        _lendFee = theLendFee;
    }

    function lend(address to, ERC20 token, uint256 amount, address target, bytes data) public payable {
        uint256 expectedBalance = token.balanceOf(this).mul(TOTAL_PERCRENTS.add(_lendFee)).div(TOTAL_PERCRENTS);
        super.lend(to, token, amount, target, data);
        require(token.balanceOf(this) >= expectedBalance, "lend: tokens must be returned with lend fee");
    }
}

 

contract IMultiToken is IBasicMultiToken {
    event Update();
    event Change(address indexed _fromToken, address indexed _toToken, address indexed _changer, uint256 _amount, uint256 _return);

    function weights(address _token) public view returns(uint256);
    function changesEnabled() public view returns(bool);
    
    function getReturn(address _fromToken, address _toToken, uint256 _amount) public view returns (uint256 returnAmount);
    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256 returnAmount);

     
    function disableChanges() public;

    bytes4 public constant InterfaceId_IMultiToken = 0x81624e24;
       
}

 

contract MultiToken is IMultiToken, BasicMultiToken {
    using CheckedERC20 for ERC20;

    mapping(address => uint256) private _weights;
    uint256 internal _minimalWeight;
    bool private _changesEnabled = true;

    event ChangesDisabled();

    modifier whenChangesEnabled {
        require(_changesEnabled, "Operation can't be performed because changes are disabled");
        _;
    }

    function weights(address _token) public view returns(uint256) {
        return _weights[_token];
    }

    function changesEnabled() public view returns(bool) {
        return _changesEnabled;
    }

    function init(ERC20[] tokens, uint256[] tokenWeights, string theName, string theSymbol, uint8 theDecimals) public {
        super.init(tokens, theName, theSymbol, theDecimals);
        require(tokenWeights.length == tokens.length, "Lenghts of tokens and tokenWeights array should be equal");

        uint256 minimalWeight = 0;
        for (uint i = 0; i < tokens.length; i++) {
            require(tokenWeights[i] != 0, "The tokenWeights array should not contains zeros");
            require(_weights[tokens[i]] == 0, "The tokens array have duplicates");
            _weights[tokens[i]] = tokenWeights[i];
            if (minimalWeight == 0 || tokenWeights[i] < minimalWeight) {
                minimalWeight = tokenWeights[i];
            }
        }
        _minimalWeight = minimalWeight;

        _registerInterface(InterfaceId_IMultiToken);
    }

    function getReturn(address fromToken, address toToken, uint256 amount) public view returns(uint256 returnAmount) {
        if (_weights[fromToken] > 0 && _weights[toToken] > 0 && fromToken != toToken) {
            uint256 fromBalance = ERC20(fromToken).balanceOf(this);
            uint256 toBalance = ERC20(toToken).balanceOf(this);
            returnAmount = amount.mul(toBalance).mul(_weights[fromToken]).div(
                amount.mul(_weights[fromToken]).div(_minimalWeight).add(fromBalance).mul(_weights[toToken])
            );
        }
    }

    function change(address fromToken, address toToken, uint256 amount, uint256 minReturn) public whenChangesEnabled notInLendingMode returns(uint256 returnAmount) {
        returnAmount = getReturn(fromToken, toToken, amount);
        require(returnAmount > 0, "The return amount is zero");
        require(returnAmount >= minReturn, "The return amount is less than minReturn value");

        ERC20(fromToken).checkedTransferFrom(msg.sender, this, amount);
        ERC20(toToken).checkedTransfer(msg.sender, returnAmount);

        emit Change(fromToken, toToken, msg.sender, amount, returnAmount);
    }

     

    function disableChanges() public onlyOwner {
        require(_changesEnabled, "Changes are already disabled");
        _changesEnabled = false;
        emit ChangesDisabled();
    }

     

    function setWeight(address token, uint256 newWeight) internal {
        _weights[token] = newWeight;
    }
}

 

contract FeeMultiToken is MultiToken, FeeBasicMultiToken {
    using CheckedERC20 for ERC20;

    uint256 internal _changeFee;
    uint256 internal _referralFee;

    function changeFee() public view returns(uint256) {
        return _changeFee;
    }

    function referralFee() public view returns(uint256) {
        return _referralFee;
    }

    function setChangeFee(uint256 theChangeFee) public onlyOwner {
        require(theChangeFee <= 30000, "setChangeFee: fee should be not greater than 3%");
        _changeFee = theChangeFee;
    }

    function setReferralFee(uint256 theReferralFee) public onlyOwner {
        require(theReferralFee <= 500000, "setReferralFee: fee should be not greater than 50% of changeFee");
        _referralFee = theReferralFee;
    }

    function getReturn(address fromToken, address toToken, uint256 amount) public view returns(uint256 returnAmount) {
        returnAmount = super.getReturn(fromToken, toToken, amount).mul(TOTAL_PERCRENTS.sub(_changeFee)).div(TOTAL_PERCRENTS);
    }

    function change(address fromToken, address toToken, uint256 amount, uint256 minReturn) public returns(uint256 returnAmount) {
        returnAmount = changeWithRef(fromToken, toToken, amount, minReturn, 0);
    }

    function changeWithRef(address fromToken, address toToken, uint256 amount, uint256 minReturn, address ref) public returns(uint256 returnAmount) {
        returnAmount = super.change(fromToken, toToken, amount, minReturn);
        uint256 refferalAmount = returnAmount
            .mul(_changeFee).div(TOTAL_PERCRENTS.sub(_changeFee))
            .mul(_referralFee).div(TOTAL_PERCRENTS);

        ERC20(toToken).checkedTransfer(ref, refferalAmount);
    }
}

 

contract AstraMultiToken is FeeMultiToken {
    function init(ERC20[] tokens, uint256[] tokenWeights, string theName, string theSymbol, uint8  ) public {
        super.init(tokens, tokenWeights, theName, theSymbol, 18);
    }
}