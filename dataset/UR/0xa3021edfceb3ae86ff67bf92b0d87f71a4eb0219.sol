 

pragma solidity ^0.4.23;

 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract CrowdsaleToken is MintableToken {
  uint256 public totalTokens = uint256(300000000).mul(1e4);  
  uint256 public crowdSaleCap = uint256(210000000).mul(1e4);  
  uint256 public hardCap = uint256(12000).mul(1 ether);  
  uint256 public softCap = uint256(1000).mul(1 ether);  
  uint256 public weiRaised;  
  uint256 public basePrice = 330000000000000;  
  uint256 public refundPercent = 90;  
  uint256 public preIcoStartDate = 1534291200;  
  uint256 public preIcoEndDate = 1537919999;  
  uint256 public icoStartDate = 1539561600;  
  uint256 public icoEndDate = 1543622399;  
  uint256 public refundEndDate = 1543881599;  
  uint256 public bonusPeriod = 432000;  
  uint256 public bonusLimit1 = uint256(45000).mul(1e4);  
  uint256 public bonusLimit2 = uint256(30000).mul(1e4);  
  uint256 public bonusLimit3 = uint256(10000).mul(1e4);  
  uint256 public bonusLimit4 = uint256(3000).mul(1e4);  
  uint256 public bonusLimit5 = uint256(25).mul(1e4);  
  address public newOwner = 0x67f00b9B121ab98CF102c5892c14A5e696eA2CC0;
  address public wallet = 0x3840428703BaA6C614E85CaE6167c59d8922C0FE;
  mapping(address => uint256) contribution;

  constructor() public {
    owner = newOwner;
    uint256 teamTokens = totalTokens.sub(crowdSaleCap);
    balances[owner] = teamTokens;
    totalSupply_ = teamTokens;
    emit Transfer(address(this), owner, teamTokens);
  } 

  function getBonuses (uint256 _tokens) public view returns (uint256) {
    if (now >= preIcoStartDate && now <= preIcoEndDate) {
      if (_tokens >= bonusLimit1) return 30;
      if (_tokens >= bonusLimit2) return 25;
      if (_tokens >= bonusLimit3) return 20;
      if (_tokens >= bonusLimit4) return 15;
      if (_tokens >= bonusLimit5) return 10;
    }
    if (now >= icoStartDate && now <= icoEndDate) {
      if (now <= icoStartDate + bonusPeriod) return 25;
      if (now <= icoStartDate + bonusPeriod.mul(2)) return 20;
      if (now <= icoStartDate + bonusPeriod.mul(3)) return 15;
      if (now <= icoStartDate + bonusPeriod.mul(4)) return 10;
      return 5;
    }
    return 0;
  }

  function mint (address _to, uint256 _amount) public returns (bool) {
    _amount = _amount.mul(1e4);
    require(totalSupply_.add(_amount) <= totalTokens);
    return super.mint(_to, _amount);
  }

  function () public payable {
    require(now >= preIcoStartDate);
    uint256 tokens = msg.value.mul(1e4).div(basePrice);
    uint256 bonuses = getBonuses(tokens);
    uint256 extraTokens = tokens.mul(bonuses).div(100);
    tokens = tokens.add(extraTokens);
    require(totalSupply_.add(tokens) <= totalTokens);
    balances[msg.sender] = balances[msg.sender].add(tokens);
    totalSupply_ = totalSupply_.add(tokens);
    contribution[msg.sender] = contribution[msg.sender].add(msg.value);
    weiRaised = weiRaised.add(msg.value);
    require(weiRaised <= hardCap);
    if (now > icoEndDate || weiRaised > hardCap) {
      wallet.transfer(msg.value);
    } else if (weiRaised >= softCap) {
      owner.transfer(msg.value);
    }
    emit Transfer(address(this), msg.sender, tokens);
  }

  function getEther () public onlyOwner {
    require(now > refundEndDate || weiRaised >= softCap);
    require(address(this).balance > 0);
    owner.transfer(address(this).balance);
  }

  function setRefundPercent (uint256 _percent) public onlyOwner {
    require(_percent > 0);
    require(_percent <= 100);
    refundPercent = _percent;
  }

  function getRefund () public {
    require(balances[msg.sender] > 0);
    require(contribution[msg.sender] > 0);
    require(address(this).balance >= contribution[msg.sender]);
    require(now > icoEndDate);
    require(now < refundEndDate);
    require(weiRaised < softCap);
    uint256 refund = contribution[msg.sender].mul(refundPercent).div(100);
    contribution[msg.sender] = 0;
    balances[msg.sender] = 0;
    msg.sender.transfer(refund);
  }
}

contract FBC is CrowdsaleToken {
  string public constant name = "Feon Bank Coin";
  string public constant symbol = "FBC";
  uint32 public constant decimals = 4;
}