 

pragma solidity 0.4.21;

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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[this] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
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
}

 

contract LandCoin is owned, TokenERC20 {

     

    uint256 public buyPrice;
    uint256 public icoStartUnix;
    uint256 public icoEndUnix;
    bool public icoOverride;
    bool public withdrawlsEnabled;

    mapping (address => uint256) public paidIn;
    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);
    event Burn(address indexed from, uint256 value);
    event FundTransfer(address recipient, uint256 amount);

     

     
    function LandCoin(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint256 _buyPrice,     
        uint256 _icoStartUnix,       
        uint256 _icoEndUnix          
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {
        buyPrice = _buyPrice;
        icoStartUnix = _icoStartUnix;
        icoEndUnix = _icoEndUnix;
        icoOverride = false;
        withdrawlsEnabled = false;
         
        allowance[this][owner] = totalSupply;
    }

     

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];   
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        require(balanceOf[_from] + balanceOf[_to] == previousBalances);  
        emit Transfer(_from, _to, _value);                        
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     

     
    modifier inICOtimeframe() {
        require((now >= icoStartUnix * 1 seconds && now <= icoEndUnix * 1 seconds) || (icoOverride == true));
        _;
    }

     
    function buy() inICOtimeframe payable public {
        uint amount = msg.value * (10 ** uint256(decimals)) / buyPrice;             
        _transfer(this, msg.sender, amount);              				 
        paidIn[msg.sender] += msg.value;
    }

     
    function () inICOtimeframe payable public {
        uint amount = msg.value * (10 ** uint256(decimals)) / buyPrice;             
        _transfer(this, msg.sender, amount);              				 
        paidIn[msg.sender] += msg.value;
    }

     

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
    function burn(uint256 _value, uint256 _confirmation) onlyOwner public returns (bool success) {
        require(_confirmation==7007);                  
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
     
    function setPrices(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;
    }

     
    function setContractAllowance(address allowedAddress, uint256 allowedAmount) onlyOwner public returns (bool success) {
    	require(allowedAmount <= totalSupply);
    	allowance[this][allowedAddress] = allowedAmount;
    	return true;
    }

     
   
   	 
    function secondaryICO(bool _icoOverride) onlyOwner public {
    	icoOverride = _icoOverride;
    }

     
    function enableWithdrawal(bool _withdrawlsEnabled) onlyOwner public {
    	withdrawlsEnabled = _withdrawlsEnabled;
    }

     function safeWithdrawal() public {
    	require(withdrawlsEnabled);
    	require(now > icoEndUnix);
    	uint256 weiAmount = paidIn[msg.sender]; 	
    	uint256 purchasedTokenAmount = paidIn[msg.sender] * (10 ** uint256(decimals)) / buyPrice;

    	 
    	if(purchasedTokenAmount > balanceOf[msg.sender]) { purchasedTokenAmount = balanceOf[msg.sender]; }
    	 
    	if(weiAmount > balanceOf[msg.sender] * buyPrice / (10 ** uint256(decimals))) { weiAmount = balanceOf[msg.sender] * buyPrice / (10 ** uint256(decimals)); }
    	
        if (purchasedTokenAmount > 0 && weiAmount > 0) {
	        _transfer(msg.sender, this, purchasedTokenAmount);
            if (msg.sender.send(weiAmount)) {
                paidIn[msg.sender] = 0;
                emit FundTransfer(msg.sender, weiAmount);
            } else {
                _transfer(this, msg.sender, purchasedTokenAmount);
            }
        }
    }

    function withdrawal() onlyOwner public returns (bool success) {
		require(now > icoEndUnix && !icoOverride);
		address thisContract = this;
		if (owner == msg.sender) {
            if (msg.sender.send(thisContract.balance)) {
                emit FundTransfer(msg.sender, thisContract.balance);
                return true;
            } else {
                return false;
            }
        }
    }

    function manualWithdrawalFallback(address target, uint256 amount) onlyOwner public returns (bool success) {
    	require(now > icoEndUnix && !icoOverride);
    	address thisContract = this;
    	require(amount <= thisContract.balance);
		if (owner == msg.sender) {
		    if (target.send(amount)) {
		        return true;
		    } else {
		        return false;
		    }
        }
    }
}