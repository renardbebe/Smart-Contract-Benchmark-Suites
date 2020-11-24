 

 

pragma solidity ^0.4.24;

 
 
 
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256)  {
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
 
contract owned {
    address public owner;

    constructor() public {
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


 
 
 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


 
contract TokenERC20 is SafeMath{
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public _totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    constructor(uint256 initialSupply,string tokenName,string tokenSymbol) public {
        _totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = _totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }
    

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        uint256 mbalanceofto = SafeMath.safeAdd(balanceOf[_to], _value);
        require(mbalanceofto > balanceOf[_to]);
         
        uint previousBalances = SafeMath.safeAdd(balanceOf[_from],balanceOf[_to]);
         
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from],_value);
         
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to],_value);
         
        uint currentBalances = SafeMath.safeAdd(balanceOf[_from],balanceOf[_to]);
        emit Transfer(_from, _to, _value);
         
        assert(currentBalances == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
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
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);             
        _totalSupply = SafeMath.safeSub(_totalSupply, _value);                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                          
         
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);             
        _totalSupply = SafeMath.safeSub(_totalSupply,_value);                               
        emit Burn(_from, _value);
        return true;
    }
}

 
 
 

contract TokenBOSC is owned, TokenERC20 {

    uint256 public buyPrice=2000;   
    uint256 public sellPrice=2500;     
    uint public minBalanceForAccounts;
    uint256 linitialSupply=428679360;
    string ltokenName="BOSCToken";
    string ltokenSymbol="BOSC";
    

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    constructor() TokenERC20(linitialSupply, ltokenName, ltokenSymbol) public {
    }

     
    function totalSupply() public constant returns (uint totalsupply) {
        totalsupply = _totalSupply ;
    }

      
     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (SafeMath.safeAdd(balanceOf[_to],_value) >= balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                          
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);   
        emit Transfer(_from, _to, _value);
    }

     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = SafeMath.safeAdd(balanceOf[target],mintedAmount);
        _totalSupply = SafeMath.safeAdd(_totalSupply, mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     
    function () public payable {
    }
}