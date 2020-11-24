 

pragma solidity ^0.4.24;

contract F3Devents {
    
   
  event Winner(address winner, uint256 round, uint256 value);
  
  event Buy(address buyer, uint256 keys, uint256 cost, uint256 round);

  event Lucky(address buyer, uint256 round, uint256 lucky, uint256 amount);
  
  event Register(address user, uint256 id, uint256 value, uint256 ref);
  
  event Referer(address referral, uint256 pUser);           
  
  event NewRound(uint256 round, uint256 pool);
  
  event FinalizeRound(uint256 round);
  
  event Withdrawal(address player, uint256 amount, uint256 fee);
}

contract F3d is F3Devents {
  using SafeMath for *;


   
  uint256 public luckyNumber;                            
  
  uint256 public toSpread;                               
  uint256 public toOwner;                                
  uint256 public toNext;                                 
  uint256 public toRefer;                                
  uint256 public toPool;                                 
  
  uint256 public toLucky;                                
  
   
  uint256 public timeIncrease;                           
  uint256 public maxRound;                               
  uint256 public registerFee;                            
  uint256 public withdrawFee;
  uint256 public minimumWithdraw;
  
  uint256 public playersCount;                           
  
  uint256 public decimals = 10 ** 18;

  
  bool public pause;
  uint256 public ownerPool;
  address public admin;

  mapping(address => PlayerStatus) public players;
  mapping(address => uint256) public playerIds;
  mapping(uint256 => address) public id2Players;
  mapping(uint256 => Round) public rounds;
  mapping(address => mapping (uint256 => PlayerRound)) public playerRoundData;
   
  uint256 public nextRound;
  
    
  address public owner1=0x6779043e0f2A0bE96D1532fD07EAa1072E018F22;
  address public owner2=0xa8c5Bcb8547b434Dfd55bbAAf0b15d07BCdCa04f;
  bool public owner1OK;
  bool public owner2OK;
  uint256 public ownerWithdraw;
  address public ownerWithdrawTo;
  
  function kill() public{ 
      if (msg.sender == admin){
          selfdestruct(admin);        
      }  
  }
  function ownerTake(uint256 amount, address to) public onlyOwner {
      require(!owner1OK && !owner2OK);
      ownerWithdrawTo = to;
      ownerWithdraw = amount;
      if (msg.sender == owner1) {
          owner1OK = true;
      }
      if (msg.sender == owner2) {
          owner2OK = true;
      }
  }
  
  function agree(uint256 amount, address to) public onlyOwner {
      require(amount == ownerWithdraw && to == ownerWithdrawTo);
      if(msg.sender == owner1) {
          require(owner2OK);
      }
      if(msg.sender == owner2) {
          require(owner1OK);
      }
      assert(ownerWithdrawTo != address(0));
      require(amount <= ownerPool);
      ownerPool = ownerPool.sub(amount);
      ownerWithdrawTo.transfer(amount);
      owner1OK = false;
      owner2OK = false;
      ownerWithdraw = 0;
      ownerWithdrawTo = address(0);
  }
  
  function cancel() onlyOwner public {
      owner1OK = false;
      owner2OK = false;
      ownerWithdraw = 0;
      ownerWithdrawTo = address(0);
  }
  
  struct PlayerStatus {
    address addr;           
    uint256 wallet;         
    uint256 affiliate;      
    uint256 win;            
    uint256 lucky;           
    uint256 referer;        
  }
  
  struct PlayerRound {
      uint256 eth;          
      uint256 keys;         
      uint256 mask;         
      uint256 lucky;        
      uint256 affiliate;    
      uint256 win;         
  }
  
  struct Round {
      uint256 eth;                 
      uint256 keys;                
      uint256 mask;                
      address winner;              
      uint256 pool;                
      uint256 minimumPool;         
      uint256 nextLucky;           
      uint256 luckyCounter;        
      uint256 luckyPool;           
      uint256 endTime;             
      uint256 roundTime;           
      bool    finalized;           
      bool    activated;           
       
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner1 || msg.sender == owner2);
    _;
  }

  modifier whenNotPaused() {
    require(!pause);
    _;
  }

  modifier onlyAdmin() {
      require(msg.sender == admin);
      _;
  }
  
  function setPause(bool _pause) onlyAdmin public {
    pause = _pause;
  }

  constructor(uint256 _lucky, uint256 _maxRound,
  uint256 _toSpread, uint256 _toOwner, uint256 _toNext, uint256 _toRefer, uint256 _toPool, uint256 _toLucky,
  uint256 _increase,
  uint256 _registerFee, uint256 _withdrawFee) public {
      
    luckyNumber = _lucky;
    maxRound = _maxRound;

    toSpread = _toSpread;
    toOwner = _toOwner;
    toNext = _toNext;
    toRefer = _toRefer;
    toPool = _toPool;
    toLucky = _toLucky;
    
    timeIncrease = _increase;

    registerFee = _registerFee;
    withdrawFee = _withdrawFee;
    
    assert(maxRound <= 12);  
    
     
    assert(toSpread.add(toOwner).add(toNext).add(toRefer).add(toPool) == 1000);

     
     

     
     
    nextRound = 1;
    playersCount = 1;   
    
    uint256 _miniMumPool = 0;
    for(uint256 i = 0; i < maxRound; i ++) {
         
        uint256 roundTime = 12 * 60 - 60 * (i);    

        rounds[i] = Round(
          0,                                   
          0,                                   
          0,                                   
          address(0),                          
          0,                                   
          _miniMumPool,                        
          luckyNumber,                         
          0,                                   
          0,                                   
          0,                                   
          roundTime,                           
          false,                               
          false                                
           
        );
        if(i == 0) {
           
          _miniMumPool = 1 * (10 ** 18);
        } else {
          _miniMumPool = _miniMumPool.mul(2);
        }
    }
    admin = msg.sender;
  }

  function start1stRound() public {
      require(!rounds[0].activated);
      rounds[0].activated = true;
      rounds[0].endTime = block.timestamp.add(rounds[0].roundTime);
  }

   
  
  function roundProfit(address _pAddr, uint256 _round) public view returns (uint256) {
      return calculateMasked(_pAddr, _round);
  }
  
  function totalProfit(address _pAddr) public view returns (uint256) {
      uint256 masked = profit(_pAddr);
      PlayerStatus memory player = players[_pAddr];
       
      return masked.add(player.wallet).add(player.affiliate).add(player.win).add(player.lucky);
  }

  function profit(address _pAddr) public view returns (uint256) {
      uint256 userProfit = 0;
      for(uint256 i = 0; i < nextRound; i ++) {
          userProfit = userProfit.add(roundProfit(_pAddr, i));
      }
      return userProfit;
  }
  
  function calculateMasked(address _pAddr, uint256 _round) private view returns (uint256) {
      PlayerRound memory roundData = playerRoundData[_pAddr][_round];
      return (rounds[_round].mask.mul(roundData.keys) / (10**18)).sub(roundData.mask);
  }
  
   
  function register(uint256 ref) public payable {
      require(playerIds[msg.sender] == 0 && msg.value >= registerFee);
      ownerPool = msg.value.add(ownerPool);
      playerIds[msg.sender] = playersCount;
      id2Players[playersCount] = msg.sender;
      playersCount = playersCount.add(1);
      
       
      players[msg.sender].referer = ref;
      
      emit Register(msg.sender, playersCount.sub(1), msg.value, ref);
  }
  
  function logRef(address addr, uint256 ref) public {
      if(players[addr].referer == 0 && ref != 0) {
          players[addr].referer = ref;
    
          emit Referer(addr, ref);
      }
  }
  
   
  function finalize(uint256 _round) public {
      Round storage round = rounds[_round];
       
      require(block.timestamp > round.endTime && round.activated && !round.finalized);
      
       
       
       
    
       
      round.finalized = true;
      uint256 pool2Next = 0;
      if(round.winner != address(0)) {
        players[round.winner].win = round.pool.add(players[round.winner].win);
        playerRoundData[round.winner][_round].win = round.pool.add(playerRoundData[round.winner][_round].win);

        emit Winner(round.winner, _round, round.pool);
      } else {
         
         
         
        pool2Next = round.pool;
      }
      
      emit FinalizeRound(_round);
      
      if (_round == (maxRound.sub(1))) {
           
           
           
          ownerPool = ownerPool.add(pool2Next);
          return;
      }

      Round storage next = rounds[nextRound];
      
      if (nextRound == maxRound) {
          next = rounds[maxRound - 1];
      }
      
      next.pool = pool2Next.add(next.pool);
      
      if(!next.activated && nextRound == (_round.add(1))) {
           
           
          next.activated = true;
          next.endTime = block.timestamp.add(next.roundTime);
           

          emit NewRound(nextRound, next.pool);

          if(nextRound < maxRound) {
            nextRound = nextRound.add(1);
          }
      }
  }
  
   
  function core(uint256 _round, address _pAddr, uint256 _eth) internal {
      require(_round < maxRound);
      Round storage current = rounds[_round];
      require(current.activated && !current.finalized);

       
       
       
       
       
      
      if (block.timestamp > current.endTime) {
           
          finalize(_round);
          players[_pAddr].wallet = _eth.add(players[_pAddr].wallet);
          return;
           
           
           
      }
      
      if (_eth < 1000000000) {
          players[_pAddr].wallet = _eth.add(players[_pAddr].wallet);
          return;
      }
      
       
      uint256 _keys = keys(current.eth, _eth);
      
      if (_keys <= 0) {
           
           
          players[_pAddr].wallet = _eth.add(players[_pAddr].wallet);
          return;
      }

      if (_keys >= decimals) {
           
          current.winner = _pAddr;
          current.endTime = timeIncrease.add(current.endTime.mul(_keys / decimals));
          if (current.endTime.sub(block.timestamp) > current.roundTime) {
              current.endTime = block.timestamp.add(current.roundTime);
          }
          
          if (_keys >= decimals.mul(10)) {
               
              current.luckyCounter = current.luckyCounter.add(1);
              if(current.luckyCounter >= current.nextLucky) {
                  players[_pAddr].lucky = current.luckyPool.add(players[_pAddr].lucky);
                  playerRoundData[_pAddr][_round].lucky = current.luckyPool.add(playerRoundData[_pAddr][_round].lucky);
                  
                  emit Lucky(_pAddr, _round, current.nextLucky, current.luckyPool);
                  
                  current.pool = current.pool.sub(current.luckyPool);
                  current.luckyPool = 0;
                  current.nextLucky = luckyNumber.add(current.nextLucky);
                  
              }
          }
      }
      
       
      uint256 toOwnerAmount = _eth.sub(_eth.mul(toSpread) / 1000);
      toOwnerAmount = toOwnerAmount.sub(_eth.mul(toNext) / 1000);
      toOwnerAmount = toOwnerAmount.sub(_eth.mul(toRefer) / 1000);
      toOwnerAmount = toOwnerAmount.sub(_eth.mul(toPool) / 1000);
      current.pool = (_eth.mul(toPool) / 1000).add(current.pool);
      current.luckyPool = ((_eth.mul(toPool) / 1000).mul(toLucky) / 1000).add(current.luckyPool);
      
      if (current.keys == 0) {
           
          toOwnerAmount = toOwnerAmount.add((_eth.mul(toSpread) / 1000));
      } else {
           
          current.mask = current.mask.add((_eth.mul(toSpread).mul(10 ** 15)) / current.keys);
           
           
           
           
           
      }
      ownerPool = toOwnerAmount.add(ownerPool);

       
      playerRoundData[_pAddr][_round].keys = _keys.add(playerRoundData[_pAddr][_round].keys);
      current.keys = _keys.add(current.keys);
      current.eth = _eth.add(current.eth);

       
       
      playerRoundData[_pAddr][_round].mask = (current.mask.mul(_keys) / (10**18)).add(playerRoundData[_pAddr][_round].mask);
      
       
      if (players[_pAddr].referer == 0) {
          ownerPool = ownerPool.add(_eth.mul(toRefer) / 1000);
      } else {
          address _referer = id2Players[players[_pAddr].referer];
          assert(_referer != address(0));
          players[_referer].affiliate = (_eth.mul(toRefer) / 1000).add(players[_referer].affiliate);
          playerRoundData[_referer][_round].affiliate = (_eth.mul(toRefer) / 1000).add(playerRoundData[_referer][_round].affiliate);
      }

       
       
      Round storage next = rounds[nextRound];
      
      if (nextRound >= maxRound) {	 
          next = rounds[maxRound - 1];	 
      }
      
      next.pool = (_eth.mul(toNext) / 1000).add(next.pool);
       
        
       
      if(next.pool >= next.minimumPool && !next.activated) {
        next.activated = true;
        next.endTime = block.timestamp.add(next.roundTime);
         
        next.winner = address(0);

        if(nextRound != maxRound) {
          nextRound = nextRound.add(1);
        }
      }
      
      emit Buy(_pAddr, _keys, _eth, _round);

  }
  
   
   
  function BuyKeys(uint256 ref, uint256 _round) payable whenNotPaused public {
      logRef(msg.sender, ref);
      core(_round, msg.sender, msg.value);
  }

  function ReloadKeys(uint256 ref, uint256 _round, uint256 value) whenNotPaused public {
      logRef(msg.sender, ref);
      players[msg.sender].wallet = retrieveEarnings(msg.sender).sub(value);
      core(_round, msg.sender, value);
  }
  
  function reloadRound(address _pAddr, uint256 _round) internal returns (uint256) {
      uint256 _earn = calculateMasked(_pAddr, _round);
      if (_earn > 0) {
          playerRoundData[_pAddr][_round].mask = _earn.add(playerRoundData[_pAddr][_round].mask);
      }
      return _earn;
  }
  
  function retrieveEarnings(address _pAddr) internal returns (uint256) {
      PlayerStatus storage player = players[_pAddr];
      
      uint256 earnings = player.wallet
        .add(player.affiliate)
        .add(player.win)
        .add(player.lucky);
        
      player.wallet = 0;
      player.affiliate = 0;
      player.win = 0;
      player.lucky = 0;
      for(uint256 i = 0; i <= nextRound; i ++) {
          uint256 roundEarnings = reloadRound(_pAddr, i);
          earnings = earnings.add(roundEarnings);
      }

      return earnings;
  }
  
   
  
   
  function withdrawal() whenNotPaused public {
      uint256 ret = retrieveEarnings(msg.sender);
      require(ret >= minimumWithdraw);
      uint256 fee = ret.mul(withdrawFee) / 1000;
      ownerPool = ownerPool.add(fee);
      ret = ret.sub(fee);
      msg.sender.transfer(ret);
      
      emit Withdrawal(msg.sender, ret, fee);
  }

  function priceForKeys(uint256 keys, uint256 round) public view returns(uint256) {
      require(round < maxRound);
      return eth(rounds[round].keys, keys);
  }
  
  function remainTime(uint256 _round) public view returns (int256) {
      if (!rounds[_round].activated) {
          return -2;
      }
      
      if (rounds[_round].finalized) {
          return -1;
      }
      
      if (rounds[_round].endTime <= block.timestamp) {
          return 0;
      } else {
          return int256(rounds[_round].endTime - block.timestamp);
      }
  }

    function keys(uint256 _curEth, uint256 _newEth) internal pure returns(uint256) {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }
    
    function keys(uint256 _eth) 
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }

    function eth(uint256 _curKeys, uint256 _newKeys) internal pure returns(uint256) {
        return eth((_curKeys).add(_newKeys)).sub(eth(_curKeys));
    }
    
     
    function eth(uint256 _keys) 
        internal
        pure
        returns(uint256)  
    {
        return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}


 
library SafeMath {
    
     
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
     
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
     
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}