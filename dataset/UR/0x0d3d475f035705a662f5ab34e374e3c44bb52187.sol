 

pragma solidity ^0.4.24;

contract Config {
    uint256 public constant jvySupply = 333333333333333;
    uint256 public constant bonusSupply = 83333333333333;
    uint256 public constant saleSupply =  250000000000000;
    uint256 public constant hardCapUSD = 8000000;

    uint256 public constant preIcoBonus = 25;
    uint256 public constant minimalContributionAmount = 0.4 ether;

    function getStartPreIco() public view returns (uint256) {
         
        uint256 nowTime = block.timestamp;
         
        uint256 _preIcoStartTime = nowTime + 1 minutes;
        return _preIcoStartTime;
    }

    function getStartIco() public view returns (uint256) {
         
         
         
        uint256 _icoStartTime = 1543554000;
        return _icoStartTime;
    }

    function getEndIco() public view returns (uint256) {
         
         
         
        uint256 _icoEndTime = 1551416400;
        return _icoEndTime;
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

contract JavvyToken is DetailedERC20, StandardToken, Ownable, Config {
    address public crowdsaleAddress;
    address public bonusAddress;
    address public multiSigAddress;

    constructor(
        string _name, 
        string _symbol, 
        uint8 _decimals
    ) public
    DetailedERC20(_name, _symbol, _decimals) {
        require(
            jvySupply == saleSupply + bonusSupply,
            "Sum of provided supplies is not equal to declared total Javvy supply. Check config!"
        );
        totalSupply_ = tokenToDecimals(jvySupply);
    }

    function initializeBalances(
        address _crowdsaleAddress,
        address _bonusAddress,
        address _multiSigAddress
    ) public 
    onlyOwner() {
        crowdsaleAddress = _crowdsaleAddress;
        bonusAddress = _bonusAddress;
        multiSigAddress = _multiSigAddress;

        _initializeBalance(_crowdsaleAddress, saleSupply);
        _initializeBalance(_bonusAddress, bonusSupply);
    }

    function _initializeBalance(address _address, uint256 _supply) private {
        require(_address != address(0), "Address cannot be equal to 0x0!");
        require(_supply != 0, "Supply cannot be equal to 0!");
        balances[_address] = tokenToDecimals(_supply);
        emit Transfer(address(0), _address, _supply);
    }

    function tokenToDecimals(uint256 _amount) private view returns (uint256){
         
        return _amount * (10 ** 12);
    }

    function getRemainingSaleTokens() external view returns (uint256) {
        return balanceOf(crowdsaleAddress);
    }

}