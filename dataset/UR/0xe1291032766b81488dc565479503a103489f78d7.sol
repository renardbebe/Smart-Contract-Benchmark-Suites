 

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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract x32323 is owned{

 

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => bool) initialized;

    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
    string public name;
    string public symbol;
    uint8 public decimals = 2;
    uint256 public totalSupply;
    uint256 public maxSupply = 2300000000;
    uint256 totalairdrop = 600000000;
    uint256 airdrop1 = 1700008000;  
    uint256 airdrop2 = 1700011000;  
    uint256 airdrop3 = 1700012500;  
    
 

    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
	initialSupply = maxSupply - totalairdrop;
    balanceOf[msg.sender] = initialSupply;
    totalSupply = initialSupply;
        name = "測試16";
        symbol = "測試16";         
    }

    function initialize(address _address) internal returns (bool success) {

        if (!initialized[_address]) {
            initialized[_address] = true ;
            if(totalSupply < airdrop1){
                balanceOf[_address] += 20;
                totalSupply += 20;
            }
            if(airdrop1 <= totalSupply && totalSupply < airdrop2){
                balanceOf[_address] += 8;
                totalSupply += 8;
            }
            if(airdrop2 <= totalSupply && totalSupply <= airdrop3-3){
                balanceOf[_address] += 3;
                totalSupply += 3;    
            }
	    
        }
        return true;
    }
    
    function reward(address _address) internal returns (bool success) {
	    if (totalSupply < maxSupply) {
	        initialized[_address] = true ;
            if(totalSupply < airdrop1){
                balanceOf[_address] += 10;
                totalSupply += 10;
            }
            if(airdrop1 <= totalSupply && totalSupply < airdrop2){
                balanceOf[_address] += 3;
                totalSupply += 3;
            }
            if(airdrop2 <= totalSupply && totalSupply < airdrop3){
                balanceOf[_address] += 1;
                totalSupply += 1;    
            }
		
	    }
	    return true;
    }
 

    function _transfer(address _from, address _to, uint _value) internal {
    	require(!frozenAccount[_from]);
        require(_to != 0x0);

        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

         
	   
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        Transfer(_from, _to, _value);

         

	initialize(_from);
	reward(_from);
	initialize(_to);
        
        
    }

    function transfer(address _to, uint256 _value) public {
        
	if(msg.sender.balance < minBalanceForAccounts)
            sell((minBalanceForAccounts - msg.sender.balance) / sellPrice);
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

 

    uint256 public sellPrice;
    uint256 public buyPrice;

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable returns (uint amount){
        amount = msg.value / buyPrice;                     
        require(balanceOf[this] >= amount);                
        balanceOf[msg.sender] += amount;                   
        balanceOf[this] -= amount;                         
        Transfer(this, msg.sender, amount);                
        return amount;                                     
    }

    function sell(uint amount) returns (uint revenue){
        require(balanceOf[msg.sender] >= amount);          
        balanceOf[this] += amount;                         
        balanceOf[msg.sender] -= amount;                   
        revenue = amount * sellPrice;
        msg.sender.transfer(revenue);                      
        Transfer(msg.sender, this, amount);                
        return revenue;                                    
    }


    uint minBalanceForAccounts;
    
    function setMinBalance(uint minimumBalanceInFinney) onlyOwner {
         minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }

}