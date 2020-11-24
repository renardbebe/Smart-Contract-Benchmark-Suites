 

pragma solidity ^0.4.17;

 

 
contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  function Ownable() {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }
    address public controller;
    function Controlled() public { controller = msg.sender;}
     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}
 
contract ERC20MiniMe is ERC20, Controlled {
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool);
    function totalSupply() public view returns (uint);
    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint);
    function totalSupplyAt(uint _blockNumber) public view returns(uint);
    function createCloneToken(string _cloneTokenName, uint8 _cloneDecimalUnits, string _cloneTokenSymbol, uint _snapshotBlock, bool _transfersEnabled) public returns(address);
    function generateTokens(address _owner, uint _amount) public returns (bool);
    function destroyTokens(address _owner, uint _amount)  public returns (bool);
    function enableTransfers(bool _transfersEnabled) public;
    function isContract(address _addr) internal view returns(bool);
    function claimTokens(address _token) public;
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
}
 
contract TokenController {
    ERC20MiniMe public ethealToken;
    address public SALE;  
     
    function addHodlerStake(address _beneficiary, uint _stake) public;
    function setHodlerStake(address _beneficiary, uint256 _stake) public;
    function setHodlerTime(uint256 _time) public;
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);
     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);
     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
}
 
contract EthealHodler is Ownable {
    using SafeMath for uint;

     
     
    struct HODL {
        uint256 stake;
         
        bool invalid;
        bool claimed3M;
        bool claimed6M;
        bool claimed9M;
    }

    mapping (address => HODL) public hodlerStakes;

     
    uint256 public hodlerTotalValue;
    uint256 public hodlerTotalCount;

     
    uint256 public hodlerTotalValue3M;
    uint256 public hodlerTotalValue6M;
    uint256 public hodlerTotalValue9M;
    uint256 public hodlerTimeStart;
    uint256 public hodlerTime3M;
    uint256 public hodlerTime6M;
    uint256 public hodlerTime9M;

     
    uint256 public TOKEN_HODL_3M;
    uint256 public TOKEN_HODL_6M;
    uint256 public TOKEN_HODL_9M;

     
    uint256 public claimedTokens;

    
    event LogHodlSetStake(address indexed _setter, address indexed _beneficiary, uint256 _value);
    event LogHodlClaimed(address indexed _setter, address indexed _beneficiary, uint256 _value);
    event LogHodlStartSet(address indexed _setter, uint256 _time);


     
    modifier beforeHodlStart() {
        if (hodlerTimeStart == 0 || now <= hodlerTimeStart)
            _;
    }

     
    function EthealHodler(uint256 _stake3m, uint256 _stake6m, uint256 _stake9m) {
        TOKEN_HODL_3M = _stake3m;
        TOKEN_HODL_6M = _stake6m;
        TOKEN_HODL_9M = _stake9m;
    }

     
     
     
     
    function addHodlerStake(address _beneficiary, uint256 _stake) public onlyOwner beforeHodlStart {
         
        if (_stake == 0 || _beneficiary == address(0))
            return;
        
         
        if (hodlerStakes[_beneficiary].stake == 0)
            hodlerTotalCount = hodlerTotalCount.add(1);

        hodlerStakes[_beneficiary].stake = hodlerStakes[_beneficiary].stake.add(_stake);

        hodlerTotalValue = hodlerTotalValue.add(_stake);

        LogHodlSetStake(msg.sender, _beneficiary, hodlerStakes[_beneficiary].stake);
    }

     
    function addManyHodlerStake(address[] _addr, uint256[] _stake) public onlyOwner beforeHodlStart {
        require(_addr.length == _stake.length);

        for (uint256 i = 0; i < _addr.length; i++) {
            addHodlerStake(_addr[i], _stake[i]);
        }
    }

     
     
     
     
    function setHodlerStake(address _beneficiary, uint256 _stake) public onlyOwner beforeHodlStart {
         
        if (hodlerStakes[_beneficiary].stake == _stake || _beneficiary == address(0))
            return;
        
         
        if (hodlerStakes[_beneficiary].stake == 0 && _stake > 0) {
            hodlerTotalCount = hodlerTotalCount.add(1);
        } else if (hodlerStakes[_beneficiary].stake > 0 && _stake == 0) {
            hodlerTotalCount = hodlerTotalCount.sub(1);
        }

        uint256 _diff = _stake > hodlerStakes[_beneficiary].stake ? _stake.sub(hodlerStakes[_beneficiary].stake) : hodlerStakes[_beneficiary].stake.sub(_stake);
        if (_stake > hodlerStakes[_beneficiary].stake) {
            hodlerTotalValue = hodlerTotalValue.add(_diff);
        } else {
            hodlerTotalValue = hodlerTotalValue.sub(_diff);
        }
        hodlerStakes[_beneficiary].stake = _stake;

        LogHodlSetStake(msg.sender, _beneficiary, _stake);
    }

     
    function setManyHodlerStake(address[] _addr, uint256[] _stake) public onlyOwner beforeHodlStart {
        require(_addr.length == _stake.length);

        for (uint256 i = 0; i < _addr.length; i++) {
            setHodlerStake(_addr[i], _stake[i]);
        }
    }

     
     
    function setHodlerTime(uint256 _time) public onlyOwner beforeHodlStart {
         
         

        hodlerTimeStart = _time;
        hodlerTime3M = _time.add(90 days);
        hodlerTime6M = _time.add(180 days);
        hodlerTime9M = _time.add(270 days);

        LogHodlStartSet(msg.sender, _time);
    }

     
     
    function invalidate(address _account) public onlyOwner {
        if (hodlerStakes[_account].stake > 0 && !hodlerStakes[_account].invalid) {
             
            claimHodlRewardFor(_account);

             
            hodlerStakes[_account].invalid = true;
            hodlerTotalValue = hodlerTotalValue.sub(hodlerStakes[_account].stake);
            hodlerTotalCount = hodlerTotalCount.sub(1);
        } else {
             
            updateAndGetHodlTotalValue();
        }
    }

     
    function claimHodlReward() public {
        claimHodlRewardFor(msg.sender);
    }

     
    function claimHodlRewardFor(address _beneficiary) public {
         
        require(hodlerStakes[_beneficiary].stake > 0 && !hodlerStakes[_beneficiary].invalid);

        uint256 _stake = 0;
        
         
        updateAndGetHodlTotalValue();

         
        if (!hodlerStakes[_beneficiary].claimed3M && now >= hodlerTime3M) {
            _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue3M));
            hodlerStakes[_beneficiary].claimed3M = true;
        }
        if (!hodlerStakes[_beneficiary].claimed6M && now >= hodlerTime6M) {
            _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_6M).div(hodlerTotalValue6M));
            hodlerStakes[_beneficiary].claimed6M = true;
        }
        if (!hodlerStakes[_beneficiary].claimed9M && now >= hodlerTime9M) {
            _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_9M).div(hodlerTotalValue9M));
            hodlerStakes[_beneficiary].claimed9M = true;
        }

        if (_stake > 0) {
             
            claimedTokens = claimedTokens.add(_stake);

             
            require(TokenController(owner).ethealToken().transfer(_beneficiary, _stake));

             
            LogHodlClaimed(msg.sender, _beneficiary, _stake);
        }
    }

     
     
     
    function claimHodlRewardsFor(address[] _beneficiaries) external {
        for (uint256 i = 0; i < _beneficiaries.length; i++)
            claimHodlRewardFor(_beneficiaries[i]);
    }

     
    function updateAndGetHodlTotalValue() public returns (uint) {
        if (hodlerTime3M > 0 && now >= hodlerTime3M && hodlerTotalValue3M == 0) {
            hodlerTotalValue3M = hodlerTotalValue;
        }

        if (hodlerTime6M > 0 && now >= hodlerTime6M && hodlerTotalValue6M == 0) {
            hodlerTotalValue6M = hodlerTotalValue;
        }

        if (hodlerTime9M > 0 && now >= hodlerTime9M && hodlerTotalValue9M == 0) {
            hodlerTotalValue9M = hodlerTotalValue;

             
            TOKEN_HODL_9M = TokenController(owner).ethealToken().balanceOf(this).sub(TOKEN_HODL_3M).sub(TOKEN_HODL_6M).add(claimedTokens);
        }

        return hodlerTotalValue;
    }
}