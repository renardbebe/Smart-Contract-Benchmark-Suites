 

pragma solidity 0.4.25;


 



library Percent {
   
  struct percent {
    uint num;
    uint den;
  }
  
   
  function mul(percent storage p, uint a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint a) internal view returns (uint) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint a) internal view returns (uint) {
    uint b = mul(p, a);
    if (b >= a) {
      return 0;
    }
    return a - b;
  }

  function add(percent storage p, uint a) internal view returns (uint) {
    return a + mul(p, a);
  }

  function toMemory(percent storage p) internal view returns (Percent.percent memory) {
    return Percent.percent(p.num, p.den);
  }

   
  function mmul(percent memory p, uint a) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function mdiv(percent memory p, uint a) internal pure returns (uint) {
    return a/p.num*p.den;
  }

  function msub(percent memory p, uint a) internal pure returns (uint) {
    uint b = mmul(p, a);
    if (b >= a) {
      return 0;
    }
    return a - b;
  }

  function madd(percent memory p, uint a) internal pure returns (uint) {
    return a + mmul(p, a);
  }
}


contract Accessibility {
  enum AccessRank { None, PayIn, Manager, Full }
  mapping(address => AccessRank) public admins;
  modifier onlyAdmin(AccessRank  r) {
    require(
      admins[msg.sender] == r || admins[msg.sender] == AccessRank.Full,
      "access denied"
    );
    _;
  }
  event LogProvideAccess(address indexed whom, AccessRank rank, uint when);

  constructor() public {
    admins[msg.sender] = AccessRank.Full;
    emit LogProvideAccess(msg.sender, AccessRank.Full, now);
  }

  function provideAccess(address addr, AccessRank rank) public onlyAdmin(AccessRank.Manager) {
    require(rank <= AccessRank.Manager, "cannot to give full access rank");
    if (admins[addr] != rank) {
      admins[addr] = rank;
      emit LogProvideAccess(addr, rank, now);
    }
  }
}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}



library Timer {
  struct timer {
    uint startup;
    uint duration;
  }
  function start(timer storage t, uint duration) internal {
    t.startup = now;
    t.duration = duration;
  }

  function timeLeft(timer storage t) internal view returns (uint) {
    if (now >= t.startup + t.duration) {
      return 0;
    }
    return t.startup + t.duration - now;
  }
}




contract LastHero is Accessibility {
  using Percent for Percent.percent;
  using Timer for Timer.timer;
  
  Percent.percent public bankPercent = Percent.percent(50, 100);
  Percent.percent public nextLevelPercent = Percent.percent(33, 100);
  Percent.percent public adminsPercent = Percent.percent(17, 100);

  bool public isActive;
  uint public nextLevelBankAmount;
  uint private m_bankAmount;
  uint public jackpot;
  uint public level;
  uint public constant betDuration = 5 minutes;
  address public adminsAddress;
  address public bettor;
  Timer.timer public timer;

  modifier notFromContract() {
    require(msg.sender == tx.origin, "only externally accounts");
    _;

     
  }

  event LogSendExcessOfEther(address indexed addr, uint excess, uint when);
  event LogNewWinner(address indexed addr, uint indexed level, uint amount, uint when);
  event LogNewLevel(uint indexed level, uint bankAmount, uint when);
  event LogNewBet(address indexed addr, uint indexed amount, uint duration, uint indexed level, uint when);


  constructor() public {
    adminsAddress = msg.sender;
    timer.duration = uint(-1);  
    nextLevel();
  }

  function() external payable {
    if (admins[msg.sender] == AccessRank.PayIn) {
      if (level <= 3) {
        increaseJackpot();
      } else {
        increaseBank();
      }
      return ;
    }

    bet();
  }

  function timeLeft() external view returns(uint duration) {
    duration = timer.timeLeft();
  }

  function setAdminsAddress(address addr) external onlyAdmin(AccessRank.Full) {
    require(addr != address(0), "require not zero address");
    adminsAddress = addr;
  }

  function activate() external onlyAdmin(AccessRank.Full) {
    isActive = true;
  }

  function betAmountAtNow() public view returns(uint amount) {
    uint balance = address(this).balance;

     
     
     

    if (balance < 100 ether) {
      amount = 0.01 ether;
    } else if (100 ether <= balance && balance <= 200 ether) {
      amount = 0.02 ether;
    } else {
      amount = 0.03 ether;
    }
  }
  
  function bankAmount() public view returns(uint) {
    if (level <= 3) {
      return jackpot;
    }
    return m_bankAmount;
  }

  function bet() public payable notFromContract {
    require(isActive, "game is not active");

    if (timer.timeLeft() == 0) {
      uint win = bankAmount();
      if (bettor.send(win)) {
        emit LogNewWinner(bettor, level, win, now);
      }

      if (level > 3) {
        m_bankAmount = nextLevelBankAmount;
        nextLevelBankAmount = 0;
      }

      nextLevel();
    }

    uint betAmount = betAmountAtNow();
    require(msg.value >= betAmount, "too low msg value");
    timer.start(betDuration);
    bettor = msg.sender;

    uint excess = msg.value - betAmount;
    if (excess > 0) {
      if (bettor.send(excess)) {
        emit LogSendExcessOfEther(bettor, excess, now);
      }
    }
 
    nextLevelBankAmount += nextLevelPercent.mul(betAmount);
    m_bankAmount += bankPercent.mul(betAmount);
    adminsAddress.send(adminsPercent.mul(betAmount));

    emit LogNewBet(bettor, betAmount, betDuration, level, now);
  }

  function increaseJackpot() public payable onlyAdmin(AccessRank.PayIn) {
    require(level <= 3, "jackpots only on first three levels");
    jackpot += msg.value / (4 - level);  
  }

  function increaseBank() public payable onlyAdmin(AccessRank.PayIn) {
    require(level > 3, "bank amount only above three level");
    m_bankAmount += msg.value;
    if (jackpot > 0) {
      m_bankAmount += jackpot;
      jackpot = 0;
    }
  }

  function nextLevel() private {
    level++;
    emit LogNewLevel(level, m_bankAmount, now);
  }
}