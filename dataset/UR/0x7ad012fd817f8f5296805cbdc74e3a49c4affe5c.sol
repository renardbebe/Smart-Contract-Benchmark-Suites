 

pragma solidity ^0.4.24;


 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
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


 
contract PriceOracleIface {
  uint256 public ethPriceInCents;

  function getUsdCentsFromWei(uint256 _wei) public view returns (uint256) {
  }
}


 
contract TransferableTokenIface {
  function transfer(address to, uint256 value) public returns (bool) {
  }

  function balanceOf(address who) public view returns (uint256) {
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract VeraCrowdsale is RBAC {
  using SafeMath for uint256;

   
  uint256 public tokenPriceInCents = 200;

   
  uint256 public minDepositInCents = 800000;

   
   
  uint256 public centsRaised;

   
   
  uint256 public tokensSold;

   
  TransferableTokenIface public token;

   
  PriceOracleIface public priceOracle;

   
  address public wallet;

   
  string public constant ROLE_ADMIN = "admin";
  string public constant ROLE_BACKEND = "backend";
  string public constant ROLE_KYC_VERIFIED_INVESTOR = "kycVerified";

   
  struct AmountBonus {

     
     
     
    uint256 id;

     
     
    uint256 amountFrom;
    uint256 amountTo;
    uint256 bonusPercent;
  }

   
  AmountBonus[] public amountBonuses;

   
  event TokenPurchase(
    address indexed investor,
    uint256 ethPriceInCents,
    uint256 valueInCents,
    uint256 bonusPercent,
    uint256 bonusIds
  );

   
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

   
  modifier onlyBackend()
  {
    checkRole(msg.sender, ROLE_BACKEND);
    _;
  }

   
  modifier onlyKYCVerifiedInvestor()
  {
    checkRole(msg.sender, ROLE_KYC_VERIFIED_INVESTOR);
    _;
  }

   
  constructor(
    TransferableTokenIface _token,
    PriceOracleIface _priceOracle,
    address _wallet
  )
    public
  {
    require(_token != address(0), "Need token contract address");
    require(_priceOracle != address(0), "Need price oracle contract address");
    require(_wallet != address(0), "Need wallet address");
    addRole(msg.sender, ROLE_ADMIN);
    token = _token;
    priceOracle = _priceOracle;
    wallet = _wallet;
     
    amountBonuses.push(AmountBonus(0x1, 800000, 1999999, 20));
     
    amountBonuses.push(AmountBonus(0x2, 2000000, 2**256 - 1, 30));
  }

   
  function ()
    external
    payable
    onlyKYCVerifiedInvestor
  {
    uint256 valueInCents = priceOracle.getUsdCentsFromWei(msg.value);
    buyTokens(msg.sender, valueInCents);
    wallet.transfer(msg.value);
  }

   
  function withdrawTokens(address _to) public onlyAdmin {
    uint256 amount = token.balanceOf(address(this));
    require(amount > 0, "no tokens on the contract");
    token.transfer(_to, amount);
  }

   
  function buyTokensViaBackend(address _investor, uint256 _cents)
    public
    onlyBackend
  {
    if (! RBAC.hasRole(_investor, ROLE_KYC_VERIFIED_INVESTOR)) {
      addKycVerifiedInvestor(_investor);
    }
    buyTokens(_investor, _cents);
  }

   
  function computeBonuses(uint256 _cents)
    public
    view
    returns (uint256, uint256)
  {
    uint256 bonusTotal;
    uint256 bonusIds;
    for (uint i = 0; i < amountBonuses.length; i++) {
      if (_cents >= amountBonuses[i].amountFrom &&
      _cents <= amountBonuses[i].amountTo) {
        bonusTotal += amountBonuses[i].bonusPercent;
        bonusIds += amountBonuses[i].id;
      }
    }
    return (bonusTotal, bonusIds);
  }

   
  function computeTokens(uint256 _cents) public view returns (uint256) {
    uint256 tokens = _cents.mul(10 ** 18).div(tokenPriceInCents);
    (uint256 bonusPercent, ) = computeBonuses(_cents);
    uint256 bonusTokens = tokens.mul(bonusPercent).div(100);
    if (_cents >= minDepositInCents) {
      return tokens.add(bonusTokens);
    }
  }

   
  function addAdmin(address addr)
    public
    onlyAdmin
  {
    addRole(addr, ROLE_ADMIN);
  }

   
  function delAdmin(address addr)
    public
    onlyAdmin
  {
    removeRole(addr, ROLE_ADMIN);
  }

   
  function addBackend(address addr)
    public
    onlyAdmin
  {
    addRole(addr, ROLE_BACKEND);
  }

   
  function delBackend(address addr)
    public
    onlyAdmin
  {
    removeRole(addr, ROLE_BACKEND);
  }

   
  function addKycVerifiedInvestor(address addr)
    public
    onlyBackend
  {
    addRole(addr, ROLE_KYC_VERIFIED_INVESTOR);
  }

   
  function delKycVerifiedInvestor(address addr)
    public
    onlyBackend
  {
    removeRole(addr, ROLE_KYC_VERIFIED_INVESTOR);
  }

   
  function buyTokens(address _investor, uint256 _cents) internal {
    (uint256 bonusPercent, uint256 bonusIds) = computeBonuses(_cents);
    uint256 tokens = computeTokens(_cents);
    require(tokens > 0, "value is not enough");
    token.transfer(_investor, tokens);
    centsRaised = centsRaised.add(_cents);
    tokensSold = tokensSold.add(tokens);
    emit TokenPurchase(
      _investor,
      priceOracle.ethPriceInCents(),
      _cents,
      bonusPercent,
      bonusIds
    );
  }
}