 

pragma solidity ^0.4.15;

contract Controllable {
  address public controller;


   
  function Controllable() public {
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

contract Ownable {
  address public owner;


   
  function Ownable() public {
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

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  function Pausable() public {}

   
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
    Pause();
    return true;
  }

   
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract TokenSale is Pausable {

  using SafeMath for uint256;

  ProofTokenInterface public proofToken;
  uint256 public totalWeiRaised;
  uint256 public tokensMinted;
  uint256 public totalSupply;
  uint256 public contributors;
  uint256 public decimalsMultiplier;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public remainingTokens;
  uint256 public allocatedTokens;

  bool public finalized;

  bool public proofTokensAllocated;
  address public proofMultiSig = 0x99892Ac6DA1b3851167Cb959fE945926bca89f09;

  uint256 public constant BASE_PRICE_IN_WEI = 88000000000000000;
  uint256 public constant PUBLIC_TOKENS = 1181031 * (10 ** 18);
  uint256 public constant TOTAL_PRESALE_TOKENS = 112386712924725508802400;
  uint256 public constant TOKENS_ALLOCATED_TO_PROOF = 1181031 * (10 ** 18);



  uint256 public tokenCap = PUBLIC_TOKENS - TOTAL_PRESALE_TOKENS;
  uint256 public cap = tokenCap / (10 ** 18);
  uint256 public weiCap = cap * BASE_PRICE_IN_WEI;

  uint256 public firstDiscountPrice = (BASE_PRICE_IN_WEI * 85) / 100;
  uint256 public secondDiscountPrice = (BASE_PRICE_IN_WEI * 90) / 100;
  uint256 public thirdDiscountPrice = (BASE_PRICE_IN_WEI * 95) / 100;

  uint256 public firstDiscountCap = (weiCap * 5) / 100;
  uint256 public secondDiscountCap = (weiCap * 10) / 100;
  uint256 public thirdDiscountCap = (weiCap * 20) / 100;

  bool public started = false;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event NewClonedToken(address indexed _cloneToken);
  event OnTransfer(address _from, address _to, uint _amount);
  event OnApprove(address _owner, address _spender, uint _amount);
  event LogInt(string _name, uint256 _value);
  event Finalized();

  function TokenSale(address _tokenAddress, uint256 _startTime, uint256 _endTime) public {
    require(_tokenAddress != 0x0);
    require(_startTime > 0);
    require(_endTime > _startTime);

    startTime = _startTime;
    endTime = _endTime;
    proofToken = ProofTokenInterface(_tokenAddress);

    decimalsMultiplier = (10 ** 18);
  }


   
  function() public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable whenNotPaused whenNotFinalized {
    require(_beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 priceInWei = getPriceInWei();
    totalWeiRaised = totalWeiRaised.add(weiAmount);

    uint256 tokens = weiAmount.mul(decimalsMultiplier).div(priceInWei);
    tokensMinted = tokensMinted.add(tokens);
    require(tokensMinted < tokenCap);

    contributors = contributors.add(1);

    proofToken.mint(_beneficiary, tokens);
    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    forwardFunds();
  }


   
  function getPriceInWei() constant public returns (uint256) {

    uint256 price;

    if (totalWeiRaised < firstDiscountCap) {
      price = firstDiscountPrice;
    } else if (totalWeiRaised < secondDiscountCap) {
      price = secondDiscountPrice;
    } else if (totalWeiRaised < thirdDiscountCap) {
      price = thirdDiscountPrice;
    } else {
      price = BASE_PRICE_IN_WEI;
    }

    return price;
  }

   
  function forwardFunds() internal {
    proofMultiSig.transfer(msg.value);
  }


   
  function validPurchase() internal constant returns (bool) {
    uint256 current = now;
    bool presaleStarted = (current >= startTime || started);
    bool presaleNotEnded = current <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return nonZeroPurchase && presaleStarted && presaleNotEnded;
  }

   
  function totalSupply() public constant returns (uint256) {
    return proofToken.totalSupply();
  }

   
  function balanceOf(address _owner) public constant returns (uint256) {
    return proofToken.balanceOf(_owner);
  }

   
  function changeController(address _newController) public {
    require(isContract(_newController));
    proofToken.transferControl(_newController);
  }


  function enableTransfers() public {
    if (now < endTime) {
      require(msg.sender == owner);
    }
    proofToken.enableTransfers(true);
  }

  function lockTransfers() public onlyOwner {
    require(now < endTime);
    proofToken.enableTransfers(false);
  }

  function enableMasterTransfers() public onlyOwner {
    proofToken.enableMasterTransfers(true);
  }

  function lockMasterTransfers() public onlyOwner {
    proofToken.enableMasterTransfers(false);
  }

  function forceStart() public onlyOwner {
    started = true;
  }

  function allocateProofTokens() public onlyOwner whenNotFinalized {
    proofToken.mint(proofMultiSig, TOKENS_ALLOCATED_TO_PROOF);
    proofTokensAllocated = true;
  }

  function finalize() public onlyOwner {
    require(paused);
    require(proofTokensAllocated);

    proofToken.finishMinting();
    proofToken.enableTransfers(true);
    Finalized();

    finalized = true;
  }


  function isContract(address _addr) constant internal returns(bool) {
    uint size;
    if (_addr == 0)
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

contract ProofTokenInterface is Controllable {

  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
  event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
  event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function totalSupply() public constant returns (uint);
  function totalSupplyAt(uint _blockNumber) public constant returns(uint);
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint);
  function transfer(address _to, uint256 _amount) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
  function approve(address _spender, uint256 _amount) public returns (bool success);
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  function mint(address _owner, uint _amount) public returns (bool);
  function importPresaleBalances(address[] _addresses, uint256[] _balances, address _presaleAddress) public returns (bool);
  function lockPresaleBalances() public returns (bool);
  function finishMinting() public returns (bool);
  function enableTransfers(bool _value) public;
  function enableMasterTransfers(bool _value) public;
  function createCloneToken(uint _snapshotBlock, string _cloneTokenName, string _cloneTokenSymbol) public returns (address);

}