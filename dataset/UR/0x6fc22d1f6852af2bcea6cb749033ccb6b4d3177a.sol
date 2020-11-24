 

pragma solidity ^0.4.24;

contract owned {
    address public owner;
}

contract TokenERC20 {
     
    string public name;
    string public symbol;
     
    uint8 public decimals = 18;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
}

contract BitSTDShares is owned, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;
}

contract BitSTDData {
     
    bool public data_migration_control = true;
    address public owner;
     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    uint256 public sellPrice;
    uint256 public buyPrice;
     
    mapping (address => bool) public owners;
     
    mapping (address => bool) public frozenAccount;
    BitSTDShares private bit;

    constructor(address contractAddress) public {
        bit = BitSTDShares(contractAddress);
        owner = msg.sender;
        name = bit.name();
        symbol = bit.symbol();
        decimals = bit.decimals();
        sellPrice = bit.sellPrice();
        buyPrice = bit.buyPrice();
        totalSupply = bit.totalSupply();
        balanceOf[msg.sender] = totalSupply;
    }

    modifier qualification {
        require(msg.sender == owner);
        _;
    }

     
    function transferAuthority(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function setBalanceOfAddr(address addr, uint256 value) qualification public {
        balanceOf[addr] = value;
    }

    function setAllowance(address authorizer, address sender, uint256 value) qualification public {
        allowance[authorizer][sender] = value;
    }


    function setFrozenAccount(address addr, bool value) qualification public {
        frozenAccount[addr] = value;
    }

    function addTotalSupply(uint256 value) qualification public {
        totalSupply = value;
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public {
        require(msg.sender == owner);
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     
    function getOldBalanceOf(address addr) constant  public returns(uint256) {
       return bit.balanceOf(addr);
    }
   
    
    function getOldAllowance(address authorizer, address sender) constant  public returns(uint256) {
        return bit.allowance(authorizer, sender);
    }

    function getOldFrozenAccount(address addr) constant public returns(bool) {
        return bit.frozenAccount(addr);
    }
   
}



interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract BitSTDLogic {
    address public owner;
     
	BitSTDData private data;

    constructor(address dataAddress) {
        data = BitSTDData(dataAddress);
        owner = msg.sender;
    }
    
     
    function transferAuthority(address newOwner) onlyOwner public {
        owner = newOwner;
    }
	modifier onlyOwner(){
		require(msg.sender == owner);
        _;
	}
	
	 
    function transferDataAuthority(address newOwner) onlyOwner public {
        data.transferAuthority(newOwner);
    }
    function setData(address dataAddress)onlyOwner public {
        data = BitSTDData(dataAddress);
    }

     
    function getOldBalanceOf(address addr) constant public returns (uint256) {
        return data.getOldBalanceOf(addr);
    }

	 
    function _transfer(address _from, address _to, uint _value) internal {
        uint256 f_value = balanceOf(_from);
        uint256 t_value = balanceOf(_to);
         
        require(_to != 0x0);
         
        require(f_value >= _value);
         
        require(t_value + _value > t_value);
         
        uint previousBalances = f_value + t_value;
         
        setBalanceOf(_from, f_value - _value);
         
        setBalanceOf(_to, t_value + _value);

         
        assert(balanceOf(_from) + balanceOf(_to) == previousBalances);

    }
     
    function migration(address sender, address receiver) onlyOwner public returns (bool) {
        require(sender != receiver);
        bool result= false;
         
         
        uint256 _value = data.getOldBalanceOf(receiver);
         
        if (data.balanceOf(receiver) == 0) {
            if (_value > 0) {
                _transfer(sender, receiver, _value);
                result = true;
            }
        }
         
        if (data.getOldFrozenAccount(receiver)== true) {
            if (data.frozenAccount(receiver)!= true) {
                data.setFrozenAccount(receiver, true);
            }
        }
         
        return result;
    }

     
    function balanceOf(address addr) constant public returns (uint256) {
        return data.balanceOf(addr);
    }

    function name() constant public returns (string) {
  	   return data.name();
  	}

  	function symbol() constant public returns(string) {
  	   return data.symbol();
  	}

  	function decimals() constant public returns(uint8) {
  	   return data.decimals();
  	}

  	function totalSupply() constant public returns(uint256) {
  	   return data.totalSupply();
  	}

  	function allowance(address authorizer, address sender) constant public returns(uint256) {
  	   return data.allowance(authorizer, sender);
  	}

  	function sellPrice() constant public returns (uint256) {
  	   return data.sellPrice();
  	}

  	function buyPrice() constant public returns (uint256) {
  	   return data.buyPrice();
  	}

  	function frozenAccount(address addr) constant public returns(bool) {
  	   return data.frozenAccount(addr);
  	}

     
    function setBalanceOf(address addr, uint256 value) onlyOwner public {
        data.setBalanceOfAddr(addr, value);
    }

     
    function transfer(address sender, address _to, uint256 _value) onlyOwner public returns (bool) {
        _transfer(sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address sender, address _to, uint256 _value) onlyOwner public returns (bool success) {
        uint256 a_value = data.allowance(_from, sender);
        require(_value <=_value );  
        data.setAllowance(_from, sender, a_value - _value);
        _transfer(_from, _to, _value);
        return true;
    }

      
    function approve(address _spender, address sender, uint256 _value) onlyOwner public returns (bool success) {
        data.setAllowance(sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, address sender, address _contract, uint256 _value, bytes _extraData) onlyOwner public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, sender, _value)) {
            spender.receiveApproval(sender, _value, _contract, _extraData);
            return true;
        }
    }

      
    function burn(address sender, uint256 _value) onlyOwner public returns (bool success) {
        uint256 f_value = balanceOf(sender);
        require(f_value >= _value);                  
        setBalanceOf(sender, f_value - _value);     
        data.addTotalSupply(totalSupply() - _value);                       
        return true;
    }

     
    function burnFrom(address _from, address sender, uint256 _value) onlyOwner public returns (bool success) {
        uint256 f_value = balanceOf(sender);
        uint256 a_value = data.allowance(_from, sender);
        require(f_value >= _value);                              
        require(_value <= a_value);                              
        setBalanceOf(_from, f_value - _value);                 
        data.setAllowance(_from, sender, f_value - _value);   
        data.addTotalSupply(totalSupply() - _value);          

        return true;
    }

     
       
       
    function mintToken(address target, address _contract, uint256 mintedAmount) onlyOwner public {
        uint256 f_value = balanceOf(target);
        setBalanceOf(target, f_value + mintedAmount);
        data.addTotalSupply(totalSupply() + mintedAmount);

    }

     
       
       
    function freezeAccount(address target, bool freeze) onlyOwner public returns (bool) {
        data.setFrozenAccount(target, freeze);
        return true;

    }

     
    function buy(address _contract, address sender, uint256 value) payable public {
        require(false);
        uint amount = value / data.buyPrice();         
        _transfer(_contract, sender, amount);               
    }
     
     
    function sell(address _contract, address sender, uint256 amount) public {
        require(false);
        require(address(_contract).balance >= amount * data.sellPrice());       
        _transfer(sender, _contract, amount);               
        sender.transfer(amount * data.sellPrice());           
    }

}



contract BitSTDView {

	BitSTDLogic private logic;
	address public owner;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);

     
    event Burn(address indexed from, uint256 value);

	 
    function balanceOf(address add)constant  public returns (uint256) {
	    return logic.balanceOf(add);
	}

	function name() constant  public returns (string) {
	    return logic.name();
	}

	function symbol() constant  public returns (string) {
	    return logic.symbol();
	}

	function decimals() constant  public returns (uint8) {
	    return logic.decimals();
	}

	function totalSupply() constant  public returns (uint256) {
	    return logic.totalSupply();
	}

	function allowance(address authorizer, address sender) constant  public returns (uint256) {
	    return logic.allowance(authorizer, sender);
	}

	function sellPrice() constant  public returns (uint256) {
	    return logic.sellPrice();
	}

	function buyPrice() constant  public returns (uint256) {
	    return logic.buyPrice();
	}

	function frozenAccount(address addr) constant  public returns (bool) {
	    return logic.frozenAccount(addr);
	}

	 

	 
    constructor(address logicAddressr) public {
        logic=BitSTDLogic(logicAddressr);
        owner=msg.sender;
    }

     
    modifier onlyOwner(){
		require(msg.sender == owner);
        _;
	}

	 
    function setBitSTD(address dataAddress,address logicAddressr) onlyOwner public{
        logic=BitSTDLogic(logicAddressr);
        logic.setData(dataAddress);
    }

     
    function transferLogicAuthority(address newOwner) onlyOwner public{
        logic.transferAuthority(newOwner);
    }

     
    function transferDataAuthority(address newOwner) onlyOwner public{
        logic.transferDataAuthority(newOwner);
    }

     
    function transferAuthority(address newOwner) onlyOwner public{
        owner=newOwner;
    }
     

     
    function migration(address addr) public {
        if (logic.migration(msg.sender, addr) == true) {
            emit Transfer(msg.sender, addr,logic.getOldBalanceOf(addr));
        }
    }

     
	function transfer(address _to, uint256 _value) public {
	    if (logic.transfer(msg.sender, _to, _value) == true) {
	        emit Transfer(msg.sender, _to, _value);
	    }
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	    if (logic.transferFrom(_from, msg.sender, _to, _value) == true) {
	        emit Transfer(_from, _to, _value);
	        return true;
	    }
	}

	 
	function approve(address _spender, uint256 _value) public returns (bool success) {
	    return logic.approve( _spender, msg.sender,  _value);
	}

	 
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
	    return logic.approveAndCall(_spender, msg.sender, this, _value, _extraData);
	}

	 
	function burn(uint256 _value) public returns (bool success) {
	    if (logic.burn(msg.sender, _value) == true) {
	        emit Burn(msg.sender, _value);
	        return true;
	    }
	}

	 
	function burnFrom(address _from, uint256 _value) public returns (bool success) {
	    if (logic.burnFrom( _from, msg.sender, _value) == true) {
	        emit Burn(_from, _value);
	        return true;
	    }
	}

	 
     
     
	function mintToken(address target, uint256 mintedAmount) onlyOwner public {
	    logic.mintToken(target, this,  mintedAmount);
	    emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
	}

	 
     
     
	function freezeAccount(address target, bool freeze) onlyOwner public {
	    if (logic.freezeAccount(target,  freeze) == true) {
	        emit FrozenFunds(target, freeze);
	    }
	}

	 
	function buy() payable public {
	    logic.buy(this, msg.sender, msg.value);
	}

	function sell(uint256 amount) public {
	    logic.sell(this,msg.sender, amount);
	}
}