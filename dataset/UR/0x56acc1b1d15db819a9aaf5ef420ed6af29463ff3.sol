 

pragma solidity ^0.4.15;

 
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

contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     

    function transfer(address _to, uint256 _value) returns (bool) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }else {
            return false;
        }
    }
    

     

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
}


     

    function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract TalentToken is BasicToken {

using SafeMath for uint256;

string public name = "Talent Token";              
string public symbol = "TAL";                                
uint8 public decimals = 18;                                  
uint256 public totalSupply = 98000000 * 10**18;              

 
uint256 public TotalTokens;                 
uint256 public LongTermProjectTokens;       
uint256 public TeamFundsTokens;             
uint256 public IcoTokens;                   
uint256 public platformTokens;              

 
address public owner;                                
address public crowdFundAddress;                     
address public founderAddress = 0xe3f38940A588922F2082FE30bCAe6bB0aa633a7b;
address public LongTermProjectTokensAddress = 0x689Aff79dCAbdFd611273703C62821baBb39823a;
address public teamFundsAddress = 0x2dd75A9A6C99B824811e3aCe16a63882Ff4C1C03;
address public platformTokensAddress = 0x5F0Be8081692a3A96d2ad10Ae5ce14488a045B10;

 

event ChangeFoundersWalletAddress(uint256  _blockTimeStamp, address indexed _foundersWalletAddress);

 

  modifier onlyCrowdFundAddress() {
    require(msg.sender == crowdFundAddress);
    _;
  }

  modifier nonZeroAddress(address _to) {
    require(_to != 0x0);
    _;
  }

  modifier onlyFounders() {
    require(msg.sender == founderAddress);
    _;
  }
  
    
   function TalentToken (address _crowdFundAddress) {
    owner = msg.sender;
    crowdFundAddress = _crowdFundAddress;

     
    LongTermProjectTokens = 22540000 * 10**18;     
    TeamFundsTokens = 1960000 * 10**18;            
    platformTokens = 19600000 * 10**18;            
    IcoTokens = 53900000 * 10**18;                 

     
    balances[crowdFundAddress] = IcoTokens;
    balances[LongTermProjectTokensAddress] = LongTermProjectTokens;
    balances[teamFundsAddress] = TeamFundsTokens;
    balances[platformTokensAddress] = platformTokens;

  }


 
  function () {
    revert();
  }

}

contract TalentICO {

    using SafeMath for uint256;
    
    TalentToken public token;                                  
         
    uint256 public IcoStartDate = 1519862400;                  
    uint256 public IcoEndDate = 1546300799;                    
    uint256 public WeiRaised;                                  
    uint256 public initialExchangeRateForETH = 15000;          
    uint256 internal IcoTotalTokensSold = 0;
    uint256 internal minAmount = 1 * 10 ** 17;                 
    bool internal isTokenDeployed = false;                     


      
    address public founderAddress = 0xe3f38940A588922F2082FE30bCAe6bB0aa633a7b;                            
     
    address public owner;                                              
    
    enum State {Crowdfund, Finish}

     
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount); 
    event CrowdFundClosed(uint256 _blockTimeStamp);
    event ChangeFoundersWalletAddress(uint256 _blockTimeStamp, address indexed _foundersWalletAddress);
   
     
    modifier tokenIsDeployed() {
        require(isTokenDeployed == true);
        _;
    }
    modifier nonZeroEth() {
        require(msg.value > 0);
        _;
    }

    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier onlyFounders() {
        require(msg.sender == founderAddress);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPublic() {
        require(msg.sender != founderAddress);
        _;
    }

    modifier inState(State state) {
        require(getState() == state); 
        _;
    }

      
    function TalentICO () {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public onlyOwner returns (bool) {
        owner = newOwner;
    }

     
    function setTokenAddress(address _tokenAddress) external onlyFounders nonZeroAddress(_tokenAddress) {
        require(isTokenDeployed == false);
        token = TalentToken(_tokenAddress);
        isTokenDeployed = true;
    }


     
     function setfounderAddress(address _newFounderAddress) onlyFounders  nonZeroAddress(_newFounderAddress) {
        founderAddress = _newFounderAddress;
        ChangeFoundersWalletAddress(now, founderAddress);
    }

     
     
    function ICOend() onlyFounders inState(State.Finish) returns (bool) {
        require(now > IcoEndDate);
        uint256 remainingToken = token.balanceOf(this);   
        if (remainingToken != 0) 
          token.transfer(founderAddress, remainingToken); 
        CrowdFundClosed(now);
        return true; 
    }

     
    function buyTokens(address beneficiary) 
    nonZeroEth 
    tokenIsDeployed 
    onlyPublic 
    nonZeroAddress(beneficiary) 
    payable 
    returns(bool) 
    {
        require(msg.value >= minAmount);

        require(now >= IcoStartDate && now <= IcoEndDate);
        fundTransfer(msg.value);

        uint256 amount = numberOfTokens(getCurrentExchangeRate(), msg.value);
            
        if (token.transfer(beneficiary, amount)) {
            IcoTotalTokensSold = IcoTotalTokensSold.add(amount);
            WeiRaised = WeiRaised.add(msg.value);
            TokenPurchase(beneficiary, msg.value, amount);
            return true;
        } 

    return false;
       
    }

     
     
    function getCurrentExchangeRate() internal view returns (uint256) {

        uint256 timeDiff = IcoEndDate - IcoStartDate;

        uint256 etherDiff = 11250;  

        uint256 initialTimeDiff = now - IcoStartDate;

        uint256 exchangeRateLess = (initialTimeDiff * etherDiff) / timeDiff;

        return (initialExchangeRateForETH - exchangeRateLess);    

    }
           

 
    function numberOfTokens(uint256 _exchangeRate, uint256 _amount) internal constant returns (uint256) {
         uint256 noOfToken = _amount.mul(_exchangeRate);
         return noOfToken;
    }

     
    function fundTransfer(uint256 weiAmount) internal {
        founderAddress.transfer(weiAmount);
    }


 

     
    function getState() public constant returns(State) {

        if (now >= IcoStartDate && now <= IcoEndDate) {
            return State.Crowdfund;
        } 
        return State.Finish;
    }

     

    function getExchangeRate() public constant returns (uint256 _exchangeRateForETH) {

        return getCurrentExchangeRate();
    
    }

    function getNoOfSoldToken() public constant returns (uint256 _IcoTotalTokensSold) {
        return (IcoTotalTokensSold);
    }

    function getWeiRaised() public constant returns (uint256 _WeiRaised) {
        return WeiRaised;
    }

     
    function() public payable {
        buyTokens(msg.sender);
    }
}