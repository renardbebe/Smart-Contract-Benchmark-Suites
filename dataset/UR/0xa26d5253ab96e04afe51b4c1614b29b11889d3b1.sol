 

pragma solidity ^0.4.17;

 
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
     
    uint256 c = a / b;
     
    return c;
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
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

   
   
  uint256 public constant hardCap = 32000 * tokenPrecision;

   
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

   
  uint256 public tokensPerEth;

   
  uint public icoStart;
  uint public icoEnd;

   
  uint256 public dripRate = 50;

   
  address public currentSaleAddress;

   
  event Freeze(address indexed from, uint256 value);
  event Participate(address indexed from, uint256 value);
  event Reconcile(address indexed from, uint256 period, uint256 value);

   
  function Ico(uint256 _icoStart, uint256 _icoEnd, address[] _team, uint256 _tokensPerEth) public {
     
    require (_icoEnd >= _icoStart);
    require (_tokensPerEth > 0);

    owner = msg.sender;

    icoStart = _icoStart;
    icoEnd = _icoEnd;
    tokensPerEth = _tokensPerEth;

     
    teamNum = _team.length;
    for (uint256 i = 0; i < teamNum; i++) {
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

   
  function participate(address beneficiary) public payable {
    require (beneficiary != address(0));
    require (now >= icoStart && now <= icoEnd);
    require (msg.value > 0);

    uint256 ethAmount = msg.value;
    uint256 numTokens = ethAmount.mul(tokensPerEth);

    require(totalSupply.add(numTokens) <= hardCap);

    balances[beneficiary] = balances[beneficiary].add(numTokens);
    totalSupply = totalSupply.add(numTokens);
    tokensFrozen = totalSupply * 2;
    aum = totalSupply;

    owner.transfer(ethAmount);
     
    Participate(beneficiary, numTokens);
     
    Transfer(0x0, beneficiary, numTokens);
  }

   
  function () external payable {
     participate(msg.sender);
  }

   
  function freeze(uint256 _amount) public onlySaleAddress returns (bool) {
    reconcileDividend(msg.sender);
    require(_amount <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    tokensFrozen = tokensFrozen.add(_amount);

    aum = aum.sub(tokenValue.mul(_amount).div(tokenPrecision));

    Freeze(msg.sender, _amount);
    Transfer(msg.sender, 0x0, _amount);
    return true;
  }

   
  function reportProfit(int256 totalProfit, address saleAddress) public onlyTeam returns (bool) {
     
    if (totalProfit > 0) {
       
      uint256 profit = uint256(totalProfit).mul(tokenPrecision).div(2);

       
      addNewDividends(profit);
    }

     
    drip(saleAddress);

     
    aum = aum.add(uint256(totalProfit).mul(tokenPrecision));

     
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
    Transfer(0x0, saleAddress, dripTokens);
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
    var (owedDividend,  ) = getOwedDividend(_owner);
    return BasicToken.balanceOf(_owner).add(owedDividend);
  }


   
   
  function reconcileDividend(address _owner) internal {
    var (owedDividend, dividends) = getOwedDividend(_owner);

    for (uint i = 0; i < dividends.length; i++) {
      if (dividends[i] > 0) {
        Reconcile(_owner, lastDividend[_owner] + i, dividends[i]);
        Transfer(0x0, _owner, dividends[i]);
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