 

pragma solidity ^0.4.23;
 
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


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }


   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  address master;

  bool public paused;


  modifier isMaster {
      require(msg.sender == master);
      _;
  }

  modifier isPause {
   require(paused == true);
   _;
 }

  modifier isNotPause {
   require(paused == false);
   _;
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

   
  function approve(address _spender, uint256 _value) public isNotPause returns (bool) {
    require(_spender != address(0));
    require(balanceOf(msg.sender) >= _value);
    require (balanceOf(_spender) + _value > balanceOf(_spender));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public isNotPause
    returns (bool)
  {
    require(_spender != address(0));
    require(balanceOf(msg.sender) >= _addedValue);
    require (allowed[msg.sender][_spender] + _addedValue > allowed[msg.sender][_spender]);
    allowed[msg.sender][_spender] = (
    allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public isNotPause
    returns (bool)
  {
    require(_spender != address(0));
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


contract NToken is StandardToken {

  string public constant name = "NToken";
  string public constant symbol = "NT";
  uint8 public constant decimals = 8;

  uint256 public constant INITIAL_SUPPLY = 660000000 * (10 ** uint256(decimals));
  address coinbase;

  address private constant project_foundation_address     = 0x9F9bed103cCa9352C7a69A05f7b789a9fC32f5C7;
  uint8   private constant project_foundation_percent     = 10;
  uint256 private constant project_foundation_starttime   = 1558627200;
  uint256 private constant project_foundation_interval    = 94608000;
  uint256 private constant project_foundation_periods     = 1;



  address private constant community_reward_address       = 0x9F9bed103cCa9352C7a69A05f7b789a9fC32f5C7;
  uint8   private constant community_reward_percent       = 90;





  struct Vesting {
    uint256 startTime;
    uint256 initReleaseAmount;
    uint256 amount;
    uint256 interval;
    uint256 periods;
    uint256 withdrawed;
  }

  mapping (address => Vesting[]) vestings;

  event AssetLock(address indexed to,uint256 startTime,uint256 initReleaseAmount,uint256 amount,uint256 interval,uint256 periods);
   
  constructor(address _master) public {
   require(_master != address(0));
   totalSupply_ = INITIAL_SUPPLY;
   master = _master;
   paused = false;
   coinbase = _master;
   balances[coinbase] = INITIAL_SUPPLY;

  
   uint256 balance_project = INITIAL_SUPPLY * project_foundation_percent / 100;
   assetLock(project_foundation_address,project_foundation_starttime,0,balance_project,project_foundation_interval,project_foundation_periods);

   uint256 balance_community_reward = INITIAL_SUPPLY * community_reward_percent / 100;
   balances[community_reward_address] = balance_community_reward;
   balances[coinbase] =  balances[coinbase].sub(balance_community_reward);


 }


  function assetLock(address _to,uint256 _startTime,uint256 _initReleaseAmount,uint256 _amount,uint256 _interval,uint256 _periods) internal {
      require(balances[coinbase] >= _amount);
      require(_initReleaseAmount <= _amount);
      vestings[_to].push(Vesting(_startTime, _initReleaseAmount, _amount, _interval, _periods, 0));
      balances[coinbase] = balances[coinbase].sub(_amount);
      emit AssetLock(_to,_startTime,_initReleaseAmount,_amount,_interval,_periods);
 }

  function batchTransfer(address[] _to, uint256[] _amount) public isNotPause returns (bool) {
     for (uint i = 0; i < _to.length; i++) {
       getVesting(msg.sender);
       transfer(_to[i] , _amount[i]);
     }
     return true;
   }

    
   function transfer(address _to, uint256 _value) public isNotPause returns (bool) {
     require(_to != address(0));
     uint256 remain = availableBalance(msg.sender);
     require(_value <= remain);
     getVesting(msg.sender);
     balances[msg.sender] = balances[msg.sender].sub(_value);
     balances[_to] = balances[_to].add(_value);
     emit Transfer(msg.sender, _to, _value);
     return true;
   }


    
   function transferFrom(
     address _from,
     address _to,
     uint256 _value
   )
     public isNotPause
     returns (bool)
   {
     require(_to != address(0));
     require(_from != address(0));
     require(_value <= allowed[_from][msg.sender]);
     uint256 remain = availableBalance(_from);
     require(_value <= remain);
     getVesting(_from);
     balances[_from] = balances[_from].sub(_value);
     balances[_to] = balances[_to].add(_value);
     allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
     emit Transfer(_from, _to, _value);
     return true;
   }


   function setPause() public isMaster isNotPause{
     paused = true;
   }

   function setResume() public isMaster isPause{
     paused = false;
   }

   function pauseStatus() public view isMaster returns (bool){
     return paused;
   }


   function vestingBalance(address _owner) internal view returns (uint256) {
     uint256 sum = 0;
      for(uint i = 0 ;i < vestings[_owner].length;i++){
        sum = sum.add(vestings[_owner][i].amount.sub(vestings[_owner][i].withdrawed));
      }
      return sum;
   }

   
   function availableBalance(address _owner) public view returns (uint256) {
     uint256 sum = 0;
      for(uint i = 0 ;i < vestings[_owner].length;i++){
        Vesting memory vs = vestings[_owner][i];
        uint256 release = vestingRelease(vs.startTime,vs.initReleaseAmount, vs.amount, vs.interval, vs.periods);
        uint256 keep = release.sub(vs.withdrawed);
        if(keep >= 0){
          sum = sum.add(keep);
        }
      }
      return sum.add(balances[_owner]);
   }

    
   function allBalance(address _owner)public view returns (uint256){
     uint256 allbalance = vestingBalance(_owner);
     return allbalance.add(balances[_owner]);
   }
     
   function vestingRelease(uint256 _startTime,uint256 _initReleaseAmount,uint256 _amount,uint256 _interval,uint256 _periods) public view returns (uint256) {
    return vestingReleaseFunc(now,_startTime,_initReleaseAmount,_amount,_interval,_periods);
   }

    
  function vestingReleaseFunc(uint256 _endTime,uint256 _startTime,uint256 _initReleaseAmount,uint256 _amount,uint256 _interval,uint256 _periods) public pure  returns (uint256) {
    if (_endTime < _startTime) {
      return 0;
    }
    uint256 last = _endTime.sub(_startTime);
    uint256 allTime =  _periods.mul(_interval);
    if (last >= allTime) {
      return _amount;
    }
    uint256 eachPeriodAmount = _amount.sub(_initReleaseAmount).div(_periods);
    uint256 lastTime = last.div(_interval);
    uint256 vestingAmount = eachPeriodAmount.mul(lastTime).add(_initReleaseAmount);
    return vestingAmount;
  }



    
   function getVesting(address _to) internal {
     uint256 sum = 0;
     for(uint i=0;i< vestings[_to].length;i++){
       if(vestings[_to][i].amount == vestings[_to][i].withdrawed){
         continue;
       }else{
         Vesting  memory vs = vestings[_to][i];
         uint256 release = vestingRelease(vs.startTime,vs.initReleaseAmount, vs.amount, vs.interval, vs.periods);
         uint256 keep = release.sub(vs.withdrawed);
         if(keep >= 0){
           vestings[_to][i].withdrawed = release;
           sum = sum.add(keep);
         }
       }
     }
     if(sum > 0 ){
       balances[_to] = balances[_to].add(sum);
     }
   }

    
   function balanceOf(address _owner) public view returns (uint256) {
     return availableBalance(_owner);
   }
}