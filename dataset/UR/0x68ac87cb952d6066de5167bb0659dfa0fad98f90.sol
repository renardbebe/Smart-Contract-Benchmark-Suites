 

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


contract ERC20Basic {
    function totalSupply() public constant returns (uint supply);
    function balanceOf( address who ) public constant returns (uint value);
    function allowance( address owner, address spender ) public constant returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint value);
     
    event Burn(address indexed from, uint256 value);
}

contract TokenERC20  is ERC20Basic{
     
    string public name;
    string public symbol;
    uint8 public decimals = 4;
    uint256 _supply;
    mapping (address => uint256)   _balances;
    mapping (address => mapping (address => uint256)) _allowance;

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint8 decimal
    ) public {
        _supply = initialSupply * 10 ** uint256(decimal);   
        _balances[msg.sender] = _supply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimal;
    }
    function totalSupply() public constant returns (uint256) {
        return _supply;
    }
    function balanceOf(address src) public constant returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy) public constant returns (uint256) {
        return _allowance[src][guy];
    }
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(_balances[_from] >= _value);
         
        require(_balances[_to] + _value > _balances[_to]);
         
        uint previousBalances = _balances[_from] + _balances[_to];
         
        _balances[_from] -= _value;
         
        _balances[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(_balances[_from] + _balances[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool){
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= _allowance[_from][msg.sender]);      
        _allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value)
        public returns (bool success) {
        if (approve(_spender, _value)) {
            Approval(msg.sender, _spender, _value);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(_balances[msg.sender] >= _value);    
        _balances[msg.sender] -= _value;             
        _supply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_balances[_from] >= _value);                 
        require(_value <= _allowance[_from][msg.sender]);     
        _balances[_from] -= _value;                          
        _allowance[_from][msg.sender] -= _value;              
        _supply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}

 
 
 

contract DYITToken is owned, TokenERC20 {

    uint256 public sellPrice = 0.00000001 ether ;  
    uint256 public buyPrice = 0.00000001 ether ; 
    
    mapping (address => bool) public _frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
   function DYITToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint8 decimal
    ) TokenERC20(initialSupply, tokenName, tokenSymbol,decimal) public {
        _balances[msg.sender] = _supply;  
    }
    
     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (_balances[_from] >= _value);                
        require (_balances[_to] + _value > _balances[_to]);  
        require(!_frozenAccount[_from]);                      
        require(!_frozenAccount[_to]);                        
        _balances[_from] -= _value;                          
        _balances[_to] += _value;                            
        Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        _balances[target] += mintedAmount;
        _supply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        _frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
     
    function transfer(address _to, uint256 _value) public returns (bool){
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     
    function buy() payable public {
        uint amount = msg.value / buyPrice;                
        _transfer(owner, msg.sender, amount);               
    }

     
     
    function sell(uint256 amount) public {
        require(owner.balance >= amount * sellPrice);       
        _transfer(msg.sender, owner, amount);               
        msg.sender.transfer(amount * sellPrice);           
    }
}