 

pragma solidity ^0.4.19;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
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


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
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

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
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

contract LareCoin is StandardToken, MintableToken
{
     
    string public constant name = "LareCoin";
    string public constant symbol = "LARE";
    uint8 public constant decimals = 18;
    
    uint256 public constant ETH_PER_LARE = 0.0006 ether;
    uint256 public constant MINIMUM_CONTRIBUTION = 0.05 ether;
    uint256 public constant MAXIMUM_CONTRIBUTION = 5000000 ether;
    
     
     
    uint256 public totalBaseLareSoldInPreSale = 0;
    uint256 public totalBaseLareSoldInMainSale = 0;
    
     
     
    uint256 public totalLareSold = 0;
    
    uint256 public constant PRE_SALE_START_TIME  = 1518998400;  
    uint256 public constant MAIN_SALE_START_TIME = 1528070400;  
    uint256 public constant MAIN_SALE_END_TIME   = 1546560000;  
    
    uint256 public constant TOTAL_LARE_FOR_SALE = 28000000000 * (uint256(10) ** decimals);
    
    address public owner;
    
     
    mapping(address => uint256) public addressToLarePurchased;
    mapping(address => uint256) public addressToEtherContributed;
    address[] public allParticipants;
    function amountOfParticipants() external view returns (uint256)
    {
        return allParticipants.length;
    }
    
     
    function LareCoin() public
    {
        owner = msg.sender;
        totalSupply_ = 58000000000 * (uint256(10) ** decimals);
        balances[owner] = totalSupply_;
        Transfer(0x0, owner, balances[owner]);
    }
    
     
    function () payable external
    {
         
        require(msg.value >= MINIMUM_CONTRIBUTION);
        require(msg.value <= MAXIMUM_CONTRIBUTION);
        
         
        uint256 purchasedTokensBase = msg.value * (uint256(10)**18) / ETH_PER_LARE;
        
         
        uint256 purchasedTokensIncludingBonus = purchasedTokensBase;
        if (now < PRE_SALE_START_TIME)
        {
             
             
            revert();
        }
        else if (now >= PRE_SALE_START_TIME && now < MAIN_SALE_START_TIME)
        {
            totalBaseLareSoldInPreSale += purchasedTokensBase;
            
            if (totalBaseLareSoldInPreSale <= 2000000000 * (uint256(10)**decimals))
            {
                 
                purchasedTokensIncludingBonus += purchasedTokensBase;
            }
            else
            {
                 
                 
                revert();
            }
        }
        else if (now >= MAIN_SALE_START_TIME && now < MAIN_SALE_END_TIME)
        {
            totalBaseLareSoldInMainSale += purchasedTokensBase;
            
             
                 if (totalBaseLareSoldInMainSale <=  2000000000 * (uint256(10)**decimals))
                purchasedTokensIncludingBonus += purchasedTokensBase * 80 / 100;

             
            else if (totalBaseLareSoldInMainSale <=  4000000000 * (uint256(10)**decimals))
                purchasedTokensIncludingBonus += purchasedTokensBase * 70 / 100;

             
            else if (totalBaseLareSoldInMainSale <=  6000000000 * (uint256(10)**decimals))
                purchasedTokensIncludingBonus += purchasedTokensBase * 60 / 100;

             
            else if (totalBaseLareSoldInMainSale <=  8000000000 * (uint256(10)**decimals))
                purchasedTokensIncludingBonus += purchasedTokensBase * 50 / 100;

             
            else if (totalBaseLareSoldInMainSale <=  9500000000 * (uint256(10)**decimals))
                purchasedTokensIncludingBonus += purchasedTokensBase * 40 / 100;

             
            else if (totalBaseLareSoldInMainSale <= 11000000000 * (uint256(10)**decimals))
                purchasedTokensIncludingBonus += purchasedTokensBase * 30 / 100;

             
            else if (totalBaseLareSoldInMainSale <= 12500000000 * (uint256(10)**decimals))
                purchasedTokensIncludingBonus += purchasedTokensBase * 20 / 100;

             
            else if (totalBaseLareSoldInMainSale <= 14000000000 * (uint256(10)**decimals))
                purchasedTokensIncludingBonus += purchasedTokensBase * 10 / 100;
            
             
            else if (totalBaseLareSoldInMainSale <= 15000000000 * (uint256(10)**decimals))
                purchasedTokensIncludingBonus += purchasedTokensBase * 8 / 100;
            
             
            else if (totalBaseLareSoldInMainSale <= 16000000000 * (uint256(10)**decimals))
                purchasedTokensIncludingBonus += purchasedTokensBase * 6 / 100;
            
             
            else if (totalBaseLareSoldInMainSale <= 16691200000 * (uint256(10)**decimals))
                purchasedTokensIncludingBonus += purchasedTokensBase * 4 / 100;
            
             
            else
                purchasedTokensIncludingBonus += purchasedTokensBase * 2 / 100;
        }
        else
        {
             
             
            revert();
        }
        
         
        if (addressToLarePurchased[msg.sender] == 0) allParticipants.push(msg.sender);
        addressToLarePurchased[msg.sender] += purchasedTokensIncludingBonus;
        addressToEtherContributed[msg.sender] += msg.value;
        totalLareSold += purchasedTokensIncludingBonus;
        
         
        require(totalLareSold < TOTAL_LARE_FOR_SALE);
        
         
        owner.transfer(msg.value);
    }
    
    function grantPurchasedTokens(address _purchaser) external onlyOwner
    {
        uint256 amountToTransfer = addressToLarePurchased[_purchaser];
        addressToLarePurchased[_purchaser] = 0;
        transfer(_purchaser, amountToTransfer);
    }
}