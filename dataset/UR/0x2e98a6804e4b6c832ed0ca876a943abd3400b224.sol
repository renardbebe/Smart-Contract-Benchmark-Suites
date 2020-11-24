 

pragma solidity ^0.4.18;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
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
    Transfer(msg.sender, _to, _value);
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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}





 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
   

   

   

   
  function mint(address _to, uint256 _amount) internal returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
}





 
contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}


 
 
 


contract Bela is MintableToken, HasNoEther 
{
     
    using SafeMath for uint;

     
     
     
    
     
     
     
    
     
    
     
     
     
    string public constant name = "Bela";
    string public constant symbol = "BELA";
    uint8 public constant  decimals = 18;

     
     
     

     
    uint public ownerTimeLastMinted;
     
    uint public ownerMintRate;

     
     
    uint private globalMintRate;
     
    uint public totalBelaStaked; 

     
    struct TokenStakeData {
        uint initialStakeBalance;
        uint initialStakeTime;
        uint initialStakePercentage;
        address stakeSplitAddress;
    }
    
     
    mapping (address => TokenStakeData) public stakeBalances;

     
    event Stake(address indexed staker, address indexed stakeSplitAddress, uint256 value);

     
    event Vest(address indexed vester, address indexed stakeSplitAddress, uint256 stakedAmount, uint256 stakingGains);

     
     
     

     
    function Bela() public
    {
         
        owner = msg.sender;
         
        uint _initOwnerSupply = 41000000 ether;
         
        bool _success = mint(msg.sender, _initOwnerSupply);
         
        require(_success);

         
         
         

         
        ownerTimeLastMinted = now;
        
         
        ownerMintRate = calculateFraction(4500, 86400, decimals);
        
         
        globalMintRate = calculateFraction(4900000, 31536000, decimals);
    }

     
    function stakeBela(uint _stakeAmount) external
    {
         
        require(stakeTokens(_stakeAmount));
    }

     
    function stakeBelaSplit(uint _stakeAmount, address _stakeSplitAddress) external
    {
         
        require(_stakeSplitAddress > 0);
         
        stakeBalances[msg.sender].stakeSplitAddress = _stakeSplitAddress;
         
        require(stakeTokens(_stakeAmount));

    }

     
     
    function claimStake() external returns (bool success)
    {
         
         
        require(stakeBalances[msg.sender].initialStakeBalance > 0);
         
        require(now > stakeBalances[msg.sender].initialStakeTime);

         
        uint _timePassedSinceStake = now.sub(stakeBalances[msg.sender].initialStakeTime);

         
        uint _tokensToMint = calculateStakeGains(_timePassedSinceStake);

         
        balances[msg.sender] += stakeBalances[msg.sender].initialStakeBalance;
        
         
        totalBelaStaked -= stakeBalances[msg.sender].initialStakeBalance;
        
         
        if (stakeBalances[msg.sender].stakeSplitAddress > 0) 
        {
             
            mint(msg.sender, _tokensToMint.div(2));
            mint(stakeBalances[msg.sender].stakeSplitAddress, _tokensToMint.div(2));
        } else {
             
            mint(msg.sender, _tokensToMint);
        }
        
         
        Vest(msg.sender, stakeBalances[msg.sender].stakeSplitAddress, stakeBalances[msg.sender].initialStakeBalance, _tokensToMint);

         
        stakeBalances[msg.sender].initialStakeBalance = 0;
        stakeBalances[msg.sender].initialStakeTime = 0;
        stakeBalances[msg.sender].initialStakePercentage = 0;
        stakeBalances[msg.sender].stakeSplitAddress = 0;

        return true;
    }

     
    function getStakedBalance() view external returns (uint stakedBalance) 
    {
        return stakeBalances[msg.sender].initialStakeBalance;
    }

     
    function ownerClaim() external onlyOwner
    {
         
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

     
     
    function stakeTokens(uint256 _value) private returns (bool success)
    {
         
         
        require(_value <= balances[msg.sender]);
         
        require(stakeBalances[msg.sender].initialStakeBalance == 0);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);

         
        stakeBalances[msg.sender].initialStakeBalance = _value;

         
        totalBelaStaked += _value;

         
        stakeBalances[msg.sender].initialStakePercentage = calculateFraction(_value, totalBelaStaked, decimals);
        
         
        stakeBalances[msg.sender].initialStakeTime = now;

         
        Stake(msg.sender, stakeBalances[msg.sender].stakeSplitAddress, _value);

        return true;
    }

     
    function calculateStakeGains(uint _timePassedSinceStake) view private returns (uint mintTotal)
    {
         
        uint _secondsPerDay = 86400;
        uint _finalStakePercentage;      
        uint _stakePercentageAverage;    
        uint _finalMintRate;             
        uint _tokensToMint = 0;          
        
         
        if (_timePassedSinceStake > _secondsPerDay) {
            
             
            
             
            _finalStakePercentage = calculateFraction(stakeBalances[msg.sender].initialStakeBalance, totalBelaStaked, decimals);

             
            _stakePercentageAverage = calculateFraction((stakeBalances[msg.sender].initialStakePercentage.add(_finalStakePercentage)), 2, 0);

             
            _finalMintRate = globalMintRate.mul(_stakePercentageAverage); 
            _finalMintRate = _finalMintRate.div(1 ether);
            
             
            if (_timePassedSinceStake > _secondsPerDay.mul(30)) {
                 
                _tokensToMint = calculateMintTotal(_secondsPerDay.mul(30), _finalMintRate);
            } else {
                 
                _tokensToMint = calculateMintTotal(_timePassedSinceStake, _finalMintRate);
            }
        } 
        
         
        return _tokensToMint;

    }

     
     
     
     
     
    function calculateFraction(uint _numerator, uint _denominator, uint _precision) pure private returns(uint quotient) 
    {
         
        _numerator = _numerator.mul(10 ** (_precision + 1));
         
        uint _quotient = ((_numerator.div(_denominator)) + 5) / 10;
        return (_quotient);
    }

     
     
     
    function calculateMintTotal(uint _timeInSeconds, uint _mintRate) pure private returns(uint mintAmount)
    {
         
        return(_timeInSeconds.mul(_mintRate));
    }

}