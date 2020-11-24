 

pragma solidity ^0.4.2;
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token {
     
    string public standard = 'Token 0.1';
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
        require(balanceOf[msg.sender] >= _value);             
        require(balanceOf[_to] + _value >= balanceOf[_to]);   
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
        require(balanceOf[_from] >= _value);                  
        require(balanceOf[_to] + _value >= balanceOf[_to]);   
        require(_value <= allowance[_from][msg.sender]);      
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

     
    function () {
        assert(false);      
    }
}

contract MyAdvancedToken is owned, token {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    function MyAdvancedToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

     
    function transfer(address _to, uint256 _value) {
        require(balanceOf[msg.sender] >= _value);             
        require(balanceOf[_to] + _value >= balanceOf[_to]);   
        require(!frozenAccount[msg.sender]);                  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(!frozenAccount[_from]);                       
        require(balanceOf[_from] >= _value);                  
        require(balanceOf[_to] + _value >= balanceOf[_to]);   
        require(_value <= allowance[_from][msg.sender]);      
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
        require(balanceOf[this] >= amount);                 
        balanceOf[msg.sender] += amount;                    
        balanceOf[this] -= amount;                          
        Transfer(this, msg.sender, amount);                 
    }

    function sell(uint256 amount) {
        require(balanceOf[msg.sender] >= amount);           
        balanceOf[this] += amount;                          
        balanceOf[msg.sender] -= amount;                    
        if (!msg.sender.send(amount * sellPrice)) {         
            assert(false);                                  
        } else {
            Transfer(msg.sender, this, amount);             
        }               
    }
}