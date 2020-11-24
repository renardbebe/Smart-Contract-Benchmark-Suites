 

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
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

 

library CheckedERC20 {
    using SafeMath for uint;

    function checkedTransfer(ERC20 _token, address _to, uint256 _value) internal {
        if (_value == 0) {
            return;
        }
        uint256 balance = _token.balanceOf(this);
        _token.transfer(_to, _value);
        require(_token.balanceOf(this) == balance.sub(_value), "checkedTransfer: Final balance didn't match");
    }

    function checkedTransferFrom(ERC20 _token, address _from, address _to, uint256 _value) internal {
        if (_value == 0) {
            return;
        }
        uint256 toBalance = _token.balanceOf(_to);
        _token.transferFrom(_from, _to, _value);
        require(_token.balanceOf(_to) == toBalance.add(_value), "checkedTransfer: Final balance didn't match");
    }
}

 

contract IBasicMultiToken is ERC20 {
    event Bundle(address indexed who, address indexed beneficiary, uint256 value);
    event Unbundle(address indexed who, address indexed beneficiary, uint256 value);

    function tokensCount() public view returns(uint256);
    function tokens(uint256 _index) public view returns(ERC20);
    function allTokens() public view returns(ERC20[]);
    function allDecimals() public view returns(uint8[]);
    function allBalances() public view returns(uint256[]);
    function allTokensDecimalsBalances() public view returns(ERC20[], uint8[], uint256[]);

    function bundleFirstTokens(address _beneficiary, uint256 _amount, uint256[] _tokenAmounts) public;
    function bundle(address _beneficiary, uint256 _amount) public;

    function unbundle(address _beneficiary, uint256 _value) public;
    function unbundleSome(address _beneficiary, uint256 _value, ERC20[] _tokens) public;
}

 

contract IMultiToken is IBasicMultiToken {
    event Update();
    event Change(address indexed _fromToken, address indexed _toToken, address indexed _changer, uint256 _amount, uint256 _return);

    function getReturn(address _fromToken, address _toToken, uint256 _amount) public view returns (uint256 returnAmount);
    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256 returnAmount);

    function allWeights() public view returns(uint256[] _weights);
    function allTokensDecimalsBalancesWeights() public view returns(ERC20[] _tokens, uint8[] _decimals, uint256[] _balances, uint256[] _weights);
}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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
    uint _addedValue
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
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
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

 

contract BasicMultiToken is Pausable, StandardToken, DetailedERC20, ERC1003Token, IBasicMultiToken {
    using CheckedERC20 for ERC20;

    ERC20[] public tokens;

    event Bundle(address indexed who, address indexed beneficiary, uint256 value);
    event Unbundle(address indexed who, address indexed beneficiary, uint256 value);
    
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

    function bundleFirstTokens(address _beneficiary, uint256 _amount, uint256[] _tokenAmounts) public {
        require(totalSupply_ == 0, "This method can be used with zero total supply only");
        _bundle(_beneficiary, _amount, _tokenAmounts);
    }

    function bundle(address _beneficiary, uint256 _amount) public {
        require(totalSupply_ != 0, "This method can be used with non zero total supply only");
        uint256[] memory tokenAmounts = new uint256[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            tokenAmounts[i] = tokens[i].balanceOf(this).mul(_amount).div(totalSupply_);
        }
        _bundle(_beneficiary, _amount, tokenAmounts);
    }

    function unbundle(address _beneficiary, uint256 _value) public {
        unbundleSome(_beneficiary, _value, tokens);
    }

    function unbundleSome(address _beneficiary, uint256 _value, ERC20[] _tokens) public {
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

    function _bundle(address _beneficiary, uint256 _amount, uint256[] _tokenAmounts) internal whenNotPaused {
        require(tokens.length == _tokenAmounts.length, "Lenghts of tokens and _tokenAmounts array should be equal");

        for (uint i = 0; i < tokens.length; i++) {
            uint256 prevBalance = tokens[i].balanceOf(this);
            tokens[i].transferFrom(msg.sender, this, _tokenAmounts[i]);  
            require(tokens[i].balanceOf(this) == prevBalance.add(_tokenAmounts[i]), "Invalid token behavior");
        }

        totalSupply_ = totalSupply_.add(_amount);
        balances[_beneficiary] = balances[_beneficiary].add(_amount);
        emit Bundle(msg.sender, _beneficiary, _amount);
        emit Transfer(0, _beneficiary, _amount);
    }

     

    function lend(address _to, ERC20 _token, uint256 _amount, address _target, bytes _data) public payable {
        uint256 prevBalance = _token.balanceOf(this);
        _token.transfer(_to, _amount);
        require(caller_.makeCall.value(msg.value)(_target, _data), "lend: arbitrary call failed");
        require(_token.balanceOf(this) >= prevBalance, "lend: lended token must be refilled");
    }

     

    function tokensCount() public view returns(uint) {
        return tokens.length;
    }

    function tokens(uint _index) public view returns(ERC20) {
        return tokens[_index];
    }

    function allTokens() public view returns(ERC20[] _tokens) {
        _tokens = tokens;
    }

    function allBalances() public view returns(uint256[] _balances) {
        _balances = new uint256[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            _balances[i] = tokens[i].balanceOf(this);
        }
    }

    function allDecimals() public view returns(uint8[] _decimals) {
        _decimals = new uint8[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            _decimals[i] = DetailedERC20(tokens[i]).decimals();
        }
    }

    function allTokensDecimalsBalances() public view returns(ERC20[] _tokens, uint8[] _decimals, uint256[] _balances) {
        _tokens = allTokens();
        _decimals = allDecimals();
        _balances = allBalances();
    }
}

 

contract MultiToken is IMultiToken, BasicMultiToken {
    using CheckedERC20 for ERC20;

    uint inLendingMode;
    uint256 internal minimalWeight;
    mapping(address => uint256) public weights;

    function init(ERC20[] _tokens, uint256[] _weights, string _name, string _symbol, uint8 _decimals) public {
        super.init(_tokens, _name, _symbol, _decimals);
        require(_weights.length == tokens.length, "Lenghts of _tokens and _weights array should be equal");
        for (uint i = 0; i < tokens.length; i++) {
            require(_weights[i] != 0, "The _weights array should not contains zeros");
            require(weights[tokens[i]] == 0, "The _tokens array have duplicates");
            weights[tokens[i]] = _weights[i];
            if (minimalWeight == 0 || minimalWeight < _weights[i]) {
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
                _amount.mul(weights[_fromToken]).div(minimalWeight).add(fromBalance)
            );
        }
    }

    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) public returns(uint256 returnAmount) {
        require(inLendingMode == 0);
        returnAmount = getReturn(_fromToken, _toToken, _amount);
        require(returnAmount > 0, "The return amount is zero");
        require(returnAmount >= _minReturn, "The return amount is less than _minReturn value");
        
        ERC20(_fromToken).checkedTransferFrom(msg.sender, this, _amount);
        ERC20(_toToken).checkedTransfer(msg.sender, returnAmount);

        emit Change(_fromToken, _toToken, msg.sender, _amount, returnAmount);
    }

     

    function lend(address _to, ERC20 _token, uint256 _amount, address _target, bytes _data) public payable {
        inLendingMode += 1;
        super.lend(_to, _token, _amount, _target, _data);
        inLendingMode -= 1;
    }

     

    function allWeights() public view returns(uint256[] _weights) {
        _weights = new uint256[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            _weights[i] = weights[tokens[i]];
        }
    }

    function allTokensDecimalsBalancesWeights() public view returns(ERC20[] _tokens, uint8[] _decimals, uint256[] _balances, uint256[] _weights) {
        (_tokens, _decimals, _balances) = allTokensDecimalsBalances();
        _weights = allWeights();
    }

}

 

contract FeeMultiToken is Ownable, MultiToken {
    using CheckedERC20 for ERC20;

    uint256 public constant ONE_HUNDRED_PERCRENTS = 1000000;
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
        returnAmount = super.getReturn(_fromToken, _toToken, _amount).mul(ONE_HUNDRED_PERCRENTS.sub(changeFee)).div(ONE_HUNDRED_PERCRENTS);
    }

    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) public returns(uint256 returnAmount) {
        returnAmount = changeWithRef(_fromToken, _toToken, _amount, _minReturn, 0);
    }

    function changeWithRef(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn, address _ref) public returns(uint256 returnAmount) {
        returnAmount = super.change(_fromToken, _toToken, _amount, _minReturn);
        uint256 refferalAmount = returnAmount
            .mul(changeFee).div(ONE_HUNDRED_PERCRENTS.sub(changeFee))
            .mul(refferalFee).div(ONE_HUNDRED_PERCRENTS);

        ERC20(_toToken).checkedTransfer(_ref, refferalAmount);
    }

    function lend(address _to, ERC20 _token, uint256 _amount, address _target, bytes _data) public payable {
        uint256 prevBalance = _token.balanceOf(this);
        super.lend(_to, _token, _amount, _target, _data);
        require(_token.balanceOf(this) >= prevBalance.mul(ONE_HUNDRED_PERCRENTS.add(lendFee)).div(ONE_HUNDRED_PERCRENTS), "lend: tokens must be returned with lend fee");
    }
}