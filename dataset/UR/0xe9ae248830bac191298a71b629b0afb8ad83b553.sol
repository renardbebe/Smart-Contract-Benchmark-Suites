 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 
 
 
 
 


 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

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

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);    
        balanceOf[msg.sender] = totalSupply;                     
        name = tokenName;                                        
        symbol = tokenSymbol;                                   
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

}

 
 
 
 
 

contract LuxuryGoodsCoin is owned, TokenERC20 {

    uint256 public sellPrice = 20180418134311;         
    uint256 public buyPrice = 1000000000000000000;     
	uint256 public limitAMT = 0;
	bool public isPreSales = false;


     mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    function LuxuryGoodsCoin(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

	 
	 
    function startPreSales(uint256 amtPreSales) onlyOwner public returns (uint256) {
	    require (balanceOf[owner] - amtPreSales > 0);
        limitAMT = balanceOf[owner] - amtPreSales;
		isPreSales = true;
		return limitAMT;
	}

	 
    function stopPreSales() onlyOwner public {
	    isPreSales = false;
	}

     
 

     
     
 

     
	 
	function getLuxAMT(uint256 amtETH) public constant returns (uint256) {
        uint256 amount = amtETH / buyPrice;                    
        amount = amount * 10 ** uint256(decimals);             
		return amount;
	}

	 
	function getBalanceLux() public constant returns (uint256) {
	    uint256 balLUX;
		balLUX = balanceOf[msg.sender];
		return balLUX;
	}

	function getSalesPrice() public constant returns (uint256) {
		return buyPrice;
	}

	function getLeftPreSalesAMT() public constant returns (uint256) {
	    uint256 leftPSAMT;
		leftPSAMT = balanceOf[owner] - limitAMT;
		return leftPSAMT;
	}

     
    function procPreSales() payable public returns (uint256) {
        require (isPreSales == true);
        uint256 amount = msg.value / buyPrice;                  
        amount = amount * 10 ** uint256(decimals);              
	    if ( balanceOf[owner] - amount <= limitAMT ){
		    isPreSales = false;
		}
        _transfer(owner, msg.sender, amount);
		owner.transfer(msg.value);
		return amount;
    }

	 
    function procNormalSales() payable public returns (uint256) {
        uint256 amount = msg.value / buyPrice;                  
        amount = amount * 10 ** uint256(decimals);              
        _transfer(owner, msg.sender, amount);
		owner.transfer(msg.value);
		return amount;
    }

	 
	 
    function procNormalBuyBack(address seller) onlyOwner payable public returns (uint256) {
        uint256 amount = msg.value / buyPrice;                  
        amount = amount * 10 ** uint256(decimals);              
        _transfer(seller, msg.sender, amount);
		seller.transfer(msg.value);
		return amount;
    }

}