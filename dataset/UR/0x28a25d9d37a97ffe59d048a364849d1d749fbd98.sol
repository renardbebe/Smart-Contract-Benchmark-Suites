 

pragma solidity ^0.4.18;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract Ownable {
  address public owner;
  address public admin;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == admin);
     
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
  function transferAdmin(address newAdmin) public onlyOwner {
    require(newAdmin != address(0));
    OwnershipTransferred(admin, newAdmin);
    admin = newAdmin;
  }

}

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 
contract CarToken is MintableToken {
  string public constant name = "car";
  string public constant symbol = "CAR";
  uint8 public constant decimals = 18;
  uint256 public constant totalSupply = 1000000000 * (10 ** uint256(decimals));
  
  function CarToken(address _admin) {
      admin = _admin;
  }
}

 
contract Crowdsale is Ownable{
  using SafeMath for uint256;

   
  MintableToken public token;
  
   
  uint256 internal SELF_SUPPLY = 600000000 * (10 ** uint256(18));
  uint256 public EARLY_BIRD_SUPPLY = 100000000 * (10 ** uint256(18));
  uint256 public PUBLIC_OFFER_SUPPLY = 300000000 * (10 ** uint256(18));

   
  address public wallet;
  
   
  bool public isEarlybird;
  bool public isEndOffer;
  
   
  uint256 internal rate;
  uint256 internal earlyBirdRate = 11000;
  uint256 internal publicOfferRate = 10000;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event EarlyBird(bool indexed statue);
  event EndOffer(bool indexed statue);

  function Crowdsale(address _wallet) public {
    require(_wallet != address(0));
    token = createTokenContract(msg.sender);
    wallet = _wallet;
    owner = msg.sender;
    dealEarlyBird(true);
  }
  
   
  function mintSelf() onlyOwner public {
      token.mint(wallet, SELF_SUPPLY);
      TokenPurchase(wallet, wallet, 0, SELF_SUPPLY);
  }
  
   
  function dealEarlyBird(bool statue) internal {
    if (statue) {
        isEarlybird = true;
        rate = earlyBirdRate;
        EarlyBird(true);
    } else {
        isEarlybird = false;
        rate = publicOfferRate;
        EarlyBird(false);
    }
  }
  
   
  function dealEndOffer(bool statue) onlyOwner public {
    if (statue) {
        isEndOffer = true;
        EndOffer(true);
    } else {
        isEndOffer = false;
        EndOffer(false);
    }
  }
  
   
   
  function createTokenContract(address _admin) internal returns (CarToken) {
    return new CarToken(_admin);
  }

   
  function () external payable {
    buyTokens();
  }

   
  function buyTokens() public payable {
    require(msg.sender != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(rate);
    uint256 allTokens = calToken(tokens);
    
    token.mint(msg.sender, allTokens);
    TokenPurchase(msg.sender, msg.sender, weiAmount, allTokens);
    
    forwardFunds();
  }
  
   
  function calToken(uint256 tokens) internal returns (uint256) {
    if (isEarlybird && EARLY_BIRD_SUPPLY > 0 && EARLY_BIRD_SUPPLY < tokens) {
      uint256 totalToken = totalToken.add(EARLY_BIRD_SUPPLY);
      uint256 remainingToken = (tokens - EARLY_BIRD_SUPPLY).mul(10).div(11);
      EARLY_BIRD_SUPPLY = 0;
      PUBLIC_OFFER_SUPPLY = PUBLIC_OFFER_SUPPLY.sub(remainingToken);
      dealEarlyBird(false);
      totalToken = totalToken.add(remainingToken);
      return totalToken;
    }
    
    if (isEarlybird && EARLY_BIRD_SUPPLY >= tokens) {
      EARLY_BIRD_SUPPLY = EARLY_BIRD_SUPPLY.sub(tokens);
      if (EARLY_BIRD_SUPPLY == 0) {
        dealEarlyBird(false);
      }
      return tokens;
    }
    
    if (!isEarlybird) {
      PUBLIC_OFFER_SUPPLY = PUBLIC_OFFER_SUPPLY.sub(tokens);
      return tokens;
    }
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    return nonZeroPurchase && !isEndOffer;
  }
  
}