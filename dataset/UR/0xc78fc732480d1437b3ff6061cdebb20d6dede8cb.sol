 

 

pragma solidity ^0.5.0;


 
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

 

pragma solidity ^0.5.0;


 
contract Ownable {
  address public owner;


   
  constructor () public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 

pragma solidity ^0.5.0;



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  constructor() public {}

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

   
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

 

pragma solidity ^0.5.0;


 
contract Controllable {
  address public controller;


   
  constructor() public {
    controller = msg.sender;
  }

   
  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }

   
  function transferControl(address newController) public onlyController {
    if (newController != address(0)) {
      controller = newController;
    }
  }

}

 

pragma solidity ^0.5.0;


 
contract TokenInterface is Controllable {

  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
  event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
  event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function totalSupply() public view returns (uint);
  function totalSupplyAt(uint _blockNumber) public view returns(uint);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint);
  function transfer(address _to, uint256 _amount) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
  function approve(address _spender, uint256 _amount) public returns (bool success);
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);
  function mint(address _owner, uint _amount) public returns (bool);
  function enableTransfers() public returns (bool);
  function finishMinting() public returns (bool);
}

 

pragma solidity ^0.5.0;



 
 contract WiraTokenSale is Pausable {
   using SafeMath for uint256;

   TokenInterface public token;
   uint256 public totalWeiRaised;
   uint256 public tokensMinted;
   uint256 public contributors;

   bool public teamTokensMinted = false;
   bool public finalized = false;

   address payable tokenSaleWalletAddress;
   address public tokenWalletAddress;
   uint256 public constant FIRST_ROUND_CAP = 20000000 * 10 ** 18;
   uint256 public constant SECOND_ROUND_CAP = 70000000 * 10 ** 18;
   uint256 public constant TOKENSALE_CAP = 122500000 * 10 ** 18;
   uint256 public constant TOTAL_CAP = 408333334 * 10 ** 18;
   uint256 public constant TEAM_TOKENS = 285833334 * 10 ** 18;  

   uint256 public conversionRateInCents = 15000;  
   uint256 public firstRoundStartDate;
   uint256 public firstRoundEndDate;
   uint256 public secondRoundStartDate;
   uint256 public secondRoundEndDate;
   uint256 public thirdRoundStartDate;
   uint256 public thirdRoundEndDate;

   event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
   event Finalized();

   constructor(
     address _tokenAddress,
     uint256 _startDate,
     address _tokenSaleWalletAddress,
     address _tokenWalletAddress
   ) public {
     require(_tokenAddress != address(0));

      token = TokenInterface(_tokenAddress);

       
       
       
       
       
       
       
      firstRoundStartDate = _startDate;
      firstRoundEndDate = _startDate + 518400;
      secondRoundStartDate = _startDate + 604800;
      secondRoundEndDate = _startDate + 1123200;
      thirdRoundStartDate = _startDate + 1209600;
      thirdRoundEndDate = _startDate + 5270400;

      tokenSaleWalletAddress = address(uint160(_tokenSaleWalletAddress));
      tokenWalletAddress = _tokenWalletAddress;
   }

    
   function() external payable {
     buyTokens(msg.sender);
   }


    
   function mintTeamTokens() public onlyOwner {
     require(!teamTokensMinted);
     token.mint(tokenWalletAddress, TEAM_TOKENS);
     teamTokensMinted = true;
   }

    
   function buyTokens(address _beneficiary) public payable whenNotPaused whenNotFinalized {
     require(_beneficiary != address(0));
     validatePurchase();

     uint256 current = now;
     uint256 tokens;

     totalWeiRaised = totalWeiRaised.add(msg.value);

     if (now >= firstRoundStartDate && now <= firstRoundEndDate) {
      tokens = (msg.value * conversionRateInCents) / 10;
     } else if (now >= secondRoundStartDate && now <= secondRoundEndDate) {
       tokens = (msg.value * conversionRateInCents) / 15;
     } else if (now >= thirdRoundStartDate && now <= thirdRoundEndDate) {
       tokens = (msg.value * conversionRateInCents) / 20;
     }

    contributors = contributors.add(1);
    tokensMinted = tokensMinted.add(tokens);

     
    bool earlyBirdSale = (current >= firstRoundStartDate && current <= firstRoundEndDate);
    bool prelaunchSale = (current >= secondRoundStartDate && current <= secondRoundEndDate);
    bool mainSale = (current >= thirdRoundStartDate && current <= thirdRoundEndDate);

    if (earlyBirdSale) require(tokensMinted < FIRST_ROUND_CAP);
    if (prelaunchSale) require(tokensMinted < SECOND_ROUND_CAP);
    if (mainSale) require(tokensMinted < TOKENSALE_CAP);

    token.mint(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, msg.value, tokens);
    forwardFunds();
   }

   function updateConversionRate(uint256 _conversionRateInCents) onlyOwner public {
     conversionRateInCents = _conversionRateInCents;
   }

    
   function forwardFunds() internal {
     address(tokenSaleWalletAddress).transfer(msg.value);
   }

   function currentDate() public view returns (uint256) {
     return now;
   }

    
   function validatePurchase() internal returns (bool) {
     uint256 current = now;
     bool duringFirstRound = (current >= firstRoundStartDate && current <= firstRoundEndDate);
     bool duringSecondRound = (current >= secondRoundStartDate && current <= secondRoundEndDate);
     bool duringThirdRound = (current >= thirdRoundStartDate && current <= thirdRoundEndDate);
     bool nonZeroPurchase = msg.value != 0;

     require(duringFirstRound || duringSecondRound || duringThirdRound);
     require(nonZeroPurchase);
   }

    
   function totalSupply() public view returns (uint256) {
     return token.totalSupply();
   }

    
   function balanceOf(address _owner) public view returns (uint256) {
     return token.balanceOf(_owner);
   }

    
   function changeController(address _newController) public onlyOwner {
     require(isContract(_newController));
     token.transferControl(_newController);
   }

   function finalize() public onlyOwner {
     require(paused);
     emit Finalized();

    uint256 remainingTokens = TOKENSALE_CAP - tokensMinted;
    token.mint(tokenWalletAddress, remainingTokens);

     finalized = true;
   }

   function enableTransfers() public onlyOwner {
     token.enableTransfers();
   }


   function isContract(address _addr) view internal returns(bool) {
     uint size;
     if (_addr == address(0))
       return false;
     assembly {
         size := extcodesize(_addr)
     }
     return size>0;
   }

   modifier whenNotFinalized() {
     require(!finalized);
     _;
   }

 }