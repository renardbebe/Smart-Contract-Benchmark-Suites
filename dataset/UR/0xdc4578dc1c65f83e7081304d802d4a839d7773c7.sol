 

pragma solidity 0.4.24;

 

 
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

 

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 

 
contract DirectAirDrop is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    event TokensReturn(uint256 amount);

    ERC20 public token;

    uint256 public totalDropped;
    mapping(address => uint256) public dropped;

     
    constructor(address _token) public {
        require(_token != address(0));
        token = ERC20(_token);
    }

     
    function returnTokens() external onlyOwner {
        uint256 remaining = token.balanceOf(address(this));
        token.safeTransfer(owner, remaining);

        emit TokensReturn(remaining);
    }

     
    function tokensBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

     
    function drop(address _beneficiary, uint256 _amount) external onlyOwner {
        totalDropped = totalDropped.add(_amount);
        dropped[_beneficiary] = dropped[_beneficiary].add(_amount);
        token.safeTransfer(_beneficiary, _amount);
    }

     
    function dropBatch(address[] _addresses, uint256[] _amounts) external onlyOwner {
        require(_addresses.length == _amounts.length);

        for (uint256 index = 0; index < _addresses.length; index++) {
            address beneficiary = _addresses[index];
            uint256 amount = _amounts[index];

            totalDropped = totalDropped.add(amount);
            dropped[beneficiary] = dropped[beneficiary].add(amount);
            token.safeTransfer(beneficiary, amount);
        }
    }
}