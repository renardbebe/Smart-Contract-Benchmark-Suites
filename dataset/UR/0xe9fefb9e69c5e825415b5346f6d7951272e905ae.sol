 

pragma solidity ^0.4.24;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);

   
  function mint(address _to, uint256 _amount) internal returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

}

 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(address(this).balance));
  }
}

 
 
 

contract Scale is MintableToken, HasNoEther {

     
    using SafeMath for uint;

     
     
     
    string public constant name = "SCALE";
    string public constant symbol = "SCALE";
    uint8 public constant  decimals = 18;

     
     
     

     
     
     
    address public pool = address(0);

     
    uint public poolMintRate;
    uint public ownerMintRate;

     
    uint public poolMintAmount;
    uint public stakingMintAmount;
    uint public ownerMintAmount;

     
    uint public poolPercentage = 70;
    uint public ownerPercentage = 5;
    uint public stakingPercentage = 25;

     
    uint public ownerTimeLastMinted;
    uint public poolTimeLastMinted;

     
     
    uint public stakingMintRate;

     
    uint public totalScaleStaked;

     
    mapping (uint => uint) totalStakingHistory;

     
    uint timingVariable = 86400;

     
    struct AddressStakeData {
        uint stakeBalance;
        uint initialStakeTime;
    }

     
    mapping (address => AddressStakeData) public stakeBalances;

     
     
    uint256 inflationRate = 1000;

     
    uint256 public lastInflationUpdate;

     
     
    event Stake(address indexed staker, uint256 value);
     
    event Unstake(address indexed unstaker, uint256 stakedAmount, uint256 stakingGains);

     
     
     

     
    constructor() public {
         
        owner = msg.sender;

         
        uint _initOwnerSupply = 10000000 ether;
         
        bool _success = mint(msg.sender, _initOwnerSupply);
         
        require(_success);

         
        ownerTimeLastMinted = now;
        poolTimeLastMinted = now;

         
        poolMintAmount = _initOwnerSupply.mul(poolPercentage).div(100);
        ownerMintAmount = _initOwnerSupply.mul(ownerPercentage).div(100);
        stakingMintAmount = _initOwnerSupply.mul(stakingPercentage).div(100);

         
        uint _oneYearInSeconds = 31536000 ether;

         
        poolMintRate = calculateFraction(poolMintAmount, _oneYearInSeconds, decimals);
        ownerMintRate = calculateFraction(ownerMintAmount, _oneYearInSeconds, decimals);
        stakingMintRate = calculateFraction(stakingMintAmount, _oneYearInSeconds, decimals);

         
        lastInflationUpdate = now;
    }

     
     
     

     
     
    function adjustInflationRate() private {


       
      lastInflationUpdate = now;

       
      if (inflationRate > 100) {

        inflationRate = inflationRate.sub(300);
      }
       
      else if (inflationRate > 10) {

        inflationRate = inflationRate.sub(5);
      }

       
       
      poolMintAmount = totalSupply.mul(inflationRate).div(1000).mul(poolPercentage).div(100);
      ownerMintAmount = totalSupply.mul(inflationRate).div(1000).mul(ownerPercentage).div(100);
      stakingMintAmount = totalSupply.mul(inflationRate).div(1000).mul(stakingPercentage).div(100);

         
        poolMintRate = calculateFraction(poolMintAmount, 31536000 ether, decimals);
        ownerMintRate = calculateFraction(ownerMintAmount, 31536000 ether, decimals);
        stakingMintRate = calculateFraction(stakingMintAmount, 31536000 ether, decimals);
    }

     
    function updateInflationRate() public {

       
      require(now.sub(lastInflationUpdate) >= 31536000);

      adjustInflationRate();

    }

     
     
     

     
     
    function stakeScale(uint _stakeAmount) external {

         
        require(stake(msg.sender, _stakeAmount));
    }

     
     
    function stakeFor(address _user, uint _stakeAmount) external {

       
      require(stakeBalances[_user].stakeBalance == 0);

       
      transfer( _user, _stakeAmount);

       
      stake(_user, _stakeAmount);
    }

     
     
    function stake(address _user, uint256 _value) private returns (bool success) {

         
        require(_value <= balances[_user]);
         
        require(stakeBalances[_user].stakeBalance == 0);

         
        balances[_user] = balances[_user].sub(_value);

         
        stakeBalances[_user].stakeBalance = _value;

         
        totalScaleStaked = totalScaleStaked.add(_value);

         
        stakeBalances[_user].initialStakeTime = now.div(timingVariable);

         
        setTotalStakingHistory();

         
        emit Stake(_user, _value);

        return true;
    }

     
     
     
    function getStakingGains(uint _now) view public returns (uint) {

        if (stakeBalances[msg.sender].stakeBalance == 0) {

          return 0;
        }

        return calculateStakeGains(_now);
    }

     
     
    function unstake() external returns (bool) {

         
        require(stakeBalances[msg.sender].stakeBalance > 0);

         
        require(now.div(timingVariable).sub(stakeBalances[msg.sender].initialStakeTime) >= 7);

         
        uint _tokensToMint = calculateStakeGains(now);

        balances[msg.sender] = balances[msg.sender].add(stakeBalances[msg.sender].stakeBalance);

         
        totalScaleStaked = totalScaleStaked.sub(stakeBalances[msg.sender].stakeBalance);

         
        mint(msg.sender, _tokensToMint);

         
        emit Unstake(msg.sender, stakeBalances[msg.sender].stakeBalance, _tokensToMint);

         
        stakeBalances[msg.sender].stakeBalance = 0;
        stakeBalances[msg.sender].initialStakeTime = 0;

         
        setTotalStakingHistory();

        return true;
    }

     
     
     
    function calculateStakeGains(uint _now) view private returns (uint mintTotal)  {

      uint _nowAsTimingVariable = _now.div(timingVariable);     
      uint _initialStakeTimeInVariable = stakeBalances[msg.sender].initialStakeTime;  
      uint _timePassedSinceStakeInVariable = _nowAsTimingVariable.sub(_initialStakeTimeInVariable);  
      uint _stakePercentages = 0;  
      uint _tokensToMint = 0;  
      uint _lastUsedVariable;   

       
      for (uint i = _initialStakeTimeInVariable; i < _nowAsTimingVariable; i++) {

         
        if (totalStakingHistory[i] != 0) {

            
          _stakePercentages = _stakePercentages.add(calculateFraction(stakeBalances[msg.sender].stakeBalance, totalStakingHistory[i], decimals));

           
          _lastUsedVariable = totalStakingHistory[i];
        }
        else {

           
          _stakePercentages = _stakePercentages.add(calculateFraction(stakeBalances[msg.sender].stakeBalance, _lastUsedVariable, decimals));
        }

      }

         
        uint _stakePercentageAverage = calculateFraction(_stakePercentages, _timePassedSinceStakeInVariable, 0);

         
        uint _finalMintRate = stakingMintRate.mul(_stakePercentageAverage);

         
        _finalMintRate = _finalMintRate.div(1 ether);

         
        if (_timePassedSinceStakeInVariable >= 365) {

           
          _tokensToMint = calculateMintTotal(timingVariable.mul(365), _finalMintRate);
        }
        else {

           
          _tokensToMint = calculateMintTotal(_timePassedSinceStakeInVariable.mul(timingVariable), _finalMintRate);
        }

        return  _tokensToMint;
    }

     
    function setTotalStakingHistory() private {

       
      uint _nowAsTimingVariable = now.div(timingVariable);

       
      totalStakingHistory[_nowAsTimingVariable] = totalScaleStaked;
    }

     
     
    function getStakedBalance() view external returns (uint stakedBalance) {

        return stakeBalances[msg.sender].stakeBalance;
    }

     
     
     

     
    function ownerClaim() external onlyOwner {

        require(now > ownerTimeLastMinted);

        uint _timePassedSinceLastMint;  
        uint _tokenMintCount;  
        bool _mintingSuccess;  

         
        _timePassedSinceLastMint = now.sub(ownerTimeLastMinted);

        assert(_timePassedSinceLastMint > 0);

         
        _tokenMintCount = calculateMintTotal(_timePassedSinceLastMint, ownerMintRate);

         
        _mintingSuccess = mint(msg.sender, _tokenMintCount);

        require(_mintingSuccess);

         
        ownerTimeLastMinted = now;
    }

     
     
     

     
    function poolIssue() public {

         
        require(pool != address(0));

         
        require(now > poolTimeLastMinted);
        require(pool != address(0));

        uint _timePassedSinceLastMint;  
        uint _tokenMintCount;  
        bool _mintingSuccess;  

         
        _timePassedSinceLastMint = now.sub(poolTimeLastMinted);

        assert(_timePassedSinceLastMint > 0);

         
        _tokenMintCount = calculateMintTotal(_timePassedSinceLastMint, poolMintRate);

         
        _mintingSuccess = mint(pool, _tokenMintCount);

        require(_mintingSuccess);

         
        poolTimeLastMinted = now;
    }

     
     
    function setPool(address _newAddress) public onlyOwner {

        pool = _newAddress;
    }

     
     
     

     
     
     
     
     
    function calculateFraction(uint _numerator, uint _denominator, uint _precision) pure private returns(uint quotient) {
         
        _numerator = _numerator.mul(10 ** (_precision + 1));
         
        uint _quotient = ((_numerator.div(_denominator)) + 5) / 10;
        return (_quotient);
    }

     
     
     
    function calculateMintTotal(uint _timeInSeconds, uint _mintRate) pure private returns(uint mintAmount) {
         
        return(_timeInSeconds.mul(_mintRate));
    }

}