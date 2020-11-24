 

pragma solidity ^ 0.4.25;
contract owned {
    address public owner;
    constructor() public{
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

contract BTCC is owned{
     
    string public name;              
    string public symbol;            
    uint8 public decimals = 18;      

    uint256 public totalSupply;      
    uint256 public sellPrice = 1 ether;
    uint256 public buyPrice = 1 ether;

     
    mapping (address => bool) public frozenAccount;
     
    mapping (address => uint256) public balanceOf;

     
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
     
    event FrozenFunds(address target, bool frozen);
     
    constructor() public {
        totalSupply = 1000000000 ether;   
        balanceOf[msg.sender] = totalSupply;                     
        name = 'BTCC';                                        
        symbol = 'btcc';                                    
        emit Transfer(this, msg.sender, totalSupply);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     
    function buy() payable public {
        uint amount = msg.value / buyPrice;                
        require(totalSupply >= amount);
        totalSupply -= amount;
        _transfer(this, msg.sender, amount);               
    }

    function sell(uint256 amount) public {
        require(address(this).balance >= amount * sellPrice);       
        _transfer(msg.sender, this, amount);               
        msg.sender.transfer(amount * sellPrice);           
    }
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        require(totalSupply >= mintedAmount);
        balanceOf[target] += mintedAmount;
        totalSupply -= mintedAmount;
        emit Transfer(this, target, mintedAmount);
    }
}