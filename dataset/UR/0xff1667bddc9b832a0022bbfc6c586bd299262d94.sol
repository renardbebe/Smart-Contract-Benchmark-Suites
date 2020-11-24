 

pragma solidity ^0.4.23;

contract Control {
    address public owner;
    bool public pause;

    event PAUSED();
    event STARTED();

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier whenPaused {
        require(pause);
        _;
    }

    modifier whenNotPaused {
        require(!pause);
        _;
    }

    function setOwner(address _owner) onlyOwner public {
        owner = _owner;
    }

    function setState(bool _pause) onlyOwner public {
        pause = _pause;
        if (pause) {
            emit PAUSED();
        } else {
            emit STARTED();
        }
    }
    
    constructor() public {
        owner = msg.sender;
    }
}

contract ERC20Token {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    function symbol() public constant returns (string);
    function decimals() public constant returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Share {
    function onIncome() public payable;
}

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

contract Crowdsale is Control {
    using SafeMath for uint256;

     
    ERC20Token public token;

    address public tokenFrom;
    function setTokenFrom(address _from) onlyOwner public {
        tokenFrom = _from;
    }

     
    Share public wallet;
    function setWallet(Share _wallet) onlyOwner public {
        wallet = _wallet;
    }

     
     
     
     
    uint256 public rate;
    function adjustRate(uint256 _rate) onlyOwner public {
        rate = _rate;
    }

    uint256 public weiRaiseLimit;
    
    function setWeiRaiseLimit(uint256 _limit) onlyOwner public {
        weiRaiseLimit = _limit;
    }
    
     
    uint256 public weiRaised;
  
     
    event TokenPurchase (
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    modifier onlyAllowed {
        require(weiRaised < weiRaiseLimit);
        _;
    }
   
  constructor(uint256 _rate, Share _wallet, ERC20Token _token, address _tokenFrom, uint256 _ethRaiseLimit) 
  public 
  {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    owner = msg.sender;
    rate = _rate;
    wallet = _wallet;
    token = _token;
    tokenFrom  = _tokenFrom;
    weiRaiseLimit = _ethRaiseLimit * (10 ** 18);
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable onlyAllowed whenNotPaused {

    uint256 weiAmount = msg.value;
    if (weiAmount > weiRaiseLimit.sub(weiRaised)) {
        weiAmount = weiRaiseLimit.sub(weiRaised);
    }
    
     
    uint256 tokens = _getTokenAmount(weiAmount);
    
    if (address(wallet) != address(0)) {
        wallet.onIncome.value(weiAmount)();
    }
    
     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );
    
    if(msg.value.sub(weiAmount) > 0) {
        msg.sender.transfer(msg.value.sub(weiAmount));
    }
  }

   
   
   

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transferFrom(tokenFrom, _beneficiary, _tokenAmount);
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
    return _weiAmount / rate;
  }
  
  function withdrawl() public {
      owner.transfer(address(this).balance);
  }
}