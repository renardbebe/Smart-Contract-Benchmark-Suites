 

contract BitSTDLogic {
    function name()constant  public returns(string) {}
	function symbol()constant  public returns(string) {}
	function decimals()constant  public returns(uint8) {}
	function totalSupply()constant  public returns(uint256) {}
	function allowance(address add,address _add)constant  public returns(uint256) {}
	function sellPrice()constant  public returns(uint256) {}
	function buyPrice()constant  public returns(uint256) {}
	function frozenAccount(address add)constant  public returns(bool) {}
	function migration(address sender,address add) public{}
	function balanceOf(address add)constant  public returns(uint256) {}
	function transfer(address sender,address _to, uint256 _value) public {}
	function transferFrom(address _from,address sender, address _to, uint256 _value) public returns (bool success) {}
	function approve(address _spender,address sender, uint256 _value) public returns (bool success) {}
	function approveAndCall(address _spender,address sender,address _contract, uint256 _value, bytes _extraData)public returns (bool success) {}
	function burn(address sender,uint256 _value) public returns (bool success) {}
	function burnFrom(address _from,address sender, uint256 _value) public returns (bool success) {}
	function mintToken(address target,address _contract, uint256 mintedAmount)  public {}
	function freezeAccount(address target, bool freeze)  public {}
	function buy(address _contract,address sender,uint256 value) payable public {}
	function sell(address _contract,address sender,uint256 amount) public {}
	function Transfer_of_authority(address newOwner) public{}
	function Transfer_of_authority_data(address newOwner) public {}
	function setData(address dataAddress) public {}
	 
    function getOld_BalanceOfr(address add)constant  public returns(uint256){}
}
contract BitSTDView{

	BitSTDLogic private logic;
	address public owner;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);

     
    event Burn(address indexed from, uint256 value);

	 
    function balanceOf(address add)constant  public returns(uint256) {
	    return logic.balanceOf(add);
	}

	function name() constant  public returns(string) {
	    return logic.name();
	}

	function symbol() constant  public returns(string) {
	    return logic.symbol();
	}

	function decimals() constant  public returns(uint8) {
	    return logic.decimals();
	}

	function totalSupply() constant  public returns(uint256) {
	    return logic.totalSupply();
	}

	function allowance(address add,address _add) constant  public returns(uint256) {
	    return logic.allowance(add,_add);
	}

	function sellPrice() constant  public returns(uint256) {
	    return logic.sellPrice();
	}

	function buyPrice() constant  public returns(uint256) {
	    return logic.buyPrice();
	}

	function frozenAccount(address add) constant  public returns(bool) {
	    return logic.frozenAccount(add);
	}

	 

	 
    function BitSTDView(address logicAddressr) public {
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

     
    function Transfer_of_authority_logic(address newOwner) onlyOwner public{
        logic.Transfer_of_authority(newOwner);
    }

     
    function Transfer_of_authority_data(address newOwner) onlyOwner public{
        logic.Transfer_of_authority_data(newOwner);
    }

     
    function Transfer_of_authority(address newOwner) onlyOwner public{
        owner=newOwner;
    }
     

     
    function migration(address add) public{
        logic.migration(msg.sender,add);
        emit Transfer(msg.sender, add,logic.getOld_BalanceOfr(add));
    }

     
	function transfer(address _to, uint256 _value) public {
	    logic.transfer(msg.sender,_to,_value);
	    emit Transfer(msg.sender, _to, _value);
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	    return logic.transferFrom( _from, msg.sender,  _to,  _value);
	     emit Transfer(_from, _to, _value);
	}

	 
	function approve(address _spender, uint256 _value) public returns (bool success) {
	    return logic.approve( _spender, msg.sender,  _value);
	}

	 
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
	    return logic.approveAndCall( _spender, msg.sender,this,  _value,  _extraData);
	}

	 
	function burn(uint256 _value) public returns (bool success) {
	    return logic.burn( msg.sender, _value);
	    emit Burn(msg.sender, _value);
	}

	 
	function burnFrom(address _from, uint256 _value) public returns (bool success) {
	    return logic.burnFrom( _from, msg.sender,  _value);
	    emit Burn(_from, _value);
	}

	 
     
     
	function mintToken(address target, uint256 mintedAmount) onlyOwner public {
	    logic.mintToken( target,this,  mintedAmount);
	    emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
	}

	 
     
     
	function freezeAccount(address target, bool freeze) onlyOwner public {
	    logic.freezeAccount( target,  freeze);
	    emit FrozenFunds(target, freeze);
	}

	 
	function buy() payable public {
	    logic.buy( this,msg.sender,msg.value);
	}

	function sell(uint256 amount) public {
	    logic.sell( this,msg.sender, amount);
	}

}