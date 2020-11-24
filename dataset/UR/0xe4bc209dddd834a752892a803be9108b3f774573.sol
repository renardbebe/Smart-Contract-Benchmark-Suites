 

pragma solidity 0.4.11;

  contract SafeMath {

    function safeMul(uint a, uint b) internal returns (uint) {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }
    function safeSub(uint a, uint b) internal returns (uint) {
      assert(b <= a);
      return a - b;
    }
    function safeAdd(uint a, uint b) internal returns (uint) {
      uint c = a + b;
      assert(c>=a && c>=b);
      return c;
    }

     
     
     
    modifier onlyPayloadSize(uint numWords) {
       assert(msg.data.length >= numWords * 32 + 4);
       _;
    }

  }

  contract Token {  

      function balanceOf(address _owner) constant returns (uint256 balance);
      function transfer(address _to, uint256 _value) returns (bool success);
      function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
      function approve(address _spender, uint256 _value) returns (bool success);
      function allowance(address _owner, address _spender) constant returns (uint256 remaining);
      event Transfer(address indexed _from, address indexed _to, uint256 _value);
      event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  }

   contract C20Vesting is SafeMath {

      address public beneficiary;
      uint256 public fundingEndBlock;

      bool private initClaim = false;  

      uint256 public firstRelease;  
      bool private firstDone = false;
      uint256 public secondRelease;
      bool private secondDone = false;
      uint256 public thirdRelease;
      bool private thirdDone = false;
      uint256 public fourthRelease;

      Token public ERC20Token;  

      enum Stages {
          initClaim,
          firstRelease,
          secondRelease,
          thirdRelease,
          fourthRelease
      }

      Stages public stage = Stages.initClaim;

      modifier atStage(Stages _stage) {
          if(stage == _stage) _;
      }

      function C20Vesting(address _token, uint256 fundingEndBlockInput) {
          require(_token != address(0));
          beneficiary = msg.sender;
          fundingEndBlock = fundingEndBlockInput;
          ERC20Token = Token(_token);
      }

      function changeBeneficiary(address newBeneficiary) external {
          require(newBeneficiary != address(0));
          require(msg.sender == beneficiary);
          beneficiary = newBeneficiary;
      }

      function updateFundingEndBlock(uint256 newFundingEndBlock) {
          require(msg.sender == beneficiary);
          require(block.number < fundingEndBlock);
          require(block.number < newFundingEndBlock);
          fundingEndBlock = newFundingEndBlock;
      }

      function checkBalance() constant returns (uint256 tokenBalance) {
          return ERC20Token.balanceOf(this);
      }

       
       
       
       
       
       
       
       
       
       

      function claim() external {
          require(msg.sender == beneficiary);
          require(block.number > fundingEndBlock);
          uint256 balance = ERC20Token.balanceOf(this);
           
          fourth_release(balance);
          third_release(balance);
          second_release(balance);
          first_release(balance);
          init_claim(balance);
      }

      function nextStage() private {
          stage = Stages(uint256(stage) + 1);
      }

      function init_claim(uint256 balance) private atStage(Stages.initClaim) {
          firstRelease = now + 26 weeks;  
          secondRelease = firstRelease + 26 weeks;
          thirdRelease = secondRelease + 26 weeks;
          fourthRelease = thirdRelease + 26 weeks;
          uint256 amountToTransfer = safeMul(balance, 53846153846) / 100000000000;
          ERC20Token.transfer(beneficiary, amountToTransfer);  
          nextStage();
      }
      function first_release(uint256 balance) private atStage(Stages.firstRelease) {
          require(now > firstRelease);
          uint256 amountToTransfer = balance / 4;
          ERC20Token.transfer(beneficiary, amountToTransfer);  
          nextStage();
      }
      function second_release(uint256 balance) private atStage(Stages.secondRelease) {
          require(now > secondRelease);
          uint256 amountToTransfer = balance / 3;
          ERC20Token.transfer(beneficiary, amountToTransfer);  
          nextStage();
      }
      function third_release(uint256 balance) private atStage(Stages.thirdRelease) {
          require(now > thirdRelease);
          uint256 amountToTransfer = balance / 2;
          ERC20Token.transfer(beneficiary, amountToTransfer);  
          nextStage();
      }
      function fourth_release(uint256 balance) private atStage(Stages.fourthRelease) {
          require(now > fourthRelease);
          ERC20Token.transfer(beneficiary, balance);  
      }

      function claimOtherTokens(address _token) external {
          require(msg.sender == beneficiary);
          require(_token != address(0));
          Token token = Token(_token);
          require(token != ERC20Token);
          uint256 balance = token.balanceOf(this);
          token.transfer(beneficiary, balance);
       }

   }