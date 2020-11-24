 

pragma solidity ^0.4.23;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
 
contract Ico is BasicToken {
  address owner;
  uint256 public teamNum;
  mapping(address => bool) team;

   
  string public constant name = "LUNA";
  string public constant symbol = "LUNA";
  uint8 public constant decimals = 18;

   
  uint256 private constant tokenPrecision = 10e17;

   
  uint256 public tokensFrozen = 0;

  uint256 public tokenValue = 1 * tokenPrecision;

   
  struct DividendSnapshot {
    uint256 totalSupply;
    uint256 dividendsIssued;
    uint256 managementDividends;
  }
   
  DividendSnapshot[] dividendSnapshots;

   
  mapping(address => uint256) lastDividend;

   
  uint256 public constant managementFees = 10;

   
  uint256 public aum = 0;

   
  uint256 public totalSupply = 0;

   
  uint256 public dripRate = 50;

   
  address public currentSaleAddress;

   
  event Freeze(address indexed from, uint256 value);
  event Reconcile(address indexed from, uint256 period, uint256 value);

   
  constructor(address[] _team, address[] shareholders, uint256[] shares, uint256 _aum, uint256 _tokensFrozen) public {
    owner = msg.sender;

     
    aum = _aum;
    tokensFrozen = _tokensFrozen;

    uint256 shareholderNum = shareholders.length;
    for (uint256 i = 0; i < shareholderNum; i++) {
      balances[shareholders[i]] = shares[i];
      totalSupply = totalSupply.add(shares[i]);
      emit Transfer(0x0, shareholders[i], shares[i]);
    }

     
    teamNum = _team.length;
    for (i = 0; i < teamNum; i++) {
      team[_team[i]] = true;
    }

     
    currentSaleAddress = owner;
  }

   
  modifier onlyOwner() {
    require (msg.sender == owner);
    _;
  }

  modifier onlyTeam() {
    require (team[msg.sender] == true);
    _;
  }

  modifier onlySaleAddress() {
    require (msg.sender == currentSaleAddress);
    _;
  }

   
  function freeze(uint256 _amount) public onlySaleAddress returns (bool) {
    reconcileDividend(msg.sender);
    require(_amount <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    tokensFrozen = tokensFrozen.add(_amount);

    aum = aum.sub(tokenValue.mul(_amount).div(tokenPrecision));

    emit Freeze(msg.sender, _amount);
    emit Transfer(msg.sender, 0x0, _amount);
    return true;
  }

   
  function reportProfit(int256 totalProfit, bool shouldDrip, address saleAddress) public onlyTeam returns (bool) {
     
    if (totalProfit > 0) {
       
      uint256 profit = uint256(totalProfit).mul(tokenPrecision).div(2);

       
      addNewDividends(profit);
    }

    if (shouldDrip) {
       
      drip(saleAddress);
    }

     
    if (totalProfit > 0) {
      aum = aum.add(uint256(totalProfit).mul(tokenPrecision));
    } else if (totalProfit < 0) {
      aum = aum.sub(uint256(-totalProfit).mul(tokenPrecision));
    }

     
    currentSaleAddress = saleAddress;

    return true;
  }


  function drip(address saleAddress) internal {
    uint256 dripTokens = tokensFrozen.div(dripRate);

    tokensFrozen = tokensFrozen.sub(dripTokens);
    totalSupply = totalSupply.add(dripTokens);
    aum = aum.add(tokenValue.mul(dripTokens).div(tokenPrecision));

    reconcileDividend(saleAddress);
    balances[saleAddress] = balances[saleAddress].add(dripTokens);
    emit Transfer(0x0, saleAddress, dripTokens);
  }

   
  function addNewDividends(uint256 profit) internal {
    uint256 newAum = aum.add(profit);  
    tokenValue = newAum.mul(tokenPrecision).div(totalSupply);  
    uint256 totalDividends = profit.mul(tokenPrecision).div(tokenValue);  
    uint256 managementDividends = totalDividends.div(managementFees);  
    uint256 dividendsIssued = totalDividends.sub(managementDividends);  

     
    require(tokensFrozen >= totalDividends);

    dividendSnapshots.push(DividendSnapshot(totalSupply, dividendsIssued, managementDividends));

     
    totalSupply = totalSupply.add(totalDividends);
    tokensFrozen = tokensFrozen.sub(totalDividends);
  }

   
  function liquidate() public onlyTeam returns (bool) {
    selfdestruct(owner);
  }

   
  function setAUM(uint256 _aum) public onlyTeam returns (bool) {
    aum = _aum;
    return true;
  }


   
  function getOwedDividend(address _owner) public view returns (uint256 total, uint256[]) {
    uint256[] memory noDividends = new uint256[](0);
     
    uint256 balance = BasicToken.balanceOf(_owner);
     
     
    uint idx = lastDividend[_owner];
    if (idx == dividendSnapshots.length) return (total, noDividends);
    if (balance == 0 && team[_owner] != true) return (total, noDividends);

    uint256[] memory dividends = new uint256[](dividendSnapshots.length - idx - i);
    uint256 currBalance = balance;
    for (uint i = idx; i < dividendSnapshots.length; i++) {
       
       
      uint256 dividend = currBalance.mul(tokenPrecision).div(dividendSnapshots[i].totalSupply).mul(dividendSnapshots[i].dividendsIssued).div(tokenPrecision);

       
      if (team[_owner] == true) {
        dividend = dividend.add(dividendSnapshots[i].managementDividends.div(teamNum));
      }

      total = total.add(dividend);

      dividends[i - idx] = dividend;

      currBalance = currBalance.add(dividend);
    }

    return (total, dividends);
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    uint256 owedDividend;
    (owedDividend,) = getOwedDividend(_owner);
    return BasicToken.balanceOf(_owner).add(owedDividend);
  }


   
   
  function reconcileDividend(address _owner) internal {
    uint256 owedDividend;
    uint256[] memory dividends;
    (owedDividend, dividends) = getOwedDividend(_owner);

    for (uint i = 0; i < dividends.length; i++) {
      if (dividends[i] > 0) {
        emit Reconcile(_owner, lastDividend[_owner] + i, dividends[i]);
        emit Transfer(0x0, _owner, dividends[i]);
      }
    }

    if(owedDividend > 0) {
      balances[_owner] = balances[_owner].add(owedDividend);
    }

     
    lastDividend[_owner] = dividendSnapshots.length;
  }

  function transfer(address _to, uint256 _amount) public returns (bool) {
    reconcileDividend(msg.sender);
    reconcileDividend(_to);
    return BasicToken.transfer(_to, _amount);
  }

}