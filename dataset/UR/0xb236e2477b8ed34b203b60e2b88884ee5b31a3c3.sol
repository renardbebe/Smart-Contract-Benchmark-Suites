 

pragma solidity 0.4.19;


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
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract UCCoin is StandardToken, Ownable {

    string public constant name = "UC Coin";
    string public constant symbol = "UCN";
    uint8 public constant decimals = 8;

    uint256 public INITIAL_TOKEN_SUPPLY = 500000000 * (10 ** uint256(decimals));

    function MAX_UCCOIN_SUPPLY() public view returns (uint256) {
        return totalSupply.div(10 ** uint256(decimals));
    }

    function UCCoin() public {
        totalSupply = INITIAL_TOKEN_SUPPLY;
        balances[msg.sender] = totalSupply;
    }
}

contract UCCoinSales is UCCoin {

    uint256 public weiRaised;

    uint256 public UCCOIN_PER_ETHER = 1540;
    uint256 public MINIMUM_SELLING_UCCOIN = 150;

    bool public shouldStopCoinSelling = true;

    mapping(address => uint256) public contributions;
    mapping(address => bool) public blacklistAddresses;

    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
    event UcCoinPriceChanged(uint256 value, uint256 updated);
    event UcCoinMinimumSellingChanged(uint256 value, uint256 updated);
    event UCCoinSaleIsOn(uint256 updated);
    event UCCoinSaleIsOff(uint256 updated);

    function UCCoinSales() public {

    }
     
    function() payable external {
        buyUcCoins();
    }
     
    function buyUcCoins() payable public {
        require(msg.sender != address(0));

        bool didSetUcCoinValue = UCCOIN_PER_ETHER > 0;
        require(!shouldStopCoinSelling && didSetUcCoinValue);
        require(blacklistAddresses[tx.origin] != true);

        uint256 weiAmount = msg.value;

        uint256 tokens = getUcCoinTokenPerEther().mul(msg.value).div(1 ether);

        require(tokens >= getMinimumSellingUcCoinToken());
        require(balances[owner] >= tokens);

        weiRaised = weiRaised.add(weiAmount);

        balances[owner] = balances[owner].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
         
        owner.transfer(msg.value);

        contributions[msg.sender] = contributions[msg.sender].add(msg.value);

        TokenPurchase(msg.sender, weiAmount, tokens);
    }

     
    function getUcCoinTokenPerEther() internal returns (uint256) {
        return UCCOIN_PER_ETHER * (10 ** uint256(decimals));
    }
     
    function getMinimumSellingUcCoinToken() internal returns (uint256) {
        return MINIMUM_SELLING_UCCOIN * (10 ** uint256(decimals));
    }

     
    function sendTokens(address target, uint256 tokenAmount) external onlyOwner returns (bool) {
        require(target != address(0));
        require(balances[owner] >= tokenAmount);
        balances[owner] = balances[owner].sub(tokenAmount);
        balances[target] = balances[target].add(tokenAmount);

        Transfer(msg.sender, target, tokenAmount);
    }
     
    function setUCCoinPerEther(uint256 coinAmount) external onlyOwner returns (uint256) {
        require(UCCOIN_PER_ETHER != coinAmount);
        require(coinAmount >= MINIMUM_SELLING_UCCOIN);
        
        UCCOIN_PER_ETHER = coinAmount;
        UcCoinPriceChanged(UCCOIN_PER_ETHER, now);

        return UCCOIN_PER_ETHER;
    }
     
    function setMinUCCoinSellingValue(uint256 coinAmount) external onlyOwner returns (uint256) {
        MINIMUM_SELLING_UCCOIN = coinAmount;
        UcCoinMinimumSellingChanged(MINIMUM_SELLING_UCCOIN, now);

        return MINIMUM_SELLING_UCCOIN;
    }
     
    function addUserIntoBlacklist(address target) external onlyOwner returns (address) {
        return setBlacklist(target, true);
    }
     
    function removeUserFromBlacklist(address target) external onlyOwner returns (address) {
        return setBlacklist(target, false);
    }
     
    function setBlacklist(address target, bool shouldBlock) internal onlyOwner returns (address) {
        blacklistAddresses[target] = shouldBlock;
        return target;
    }  
     
    function setStopSelling() external onlyOwner {
        shouldStopCoinSelling = true;
        UCCoinSaleIsOff(now);
    }
     
    function setContinueSelling() external onlyOwner {
        shouldStopCoinSelling = false;
        UCCoinSaleIsOn(now);
    }

     
    function pushAllRemainToken(address target) external onlyOwner {
        uint256 remainAmount = balances[msg.sender];
        balances[msg.sender] = balances[msg.sender].sub(remainAmount);
        balances[target] = balances[target].add(remainAmount);

        Transfer(msg.sender, target, remainAmount);
    }
     
    function getBuyerContribution(address target) onlyOwner public returns (uint256 contribute) {
        return contributions[target];
    }
}