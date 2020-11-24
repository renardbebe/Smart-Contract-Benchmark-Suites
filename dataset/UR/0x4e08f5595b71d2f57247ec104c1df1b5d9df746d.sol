 

pragma solidity 0.4.25;

 
contract IERC20 {
    function transfer(address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    require(b > 0);
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Auth {

  address internal admin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor(address _admin) internal {
    admin = _admin;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "onlyAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyAdmin internal {
    require(_newOwner != address(0x0));
    admin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }
}

contract TagMembership is Auth {
  using SafeMath for uint;

  enum Type {
    Monthly,
    Yearly
  }
  enum Method {
    TAG,
    USDT
  }
  struct Membership {
    Type[] types;
    uint[] expiredAt;
  }
  mapping(string => Membership) memberships;
  string[] private members;
  IERC20 tagToken = IERC20(0x5Ac44ca5368698568d96437363BEcc8Cd84EF061);
  IERC20 usdtToken = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  uint public tokenPrice = 2;
  uint public vipMonthFee = 10000;
  uint public vipYearFee = 100000;

  event MembershipActivated(string userId, Type membershipType, uint expiredAt, Method method);

  constructor(address _admin) public Auth(_admin) {}

   

  function countMembers() onlyAdmin public view returns(uint) {
    return members.length;
  }

  function getUserInfoAt(string _user, uint _position) onlyAdmin public view returns(uint, uint) {
    Membership storage memberShip = memberships[_user];
    require(_position < memberShip.types.length, 'position invalid');
    return (
      uint(memberShip.types[_position]),
      memberShip.expiredAt[_position]
    );
  }

  function updateTokenPrice(uint _tokenPrice) onlyAdmin public {
    tokenPrice = _tokenPrice;
  }

  function setVipMonthFee(uint _vipMonthFee) onlyAdmin public {
    require(_vipMonthFee > 0, 'fee is invalid');
    vipMonthFee = _vipMonthFee;
  }

  function setVipYearFee(uint _vipYearFee) onlyAdmin public {
    require(_vipYearFee > vipMonthFee, 'fee is invalid');
    vipYearFee = _vipYearFee;
  }

  function updateAdmin(address _admin) public {
    transferOwnership(_admin);
  }

  function drain() onlyAdmin public {
    tagToken.transfer(admin, tagToken.balanceOf(address(this)));
    usdtToken.transfer(admin, usdtToken.balanceOf(address(this)));
    admin.transfer(address(this).balance);
  }

   

  function activateMembership(Type _type, string _userId, Method _method) public {
    uint tokenAmount = calculateTokenAmount(_type, _method);
    IERC20 token = _method == Method.TAG ? tagToken : usdtToken;
    require(token.allowance(msg.sender, address(this)) >= tokenAmount, 'please call approve() first');
    require(token.balanceOf(msg.sender) >= tokenAmount, 'you have not enough token');
    require(token.transferFrom(msg.sender, admin, tokenAmount), 'transfer token to contract failed');
    if (!isMembership(_userId)) {
      members.push(_userId);
    }
    Membership storage memberShip = memberships[_userId];
    memberShip.types.push(_type);
    uint newExpiredAt;
    uint extendedPeriod = _type == Type.Monthly ? 30 days : 365 days;
    bool userStillInMembership = memberShip.expiredAt.length > 0 && memberShip.expiredAt[memberShip.expiredAt.length - 1] > now;
    if (userStillInMembership) {
      newExpiredAt = memberShip.expiredAt[memberShip.expiredAt.length - 1].add(extendedPeriod);
    } else {
      newExpiredAt = now.add(extendedPeriod);
    }
    memberShip.expiredAt.push(newExpiredAt);
    emit MembershipActivated(_userId, _type, newExpiredAt, _method);
  }

  function getMyMembership(string _userId) public view returns(uint, uint) {
    Membership storage memberShip = memberships[_userId];
    return (
      uint(memberShip.types[memberShip.types.length - 1]),
      memberShip.expiredAt[memberShip.expiredAt.length - 1]
    );
  }

   

  function calculateTokenAmount(Type _type, Method _method) private view returns (uint) {
    uint activationPrice = _type == Type.Monthly ? vipMonthFee : vipYearFee;
    if (_method == Method.TAG) {
      return activationPrice.div(tokenPrice).mul(70).div(100).mul(10 ** 18);
    }
    uint usdt = 1000;
    return activationPrice.div(usdt).mul(10 ** 6);
  }

  function isMembership(string _user) private view returns(bool) {
    return memberships[_user].types.length > 0;
  }
}