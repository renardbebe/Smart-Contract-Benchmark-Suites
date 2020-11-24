 

pragma solidity ^0.4.16;

   
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
     
     
     
    return a / b;
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

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 is Pausable{
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
    uint256 totalSupplyForDivision;

     
    mapping (address => uint256) public balanceOf; 
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;
    }
    
     
    function _transfer(address _from, address _to, uint _value) internal whenNotPaused{
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public whenNotPaused {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public whenNotPaused
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) whenNotPaused
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public whenPaused returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        totalSupplyForDivision = totalSupply;                               
        emit Burn(msg.sender, _value);
        return true;
    }
     
    function burnFrom(address _from, uint256 _value) public whenPaused returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        totalSupplyForDivision = totalSupply;                               
        emit Burn(_from, _value);
        return true;
    }
}

 
 
 

contract DunkPayToken is TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public buySupply;
    uint256 public totalEth;
    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    function DunkPayToken() TokenERC20(totalSupply, name, symbol) public {

        buyPrice = 1000;
        sellPrice = 1000;
        
        name = "DunkPay Token";
        symbol = "DNK";
        totalSupply = buyPrice * 10000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = buyPrice * 5100 * 10 ** uint256(decimals);              
        balanceOf[this] = totalSupply - balanceOf[msg.sender];
        buySupply = balanceOf[this];
        allowance[this][msg.sender] = buySupply;
        totalSupplyForDivision = totalSupply; 
        totalEth = address(this).balance;
    }

    function percent(uint256 numerator, uint256 denominator , uint precision) returns(uint256 quotient) {
        if(numerator <= 0)
        {
            return 0;
        }
         
        uint256 _numerator  = numerator * 10 ** uint256(precision+1);
         
        uint256 _quotient =  ((_numerator / denominator) - 5) / 10;
        return  _quotient;
    }
    
    function getZero(uint256 number) returns(uint num_len) {
        uint i = 1;
        uint _num_len = 0;
        while( number > i )
        {
            i *= 10;
            _num_len++;
        }
        return _num_len;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        
        buySupply = balanceOf[this];  
        allowance[this][msg.sender] = buySupply;
        emit Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        
        buySupply = balanceOf[this];  
        allowance[this][msg.sender] = buySupply;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice, uint256 newBuySupply) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
        buySupply = newBuySupply;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused {
        if(_to == address(this)){
            sell(_value);
        }else{
            _transfer(msg.sender, _to, _value);
        }
    }

    function () payable public {
     buy();
    }

     
    function buy() payable whenNotPaused public {
        uint256 dnkForBuy = msg.value;
        uint zeros = getZero(buySupply);
        uint256 interest = msg.value / 2 * percent(balanceOf[this] , buySupply , zeros);
        interest = interest / 10 ** uint256(zeros);
        dnkForBuy = dnkForBuy + interest;
        _transfer(this, msg.sender, dnkForBuy * buyPrice);               
        totalEth += msg.value;
    }

     
     
    function sell(uint256 amount) whenNotPaused public {
        uint256 ethForSell =  amount;
        uint zeros = getZero(balanceOf[this]);
        uint256 interest = amount / 2 * percent( buySupply , balanceOf[this] ,zeros);
        interest = interest / 10 ** uint256(zeros);
        ethForSell = ethForSell - interest;
        ethForSell = ethForSell - (ethForSell/100);  
        ethForSell = ethForSell / sellPrice;
        uint256 minimumAmount = address(this).balance; 
        require(minimumAmount >= ethForSell);       
        _transfer(msg.sender, this, amount);               
        msg.sender.transfer(ethForSell);           
        totalEth -= ethForSell;
    } 

     
     
    function withdraw(uint256 amount) onlyOwner public {
        uint256 minimumAmount = address(this).balance; 
        require(minimumAmount >= amount);       
        msg.sender.transfer(amount);           
    }

    function airdrop(address[] _holders, uint256 mintedAmount) onlyOwner whenPaused public {
        for (uint i = 0; i < _holders.length; i++) {
            uint zeros = getZero(totalSupplyForDivision);
            uint256 amount = percent(balanceOf[_holders[i]],totalSupplyForDivision,zeros)  * mintedAmount;
            amount = amount / 10 ** uint256(zeros);
            if(amount != 0){
                mintToken(_holders[i], amount);
            }
        }
        totalSupplyForDivision = totalSupply;
    }

    function bankrupt(address[] _holders) onlyOwner whenPaused public {
        uint256 restBalance = balanceOf[this];
        totalSupplyForDivision = totalSupply - restBalance;                              
        totalEth = address(this).balance;
        for (uint i = 0; i < _holders.length; i++) {
          uint zeros = getZero(totalSupplyForDivision);
          uint256 amount = percent(balanceOf[_holders[i]],totalSupplyForDivision , zeros) * totalEth;
          amount = amount / 10 ** uint256(zeros);
        
          if(amount != 0){
            uint256 minimumAmount = address(this).balance; 
            require(minimumAmount >= amount);       
            uint256 holderBalance = balanceOf[_holders[i]];
            balanceOf[_holders[i]] -= holderBalance;                         
            totalSupply -= holderBalance;            
            _holders[i].transfer(amount);           
          } 
        }
        totalSupplyForDivision = totalSupply;
        totalEth = address(this).balance;
    }    
}