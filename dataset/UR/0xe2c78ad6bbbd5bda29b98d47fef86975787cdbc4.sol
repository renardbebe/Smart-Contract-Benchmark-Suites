 

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
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns
(uint256);
  function transferFrom(address from, address to, uint256 value) public
returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256
value);
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


   
  function transferFrom(address _from, address _to, uint256 _value) public
returns (bool) {
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

   
  function allowance(address _owner, address _spender) public view returns
(uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public
returns (bool) {
    allowed[msg.sender][_spender] =
allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public
returns (bool) {
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

contract RandoCoin is StandardToken {
    using SafeMath for uint256;
    
     
     
    uint256 public totalSupply = (100000000) * 1000;
    string public name = "RandoCoin";
    string public symbol = "RAND";
    uint8 public decimals = 3;
    uint BLOCK_WAIT_TIME = 30;
    uint INIT_BLOCK_WAIT = 250;
    
     
    address owner;
    uint public buyPrice;
    uint public sellPrice;
    uint public priceChangeBlock;
    uint public oldPriceChangeBlock;
    bool isInitialized = false;
    
     
     
     
     
     
     
     
     
    uint public PRICE_MIN = 0.00000001 ether;
    uint public PRICE_MAX = 0.00001 ether;
    uint public PRICE_MID = 0.000005 ether;
    
     
    event BuyPriceChanged(uint newBuyPrice);
    event SellPriceChanged(uint newSellPrice);

    function RandoCoin() public payable {
        owner = msg.sender;
         
         
        balances[this] = totalSupply;
        
         
         
        priceChangeBlock = block.number + INIT_BLOCK_WAIT;
        oldPriceChangeBlock = block.number;
        buyPrice = PRICE_MID;
        sellPrice = PRICE_MID;
    }
    
     
     
     
    function init() public {
        require(msg.sender == owner);
        require(!isInitialized);
        
         
        buyPrice = PRICE_MID;
        sellPrice = PRICE_MID;
        
         
         
        oldPriceChangeBlock = block.number;
        priceChangeBlock = block.number + INIT_BLOCK_WAIT;
        isInitialized = true;
    }
    
    function buy() public requireNotExpired requireCooldown payable returns (uint amount){
        amount = msg.value / buyPrice;
        require(balances[this] >= amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        balances[this] = balances[this].sub(amount);
        
        Transfer(this, msg.sender, amount);
        return amount;
    }
    
    function sell(uint amount) public requireNotExpired requireCooldown returns (uint revenue){
        require(balances[msg.sender] >= amount);
        balances[this] += amount;
        balances[msg.sender] -= amount;

        revenue = amount.mul(sellPrice);
        msg.sender.transfer(revenue);
        
        Transfer(msg.sender, this, amount);
        return revenue;
    }
    
     
     
    function maybeChangePrice() public {
         
         
         
         
         
        require(block.number > priceChangeBlock + 1);
        
         
         
         
        if (block.number - priceChangeBlock > 250) {
            waitMoreTime();
            return;
        }
        
         
         
        sellPrice = shittyRand(0);
        buyPrice = shittyRand(1);
        
         
        if (sellPrice < PRICE_MIN) {
            sellPrice = PRICE_MIN;
        }
        
        if (buyPrice < PRICE_MIN) {
            buyPrice = PRICE_MIN;
        }
        
        BuyPriceChanged(buyPrice);
        SellPriceChanged(sellPrice);

        oldPriceChangeBlock = priceChangeBlock;
        priceChangeBlock = block.number + BLOCK_WAIT_TIME;
        
         
        uint reward = 100;
        if (balances[this] > reward) {
            balances[msg.sender] = balances[msg.sender].add(reward);
            balances[this] = balances[this].sub(reward);
        }
    }
    
     
     
     
    modifier requireCooldown() {
         
        if (block.number >= oldPriceChangeBlock) {
            require(block.number - priceChangeBlock > 2);
        }
        _;
    }
    
    modifier requireNotExpired() {
        require(block.number < priceChangeBlock);
        _;
    }
    
     
     
     
     
     
    function waitMoreTime() internal {
        priceChangeBlock = block.number + BLOCK_WAIT_TIME;
    }
    
     
    function shittyRand(uint seed) public returns(uint) {
        uint randomSeed = uint(block.blockhash(priceChangeBlock + seed));
        return randomSeed % PRICE_MAX;
    }
    
    function getBlockNumber() public returns(uint) {
        return block.number;
    }

}