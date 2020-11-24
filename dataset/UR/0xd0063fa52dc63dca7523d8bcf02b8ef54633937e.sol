 

pragma solidity ^0.4.24;

 

 
contract FlyToTheMarsEvents {

   
  event onFirStage
  (
    address indexed player,
    uint256 indexed rndNo,
    uint256 keys,
    uint256 eth,
    uint256 timeStamp
  );

   
  event onSecStage
  (
    address indexed player,
    uint256 indexed rndNo,
    uint256 eth,
    uint256 timeStamp
  );

   
  event onWithdraw
  (
    address indexed player,
    uint256 indexed rndNo,
    uint256 eth,
    uint256 timeStamp
  );

   
  event onAward
  (
    address indexed player,
    uint256 indexed rndNo,
    uint256 eth,
    uint256 timeStamp
  );
}

 
contract FlyToTheMars is FlyToTheMarsEvents {

  using SafeMath for *;            
  using KeysCalc for uint256;      

   
  struct Round {
    uint256 eth;         
    uint256 keys;        
    uint256 startTime;   
    uint256 endTime;     
    address leader;      
    uint256 lastPrice;   
    bool award;          
  }

   
  struct PlayerRound {
    uint256 eth;         
    uint256 keys;        
    uint256 withdraw;    
  }

  uint256 public rndNo = 1;                                    
  uint256 public totalEth = 0;                                 

  uint256 constant private rndFirStage_ = 12 hours;            
  uint256 constant private rndSecStage_ = 12 hours;            

  mapping(uint256 => Round) public round_m;                   
  mapping(uint256 => mapping(address => PlayerRound)) public playerRound_m;    

  address public owner;                
  uint256 public ownerWithdraw = 0;    

   
  constructor()
    public
  {
     
    round_m[1].startTime = now;
    round_m[1].endTime = now + rndFirStage_;

     
    owner = msg.sender;
  }

   
  modifier onlyHuman()
  {
    address _addr = msg.sender;
    uint256 _codeLength;

    assembly {_codeLength := extcodesize(_addr)}
    require(_codeLength == 0, "sorry humans only");
    _;
  }

   
  modifier isWithinLimits(uint256 _eth)
  {
    require(_eth >= 1000000000, "pocket lint: not a valid currency");  
    require(_eth <= 100000000000000000000000, "no vitalik, no");  
    _;
  }

   
  modifier onlyOwner()
  {
    require(owner == msg.sender, "only owner can do it");
    _;
  }

   
  function()
  onlyHuman()
  isWithinLimits(msg.value)
  public
  payable
  {
    uint256 _eth = msg.value;      
    uint256 _now = now;            
    uint256 _rndNo = rndNo;        
    uint256 _ethUse = msg.value;   

     
    if (_now > round_m[_rndNo].endTime)
    {
      _rndNo = _rndNo.add(1);      
      rndNo = _rndNo;

      round_m[_rndNo].startTime = _now;
      round_m[_rndNo].endTime = _now + rndFirStage_;
    }

     
    if (round_m[_rndNo].keys < 10000000000000000000000000)
    {
       
      uint256 _keys = (round_m[_rndNo].eth).keysRec(_eth);

       
      if (_keys.add(round_m[_rndNo].keys) >= 10000000000000000000000000)
      {
         
        _keys = (10000000000000000000000000).sub(round_m[_rndNo].keys);

         
        if (round_m[_rndNo].eth >= 8562500000000000000000)
        {
          _ethUse = 0;
        } else {
          _ethUse = (8562500000000000000000).sub(round_m[_rndNo].eth);
        }

         
        if (_eth > _ethUse)
        {
           
          msg.sender.transfer(_eth.sub(_ethUse));
        } else {
           
          _ethUse = _eth;
        }
      }

       
      if (_keys >= 1000000000000000000)
      {
        round_m[_rndNo].endTime = _now + rndFirStage_;
        round_m[_rndNo].leader = msg.sender;
      }

       
      playerRound_m[_rndNo][msg.sender].keys = _keys.add(playerRound_m[_rndNo][msg.sender].keys);
      playerRound_m[_rndNo][msg.sender].eth = _ethUse.add(playerRound_m[_rndNo][msg.sender].eth);

       
      round_m[_rndNo].keys = _keys.add(round_m[_rndNo].keys);
      round_m[_rndNo].eth = _ethUse.add(round_m[_rndNo].eth);

       
      totalEth = _ethUse.add(totalEth);

       
      emit FlyToTheMarsEvents.onFirStage
      (
        msg.sender,
        _rndNo,
        _keys,
        _ethUse,
        _now
      );
    } else {
       

       
       
      uint256 _lastPrice = round_m[_rndNo].lastPrice;
      uint256 _maxPrice = (10000000000000000000).add(_lastPrice);

       
       
      require(_eth >= (100000000000000000).add(_lastPrice), "Need more Ether");

       
       
      if (_eth > _maxPrice)
      {
        _ethUse = _maxPrice;

         
        msg.sender.transfer(_eth.sub(_ethUse));
      }

       
      round_m[_rndNo].endTime = _now + rndSecStage_;
      round_m[_rndNo].leader = msg.sender;
      round_m[_rndNo].lastPrice = _ethUse;

       
      playerRound_m[_rndNo][msg.sender].eth = _ethUse.add(playerRound_m[_rndNo][msg.sender].eth);

       
      round_m[_rndNo].eth = _ethUse.add(round_m[_rndNo].eth);

       
      totalEth = _ethUse.add(totalEth);

       
      emit FlyToTheMarsEvents.onSecStage
      (
        msg.sender,
        _rndNo,
        _ethUse,
        _now
      );
    }
  }

   
  function withdrawByRndNo(uint256 _rndNo)
  onlyHuman()
  public
  {
    require(_rndNo <= rndNo, "You're running too fast");                       

     
    uint256 _total = (((round_m[_rndNo].eth).mul(playerRound_m[_rndNo][msg.sender].keys)).mul(60) / ((round_m[_rndNo].keys).mul(100)));
    uint256 _withdrawed = playerRound_m[_rndNo][msg.sender].withdraw;

    require(_total > _withdrawed, "No need to withdraw");                      

    uint256 _ethOut = _total.sub(_withdrawed);                                 
    playerRound_m[_rndNo][msg.sender].withdraw = _total;                       

    msg.sender.transfer(_ethOut);                                              

     
    emit FlyToTheMarsEvents.onWithdraw
    (
      msg.sender,
      _rndNo,
      _ethOut,
      now
    );
  }

   
  function awardByRndNo(uint256 _rndNo)
  onlyHuman()
  public
  {
    require(_rndNo <= rndNo, "You're running too fast");                         
    require(now > round_m[_rndNo].endTime, "Wait patiently");                    
    require(round_m[_rndNo].leader == msg.sender, "The prize is not yours");     
    require(round_m[_rndNo].award == false, "Can't get prizes repeatedly");      

    uint256 _ethOut = ((round_m[_rndNo].eth).mul(35) / (100));   
    round_m[_rndNo].award = true;                                
    msg.sender.transfer(_ethOut);                                

     
    emit FlyToTheMarsEvents.onAward
    (
      msg.sender,
      _rndNo,
      _ethOut,
      now
    );
  }

   
  function feeWithdraw()
  onlyHuman()
  public
  {
    uint256 _total = (totalEth.mul(5) / (100));            
    uint256 _withdrawed = ownerWithdraw;                   

    require(_total > _withdrawed, "No need to withdraw");  

    ownerWithdraw = _total;                                
    owner.transfer(_total.sub(_withdrawed));               
  }

   
  function changeOwner(address newOwner)
  onlyOwner()
  public
  {
    owner = newOwner;
  }

   
  function getCurrentRoundInfo()
  public
  view
  returns (uint256, uint256, uint256, uint256, uint256, address, uint256, uint256)
  {

    uint256 _rndNo = rndNo;

    return (
    _rndNo,
    round_m[_rndNo].eth,
    round_m[_rndNo].keys,
    round_m[_rndNo].startTime,
    round_m[_rndNo].endTime,
    round_m[_rndNo].leader,
    round_m[_rndNo].lastPrice,
    getBuyPrice()
    );
  }

   
  function getBuyPrice()
  public
  view
  returns (uint256)
  {
    uint256 _rndNo = rndNo;
    uint256 _now = now;

     
    if (_now > round_m[_rndNo].endTime)
    {
      return (75000000000000);
    }
    if (round_m[_rndNo].keys < 10000000000000000000000000)
    {
      return ((round_m[_rndNo].keys.add(1000000000000000000)).ethRec(1000000000000000000));
    }
     
    return (0);
  }
}

 
library KeysCalc {

   
  using SafeMath for *;

   
  function keysRec(uint256 _curEth, uint256 _newEth)
  internal
  pure
  returns (uint256)
  {
    return (keys((_curEth).add(_newEth)).sub(keys(_curEth)));
  }

   
  function ethRec(uint256 _curKeys, uint256 _sellKeys)
  internal
  pure
  returns (uint256)
  {
    return ((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
  }

   
  function keys(uint256 _eth)
  internal
  pure
  returns (uint256)
  {
    return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
  }

   
  function eth(uint256 _keys)
  internal
  pure
  returns (uint256)
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
    uint256 z = ((add(x, 1)) / 2);
    y = x;
    while (z < y)
    {
      y = z;
      z = ((add((x / z), z)) / 2);
    }
  }

   
  function sq(uint256 x)
  internal
  pure
  returns (uint256)
  {
    return (mul(x, x));
  }

   
  function pwr(uint256 x, uint256 y)
  internal
  pure
  returns (uint256)
  {
    if (x == 0)
      return (0);
    else if (y == 0)
      return (1);
    else
    {
      uint256 z = x;
      for (uint256 i = 1; i < y; i++)
        z = mul(z, x);
      return (z);
    }
  }
}