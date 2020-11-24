 

pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
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

 
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external ; }

contract TokenERC20 is SafeMath {
     
    string public name = "World Trading Unit";
    string public symbol = "WTU";
    uint8 public decimals = 8;
     
    uint256 public TotalToken = 21000000;
    uint256 public RemainingTokenStockForSale;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20() public {
        RemainingTokenStockForSale = safeMul(TotalToken,10 ** uint256(decimals));   
        balanceOf[msg.sender] = RemainingTokenStockForSale;                     
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        uint previousBalances = safeAdd(balanceOf[_from],balanceOf[_to]);
         
        balanceOf[_from] =  safeSub(balanceOf[_from], _value);
         
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);
        Transfer(_from, _to, _value);
         
        assert(safeAdd(balanceOf[_from],balanceOf[_to]) == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender],_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender],_value);       
        RemainingTokenStockForSale = safeSub(RemainingTokenStockForSale,_value);                 
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender]  = safeSub(allowance[_from][msg.sender],_value);              
        RemainingTokenStockForSale = safeSub(RemainingTokenStockForSale,_value);                               
        Burn(_from, _value);
        return true;
    }
}

 
 
 

contract MyAdvancedToken is owned, TokenERC20 {

    uint256 public sellPrice = 0.001 ether;
    uint256 public buyPrice = 0.001 ether;

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (safeAdd(balanceOf[_to],_value) > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] = safeSub(balanceOf[_from],_value);                          
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);                            
        Transfer(_from, _to, _value);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     
    function buy() payable public {
        uint amount = safeDiv(msg.value, buyPrice);                
        _transfer(this, msg.sender, amount);               
    }

     
     
    function sell(uint256 amount) public {
        require(this.balance >= safeMul(amount,sellPrice));       
        _transfer(msg.sender, this, amount);               
        msg.sender.transfer(safeMul(amount, sellPrice));           
    }
     
    function () payable public {
        
    }
 


}