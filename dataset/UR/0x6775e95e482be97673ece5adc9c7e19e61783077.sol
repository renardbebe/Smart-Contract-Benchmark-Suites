 

pragma solidity 0.4.21;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

library R {

    struct Rational {
        uint n;   
        uint d;   
    }

}


library Rationals {
    using SafeMath for uint;

    function rmul(uint256 amount, R.Rational memory r) internal pure returns (uint256) {
        return amount.mul(r.n).div(r.d);
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

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

 
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

 

 
contract Exchange is Pausable, RBAC {
    using SafeMath for uint256;

    string constant ROLE_ORACLE = "oracle";

    ERC20 baseToken;
    ERC20 dai;   
    address public oracle;
    R.Rational public ethRate;
    R.Rational public daiRate;

    event TradeETH(uint256 amountETH, uint256 amountBaseToken);
    event TradeDAI(uint256 amountDAI, uint256 amountBaseToken);
    event RateUpdatedETH(uint256 n, uint256 d);
    event RateUpdatedDAI(uint256 n, uint256 d);
    event OracleSet(address oracle);

     
    function Exchange(
        address _baseToken,
        address _dai,
        address _oracle,
        uint256 _ethRateN,
        uint256 _ethRateD,
        uint256 _daiRateN,
        uint256 _daiRateD
    ) public {
        baseToken = ERC20(_baseToken);
        dai = ERC20(_dai);
        addRole(_oracle, ROLE_ORACLE);
        oracle = _oracle;
        ethRate = R.Rational(_ethRateN, _ethRateD);
        daiRate = R.Rational(_daiRateN, _daiRateD);
    }

     
    function tradeETH(uint256 expectedAmountBaseToken) public whenNotPaused() payable {
        uint256 amountBaseToken = calculateAmountForETH(msg.value);
        require(amountBaseToken == expectedAmountBaseToken);
        require(baseToken.transfer(msg.sender, amountBaseToken));
        emit TradeETH(msg.value, amountBaseToken);
    }

     
    function tradeDAI(uint256 amountDAI, uint256 expectedAmountBaseToken) public whenNotPaused() {
        uint256 amountBaseToken = calculateAmountForDAI(amountDAI);
        require(amountBaseToken == expectedAmountBaseToken);
        require(dai.transferFrom(msg.sender, address(this), amountDAI));
        require(baseToken.transfer(msg.sender, amountBaseToken));
        emit TradeDAI(amountDAI, amountBaseToken);
    }

     
    function calculateAmountForETH(uint256 amountETH) public view returns (uint256) {
        return Rationals.rmul(amountETH, ethRate);
    }

     
    function calculateAmountForDAI(uint256 amountDAI) public view returns (uint256) {
        return Rationals.rmul(amountDAI, daiRate);
    }

     
    function setETHRate(uint256 n, uint256 d) external onlyRole(ROLE_ORACLE) {
        ethRate = R.Rational(n, d);
        emit RateUpdatedETH(n, d);
    }

     
    function setDAIRate(uint256 n, uint256 d) external onlyRole(ROLE_ORACLE) {
        daiRate = R.Rational(n, d);
        emit RateUpdatedDAI(n, d);
    }

     
    function withdrawERC20s(address token, uint256 amount) external onlyOwner {
        ERC20 erc20 = ERC20(token);
        require(erc20.transfer(owner, amount));
    }

     
    function setOracle(address _oracle) external onlyOwner {
        removeRole(oracle, ROLE_ORACLE);
        addRole(_oracle, ROLE_ORACLE);
        oracle = _oracle;
        emit OracleSet(_oracle);
    }

     
    function withdrawEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }

}