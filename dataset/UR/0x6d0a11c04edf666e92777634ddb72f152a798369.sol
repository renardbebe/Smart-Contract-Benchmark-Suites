 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}


contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token {
     
    string public standard = "BlocHipo";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
    }

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;    
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

     
    function () {
        throw;      
    }
}

contract BlocHipo is owned, token {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping(address=>bool) public frozenAccount;


     
    event FrozenFunds(address target, bool frozen);

     
    uint256 public constant initialSupply = 2000000000 * 10**18;
    uint8 public constant decimalUnits = 18;
    string public tokenName = "BlocHipo";
    string public tokenSymbol = "HIPO";
    function BlocHipo() token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}
      
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if (frozenAccount[msg.sender]) throw;                 
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;                         
        if (balanceOf[_from] < _value) throw;                  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;    
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable {
        uint amount = msg.value / buyPrice;                 
        if (balanceOf[this] < amount) throw;                
        balanceOf[msg.sender] += amount;                    
        balanceOf[this] -= amount;                          
        Transfer(this, msg.sender, amount);                 
    }

    function sell(uint256 amount) {
        if (balanceOf[msg.sender] < amount ) throw;         
        balanceOf[this] += amount;                          
        balanceOf[msg.sender] -= amount;                    
        if (!msg.sender.send(amount * sellPrice)) {         
            throw;                                          
        } else {
            Transfer(msg.sender, this, amount);             
        }
    }
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  constructor() public{
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;

   
  token myToken;
  
   
  address public wallet;
  
   
  uint256 public rate = 500000 ; 

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);


  constructor(address tokenContractAddress, address _walletAddress) public{
    wallet = _walletAddress;
    myToken = token(tokenContractAddress);
  }

   
  function () payable public{
    buyTokens(msg.sender);
  }

  function getBalance() public constant returns(uint256){
      return myToken.balanceOf(this);
  }    

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(msg.value >= 10000000000000000); 
    require(msg.value <= 2000000000000000000); 

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate).div(100);

     
    weiRaised = weiRaised.add(weiAmount);

    myToken.transfer(beneficiary, tokens);

    emit TokenPurchase(beneficiary, weiAmount, tokens);
  }

   
  function updateRate(uint256 new_rate) onlyOwner public{
    rate = new_rate;
  }


   
   
  function forwardFunds() onlyOwner public {
    wallet.transfer(address(this).balance);
  }

  function transferBackTo(uint256 tokens, address beneficiary) onlyOwner public returns (bool){
    myToken.transfer(beneficiary, tokens);
    return true;
  }

}