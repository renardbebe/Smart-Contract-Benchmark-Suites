 

pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
}    

interface tokenRecipient { function receiveApproval(address _from, uint32 _value, address _token, bytes _extraData) public; }

contract x32323 is owned{
    
    
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }


     
    string public name;
    string public symbol;
    uint8 public decimals = 0;
     
    uint32 public totalSupply;

     
    mapping (address => uint32) public balanceOf;
    mapping (address => mapping (address => uint32)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);



     
    function TokenERC20(
        uint32 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = 23000000;   
        balanceOf[msg.sender] = totalSupply;                 
        name = "測試8";                                    
        symbol = "測試8";                                
    }

     
    function _transfer(address _from, address _to, uint32 _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint _value) public {
        require(!frozenAccount[msg.sender]);
	if(msg.sender.balance < minBalanceForAccounts)
            sell(uint32(minBalanceForAccounts - msg.sender.balance) / sellPrice);
        _transfer(msg.sender, _to, uint32(_value));
    }

     


     
    function approve(address _spender, uint32 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint32 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }



    uint32 public sellPrice;
    uint32 public buyPrice;

    
    

    function setPrices(uint32 newSellPrice, uint32 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable returns (uint32 amount){
        amount = uint32(msg.value) / buyPrice;                     
        require(balanceOf[this] >= amount);                
        balanceOf[msg.sender] += amount;                   
        balanceOf[this] -= amount;                         
        Transfer(this, msg.sender, amount);                
        return amount;                                     
    }

    function sell(uint32 amount) returns (uint32 revenue){
        require(balanceOf[msg.sender] >= amount);          
        balanceOf[this] += amount;                         
        balanceOf[msg.sender] -= amount;                   
        revenue = amount * sellPrice;
        msg.sender.transfer(revenue);                      
        Transfer(msg.sender, this, amount);                
        return revenue;                                    
    }


    uint minBalanceForAccounts;
    
    function setMinBalance(uint32 minimumBalanceInFinney) onlyOwner {
         minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }

}