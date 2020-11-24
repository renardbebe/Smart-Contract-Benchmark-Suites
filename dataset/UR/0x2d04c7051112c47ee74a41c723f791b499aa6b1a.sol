 

pragma solidity ^0.4.24;
 
 
 
 
 
 
 
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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
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

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
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


 
contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
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
 
 
 


  
contract LotteryInterface {
  function checkLastMintData(address addr) external;   
  function getLastMintAmount(address addr) view external returns(uint256, uint256);
  function getReferrerEarnings(address addr) view external returns(uint256);
  function checkReferrerEarnings(address addr) external;
  function deposit() public payable;
}

 
contract YHToken is StandardBurnableToken, Ownable {
  string public constant name = "YHToken";
  string public constant symbol = "YHT";
  uint8 public constant decimals = 18;
  
  uint256 constant private kAutoCombineBonusesCount = 50;            
  
  struct Bonus {                                                                    
    uint256 payment;                                                 
    uint256 currentTotalSupply;                                      
  }
  
  struct BalanceSnapshot {
    uint256 balance;                                                 
    uint256 bonusIdBegin;                                            
    uint256 bonusIdEnd;                                              
  }
  
  struct User {
    uint256 extraEarnings;                                              
    uint256 bonusEarnings;
    BalanceSnapshot[] snapshots;                                     
    uint256 snapshotsLength;                                         
  }
  
  LotteryInterface public Lottery;
  uint256 public bonusRoundId_;                                      
  mapping(address => User) public users_;                            
  mapping(uint256 => Bonus) public bonuses_;                         
    
  event Started(address lottery);
  event AddTotalSupply(uint256 addValue, uint256 total);
  event AddExtraEarnings(address indexed from, address indexed to, uint256 amount);
  event AddBonusEarnings(address indexed from, uint256 amount, uint256 bonusId, uint256 currentTotalSupply);
  event Withdraw(address indexed addr, uint256 amount);

  constructor() public {
    totalSupply_ = 0;       
    bonusRoundId_ = 1;
  }

   
  modifier isLottery() {
    require(msg.sender == address(Lottery)); 
    _;
  }
  
   
  function start(address lottery) onlyOwner public {
    require(Lottery == address(0));
    Lottery = LotteryInterface(lottery);
    emit Started(lottery);
  }
  
    
  function balanceSnapshot(address addr, uint256 bonusRoundId) private {
    uint256 currentBalance = balances[addr];     
    User storage user = users_[addr];   
    if (user.snapshotsLength == 0) {
      user.snapshotsLength = 1;
      user.snapshots.push(BalanceSnapshot(currentBalance, bonusRoundId, 0));
    }
    else {
      BalanceSnapshot storage lastSnapshot = user.snapshots[user.snapshotsLength - 1];
      assert(lastSnapshot.bonusIdEnd == 0);
      
       
      if (lastSnapshot.bonusIdBegin == bonusRoundId) {
        lastSnapshot.balance = currentBalance;      
      }
      else {
        assert(lastSnapshot.bonusIdBegin < bonusRoundId);
        
         
        if (bonusRoundId - lastSnapshot.bonusIdBegin < kAutoCombineBonusesCount) {
           uint256 amount = computeRoundBonuses(lastSnapshot.bonusIdBegin, bonusRoundId, lastSnapshot.balance);
           user.bonusEarnings = user.bonusEarnings.add(amount);
           
           lastSnapshot.balance = currentBalance;
           lastSnapshot.bonusIdBegin = bonusRoundId;
           lastSnapshot.bonusIdEnd = 0;
        }
        else {
          lastSnapshot.bonusIdEnd = bonusRoundId;     
          
           
          if (user.snapshotsLength == user.snapshots.length) {
            user.snapshots.length += 1;  
          } 
          user.snapshots[user.snapshotsLength++] = BalanceSnapshot(currentBalance, bonusRoundId, 0);
        }
      }
    }
  }
  
    
  function mint(address to, uint256 amount, uint256 bonusRoundId) private {
    balances[to] = balances[to].add(amount);
    emit Transfer(address(0), to, amount); 
    balanceSnapshot(to, bonusRoundId);  
  }
  
     
  function mintToFounder(address to, uint256 amount, uint256 normalAmount) isLottery external {
    checkLastMint(to);
    uint256 value = normalAmount.add(amount);
    totalSupply_ = totalSupply_.add(value);
    emit AddTotalSupply(value, totalSupply_);
    mint(to, amount, bonusRoundId_);
  }
  
    
  function mintToNormal(address to, uint256 amount, uint256 bonusRoundId) isLottery external {
    require(bonusRoundId < bonusRoundId_);
    mint(to, amount, bonusRoundId);
  }
  
    
  function checkLastMint(address addr) private {
    Lottery.checkLastMintData(addr);  
  }

  function balanceSnapshot(address addr) private {
    balanceSnapshot(addr, bonusRoundId_);  
  }

    
  function getBalanceSnapshot(address addr, uint256 index) view public returns(uint256, uint256, uint256) {
    BalanceSnapshot storage snapshot = users_[addr].snapshots[index];
    return (
      snapshot.bonusIdBegin,
      snapshot.bonusIdEnd,
      snapshot.balance
    );
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    checkLastMint(msg.sender);
    checkLastMint(_to);
    super.transfer(_to, _value);
    balanceSnapshot(msg.sender);
    balanceSnapshot(_to);
    return true;
  } 

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    checkLastMint(_from);
    checkLastMint(_to);
    super.transferFrom(_from, _to, _value);
    balanceSnapshot(_from);
    balanceSnapshot(_to);
    return true;
  }
  
  function _burn(address _who, uint256 _value) internal {
    checkLastMint(_who);  
    super._burn(_who, _value);  
    balanceSnapshot(_who);
  } 
  
    
  function unused(uint256) pure private {} 
  
  
  function balanceOf(address _owner) public view returns (uint256) {
    (uint256 lastMintAmount, uint256 lastBonusRoundId) = Lottery.getLastMintAmount(_owner);  
    unused(lastBonusRoundId);
    return balances[_owner].add(lastMintAmount);  
  }

   
  function transferExtraEarnings(address to) external payable {
    if (msg.sender != address(Lottery)) {
      require(msg.value > 662607004);
      require(msg.value < 66740800000000000000000);
    }  
    users_[to].extraEarnings = users_[to].extraEarnings.add(msg.value);   
    emit AddExtraEarnings(msg.sender, to, msg.value);
  }
  
   
  function transferBonusEarnings() external payable returns(uint256) {
    require(msg.value > 0);
    require(totalSupply_ > 0);
    if (msg.sender != address(Lottery)) {
      require(msg.value > 314159265358979323);
      require(msg.value < 29979245800000000000000);   
    }
    
    uint256 bonusRoundId = bonusRoundId_;
    bonuses_[bonusRoundId].payment = msg.value;
    bonuses_[bonusRoundId].currentTotalSupply = totalSupply_;
    emit AddBonusEarnings(msg.sender, msg.value, bonusRoundId_, totalSupply_);
    
    ++bonusRoundId_;
    return bonusRoundId;
  }

    
  function getEarnings(address addr) view public returns(uint256) {
    User storage user = users_[addr];  
    uint256 amount;
    (uint256 lastMintAmount, uint256 lastBonusRoundId) = Lottery.getLastMintAmount(addr);
    if (lastMintAmount > 0) {
      amount = computeSnapshotBonuses(user, lastBonusRoundId);
      amount = amount.add(computeRoundBonuses(lastBonusRoundId, bonusRoundId_, balances[addr].add(lastMintAmount)));
    } else {
      amount = computeSnapshotBonuses(user, bonusRoundId_);     
    }
    uint256 referrerEarnings = Lottery.getReferrerEarnings(addr);
    return user.extraEarnings + user.bonusEarnings + amount + referrerEarnings;
  }
  
    
  function computeRoundBonuses(uint256 begin, uint256 end, uint256 balance) view private returns(uint256) {
    require(begin != 0);
    require(end != 0);  
    
    uint256 amount = 0;
    while (begin < end) {
      uint256 value = balance * bonuses_[begin].payment / bonuses_[begin].currentTotalSupply;      
      amount += value;
      ++begin;    
    }
    return amount;
  }
  
    
  function computeSnapshotBonuses(User storage user, uint256 lastBonusRoundId) view private returns(uint256) {
    uint256 amount = 0;
    uint256 length = user.snapshotsLength;
    for (uint256 i = 0; i < length; ++i) {
      uint256 value = computeRoundBonuses(
        user.snapshots[i].bonusIdBegin,
        i < length - 1 ? user.snapshots[i].bonusIdEnd : lastBonusRoundId,
        user.snapshots[i].balance);
      amount = amount.add(value);
    }
    return amount;
  }
    
    
  function combineBonuses(address addr) private {
    checkLastMint(addr);
    User storage user = users_[addr];
    if (user.snapshotsLength > 0) {
      uint256 amount = computeSnapshotBonuses(user, bonusRoundId_);
      if (amount > 0) {
        user.bonusEarnings = user.bonusEarnings.add(amount);
        user.snapshotsLength = 1;
        user.snapshots[0].balance = balances[addr];
        user.snapshots[0].bonusIdBegin = bonusRoundId_;
        user.snapshots[0].bonusIdEnd = 0;     
      }
    }
    Lottery.checkReferrerEarnings(addr);
  }
  
   
  function withdraw() public {
    combineBonuses(msg.sender);
    uint256 amount = users_[msg.sender].extraEarnings.add(users_[msg.sender].bonusEarnings);
    if (amount > 0) {
      users_[msg.sender].extraEarnings = 0;
      users_[msg.sender].bonusEarnings = 0;
      msg.sender.transfer(amount);
    }
    emit Withdraw(msg.sender, amount);
  }
  
    
  function withdrawForBet(address addr, uint256 value) isLottery external {
    combineBonuses(addr);
    uint256 extraEarnings = users_[addr].extraEarnings; 
    if (extraEarnings >= value) {
      users_[addr].extraEarnings -= value;    
    } else {
      users_[addr].extraEarnings = 0;
      uint256 remain = value - extraEarnings;
      require(users_[addr].bonusEarnings >= remain);
      users_[addr].bonusEarnings -= remain;
    }
    Lottery.deposit.value(value)();
  }
  
   
  function getUserInfos(address addr) view public returns(uint256, uint256, uint256) {
    return (
      totalSupply_,
      balanceOf(addr),
      getEarnings(addr)
    );  
  }
}