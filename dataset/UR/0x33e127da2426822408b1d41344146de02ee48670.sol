 

pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract PONTEM {
     
    string public name  ;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    constructor (uint256 initialSupply , string tokenName , string tokenSymbol) public {

        totalSupply  = 250000000  * 10 ** uint256(18) ;  
        balanceOf[msg.sender]  = totalSupply;                 
        name  = "PONTEM";                                    
        symbol  = "PXM";                                
    }

     
         
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
       emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
        require(!frozenAccount[msg.sender]);

    }    
        
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
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
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
      emit  Burn(msg.sender, _value);
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
        
    } mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    function freezeAccount(address target, bool freeze) public {
        frozenAccount[target] = freeze;
      emit  FrozenFunds(target, freeze);
        
    }    uint256 public sellPrice;
    uint256 public buyPrice;

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice)  public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
        
    } 
    function buy() payable public returns(uint amount) {
        amount = msg.value / buyPrice;                
        require(balanceOf[this] >= amount);                
        require(balanceOf[msg.sender] >= amount * buyPrice);  
        balanceOf[msg.sender] += amount;                   
        balanceOf[this] -= amount;                         
        _transfer(this, msg.sender, amount);               
        return amount;
    }

     
     
    function sell(uint256 amount) public returns(uint revenue) {
        require(address(this).balance >= amount * sellPrice);       
        require(balanceOf[msg.sender] >= amount);          
        balanceOf[this] += amount;                   
        balanceOf[msg.sender] -= amount;                         
        revenue = amount * sellPrice;
        _transfer(msg.sender, this, amount);               
        require(msg.sender.send(revenue));                 
       return revenue;
    }


}