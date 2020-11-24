 

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

 

contract IDeployer is Ownable {
    function deploy(bytes data) external returns(address mtkn);
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
            if eq(returndatasize(), 32) {  
                returndatacopy(0, 0, 32)
                result := mload(0)
            }
            if gt(returndatasize(), 32) {  
                returndatacopy(0, 64, 32)
                result := mload(0)
            }
            if lt(returndatasize(), 32) {  
                revert(0, 0)
            }
        }
    }

    function asmTransfer(address _token, address _to, uint256 _value) internal returns(bool) {
        require(isContract(_token));
         
        require(_token.call(bytes4(keccak256("transfer(address,uint256)")), _to, _value));
        return handleReturnBool();
    }

    function asmTransferFrom(address _token, address _from, address _to, uint256 _value) internal returns(bool) {
        require(isContract(_token));
         
        require(_token.call(bytes4(keccak256("transferFrom(address,address,uint256)")), _from, _to, _value));
        return handleReturnBool();
    }

    function asmApprove(address _token, address _spender, uint256 _value) internal returns(bool) {
        require(isContract(_token));
         
        require(_token.call(bytes4(keccak256("approve(address,uint256)")), _spender, _value));
        return handleReturnBool();
    }

     

    function checkedTransfer(ERC20 _token, address _to, uint256 _value) internal {
        if (_value > 0) {
            uint256 balance = _token.balanceOf(this);
            asmTransfer(_token, _to, _value);
            require(_token.balanceOf(this) == balance.sub(_value), "checkedTransfer: Final balance didn't match");
        }
    }

    function checkedTransferFrom(ERC20 _token, address _from, address _to, uint256 _value) internal {
        if (_value > 0) {
            uint256 toBalance = _token.balanceOf(_to);
            asmTransferFrom(_token, _from, _to, _value);
            require(_token.balanceOf(_to) == toBalance.add(_value), "checkedTransfer: Final balance didn't match");
        }
    }

     

    function asmName(address _token) internal view returns(bytes32) {
        require(isContract(_token));
         
        require(_token.call(bytes4(keccak256("name()"))));
        return handleReturnBytes32();
    }

    function asmSymbol(address _token) internal view returns(bytes32) {
        require(isContract(_token));
         
        require(_token.call(bytes4(keccak256("symbol()"))));
        return handleReturnBytes32();
    }
}

 

contract IBasicMultiToken is ERC20 {
    event Bundle(address indexed who, address indexed beneficiary, uint256 value);
    event Unbundle(address indexed who, address indexed beneficiary, uint256 value);

    ERC20[] public tokens;

    function tokensCount() public view returns(uint256);

    function bundleFirstTokens(address _beneficiary, uint256 _amount, uint256[] _tokenAmounts) public;
    function bundle(address _beneficiary, uint256 _amount) public;

    function unbundle(address _beneficiary, uint256 _value) public;
    function unbundleSome(address _beneficiary, uint256 _value, ERC20[] _tokens) public;

    function disableBundling() public;
    function enableBundling() public;
}

 

contract IMultiToken is IBasicMultiToken {
    event Update();
    event Change(address indexed _fromToken, address indexed _toToken, address indexed _changer, uint256 _amount, uint256 _return);

    mapping(address => uint256) public weights;

    function getReturn(address _fromToken, address _toToken, uint256 _amount) public view returns (uint256 returnAmount);
    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256 returnAmount);

    function disableChanges() public;
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

 

contract ERC1003Caller is Ownable {
    function makeCall(address _target, bytes _data) external payable onlyOwner returns (bool) {
         
        return _target.call.value(msg.value)(_data);
    }
}


contract ERC1003Token is ERC20 {
    ERC1003Caller public caller_ = new ERC1003Caller();
    address[] internal sendersStack_;

    function approveAndCall(address _to, uint256 _value, bytes _data) public payable returns (bool) {
        sendersStack_.push(msg.sender);
        approve(_to, _value);
        require(caller_.makeCall.value(msg.value)(_to, _data));
        sendersStack_.length -= 1;
        return true;
    }

    function transferAndCall(address _to, uint256 _value, bytes _data) public payable returns (bool) {
        transfer(_to, _value);
        require(caller_.makeCall.value(msg.value)(_to, _data));
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        address from = (_from != address(caller_)) ? _from : sendersStack_[sendersStack_.length - 1];
        return super.transferFrom(from, _to, _value);
    }
}

 

contract BasicMultiToken is Ownable, StandardToken, DetailedERC20, ERC1003Token, IBasicMultiToken {
    using CheckedERC20 for ERC20;
    using CheckedERC20 for DetailedERC20;

    uint internal inLendingMode;
    bool public bundlingEnabled = true;

    event Bundle(address indexed who, address indexed beneficiary, uint256 value);
    event Unbundle(address indexed who, address indexed beneficiary, uint256 value);
    event BundlingStatus(bool enabled);

    modifier notInLendingMode {
        require(inLendingMode == 0, "Operation can't be performed while lending");
        _;
    }

    modifier whenBundlingEnabled {
        require(bundlingEnabled, "Bundling is disabled");
        _;
    }

    constructor() public DetailedERC20("", "", 0) {
    }

    function init(ERC20[] _tokens, string _name, string _symbol, uint8 _decimals) public {
        require(decimals == 0, "init: contract was already initialized");
        require(_decimals > 0, "init: _decimals should not be zero");
        require(bytes(_name).length > 0, "init: _name should not be empty");
        require(bytes(_symbol).length > 0, "init: _symbol should not be empty");
        require(_tokens.length >= 2, "Contract do not support less than 2 inner tokens");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        tokens = _tokens;
    }

    function tokensCount() public view returns(uint) {
        return tokens.length;
    }

    function bundleFirstTokens(address _beneficiary, uint256 _amount, uint256[] _tokenAmounts) public whenBundlingEnabled notInLendingMode {
        require(totalSupply_ == 0, "bundleFirstTokens: This method can be used with zero total supply only");
        _bundle(_beneficiary, _amount, _tokenAmounts);
    }

    function bundle(address _beneficiary, uint256 _amount) public whenBundlingEnabled notInLendingMode {
        require(totalSupply_ != 0, "This method can be used with non zero total supply only");
        uint256[] memory tokenAmounts = new uint256[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            tokenAmounts[i] = tokens[i].balanceOf(this).mul(_amount).div(totalSupply_);
        }
        _bundle(_beneficiary, _amount, tokenAmounts);
    }

    function unbundle(address _beneficiary, uint256 _value) public notInLendingMode {
        unbundleSome(_beneficiary, _value, tokens);
    }

    function unbundleSome(address _beneficiary, uint256 _value, ERC20[] _tokens) public notInLendingMode {
        require(_tokens.length > 0, "Array of tokens can't be empty");

        uint256 totalSupply = totalSupply_;
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply.sub(_value);
        emit Unbundle(msg.sender, _beneficiary, _value);
        emit Transfer(msg.sender, 0, _value);

        for (uint i = 0; i < _tokens.length; i++) {
            for (uint j = 0; j < i; j++) {
                require(_tokens[i] != _tokens[j], "unbundleSome: should not unbundle same token multiple times");
            }
            uint256 tokenAmount = _tokens[i].balanceOf(this).mul(_value).div(totalSupply);
            _tokens[i].checkedTransfer(_beneficiary, tokenAmount);
        }
    }

     

    function disableBundling() public onlyOwner {
        require(bundlingEnabled, "Bundling is already disabled");
        bundlingEnabled = false;
        emit BundlingStatus(false);
    }

    function enableBundling() public onlyOwner {
        require(!bundlingEnabled, "Bundling is already enabled");
        bundlingEnabled = true;
        emit BundlingStatus(true);
    }

     

    function _bundle(address _beneficiary, uint256 _amount, uint256[] _tokenAmounts) internal {
        require(_amount != 0, "Bundling amount should be non-zero");
        require(tokens.length == _tokenAmounts.length, "Lenghts of tokens and _tokenAmounts array should be equal");

        for (uint i = 0; i < tokens.length; i++) {
            require(_tokenAmounts[i] != 0, "Token amount should be non-zero");
            tokens[i].checkedTransferFrom(msg.sender, this, _tokenAmounts[i]);
        }

        totalSupply_ = totalSupply_.add(_amount);
        balances[_beneficiary] = balances[_beneficiary].add(_amount);
        emit Bundle(msg.sender, _beneficiary, _amount);
        emit Transfer(0, _beneficiary, _amount);
    }

     

    function lend(address _to, ERC20 _token, uint256 _amount, address _target, bytes _data) public payable {
        uint256 prevBalance = _token.balanceOf(this);
        _token.asmTransfer(_to, _amount);
        inLendingMode += 1;
        require(caller_.makeCall.value(msg.value)(_target, _data), "lend: arbitrary call failed");
        inLendingMode -= 1;
        require(_token.balanceOf(this) >= prevBalance, "lend: lended token must be refilled");
    }
}

 

contract MultiToken is IMultiToken, BasicMultiToken {
    using CheckedERC20 for ERC20;

    uint256 internal minimalWeight;
    bool public changesEnabled = true;

    event ChangesDisabled();

    modifier whenChangesEnabled {
        require(changesEnabled, "Operation can't be performed because changes are disabled");
        _;
    }

    function init(ERC20[] _tokens, uint256[] _weights, string _name, string _symbol, uint8 _decimals) public {
        super.init(_tokens, _name, _symbol, _decimals);
        require(_weights.length == tokens.length, "Lenghts of _tokens and _weights array should be equal");
        for (uint i = 0; i < tokens.length; i++) {
            require(_weights[i] != 0, "The _weights array should not contains zeros");
            require(weights[tokens[i]] == 0, "The _tokens array have duplicates");
            weights[tokens[i]] = _weights[i];
            if (minimalWeight == 0 || _weights[i] < minimalWeight) {
                minimalWeight = _weights[i];
            }
        }
    }

    function init2(ERC20[] _tokens, uint256[] _weights, string _name, string _symbol, uint8 _decimals) public {
        init(_tokens, _weights, _name, _symbol, _decimals);
    }

    function getReturn(address _fromToken, address _toToken, uint256 _amount) public view returns(uint256 returnAmount) {
        if (weights[_fromToken] > 0 && weights[_toToken] > 0 && _fromToken != _toToken) {
            uint256 fromBalance = ERC20(_fromToken).balanceOf(this);
            uint256 toBalance = ERC20(_toToken).balanceOf(this);
            returnAmount = _amount.mul(toBalance).mul(weights[_fromToken]).div(
                _amount.mul(weights[_fromToken]).div(minimalWeight).add(fromBalance).mul(weights[_toToken])
            );
        }
    }

    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) public whenChangesEnabled notInLendingMode returns(uint256 returnAmount) {
        returnAmount = getReturn(_fromToken, _toToken, _amount);
        require(returnAmount > 0, "The return amount is zero");
        require(returnAmount >= _minReturn, "The return amount is less than _minReturn value");

        ERC20(_fromToken).checkedTransferFrom(msg.sender, this, _amount);
        ERC20(_toToken).checkedTransfer(msg.sender, returnAmount);

        emit Change(_fromToken, _toToken, msg.sender, _amount, returnAmount);
    }

     

    function disableChanges() public onlyOwner {
        require(changesEnabled, "Changes are already disabled");
        changesEnabled = false;
        emit ChangesDisabled();
    }
}

 

contract FeeMultiToken is Ownable, MultiToken {
    using CheckedERC20 for ERC20;

    uint256 public constant TOTAL_PERCRENTS = 1000000;
    uint256 public lendFee;
    uint256 public changeFee;
    uint256 public refferalFee;

    function init(ERC20[] _tokens, uint256[] _weights, string _name, string _symbol, uint8  ) public {
        super.init(_tokens, _weights, _name, _symbol, 18);
    }

    function setLendFee(uint256 _lendFee) public onlyOwner {
        require(_lendFee <= 30000, "setLendFee: fee should be not greater than 3%");
        lendFee = _lendFee;
    }

    function setChangeFee(uint256 _changeFee) public onlyOwner {
        require(_changeFee <= 30000, "setChangeFee: fee should be not greater than 3%");
        changeFee = _changeFee;
    }

    function setRefferalFee(uint256 _refferalFee) public onlyOwner {
        require(_refferalFee <= 500000, "setChangeFee: fee should be not greater than 50% of changeFee");
        refferalFee = _refferalFee;
    }

    function getReturn(address _fromToken, address _toToken, uint256 _amount) public view returns(uint256 returnAmount) {
        returnAmount = super.getReturn(_fromToken, _toToken, _amount).mul(TOTAL_PERCRENTS.sub(changeFee)).div(TOTAL_PERCRENTS);
    }

    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) public returns(uint256 returnAmount) {
        returnAmount = changeWithRef(_fromToken, _toToken, _amount, _minReturn, 0);
    }

    function changeWithRef(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn, address _ref) public returns(uint256 returnAmount) {
        returnAmount = super.change(_fromToken, _toToken, _amount, _minReturn);
        uint256 refferalAmount = returnAmount
            .mul(changeFee).div(TOTAL_PERCRENTS.sub(changeFee))
            .mul(refferalFee).div(TOTAL_PERCRENTS);

        ERC20(_toToken).checkedTransfer(_ref, refferalAmount);
    }

    function lend(address _to, ERC20 _token, uint256 _amount, address _target, bytes _data) public payable {
        uint256 prevBalance = _token.balanceOf(this);
        super.lend(_to, _token, _amount, _target, _data);
        require(_token.balanceOf(this) >= prevBalance.mul(TOTAL_PERCRENTS.add(lendFee)).div(TOTAL_PERCRENTS), "lend: tokens must be returned with lend fee");
    }
}