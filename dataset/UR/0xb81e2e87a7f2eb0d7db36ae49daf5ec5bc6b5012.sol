 

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


 
contract ERC20 {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
}


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


 
contract QWoodDAOTokenSale is Pausable {
  using SafeMath for uint256;


   
  struct ReceivedToken {
     
    string name;

     
    uint256 rate;

     
    uint256 raised;
  }


   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  mapping (address => ReceivedToken) public receivedTokens;


   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  event TokenForTokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  event ChangeRate(uint256 newRate);

   
  event AddReceivedToken(
    address indexed tokenAddress,
    string name,
    uint256 rate
  );

   
  event RemoveReceivedToken(address indexed tokenAddress);

   
  event SetReceivedTokenRate(
    address indexed tokenAddress,
    uint256 newRate
  );

   
  event SendEtherExcess(
    address indexed beneficiary,
    uint256 value
  );

   
  event SendTokensExcess(
    address indexed beneficiary,
    uint256 value
  );

   
  event ReceivedTokens(
    address indexed from,
    uint256 amount,
    address indexed tokenAddress,
    bytes extraData
  );


   
  constructor (
    uint256 _rate,
    address _wallet,
    ERC20 _token
  )
    public
  {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }


   
   
   

   
  function () whenNotPaused external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) whenNotPaused public payable {
    require(_beneficiary != address(0));

    uint256 weiAmount = msg.value;
    require(weiAmount != 0);

    uint256 tokenBalance = token.balanceOf(address(this));
    require(tokenBalance > 0);

    uint256 tokens = _getTokenAmount(address(0), weiAmount);

    if (tokens > tokenBalance) {
      tokens = tokenBalance;
      weiAmount = _inverseGetTokenAmount(address(0), tokens);

      uint256 senderExcess = msg.value.sub(weiAmount);
      msg.sender.transfer(senderExcess);

      emit SendEtherExcess(
        msg.sender,
        senderExcess
      );
    }

    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );
  }

   
  function setRate(uint256 _newRate) onlyOwner external {
    require(_newRate > 0);
    rate = _newRate;

    emit ChangeRate(_newRate);
  }

   
  function setWallet(address _newWallet) onlyOwner external {
    require(_newWallet != address(0));
    wallet = _newWallet;
  }

   
  function setToken(ERC20 _newToken) onlyOwner external {
    require(_newToken != address(0));
    token = _newToken;
  }

   
  function withdrawTokens(ERC20 _tokenContract) onlyOwner external {
    require(_tokenContract != address(0));

    uint256 amount = _tokenContract.balanceOf(address(this));
    _tokenContract.transfer(wallet, amount);
  }

   
  function withdraw() onlyOwner external {
    wallet.transfer(address(this).balance);
  }

   
  function addReceivedToken(
    ERC20 _tokenAddress,
    string _tokenName,
    uint256 _tokenRate
  )
    onlyOwner
    external
  {
    require(_tokenAddress != address(0));
    require(_tokenRate > 0);

    ReceivedToken memory _token = ReceivedToken({
      name: _tokenName,
      rate: _tokenRate,
      raised: 0
    });

    receivedTokens[_tokenAddress] = _token;

    emit AddReceivedToken(
      _tokenAddress,
      _token.name,
      _token.rate
    );
  }

   
  function removeReceivedToken(ERC20 _tokenAddress) onlyOwner external {
    require(_tokenAddress != address(0));

    delete receivedTokens[_tokenAddress];

    emit RemoveReceivedToken(_tokenAddress);
  }

   
  function setReceivedTokenRate(
    ERC20 _tokenAddress,
    uint256 _newTokenRate
  )
    onlyOwner
    external
  {
    require(_tokenAddress != address(0));
    require(receivedTokens[_tokenAddress].rate > 0);
    require(_newTokenRate > 0);

    receivedTokens[_tokenAddress].rate = _newTokenRate;

    emit SetReceivedTokenRate(
      _tokenAddress,
      _newTokenRate
    );
  }

   
  function receiveApproval(
    address _from,
    uint256 _amount,
    address _tokenAddress,
    bytes _extraData
  )
    whenNotPaused external
  {

    require(_from != address(0));
    require(_tokenAddress != address(0));
    require(receivedTokens[_tokenAddress].rate > 0);  
    require(_amount > 0);

    require(msg.sender == _tokenAddress);

    emit ReceivedTokens(
      _from,
      _amount,
      _tokenAddress,
      _extraData
    );

    _exchangeTokens(ERC20(_tokenAddress), _from, _amount);
  }

   
  function depositToken(
    ERC20 _tokenAddress,
    uint256 _amount
  )
    whenNotPaused external
  {
     
     
    require(_tokenAddress != address(0));

    require(receivedTokens[_tokenAddress].rate > 0);
    require(_amount > 0);

    _exchangeTokens(_tokenAddress, msg.sender, _amount);
  }


   
   
   

   
  function _exchangeTokens(
    ERC20 _tokenAddress,
    address _sender,
    uint256 _amount
  )
    internal
  {
    uint256 foreignTokenAmount = _amount;

    require(_tokenAddress.transferFrom(_sender, address(this), foreignTokenAmount));

    uint256 tokenBalance = token.balanceOf(address(this));
    require(tokenBalance > 0);

    uint256 tokens = _getTokenAmount(_tokenAddress, foreignTokenAmount);

    if (tokens > tokenBalance) {
      tokens = tokenBalance;
      foreignTokenAmount = _inverseGetTokenAmount(_tokenAddress, tokens);

      uint256 senderForeignTokenExcess = _amount.sub(foreignTokenAmount);
      _tokenAddress.transfer(_sender, senderForeignTokenExcess);

      emit SendTokensExcess(
        _sender,
        senderForeignTokenExcess
      );
    }

    receivedTokens[_tokenAddress].raised = receivedTokens[_tokenAddress].raised.add(foreignTokenAmount);

    _processPurchase(_sender, tokens);
    emit TokenForTokenPurchase(
      _sender,
      _sender,
      foreignTokenAmount,
      tokens
    );
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _getTokenAmount(address _tokenAddress, uint256 _amount)
    internal view returns (uint256)
  {
    uint256 _rate;

    if (_tokenAddress == address(0)) {
      _rate = rate;
    } else {
      _rate = receivedTokens[_tokenAddress].rate;
    }

    return _amount.mul(_rate);
  }

   
  function _inverseGetTokenAmount(address _tokenAddress, uint256 _tokenAmount)
    internal view returns (uint256)
  {
    uint256 _rate;

    if (_tokenAddress == address(0)) {
      _rate = rate;
    } else {
      _rate = receivedTokens[_tokenAddress].rate;
    }

    return _tokenAmount.div(_rate);
  }
}