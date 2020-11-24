 

pragma solidity ^0.4.23;

 

contract IRoleModel {
   
  uint8 constant RL_DEFAULT = 0x00;
  
   
  uint8 constant RL_POOL_MANAGER = 0x01;
  
   
  uint8 constant RL_ICO_MANAGER = 0x02;
  
   
  uint8 constant RL_ADMIN = 0x04;
  
   
  uint8 constant RL_PAYBOT = 0x08;

  function getRole_() view internal returns(uint8);
  function getRole_(address _for) view internal returns(uint8);
  function getRoleAddress_(uint8 _for) view internal returns(address);
  
}

 

contract IStateModel {
   
  uint8 constant ST_DEFAULT = 0x00;
  
   
  uint8 constant ST_RAISING = 0x01;
  
   
  uint8 constant ST_WAIT_FOR_ICO = 0x02;
  
   
  uint8 constant ST_MONEY_BACK = 0x04;
  
   
  uint8 constant ST_TOKEN_DISTRIBUTION = 0x08;
  
   
  uint8 constant ST_FUND_DEPRECATED = 0x10;
  
   
  uint8 constant TST_DEFAULT = 0x00;
  
   
  uint8 constant TST_RAISING = 0x01;
  
   
  uint8 constant TST_WAIT_FOR_ICO = 0x02;
  
   
  uint8 constant TST_TOKEN_DISTRIBUTION = 0x08;
  
   
  uint8 constant TST_FUND_DEPRECATED = 0x10;
  
   
  uint8 constant RST_NOT_COLLECTED = 0x01;
  
   
  uint8 constant RST_COLLECTED = 0x02;
  
   
  uint8 constant RST_FULL = 0x04;

  function getState_() internal view returns (uint8);
  function getShareRemaining_() internal view returns(uint);
}

 

contract RoleModel is IRoleModel{
  mapping (address => uint8) internal role_;
  mapping (uint8 => address) internal roleAddress_;
  
  function setRole_(uint8 _for, address _afor) internal returns(bool) {
    require((role_[_afor] == 0) && (roleAddress_[_for] == address(0)));
    role_[_afor] = _for;
    roleAddress_[_for] = _afor;
  }

  function getRole_() view internal returns(uint8) {
    return role_[msg.sender];
  }

  function getRole_(address _for) view internal returns(uint8) {
    return role_[_for];
  }

  function getRoleAddress_(uint8 _for) view internal returns(address) {
    return roleAddress_[_for];
  }
  
   
  function getRole(address _targetAddress) external view returns(uint8){
    return role_[_targetAddress];
  }

}

 

contract ITimeMachine {
  function getTimestamp_() internal view returns (uint);
}

 

contract IShareStore {
  function getTotalShare_() internal view returns(uint);
  
   
  event BuyShare(address indexed addr, uint value);
  
   
  event RefundShare(address indexed addr, uint value);
  
   
  event ReleaseEtherToStakeholder(uint8 indexed role, address indexed addr, uint value);
  
   
  event AcceptTokenFromICO(address indexed addr, uint value);
  
   
  event ReleaseEther(address indexed addr, uint value);
  
   
  event ReleaseToken(address indexed addr, uint value);

}

 

 
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

 

contract StateModel is IRoleModel, IShareStore, IStateModel, ITimeMachine {
  using SafeMath for uint;
   
  uint public launchTimestamp;

   
  uint public raisingPeriod;

   
  uint public icoPeriod;

   
  uint public distributionPeriod;

   
  uint public minimalFundSize;
  
   
  uint public maximalFundSize;
  
  uint8 internal initialState_;

  function getShareRemaining_() internal view returns(uint)
  {
    return maximalFundSize.sub(getTotalShare_());
  }
 
  function getTimeState_() internal view returns (uint8) {
    uint _launchTimestamp = launchTimestamp;
    uint _relativeTimestamp = getTimestamp_() - _launchTimestamp;
    if (_launchTimestamp == 0)
      return TST_DEFAULT;
    if (_relativeTimestamp < raisingPeriod)
      return TST_RAISING;
    if (_relativeTimestamp < icoPeriod)
      return TST_WAIT_FOR_ICO;
    if (_relativeTimestamp < distributionPeriod)
      return TST_TOKEN_DISTRIBUTION;
    return TST_FUND_DEPRECATED;
  }

  function getRaisingState_() internal view returns(uint8) {
    uint _totalEther = getTotalShare_();
    if (_totalEther < minimalFundSize) 
      return RST_NOT_COLLECTED;
    if (_totalEther < maximalFundSize)
      return RST_COLLECTED;
    return RST_FULL;
  }

  function getState_() internal view returns (uint8) {
    uint _initialState = initialState_;
    uint _timeState = getTimeState_();
    uint _raisingState = getRaisingState_();
    return getState_(_initialState, _timeState, _raisingState);
  }
  
  function getState_(uint _initialState, uint _timeState, uint _raisingState) private pure returns (uint8) {
    if (_initialState == ST_DEFAULT) return ST_DEFAULT;

    if (_initialState == ST_RAISING) {
      if (_timeState == TST_RAISING) {
        if (_raisingState == RST_FULL) {
          return ST_WAIT_FOR_ICO;
        }
        return ST_RAISING;
      }
      if (_raisingState == RST_NOT_COLLECTED && (_timeState == TST_WAIT_FOR_ICO || _timeState == TST_TOKEN_DISTRIBUTION)) {
        return ST_MONEY_BACK;
      }
      if (_timeState == TST_WAIT_FOR_ICO) {
        return ST_WAIT_FOR_ICO;
      }
      if (_timeState == TST_TOKEN_DISTRIBUTION) {
        return ST_TOKEN_DISTRIBUTION;
      }
      return ST_FUND_DEPRECATED;
    }

    if (_initialState == ST_WAIT_FOR_ICO) {
      if (_timeState == TST_RAISING || _timeState == TST_WAIT_FOR_ICO) {
        return ST_WAIT_FOR_ICO;
      }
      if (_timeState == TST_TOKEN_DISTRIBUTION) {
        return ST_TOKEN_DISTRIBUTION;
      }
      return ST_FUND_DEPRECATED;
    }

    if (_initialState == ST_MONEY_BACK) {
      if (_timeState == TST_RAISING || _timeState == TST_WAIT_FOR_ICO || _timeState == TST_TOKEN_DISTRIBUTION) {
        return ST_MONEY_BACK;
      }
      return ST_FUND_DEPRECATED;
    }
    
    if (_initialState == ST_TOKEN_DISTRIBUTION) {
      if (_timeState == TST_RAISING || _timeState == TST_WAIT_FOR_ICO || _timeState == TST_TOKEN_DISTRIBUTION) {
        return ST_TOKEN_DISTRIBUTION;
      }
      return ST_FUND_DEPRECATED;
    }

    return ST_FUND_DEPRECATED;
  }
  
  function setState_(uint _stateNew) internal returns (bool) {
    uint _initialState = initialState_;
    uint _timeState = getTimeState_();
    uint _raisingState = getRaisingState_();
    uint8 _state = getState_(_initialState, _timeState, _raisingState);
    uint8 _role = getRole_();

    if (_stateNew == ST_RAISING) {
      if ((_role == RL_POOL_MANAGER) && (_state == ST_DEFAULT)) {
        launchTimestamp = getTimestamp_();
        initialState_ = ST_RAISING;
        return true;
      }
      revert();
    }

    if (_stateNew == ST_WAIT_FOR_ICO) {
      if ((_role == RL_POOL_MANAGER || _role == RL_ICO_MANAGER) && (_raisingState == RST_COLLECTED)) {
        initialState_ = ST_WAIT_FOR_ICO;
        return true;
      }
      revert();
    }

    if (_stateNew == ST_MONEY_BACK) {
      if ((_role == RL_POOL_MANAGER || _role == RL_ADMIN || _role == RL_PAYBOT) && (_state == ST_RAISING)) {
        initialState_ = ST_MONEY_BACK;
        return true;
      }
      revert();
    }

    if (_stateNew == ST_TOKEN_DISTRIBUTION) {
      if ((_role == RL_POOL_MANAGER || _role == RL_ADMIN || _role == RL_ICO_MANAGER || _role == RL_PAYBOT) && (_state == ST_WAIT_FOR_ICO)) {
        initialState_ = ST_TOKEN_DISTRIBUTION;
        return true;
      }
      revert();
    }

    revert();
    return true;
  }
  
   
  function getState() external view returns(uint8) {
    return getState_();
  }
  
   
  function setState(uint newState) external returns(bool) {
    return setState_(newState);
  }

}

 

 
contract IERC20{
  function allowance(address owner, address spender) external view returns (uint);
  function transferFrom(address from, address to, uint value) external returns (bool);
  function approve(address spender, uint value) external returns (bool);
  function totalSupply() external view returns (uint);
  function balanceOf(address who) external view returns (uint);
  function transfer(address to, uint value) external returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 

contract ShareStore is IRoleModel, IShareStore, IStateModel {
  
  using SafeMath for uint;
  
   
  uint public minimalDeposit;
  
   
  address public tokenAddress;
  
   
  mapping (address=>uint) public share;
  
   
  uint public totalShare;
  
   
  uint public totalToken;
  
   
  mapping (uint8=>uint) public stakeholderShare;
  mapping (address=>uint) internal etherReleased_;
  mapping (address=>uint) internal tokenReleased_;
  mapping (uint8=>uint) internal stakeholderEtherReleased_;
  uint constant DECIMAL_MULTIPLIER = 1e18;

   
  uint public tokenPrice;
  
   
  function () public payable {
    uint8 _state = getState_();
    if (_state == ST_RAISING){
      buyShare_(_state);
      return;
    }
    
    if (_state == ST_MONEY_BACK) {
      refundShare_(msg.sender, share[msg.sender]);
      if(msg.value > 0)
        msg.sender.transfer(msg.value);
      return;
    }
    
    if (_state == ST_TOKEN_DISTRIBUTION) {
      releaseEther_(msg.sender, getBalanceEtherOf_(msg.sender));
      releaseToken_(msg.sender, getBalanceTokenOf_(msg.sender));
      if(msg.value > 0)
        msg.sender.transfer(msg.value);
      return;
    }
    revert();
  }
  
  
   
  function buyShare() external payable returns(bool) {
    return buyShare_(getState_());
  }
  
   
  function acceptTokenFromICO(uint _value) external returns(bool) {
    return acceptTokenFromICO_(_value);
  }
  
   
  function getStakeholderBalanceOf(uint8 _for) external view returns(uint) {
    return getStakeholderBalanceOf_(_for);
  }
  
   
  function getBalanceEtherOf(address _for) external view returns(uint) {
    return getBalanceEtherOf_(_for);
  }
  
   
  function getBalanceTokenOf(address _for) external view returns(uint) {
    return getBalanceTokenOf_(_for);
  }
  
   
  function releaseEtherToStakeholder(uint _value) external returns(bool) {
    uint8 _state = getState_();
    uint8 _for = getRole_();
    require(!((_for == RL_ICO_MANAGER) && ((_state != ST_WAIT_FOR_ICO) || (tokenPrice > 0))));
    return releaseEtherToStakeholder_(_state, _for, _value);
  }
  
   
  function releaseEtherToStakeholderForce(uint8 _for, uint _value) external returns(bool) {
    uint8 _role = getRole_();
    require((_role==RL_ADMIN) || (_role==RL_PAYBOT));
    uint8 _state = getState_();
    require(!((_for == RL_ICO_MANAGER) && ((_state != ST_WAIT_FOR_ICO) || (tokenPrice > 0))));
    return releaseEtherToStakeholder_(_state, _for, _value);
  }
  
   
  function releaseEther(uint _value) external returns(bool) {
    uint8 _state = getState_();
    require(_state == ST_TOKEN_DISTRIBUTION);
    return releaseEther_(msg.sender, _value);
  }
  
   
  function releaseEtherForce(address _for, uint _value) external returns(bool) {
    uint8 _role = getRole_();
    uint8 _state = getState_();
    require(_state == ST_TOKEN_DISTRIBUTION);
    require((_role==RL_ADMIN) || (_role==RL_PAYBOT));
    return releaseEther_(_for, _value);
  }

   
  function releaseEtherForceMulti(address[] _for, uint[] _value) external returns(bool) {
    uint _sz = _for.length;
    require(_value.length == _sz);
    uint8 _role = getRole_();
    uint8 _state = getState_();
    require(_state == ST_TOKEN_DISTRIBUTION);
    require((_role==RL_ADMIN) || (_role==RL_PAYBOT));
    for (uint i = 0; i < _sz; i++){
      require(releaseEther_(_for[i], _value[i]));
    }
    return true;
  }
  
   
  function releaseToken(uint _value) external returns(bool) {
    uint8 _state = getState_();
    require(_state == ST_TOKEN_DISTRIBUTION);
    return releaseToken_(msg.sender, _value);
  }
  
   
  function releaseTokenForce(address _for, uint _value) external returns(bool) {
    uint8 _role = getRole_();
    uint8 _state = getState_();
    require(_state == ST_TOKEN_DISTRIBUTION);
    require((_role==RL_ADMIN) || (_role==RL_PAYBOT));
    return releaseToken_(_for, _value);
  }


   
  function releaseTokenForceMulti(address[] _for, uint[] _value) external returns(bool) {
    uint _sz = _for.length;
    require(_value.length == _sz);
    uint8 _role = getRole_();
    uint8 _state = getState_();
    require(_state == ST_TOKEN_DISTRIBUTION);
    require((_role==RL_ADMIN) || (_role==RL_PAYBOT));
    for(uint i = 0; i < _sz; i++){
      require(releaseToken_(_for[i], _value[i]));
    }
    return true;
  }
  
   
  function refundShare(uint _value) external returns(bool) {
    uint8 _state = getState_();
    require (_state == ST_MONEY_BACK);
    return refundShare_(msg.sender, _value);
  }
  
   
  function refundShareForce(address _for, uint _value) external returns(bool) {
    uint8 _state = getState_();
    uint8 _role = getRole_();
    require(_role == RL_ADMIN || _role == RL_PAYBOT);
    require (_state == ST_MONEY_BACK || _state == ST_RAISING);
    return refundShare_(_for, _value);
  }
  
   
  function execute(address _to, uint _value, bytes _data) external returns (bool) {
    require (getRole_()==RL_ADMIN);
    require (getState_()==ST_FUND_DEPRECATED);
     
    return _to.call.value(_value)(_data);
  }
  
  function getTotalShare_() internal view returns(uint){
    return totalShare;
  }

  function getEtherCollected_() internal view returns(uint){
    return totalShare;
  }

  function buyShare_(uint8 _state) internal returns(bool) {
    require(_state == ST_RAISING);
    require(msg.value >= minimalDeposit);
    uint _shareRemaining = getShareRemaining_();
    uint _shareAccept = (msg.value <= _shareRemaining) ? msg.value : _shareRemaining;

    share[msg.sender] = share[msg.sender].add(_shareAccept);
    totalShare = totalShare.add(_shareAccept);
    emit BuyShare(msg.sender, _shareAccept);
    if (msg.value!=_shareAccept) {
      msg.sender.transfer(msg.value.sub(_shareAccept));
    }
    return true;
  }

  function acceptTokenFromICO_(uint _value) internal returns(bool) {
    uint8 _state = getState_();
    uint8 _for = getRole_();
    require(_state == ST_WAIT_FOR_ICO);
    require(_for == RL_ICO_MANAGER);
    
    totalToken = totalToken.add(_value);
    emit AcceptTokenFromICO(msg.sender, _value);
    require(IERC20(tokenAddress).transferFrom(msg.sender, this, _value));
    if (tokenPrice > 0) {
      releaseEtherToStakeholder_(_state, _for, _value.mul(tokenPrice).div(DECIMAL_MULTIPLIER));
    }
    return true;
  }

  function getStakeholderBalanceOf_(uint8 _for) internal view returns (uint) {
    if (_for == RL_ICO_MANAGER) {
      return getEtherCollected_().mul(stakeholderShare[_for]).div(DECIMAL_MULTIPLIER).sub(stakeholderEtherReleased_[_for]);
    }

    if ((_for == RL_POOL_MANAGER) || (_for == RL_ADMIN)) {
      return stakeholderEtherReleased_[RL_ICO_MANAGER].mul(stakeholderShare[_for]).div(stakeholderShare[RL_ICO_MANAGER]);
    }
    return 0;
  }

  function releaseEtherToStakeholder_(uint8 _state, uint8 _for, uint _value) internal returns (bool) {
    require(_for != RL_DEFAULT);
    require(_for != RL_PAYBOT);
    require(!((_for == RL_ICO_MANAGER) && (_state != ST_WAIT_FOR_ICO)));
    uint _balance = getStakeholderBalanceOf_(_for);
    address _afor = getRoleAddress_(_for);
    require(_balance >= _value);
    stakeholderEtherReleased_[_for] = stakeholderEtherReleased_[_for].add(_value);
    emit ReleaseEtherToStakeholder(_for, _afor, _value);
    _afor.transfer(_value);
    return true;
  }

  function getBalanceEtherOf_(address _for) internal view returns (uint) {
    uint _stakeholderTotalEtherReserved = stakeholderEtherReleased_[RL_ICO_MANAGER]
    .mul(DECIMAL_MULTIPLIER).div(stakeholderShare[RL_ICO_MANAGER]);
    uint _restEther = getEtherCollected_().sub(_stakeholderTotalEtherReserved);
    return _restEther.mul(share[_for]).div(totalShare).sub(etherReleased_[_for]);
  }

  function getBalanceTokenOf_(address _for) internal view returns (uint) {
    return totalToken.mul(share[_for]).div(totalShare).sub(tokenReleased_[_for]);
  }

  function releaseEther_(address _for, uint _value) internal returns (bool) {
    uint _balance = getBalanceEtherOf_(_for);
    require(_balance >= _value);
    etherReleased_[_for] = etherReleased_[_for].add(_value);
    emit ReleaseEther(_for, _value);
    _for.transfer(_value);
    return true;
  }

  function releaseToken_( address _for, uint _value) internal returns (bool) {
    uint _balance = getBalanceTokenOf_(_for);
    require(_balance >= _value);
    tokenReleased_[_for] = tokenReleased_[_for].add(_value);
    emit ReleaseToken(_for, _value);
    require(IERC20(tokenAddress).transfer(_for, _value));
    return true;
  }

  function refundShare_(address _for, uint _value) internal returns(bool) {
    uint _balance = share[_for];
    require(_balance >= _value);
    share[_for] = _balance.sub(_value);
    totalShare = totalShare.sub(_value);
    emit RefundShare(_for, _value);
    _for.transfer(_value);
    return true;
  }
  
}

 

contract Pool is ShareStore, StateModel, RoleModel {
}

 

 
contract TimeMachineP {
  
   
  function getTimestamp_() internal view returns(uint) {
    return block.timestamp;
  }
}

 

contract PoolProd is Pool, TimeMachineP {
  uint constant DECIMAL_MULTIPLIER = 1e18;
  

  constructor() public {
    uint day = 86400;
    raisingPeriod = day*30;
    icoPeriod = day*60;
    distributionPeriod = day*90;

    minimalFundSize = 0.1e18;
    maximalFundSize = 10e18;

    minimalDeposit = 0.01e18;

    stakeholderShare[RL_ADMIN] = 0.02e18;
    stakeholderShare[RL_POOL_MANAGER] = 0.01e18;
    stakeholderShare[RL_ICO_MANAGER] = DECIMAL_MULTIPLIER - 0.02e18 - 0.01e18;

    setRole_(RL_ADMIN, 0xa4280AEF10BE355d6777d97758cb6fC6c5C3779C);
    setRole_(RL_POOL_MANAGER, 0x91b4DABf4f2562E714DBd84B6D4a4efd7e1a97a8);
    setRole_(RL_ICO_MANAGER, 0x79Cd7826636cb299059272f4324a5866496807Ef);
    setRole_(RL_PAYBOT, 0x3Fae7A405A45025E5Fb0AD09e225C4168bF916D4);

    tokenAddress = 0x45245bc59219eeaAF6cD3f382e078A461FF9De7B;
    tokenPrice = 5000000000000000;
  }
}