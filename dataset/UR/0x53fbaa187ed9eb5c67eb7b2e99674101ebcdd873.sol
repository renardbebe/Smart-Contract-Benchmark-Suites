 

 

pragma solidity ^0.4.24;

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
}

interface IERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
}

 
contract ElementiumVesting {
  using SafeMath for uint256;

  struct StagedLockingPlan {
    address beneficiary;
    uint256 managedAmount;
    uint256 start;
    uint256 stages;
    uint256 durationPerStage;
    uint256 releaseRatio;
    uint256 currentyStage;
    uint256 released;
  }

  uint256 private _milestone1 = 1540425600;      
  uint256 private _milestone2 = 1571961600;      
  uint256 private _durationMonth = 2592000;      
  uint256 private _durationYear = 31536000;      

   
  IERC20 private _token;

   
  uint256 private _numPlans;
  mapping (uint256 => StagedLockingPlan) private _plans;

  constructor(IERC20 token) public {
    _token = token;

     
    _addLockingPlan(
      address(0xcCDAb5791D3d11209f5bEEE58003Aa4EAb3E9b63),     
      150000000000000000,    
      _milestone2,           
      1,                     
      _durationYear,         
      0);                    

     
    _addLockingPlan(
      address(0x8D4Db0c0cB4b937523eBcfd86A8038eb0475166A),     
      250000000000000000,    
      _milestone1,           
      4,                     
      _durationMonth,        
      0);                    

     
    _addLockingPlan(
      address(0xCFc030Fb11d88772a58BFE30a296C6c215A912Bb),     
      400000000000000000,    
      _milestone1,           
      20,                    
      _durationYear,         
      4);                    
  }

  function _addLockingPlan (
    address beneficiary,
    uint256 managedAmount,
    uint256 start,
    uint256 stages,
    uint256 durationPerStage,
    uint256 releaseRatio
  ) 
    private 
  {
    require(beneficiary != address(0));
    require(managedAmount > 0);
    require(stages > 0);

    _plans[_numPlans] = StagedLockingPlan({
      beneficiary: beneficiary,
      managedAmount: managedAmount,
      start: start,
      stages: stages,
      durationPerStage: durationPerStage,
      releaseRatio: releaseRatio,
      currentyStage: 0,
      released: 0
    });
    _numPlans = _numPlans.add(1);
  }

  function _releasableAmount(uint256 i, uint256 nextStage) private view returns (uint256) {
    uint256 cliff = _plans[i].released;
    if(nextStage < _plans[i].stages) {
       
      if(_plans[i].releaseRatio == 0) {
        uint256 amountPerStage = _plans[i].managedAmount.div(_plans[i].stages);
        cliff = nextStage.mul(amountPerStage);
      }
       
      else {
        cliff = 0;
         
        for(uint j = 0; j < nextStage; j++) {
          uint256 remained = _plans[i].managedAmount.sub(cliff);
          cliff = cliff.add(remained.div(_plans[i].releaseRatio));
        }
      }
    }
     
    else {
      cliff = _plans[i].managedAmount;     
    }
    return cliff.sub(_plans[i].released);
  }

  function release(uint256 iPlan) public {
    require(iPlan >= 0 && iPlan < _numPlans);
    require(_plans[iPlan].currentyStage < _plans[iPlan].stages);
    uint256 duration = block.timestamp.sub(_plans[iPlan].start);
    uint256 nextStage = duration.div(_plans[iPlan].durationPerStage);
    nextStage = nextStage.add(1);    
    if(nextStage > _plans[iPlan].stages) {
      nextStage = _plans[iPlan].stages;     
    }
    uint256 unreleased = _releasableAmount(iPlan, nextStage);
    require(unreleased > 0);
    _plans[iPlan].currentyStage = nextStage;
    _plans[iPlan].released = _plans[iPlan].released.add(unreleased);
    _token.transfer(_plans[iPlan].beneficiary, unreleased);
  }

  function token() public view returns (address) {
    return address(_token);
  }

  function balance() public view returns (uint256) {
    return _token.balanceOf(address(this));
  }

  function locked() public view 
    returns (uint256 total, uint256 plan1, uint256 plan2, uint256 plan3) 
  {
    plan1 = _plans[0].managedAmount.sub(_plans[0].released);
    plan2 = _plans[1].managedAmount.sub(_plans[1].released);
    plan3 = _plans[2].managedAmount.sub(_plans[2].released);
    total = plan1.add(plan2.add(plan3));
  }

  function released() public view 
    returns (uint256 total, uint256 plan1, uint256 plan2, uint256 plan3) 
  {
    plan1 = _plans[0].released;
    plan2 = _plans[1].released;
    plan3 = _plans[2].released;
    total = plan1.add(plan2.add(plan3));
  }

  function currentyStage() public view 
    returns (uint256 plan1, uint256 plan2, uint256 plan3) 
  {
    plan1 = _plans[0].currentyStage;
    plan2 = _plans[1].currentyStage;
    plan3 = _plans[2].currentyStage;
  }
}