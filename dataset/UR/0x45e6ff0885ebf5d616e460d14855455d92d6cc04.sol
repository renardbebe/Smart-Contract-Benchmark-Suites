 

pragma solidity 0.4.18;



 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
library SafeMath64 {
  function mul(uint64 a, uint64 b) internal constant returns (uint64) {
    uint64 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint64 a, uint64 b) internal constant returns (uint64) {
     
    uint64 c = a / b;
     
    return c;
  }

  function sub(uint64 a, uint64 b) internal constant returns (uint64) {
    assert(b <= a);
    return a - b;
  }

  function add(uint64 a, uint64 b) internal constant returns (uint64) {
    uint64 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract VestingERC20 {
    using SafeMath for uint256;
    using SafeMath64 for uint64;

    struct Grant {
        uint256 vestedAmount;
        uint64 startTime;
        uint64 cliffTime;
        uint64 endTime;
        uint256 withdrawnAmount;
    }

     
    mapping(address => mapping(address => mapping(address => Grant))) public grantPerTokenGranterVester;

     
    mapping(address => mapping(address => uint256)) private balancePerPersonPerToken;


    event NewGrant(address granter, address vester, address token, uint256 vestedAmount, uint64 startTime, uint64 cliffTime, uint64 endTime);
    event GrantRevoked(address granter, address vester, address token);
    event Deposit(address token, address granter, uint amount, uint balance);
    event TokenReleased(address token, address granter, address vester, uint amount);
    event Withdraw(address token, address user, uint amount);

     
    function createVesting(
        address _token, 
        address _vester,  
        uint256 _vestedAmount,
        uint64 _startTime,
        uint64 _grantPeriod,
        uint64 _cliffPeriod) 
        external
    {
        require(_token != 0);
        require(_vester != 0);
        require(_cliffPeriod <= _grantPeriod);
        require(_vestedAmount != 0);
        require(_grantPeriod==0 || _vestedAmount * _grantPeriod >= _vestedAmount);  

         
        require(grantPerTokenGranterVester[_token][msg.sender][_vester].vestedAmount==0);

        var cliffTime = _startTime.add(_cliffPeriod);
        var endTime = _startTime.add(_grantPeriod);

        grantPerTokenGranterVester[_token][msg.sender][_vester] = Grant(_vestedAmount, _startTime, cliffTime, endTime, 0);

         
        balancePerPersonPerToken[_token][msg.sender] = balancePerPersonPerToken[_token][msg.sender].sub(_vestedAmount);

        NewGrant(msg.sender, _vester, _token, _vestedAmount, _startTime, cliffTime, endTime);
    }

     
    function revokeVesting(address _token, address _vester) 
        external
    {
        require(_token != 0);
        require(_vester != 0);

        Grant storage _grant = grantPerTokenGranterVester[_token][msg.sender][_vester];

         
        require(_grant.vestedAmount!=0);

         
        sendTokenReleasedToBalanceInternal(_token, msg.sender, _vester);

         
        balancePerPersonPerToken[_token][msg.sender] = 
            balancePerPersonPerToken[_token][msg.sender].add(
                _grant.vestedAmount.sub(_grant.withdrawnAmount)
            );

         
        delete grantPerTokenGranterVester[_token][msg.sender][_vester];

        GrantRevoked(msg.sender, _vester, _token);
    }

     
    function releaseGrant(address _token, address _granter, bool _doWithdraw) 
        external
    {
         
        sendTokenReleasedToBalanceInternal(_token, _granter, msg.sender);

        if(_doWithdraw) {
            withdraw(_token);           
        }

         
        Grant storage _grant = grantPerTokenGranterVester[_token][_granter][msg.sender];
        if(_grant.vestedAmount == _grant.withdrawnAmount) 
        {
            delete grantPerTokenGranterVester[_token][_granter][msg.sender];
        }
    }

     
    function withdraw(address _token) 
        public
    {
        uint amountToSend = balancePerPersonPerToken[_token][msg.sender];
        balancePerPersonPerToken[_token][msg.sender] = 0;
        Withdraw(_token, msg.sender, amountToSend);
        require(ERC20(_token).transfer(msg.sender, amountToSend));
    }

     
    function sendTokenReleasedToBalanceInternal(address _token, address _granter, address _vester) 
        internal
    {
        Grant storage _grant = grantPerTokenGranterVester[_token][_granter][_vester];
        uint256 amountToSend = getBalanceVestingInternal(_grant);

         
        _grant.withdrawnAmount = _grant.withdrawnAmount.add(amountToSend);

        TokenReleased(_token, _granter, _vester, amountToSend);

         
        balancePerPersonPerToken[_token][_vester] = balancePerPersonPerToken[_token][_vester].add(amountToSend); 
    }

     
    function getBalanceVestingInternal(Grant _grant)
        internal
        constant
        returns(uint256)
    {
        if(now < _grant.cliffTime) 
        {
             
            return 0;
        }
        else if(now >= _grant.endTime)
        {
             
            return _grant.vestedAmount.sub(_grant.withdrawnAmount);
        }
        else
        {
             
             
            return _grant.vestedAmount.mul( 
                        now.sub(_grant.startTime)
                    ).div(
                        _grant.endTime.sub(_grant.startTime) 
                    ).sub(_grant.withdrawnAmount);
        }
    }

     
    function getVestingBalance(address _token, address _granter, address _vester) 
        external
        constant 
        returns(uint256) 
    {
        Grant memory _grant = grantPerTokenGranterVester[_token][_granter][_vester];
        return getBalanceVestingInternal(_grant);
    }

     
    function getContractBalance(address _token, address _user) 
        external
        constant 
        returns(uint256) 
    {
        return balancePerPersonPerToken[_token][_user];
    }

     
    function deposit(address _token, uint256 _amount) 
        external
        returns(uint256) 
    {
        require(_token!=0);
        require(ERC20(_token).transferFrom(msg.sender, this, _amount));
        balancePerPersonPerToken[_token][msg.sender] = balancePerPersonPerToken[_token][msg.sender].add(_amount);
        Deposit(_token, msg.sender, _amount, balancePerPersonPerToken[_token][msg.sender]);

        return balancePerPersonPerToken[_token][msg.sender];
    }
}