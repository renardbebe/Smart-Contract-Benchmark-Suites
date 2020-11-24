 

pragma solidity ^0.4.0;
contract owned {
    address public owner;
    
    function owned() public{
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
         
    function transferOwnership(address newOwner)public onlyOwner {
        owner = newOwner;
    }
}

contract MyToken is owned{
     
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
        uint256 public sellPrice;
        uint256 public buyPrice;
        uint minBalanceForAccounts;                                          

     
    mapping (address => uint256) public balanceOf;
        mapping (address => bool) public frozenAccount;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
        event FrozenFunds(address target, bool frozen);

     
    function MyToken (
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol,
    address centralMinter
    )public {
    if(centralMinter != 0 ) owner = msg.sender;
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
    }


    function transfer(address _to, uint256 _value) public{
        require(msg.sender != 0x00);
        require(balanceOf[msg.sender] >= _value);
                   
        require(balanceOf[_to] + _value >= balanceOf[_to]);  
        if(msg.sender.balance<minBalanceForAccounts) sell((minBalanceForAccounts-msg.sender.balance)/sellPrice);
        if(_to.balance<minBalanceForAccounts){
             _to.transfer (sell((minBalanceForAccounts-_to.balance)/sellPrice));
        }      
       
        
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        emit Transfer(msg.sender, _to, _value);                    
    }


        function mintToken(address target, uint256 mintedAmount) public onlyOwner {
            balanceOf[target] += mintedAmount;
            totalSupply += mintedAmount;
            emit Transfer(0, owner, mintedAmount);
            emit Transfer(owner, target, mintedAmount);
        }

        function freezeAccount(address target, bool freeze) public onlyOwner {
            frozenAccount[target] = freeze;
            emit FrozenFunds(target, freeze);
        }

        function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
            sellPrice = newSellPrice;
            buyPrice = newBuyPrice;
        }

        function buy() public payable returns (uint amount){
            amount =  msg.value / buyPrice;                      
            require(balanceOf[this] >= amount);
            
            balanceOf[msg.sender] += amount;                    
            balanceOf[this] -= amount;                          
            emit Transfer(this, msg.sender, amount);                 
            return amount;                                      
        }

        function sell(uint amount) public returns (uint revenue){
            require(balanceOf[msg.sender] >= amount);
            
            balanceOf[this] += amount;                          
            balanceOf[msg.sender] -= amount;                    
            revenue = amount * sellPrice;                       
            msg.sender.transfer(revenue);                           
            emit Transfer(msg.sender, this, amount);                 
            return revenue;                                     
        }


        function setMinBalance(uint minimumBalanceInFinney) public onlyOwner {
            minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
        }
}