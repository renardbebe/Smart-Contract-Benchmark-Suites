 

pragma solidity 0.4.18;

contract Token {  

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

contract SafeMath {

  function safeMul(uint a, uint b) pure internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function safeSub(uint a, uint b) pure internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function safeAdd(uint a, uint b) pure internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  function safeNumDigits(uint number) pure internal returns (uint8) {
    uint8 digits = 0;
    while (number != 0) {
        number /= 10;
        digits++;
    }
    return digits;
}

   
   
   
  modifier onlyPayloadSize(uint numWords) {
     assert(msg.data.length >= numWords * 32 + 4);
     _;
  }

}
 

contract GROVesting is SafeMath {

  address public beneficiary;
  uint256 public fundingEndBlock;

  bool private initClaim = false;  

  uint256 public firstRelease;  
  bool private firstDone = false;
  uint256 public secondRelease;
  bool private secondDone = false;
  uint256 public thirdRelease;

  Token public ERC20Token;  

  enum Stages {
    initClaim,
    firstRelease,
    secondRelease,
    thirdRelease
  }

  Stages public stage = Stages.initClaim;

  modifier atStage(Stages _stage){
    if (stage == _stage) _;
  }

  modifier onlyBeneficiary {
    require(msg.sender == beneficiary);
    _;
  }

  function GROVesting() public {
    beneficiary = msg.sender;
  }

   
   
  function initialiseContract(address _token, uint256 fundingEndBlockInput) external onlyBeneficiary {
    require(_token != address(0));
    fundingEndBlock = fundingEndBlockInput;
    ERC20Token = Token(_token);
  }
    
  function changeBeneficiary(address newBeneficiary) external {
    require(newBeneficiary != address(0));
    require(msg.sender == beneficiary);
    beneficiary = newBeneficiary;
  }

  function updateFundingEndBlock(uint256 newFundingEndBlock) public {
    require(msg.sender == beneficiary);
    require(currentBlock() < fundingEndBlock);
    require(currentBlock() < newFundingEndBlock);
    fundingEndBlock = newFundingEndBlock;
  }

  function checkBalance() public constant returns (uint256 tokenBalance) {
    return ERC20Token.balanceOf(this);
  }

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   

  function claim() external {
    require(msg.sender == beneficiary);
    require(currentBlock() > fundingEndBlock);
    uint256 balance = ERC20Token.balanceOf(this);
     
    third_release(balance);
    second_release(balance);
    first_release(balance);
    init_claim(balance);
  }

  function nextStage() private {
    stage = Stages(uint256(stage) + 1);
  }

  function init_claim(uint256 balance) private atStage(Stages.initClaim) {
    firstRelease = currentTime() + 26 weeks;                           
    secondRelease = currentTime() + 52 weeks;                          
    thirdRelease = secondRelease + 52 weeks;                 
    uint256 amountToTransfer = safeMul(balance, 40) / 100;   
    ERC20Token.transfer(beneficiary, amountToTransfer);      
    nextStage();
  }
  function first_release(uint256 balance) private atStage(Stages.firstRelease) {
    require(currentTime() > firstRelease);
    uint256 amountToTransfer = safeMul(balance, 30) / 100;   
    ERC20Token.transfer(beneficiary, amountToTransfer);      
    nextStage();
  }
  function second_release(uint256 balance) private atStage(Stages.secondRelease) {
    require(currentTime() > secondRelease);
    uint256 amountToTransfer = balance / 2;              
    ERC20Token.transfer(beneficiary, amountToTransfer);  
    nextStage();
  }
  function third_release(uint256 balance) private atStage(Stages.thirdRelease) {
    require(currentTime() > thirdRelease);
    uint256 amountToTransfer = balance;                  
    ERC20Token.transfer(beneficiary, amountToTransfer);
    nextStage();
  }

  function claimOtherTokens(address _token) external {
    require(msg.sender == beneficiary);
    require(_token != address(0));
    Token token = Token(_token);
    require(token != ERC20Token);
    uint256 balance = token.balanceOf(this);
    token.transfer(beneficiary, balance);
  }

  function currentBlock() private constant returns(uint256 _currentBlock) {
    return block.number;
  }

  function currentTime() private constant returns(uint256 _currentTime) {
    return now;
  } 
}