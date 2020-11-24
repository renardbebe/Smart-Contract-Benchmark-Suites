 

pragma solidity ^0.4.24;

contract CryptoPunk
{
  function punkIndexToAddress(uint256 punkIndex) public view returns (address ownerAddress);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function transferPunk(address to, uint punkIndex) public;
}

contract ERC20
{
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function transfer(address to, uint tokens) public returns (bool success);
}

contract PunkLombard
{
  address public CryptoPunksContract;

  uint256 public loanAmount;  
  uint256 public punkIndex;  
  uint256 public annualInterestRate;  
  uint256 public loanTenor;  
  uint256 public loanPeriod;  
  address public lender;  
  address public borrower;  
  uint256 public loanStart;  
  uint256 public loanEnd;  
  uint256 public interest;  

  address public contractOwner;

  modifier onlyOwner
  {
    if (msg.sender != contractOwner) revert();
    _;
  }

  modifier onlyLender
  {
    if (msg.sender != lender) revert();
    _;
  }

  constructor () public
  {
    CryptoPunksContract = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;  
    contractOwner = msg.sender;
    borrower = msg.sender;
  }

  function transferContractOwnership(address newContractOwner) public onlyOwner
  {
    contractOwner = newContractOwner;
  }

  function setTerms(uint256 _loanAmount, uint256 _annualInterestRate, uint256 _loanTenor, uint256 _punkIndex) public onlyOwner
  {
    require(CryptoPunk(CryptoPunksContract).balanceOf(address(this)) == 1);
    loanAmount = _loanAmount;
    annualInterestRate = _annualInterestRate;
    loanTenor = _loanTenor;
    punkIndex = _punkIndex;
  }


  function claimCollateral() public onlyLender  
  {
    require(now > (loanStart + loanTenor));
    CryptoPunk(CryptoPunksContract).transferPunk(lender, punkIndex);  
  }

  function () payable public
  {

    if(msg.sender == borrower)  
    {
      require(now <= (loanStart + loanTenor));  
      uint256 loanPeriodCheck = (now - loanStart);
      interest = (((loanAmount * annualInterestRate) / 10 ** 18) * loanPeriodCheck) / 365 days;
      require(msg.value >= loanAmount + interest);
      loanPeriod = loanPeriodCheck;
      loanEnd = now;
      uint256 change = msg.value - (loanAmount + interest);
      lender.transfer(loanAmount + interest);
      if(change > 0)
      {
        borrower.transfer(change);
      }
      CryptoPunk(CryptoPunksContract).transferPunk(borrower, punkIndex);  
    }

    if(msg.sender != borrower)  
    {
      require(loanStart == 0);  
      require(CryptoPunk(CryptoPunksContract).balanceOf(address(this)) == 1);  
      require(CryptoPunk(CryptoPunksContract).punkIndexToAddress(punkIndex) == address(this));   
      require(msg.value >= loanAmount);  
      lender = msg.sender;
      loanStart = now;
      if(msg.value > loanAmount)  
      {
        msg.sender.transfer(msg.value-loanAmount);  
      }
      borrower.transfer(loanAmount);  
    }

  }

   
  function transfer_targetToken(address target, address to, uint256 quantity) public onlyOwner
  {
    ERC20(target).transfer(to, quantity);
  }

   
  function reclaimPunkBeforeLoan(address _to, uint256 _punkIndex) public onlyOwner
  {
    require(loanStart == 0);
    CryptoPunk(CryptoPunksContract).transferPunk(_to, _punkIndex);
  }
}