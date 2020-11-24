 

pragma solidity ^0.4.23;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract token { function transfer(address receiver, uint amount){ receiver; amount; } }

 
contract Crowdsale {
  using SafeMath for uint256;

   
  token public vppToken;

   
  address public owner;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

  modifier onlyOwner() { 
    require (msg.sender == owner); 
    _;
  }
  
   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, token _vppToken) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_vppToken != address(0));

    owner = msg.sender;
    rate = _rate;
    wallet = _wallet;
    vppToken = _vppToken;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _forwardFunds();

  }

   
   
   
    
  function ownerTokenTransfer(address _beneficiary, uint _tokenAmount) public onlyOwner {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

    
  function ownerSetOwner(address _newOwner) public onlyOwner {
    owner = _newOwner;
  }

    
  function ownerSetWallet(address _newWallet) public onlyOwner {
    wallet = _newWallet;
  }

    
  function ownerSetRate(uint256 _newRate) public onlyOwner {
    rate = _newRate;
  }

    
  function ownerSelfDestruct() public onlyOwner {
    selfdestruct(owner);
  }



   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal pure
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }


   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    vppToken.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}