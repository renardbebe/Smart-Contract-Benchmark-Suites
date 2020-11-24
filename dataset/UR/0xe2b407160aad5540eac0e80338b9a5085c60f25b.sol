 

pragma solidity ^0.4.16;
     
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract owned {
        address public owner;

        function owned() public{
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner public{
            owner = newOwner;
        }
    }


contract GPN is owned {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
    address public centralMinter;
    uint public minBalanceForAccounts;
    uint minimumBalanceInFinney=1;
    uint256 public sellPrice;
    uint256 public buyPrice;
     uint256 public unitsOneEthCanBuy;      
    uint256 public totalEthInWei;          
    address public fundsWallet;    

   
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
     mapping (address => bool) public approvedAccount;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
event FrozenFunds(address target, bool frozen);
    
     
    event Burn(address indexed from, uint256 value);

     
    function GPN(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        address tokenCentralMinter
        ) 
        public {
        if(tokenCentralMinter!=0)owner=tokenCentralMinter;
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        setMinBalance();
        unitsOneEthCanBuy = 960;                                       
        fundsWallet = msg.sender;   
    }
   function()public payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        if (balanceOf[fundsWallet] < amount) {
            return;
        }

        balanceOf[fundsWallet] = balanceOf[fundsWallet] - amount;
        balanceOf[msg.sender] = balanceOf[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount);  

         
        fundsWallet.transfer(msg.value);                               
    }

     function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public{
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function buy()public payable returns (uint amount) {
        amount = msg.value / buyPrice;                     
        require(balanceOf[this] >= amount);                
        balanceOf[msg.sender] += amount;                   
        balanceOf[this] -= amount;                         
        Transfer(this, msg.sender, amount);                
        return amount;                                     
    }

    function sell(uint amount)public returns (uint revenue){
        require(balanceOf[msg.sender] >= amount);          
        balanceOf[this] += amount;                         
        balanceOf[msg.sender] -= amount;                   
        revenue = amount * sellPrice;
        msg.sender.transfer(revenue);                      
        Transfer(msg.sender, this, amount);                
        return revenue;                                    
    }
    
    function freezeAccount(address target, bool freeze) onlyOwner public{
        approvedAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    function mintToken(address target, uint256 mintedAmount) onlyOwner public{
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }


    function setMinBalance() onlyOwner public{
         minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
            
        require(!approvedAccount[msg.sender]);
             
    
        if(msg.sender.balance < minBalanceForAccounts)
            sell((minBalanceForAccounts - msg.sender.balance)/sellPrice);
        else
        _transfer(msg.sender, _to, _value);
             
    
     
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
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}