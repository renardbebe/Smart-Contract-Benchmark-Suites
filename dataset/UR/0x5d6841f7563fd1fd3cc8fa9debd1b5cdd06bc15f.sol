 

pragma solidity ^0.4.18;

contract CalledA {

    address[] public callers;

    function CalledA() public {
        callers.push(msg.sender);
    }

    modifier onlyCallers {
        bool encontrado = false;
        for (uint i = 0; i < callers.length && !encontrado; i++) {
            if (callers[i] == msg.sender) {
                encontrado = true;
            }
        }
        require(encontrado);
        _;
    }

    function transferCallership(address newCaller,uint index) public onlyCallers {
        callers[index] = newCaller;
    }

    function deleteCaller(uint index) public onlyCallers {
        delete callers[index];
    }

    function addCaller(address caller) public onlyCallers {
        callers.push(caller);
    }
}

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

    

    
}

 
 
 

contract Mimicoin is CalledA, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    function Mimicoin(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {
        sellPrice = 1161723500000000;
        buyPrice = 929378000000000;
    }

    function () payable public onlyCallers {

    }

    function getBalance(address addr) public view returns(uint) {
		return balanceOf[addr];
	}

    function getRevenue(uint amount) public onlyCallers {
        callers[0].transfer(amount);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        _transfer(_from, _to, _value);
        return true;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] = safeSub(balanceOf[_from],_value);                          
        balanceOf[_to] = safeAdd(_value,balanceOf[_to]);                            
        Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyCallers public {
        balanceOf[target] += mintedAmount;
        totalSupply = safeAdd(mintedAmount,totalSupply);
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyCallers public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyCallers public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     
    function buy() payable public {
        uint amount = msg.value * (10 ** uint256(decimals)) / buyPrice;                
        _transfer(callers[0], msg.sender, amount);    
    }

     
     
    function sell(uint256 amount) public {
       require(balanceOf[msg.sender] >= amount);         
       uint revenue = safeMul(amount,sellPrice);
       revenue = revenue / (10 ** uint256(decimals));
        msg.sender.transfer (revenue);
        _transfer(msg.sender, callers[0], amount);
    }
    
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}