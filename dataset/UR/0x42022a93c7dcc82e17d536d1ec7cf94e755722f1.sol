 

pragma solidity ^0.4.18;

 
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

pragma solidity ^0.4.11;


 
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


contract DebtToken {
  using SafeMath for uint256;
   
  string public name;
  string public symbol;
  string public version = 'DT0.1';
  uint256 public decimals = 18;

   
  uint256 public totalSupply;
  mapping(address => uint256) public balances;
  event Transfer(address indexed from, address indexed to, uint256 value);

   
  bool public mintingFinished = true;
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

   
  uint256 public dayLength; 
  uint256 public loanTerm; 
  uint256 public exchangeRate;  
  uint256 public initialSupply;  
  uint256 public loanActivation;  
  
  uint256 public interestRatePerCycle;  
  uint256 public interestCycleLength;  
  
  uint256 public totalInterestCycles;  
  uint256 public lastInterestCycle;  
  
  address public lender;  
  address public borrower;
  
  uint256 public constant PERCENT_DIVISOR = 100;
  
  function DebtToken(
      string _tokenName,
      string _tokenSymbol,
      uint256 _initialAmount,
      uint256 _exchangeRate,
      uint256 _dayLength,
      uint256 _loanTerm,
      uint256 _loanCycle,
      uint256 _interestRatePerCycle,
      address _lender,
      address _borrower
      ) {

      require(_exchangeRate > 0);
      require(_initialAmount > 0);
      require(_dayLength > 0);
      require(_loanCycle > 0);

      require(_lender != 0x0);
      require(_borrower != 0x0);
      
      exchangeRate = _exchangeRate;                            
      initialSupply = _initialAmount.mul(exchangeRate);             
      totalSupply = initialSupply;                            
      balances[_borrower] = initialSupply;                  

      name = _tokenName;                                     
      symbol = _tokenSymbol;                               
      
      dayLength = _dayLength;                              
      loanTerm = _loanTerm;                                
      interestCycleLength = _loanCycle;                    
      interestRatePerCycle = _interestRatePerCycle;                       
      lender = _lender;                              
      borrower = _borrower;

      Transfer(0,_borrower,totalSupply); 
  }

   
  function actualTotalSupply() public constant returns(uint) {
    uint256 coins;
    uint256 cycle;
    (coins,cycle) = calculateInterestDue();
    return totalSupply.add(coins);
  }

   
  function getLoanValue(bool initial) public constant returns(uint){
     
    if(initial == true)
      return initialSupply.div(exchangeRate);
    else{
      uint totalTokens = actualTotalSupply().sub(balances[borrower]);
      return totalTokens.div(exchangeRate);
    }
  }

   
  function getInterest() public constant returns (uint){
    return actualTotalSupply().sub(initialSupply);
  }

   
  function isLender() private constant returns(bool){
    return msg.sender == lender;
  }

   
  function isBorrower() private constant returns (bool){
    return msg.sender == borrower;
  }

  function isLoanFunded() public constant returns(bool) {
    return balances[lender] > 0 && balances[borrower] == 0;
  }

   
  function isTermOver() public constant returns (bool){
    if(loanActivation == 0)
      return false;
    else
      return now >= loanActivation.add( dayLength.mul(loanTerm) );
  }

   
  function isInterestStatusUpdated() public constant returns(bool){
    if(!isTermOver())
      return true;
    else
      return !( now >= lastInterestCycle.add( interestCycleLength.mul(dayLength) ) );
  }

   
  function calculateInterestDue() public constant returns(uint256 _coins,uint256 _cycle){
    if(!isTermOver() || !isLoanFunded())
      return (0,0);
    else{
      uint timeDiff = now.sub(lastInterestCycle);
      _cycle = timeDiff.div(dayLength.mul(interestCycleLength) );
      _coins = _cycle.mul( interestRatePerCycle.mul(initialSupply) ).div(PERCENT_DIVISOR); 
    }
  }

   
  function updateInterest() public {
    require( isTermOver() );
    uint interest_coins;
    uint256 interest_cycle;
    (interest_coins,interest_cycle) = calculateInterestDue();
    assert(interest_coins > 0 && interest_cycle > 0);
    totalInterestCycles =  totalInterestCycles.add(interest_cycle);
    lastInterestCycle = lastInterestCycle.add( interest_cycle.mul( interestCycleLength.mul(dayLength) ) );
    mint(lender , interest_coins);
  }

   
  function fundLoan() public payable{
    require(isLender());
    require(msg.value == getLoanValue(true));  
    require(!isLoanFunded());  

    loanActivation = now;   
    lastInterestCycle = now.add(dayLength.mul(loanTerm) ) ;  
    mintingFinished = false;                  
    transferFrom(borrower,lender,totalSupply);

    borrower.transfer(msg.value);
  }

   
  function refundLoan() onlyBorrower public payable{
    if(! isInterestStatusUpdated() )
        updateInterest();  

    require(msg.value == getLoanValue(false));
    require(isLoanFunded());

    finishMinting() ; 
    transferFrom(lender,borrower,totalSupply);

    lender.transfer(msg.value);
  }

   

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  function transferFrom(address _from, address _to, uint256 _value) internal {
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
  }

   

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) canMint internal returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyBorrower internal returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }


   
  function() public payable{
    require(initialSupply > 0); 
    if(isBorrower())
      refundLoan();
    else if(isLender())
      fundLoan();
    else revert();  
  }

   
  modifier onlyBorrower() {
    require(isBorrower());
    _;
  }
}

contract DebtTokenDeployer is Ownable{

    address public dayTokenAddress;
    uint public dayTokenFees;  
    ERC20 dayToken;

    event FeeUpdated(uint _fee, uint _time);
    event DebtTokenCreated(address  _creator, address _debtTokenAddress, uint256 _time);

    function DebtTokenDeployer(address _dayTokenAddress, uint _dayTokenFees){
        dayTokenAddress = _dayTokenAddress;
        dayTokenFees = _dayTokenFees;
        dayToken = ERC20(dayTokenAddress);
    }

    function updateDayTokenFees(uint _dayTokenFees) onlyOwner public {
        dayTokenFees = _dayTokenFees;
        FeeUpdated(dayTokenFees, now);
    }

    function createDebtToken(string _tokenName,
        string _tokenSymbol,
        uint256 _initialAmount,
        uint256 _exchangeRate,
        uint256 _dayLength,
        uint256 _loanTerm,
        uint256 _loanCycle,
        uint256 _intrestRatePerCycle,
        address _lender)
    public
    {
        if(dayToken.transferFrom(msg.sender, this, dayTokenFees)){
            DebtToken newDebtToken = new DebtToken(_tokenName, _tokenSymbol, _initialAmount, _exchangeRate,
                 _dayLength, _loanTerm, _loanCycle,
                _intrestRatePerCycle, _lender, msg.sender);
            DebtTokenCreated(msg.sender, address(newDebtToken), now);
        }
    }

     
    function fetchDayTokens() onlyOwner public {
        dayToken.transfer(owner, dayToken.balanceOf(this));
    }
}