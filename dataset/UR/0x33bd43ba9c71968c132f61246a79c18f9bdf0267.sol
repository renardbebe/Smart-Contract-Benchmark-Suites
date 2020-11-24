 

pragma solidity ^0.4.25;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract BouncyCoinSelfdrop {

  event TokensSold(address buyer, uint256 tokensAmount, uint256 ethAmount);

   
  uint256 public constant MAX_TOKENS_SOLD = 14000000000 * 10**18;

   
  uint256 public constant PRICE = 0.00000006665 * 10**18;

  uint256 public constant MIN_CONTRIBUTION = 0.01 ether;

  uint256 public constant HARD_CAP = 500 ether;

   
   
  uint256 oct_17 = 1539734400;

   
   
  uint256 oct_24 = 1540339200;

   
   
  uint256 oct_28 = 1540684800;

   
  uint256 public first_round_base_multiplier = 40;  
  uint256 public second_round_base_multiplier = 20;  
  uint256 public third_round_base_multiplier = 0;  

  address public owner;

  address public wallet;

  uint256 public tokensSold;

  uint256 public totalReceived;

  ERC20 public bouncyCoinToken;

   
  Stages public stage;

  enum Stages {
    Deployed,
    Started,
    Ended
  }

   

  modifier atStage(Stages _stage) {
    require(stage == _stage);
    _;
  }

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

   

  constructor(address _wallet, address _bouncyCoinToken)
    public {
    require(_wallet != 0x0);
    require(_bouncyCoinToken != 0x0);

    owner = msg.sender;
    wallet = _wallet;
    bouncyCoinToken = ERC20(_bouncyCoinToken);
    stage = Stages.Deployed;
  }

   

  function()
    public
    payable {
    if (stage == Stages.Started) {
      buyTokens();
    } else {
      revert();
    }
  }

  function buyTokens()
    public
    payable
    atStage(Stages.Started) {
    require(msg.value >= MIN_CONTRIBUTION);

    uint256 base_multiplier;
    if (now > oct_28) {
      base_multiplier = third_round_base_multiplier;
    } else if (now > oct_24) {
      base_multiplier = second_round_base_multiplier;
    } else if (now > oct_17) {
      base_multiplier = first_round_base_multiplier;
    } else {
      base_multiplier = 0;
    }

    uint256 multiplier;
    if (msg.value >= 1 ether) multiplier = base_multiplier + 10;
    else multiplier = base_multiplier;

    uint256 amountRemaining = msg.value;

    uint256 tokensAvailable = MAX_TOKENS_SOLD - tokensSold;
    uint256 baseTokens = amountRemaining * 10**18 / PRICE;
     
    uint256 maxTokensByAmount = baseTokens + ((baseTokens * multiplier) / 100);

    uint256 tokensToReceive = 0;
    if (maxTokensByAmount > tokensAvailable) {
      tokensToReceive = tokensAvailable;
      amountRemaining -= (PRICE * tokensToReceive) / 10**18;
    } else {
      tokensToReceive = maxTokensByAmount;
      amountRemaining = 0;
    }
    tokensSold += tokensToReceive;

    assert(tokensToReceive > 0);
    assert(bouncyCoinToken.transfer(msg.sender, tokensToReceive));

    if (amountRemaining != 0) {
      msg.sender.transfer(amountRemaining);
    }

    uint256 amountAccepted = msg.value - amountRemaining;
    wallet.transfer(amountAccepted);
    totalReceived += amountAccepted;
    require(totalReceived <= HARD_CAP);

    if (tokensSold == MAX_TOKENS_SOLD) {
      finalize();
    }

    emit TokensSold(msg.sender, tokensToReceive, amountAccepted);
  }

  function start()
    public
    isOwner {
    stage = Stages.Started;
  }

  function stop()
    public
    isOwner {
    finalize();
  }

  function finalize()
    private {
    stage = Stages.Ended;
  }

   
  function withdraw()
    public
    isOwner {
    owner.transfer(address(this).balance);
  }

   
  function transferERC20Token(address _tokenAddress, address _to, uint256 _value)
    public
    isOwner {
    ERC20 token = ERC20(_tokenAddress);
    assert(token.transfer(_to, _value));
  }

}