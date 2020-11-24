 

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;



 
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

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.21;





contract Purchase is Ownable {
  uint256 constant UINT256_MAX = ~uint256(0);
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

  uint256 resetPrice;

  mapping(uint256 => uint256) public packages;

  constructor (
    address _fundWallet,
    ERC20 _token,
    uint256 _resetPrice) public
  {
    require(_token != address(0), "INVALID TOKEN ADDRESS");
    require(_fundWallet != address(0), "INVALID WALLET ADDRESS");
    token = _token;
    wallet = _fundWallet;
    resetPrice = _resetPrice;
  }

  event Buy(uint256 _accountId, uint256 _amount);

  function setResetPrice(uint256 _resetPrice) external onlyOwner {
    resetPrice = _resetPrice;
  }

  function setPackagePrice(uint256 _amount, uint256 _price) external onlyOwner {
    packages[_amount] = _price;
  }

  function resetPortfolio(uint256 _accountId) external {
    require(token.transferFrom(msg.sender, wallet, resetPrice), "TRANSFER ERROR");
  }

  function buyFund(uint256 _accountId, uint256 _amount) external {
    uint256 price = packages[_amount];
    require(price != 0, "NEED PACKAGE PRICE");
    require(token.transferFrom(msg.sender, wallet, price), "TRANSFER ERROR");
    emit Buy(_accountId, _amount);
  }
}