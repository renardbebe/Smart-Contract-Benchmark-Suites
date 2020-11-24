 

 

 
contract TokenInterface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _amount) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success);
    function approve(address _spender, uint256 _amount) returns (bool success);
    function allowance(
        address _owner,
        address _spender
    ) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );
}


 
contract Token_Offer {
  address public tokenHolder;
  address public owner;
  TokenInterface public tokenContract;
  uint16 public price;   
  uint public tokensPurchasedTotal;
  uint public ethCostTotal;

  event TokensPurchased(address buyer, uint16 price, uint tokensPurchased, uint ethCost, uint ethSent, uint ethReturned, uint tokenSupplyLeft);
  event Log(string msg, uint val);

  modifier onlyOwnerAllowed() {if (tx.origin != owner) throw; _}

  function Token_Offer(address _tokenContract, address _tokenHolder, uint16 _price)  {
    owner = tx.origin;
    tokenContract = TokenInterface(_tokenContract);
    tokenHolder = _tokenHolder;
    price = _price;
  }

  function tokenSupply() constant returns (uint tokens) {
    uint allowance = tokenContract.allowance(tokenHolder, address(this));
    uint balance = tokenContract.balanceOf(tokenHolder);
    if (allowance < balance) return allowance;
    else return balance;
  }

  function () {
    buyTokens(price);
  }

  function buyTokens() {
    buyTokens(price);
  }

   
   
  function buyTokens(uint16 _bidPrice) {
    if (tx.origin != msg.sender) {  
      if (!msg.sender.send(msg.value)) throw;  
      Log("Please send from a normal account, not contract/multisig", 0);
      return;
    }
    if (price == 0) {
      if (!tx.origin.send(msg.value)) throw;  
      Log("Contract disabled", 0);
      return;
    }
    if (_bidPrice < price) {
      if (!tx.origin.send(msg.value)) throw;  
      Log("Bid too low, price is:", price);
      return;
    }
    if (msg.value == 0) {
      Log("No ether received", 0);
      return;
    }
    uint _tokenSupply = tokenSupply();
    if (_tokenSupply == 0) {
      if (!tx.origin.send(msg.value)) throw;  
      Log("No tokens available, please try later", 0);
      return;
    }

    uint _tokensToPurchase = (msg.value * 1000) / price;

    if (_tokensToPurchase <= _tokenSupply) {  
      if (!tokenContract.transferFrom(tokenHolder, tx.origin, _tokensToPurchase))  
        throw;
      tokensPurchasedTotal += _tokensToPurchase;
      ethCostTotal += msg.value;
      TokensPurchased(tx.origin, price, _tokensToPurchase, msg.value, msg.value, 0, _tokenSupply-_tokensToPurchase);

    } else {  
      uint _supplyInEth = (_tokenSupply * price) / 1000;
      if (!tx.origin.send(msg.value-_supplyInEth))  
        throw;
      if (!tokenContract.transferFrom(tokenHolder, tx.origin, _tokenSupply))  
        throw;
      tokensPurchasedTotal += _tokenSupply;
      ethCostTotal += _supplyInEth;
      TokensPurchased(tx.origin, price, _tokenSupply, _supplyInEth, msg.value, msg.value-_supplyInEth, 0);
    }
  }

   
  function setPrice(uint16 _price) onlyOwnerAllowed {
    price = _price;
    Log("Price changed:", price);  
  }
  function tokenSupplyChanged() onlyOwnerAllowed {
    Log("Supply changed, new supply:", tokenSupply());  
  }
  function setTokenHolder(address _tokenHolder) onlyOwnerAllowed {
    tokenHolder = _tokenHolder;
  }
  function setOwner(address _owner) onlyOwnerAllowed {
    owner = _owner;
  }
  function transferETH(address _to, uint _amount) onlyOwnerAllowed {
    if (_amount > address(this).balance) {
      _amount = address(this).balance;
    }
    _to.send(_amount);
  }
}