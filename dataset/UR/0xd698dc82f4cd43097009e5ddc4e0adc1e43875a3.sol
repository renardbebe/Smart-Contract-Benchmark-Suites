 

pragma solidity 0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

contract Vault12LockedTokens {
    using SafeMath for uint256;
    uint256 constant internal SECONDS_PER_YEAR = 31561600;

    modifier onlyV12MultiSig {
        require(msg.sender == v12MultiSig, "not owner");
        _;
    }

    modifier onlyValidAddress(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this) && _recipient != address(token), "not valid _recipient");
        _;
    }

    struct Grant {
        uint256 startTime;
        uint256 amount;
        uint256 vestingDuration;
        uint256 yearsClaimed;
        uint256 totalClaimed;
    }

    event GrantAdded(address recipient, uint256 amount);
    event GrantTokensClaimed(address recipient, uint256 amountClaimed);
    event ChangedMultisig(address multisig);

    ERC20 public token;
    
    mapping (address => Grant) public tokenGrants;
    address public v12MultiSig;

    constructor(ERC20 _token) public {
        require(address(_token) != address(0));
        v12MultiSig = msg.sender;
        token = _token;
    }
    
    function addTokenGrant(
        address _recipient,
        uint256 _startTime,
        uint256 _amount,
        uint256 _vestingDurationInYears
    )
        onlyV12MultiSig
        onlyValidAddress(_recipient)
        external
    {
        require(!grantExist(_recipient), "grant already exist");
        require(_vestingDurationInYears <= 25, "more than 25 years");
        uint256 amountVestedPerYear = _amount.div(_vestingDurationInYears);
        require(amountVestedPerYear > 0, "amountVestedPerYear > 0");

         
        require(token.transferFrom(msg.sender, address(this), _amount), "transfer failed");

        Grant memory grant = Grant({
            startTime: _startTime == 0 ? currentTime() : _startTime,
            amount: _amount,
            vestingDuration: _vestingDurationInYears,
            yearsClaimed: 0,
            totalClaimed: 0
        });
        tokenGrants[_recipient] = grant;
        emit GrantAdded(_recipient, _amount);
    }

     
     
     
    function calculateGrantClaim(address _recipient) public view returns (uint256, uint256) {
        Grant storage tokenGrant = tokenGrants[_recipient];

         
        if (currentTime() < tokenGrant.startTime) {
            return (0, 0);
        }

        uint256 elapsedTime = currentTime().sub(tokenGrant.startTime);
        uint256 elapsedYears = elapsedTime.div(SECONDS_PER_YEAR);
        
         
        if (elapsedYears >= tokenGrant.vestingDuration) {
            uint256 remainingGrant = tokenGrant.amount.sub(tokenGrant.totalClaimed);
            uint256 remainingYears = tokenGrant.vestingDuration.sub(tokenGrant.yearsClaimed);
            return (remainingYears, remainingGrant);
        } else {
            uint256 i = 0;
            uint256 tokenGrantAmount = tokenGrant.amount;
            uint256 totalVested = 0;
            for(i; i < elapsedYears; i++){
                totalVested = (tokenGrantAmount.mul(10)).div(100).add(totalVested); 
                tokenGrantAmount = tokenGrant.amount.sub(totalVested);
            }
            uint256 amountVested = totalVested.sub(tokenGrant.totalClaimed);
            return (elapsedYears, amountVested);
        }
    }

     
     
    function claimVestedTokens(address _recipient) external {
        uint256 yearsVested;
        uint256 amountVested;
        (yearsVested, amountVested) = calculateGrantClaim(_recipient);
        require(amountVested > 0, "amountVested is 0");

        Grant storage tokenGrant = tokenGrants[_recipient];
        tokenGrant.yearsClaimed = yearsVested;
        tokenGrant.totalClaimed = tokenGrant.totalClaimed.add(amountVested);
        
        require(token.transfer(_recipient, amountVested), "no tokens");
        emit GrantTokensClaimed(_recipient, amountVested);
    }

    function currentTime() public view returns(uint256) {
        return block.timestamp;
    }

    function changeMultiSig(address _newMultisig) 
        external 
        onlyV12MultiSig
        onlyValidAddress(_newMultisig)
    {
        v12MultiSig = _newMultisig;
        emit ChangedMultisig(_newMultisig);
    }

    function grantExist(address _recipient) public view returns(bool) {
        return tokenGrants[_recipient].amount > 0;
    }

}