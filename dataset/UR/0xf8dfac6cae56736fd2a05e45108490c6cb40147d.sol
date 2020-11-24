 

pragma solidity ^0.4.18;

 
contract owned {
	address public owner;
    
     
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function owned() public {
		owner = msg.sender;
	}

     
	function changeOwner(address newOwner) onlyOwner public {
		owner = newOwner;
	}
    
     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
     
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

 
contract Utils {
    
	 
	modifier validAddress(address _address) {
		require(_address != 0x0);
		_;
	}

	 
	modifier notThis(address _address) {
		require(_address != address(this));
		_;
	}
}

 
contract GraphenePowerToken is owned,Utils{
    
     
	string public standard = 'Token 0.1';

	string public name = 'Graphene Power';

	string public symbol = 'GRP';

	uint8 public decimals = 18;

	uint256 _totalSupply =0;
	
	 
    uint preSaleStart=1513771200;
    uint preSaleEnd=1515585600;
    uint256 preSaleTotalTokens=30000000;
    uint256 preSaleTokenCost=6000;
    address preSaleAddress;
    bool enablePreSale=false;
    
     
    uint icoStart;
    uint256 icoSaleTotalTokens=400000000;
    address icoAddress;
    bool enableIco=false;
    
     
    uint256 advisersConsultantTokens=15000000;
    address advisersConsultantsAddress;
    
     
    uint256 bountyTokens=15000000;
    address bountyAddress;
    
     
    uint256 founderTokens=40000000;
    address founderAddress;
    
     
    address public wallet;
    
     
    bool enableMintTokens=true;
    
     
    bool public transfersEnabled = false;
    
      
    mapping (address => uint256) balanceOf;
    
     
    mapping (address => mapping (address => uint256)) allowed;
    
     
    event Transfer(address from, address to, uint256 value);
    
	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	 
	event Destruction(uint256 _amount);
	
	 
	event Burn(address indexed from, uint256 value);
	
	 
	event Issuance(uint256 _amount);
	
	function GraphenePowerToken() public{
        preSaleAddress=0xC07850969A0EC345A84289f9C5bb5F979f27110f;
        icoAddress=0x1C21Cf57BF4e2dd28883eE68C03a9725056D29F1;
        advisersConsultantsAddress=0xe8B6dA1B801b7F57e3061C1c53a011b31C9315C7;
        bountyAddress=0xD53E82Aea770feED8e57433D3D61674caEC1D1Be;
        founderAddress=0xDA0D3Dad39165EA2d7386f18F96664Ee2e9FD8db;
        _totalSupply =500000000;
        balanceOf[this]=_totalSupply;
	}
	
	  
    modifier transfersAllowed {
		assert(transfersEnabled);
		_;
	}
	
	 
	modifier validAddress(address _address) {
		require(_address != 0x0);
		_;
	}

	 
	modifier notThis(address _address) {
		require(_address != address(this));
		_;
	}
	
	    
    function() payable public {
        require(msg.value>0);
        buyTokens(msg.sender);
	}
	
	 
	function buyTokens(address beneficiary) payable public {
        require(beneficiary != 0x0);

        uint256 weiAmount;
        uint256 tokens;
        wallet=owner;
        
        if(isPreSale()){
            wallet=preSaleAddress;
            weiAmount=6000;
        }
        else if(isIco()){
            wallet=icoAddress;
            
            if((icoStart+(7*24*60*60)) >= now){
               weiAmount=4000;
            }
            else if((icoStart+(14*24*60*60)) >= now){
                 weiAmount=3750;
            }
            else if((icoStart+(21*24*60*60)) >= now){
                 weiAmount=3500;
            }
            else if((icoStart+(28*24*60*60)) >= now){
                 weiAmount=3250;
            }
            else if((icoStart+(35*24*60*60)) >= now){
                 weiAmount=3000;
            }
            else{
                weiAmount=2000;
            }
        }
        else{
            weiAmount=6000;
        }
        
        forwardFunds();
        tokens=msg.value*weiAmount/1000000000000000000;
        mintToken(beneficiary, tokens);
        Transfer(this, beneficiary, tokens);
     }
    
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
    
     
	function getTokensForGraphenePower() onlyOwner public returns(bool result){
	    require(enableMintTokens);
	    mintToken(bountyAddress, bountyTokens);
	    Transfer(this, bountyAddress, bountyTokens);
	    mintToken(founderAddress, founderTokens);
	    Transfer(this, founderAddress, founderTokens);
	    mintToken(advisersConsultantsAddress, advisersConsultantTokens);
        Transfer(this, advisersConsultantsAddress, advisersConsultantTokens);
	    return true;
	}
	
	 
	function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
	
	 
	function transfer(address _to, uint256 _value) transfersAllowed public returns (bool success) {
		require(balanceOf[_to] >= _value);
		 
		balanceOf[msg.sender] = (balanceOf[msg.sender] -_value);
		balanceOf[_to] =(balanceOf[_to] + _value);
		Transfer(msg.sender, _to, _value);
		return true;
	}
	
	 
	function mintToken(address target, uint256 mintedAmount) onlyOwner public returns(bool result) {
	    if(enableMintTokens){
	        balanceOf[target] += mintedAmount;
		    _totalSupply =(_totalSupply-mintedAmount);
		    Transfer(this, target, mintedAmount);
		    return true;
	    }
	    else{
	        return false;
	    }
	}
	
	 
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}
	
	 
	function transferFrom(address _from, address _to, uint256 _value) transfersAllowed public returns (bool success) {
	    require(transfersEnabled);
		 
		require(balanceOf[_from] >= _value);
		 
		require(_value <= allowed[_from][msg.sender]);

		 
		balanceOf[_from] = (balanceOf[_from] - _value);
		 
		balanceOf[_to] = (balanceOf[_to] + _value);

		allowed[_from][msg.sender] = (allowed[_from][msg.sender] - _value);
		Transfer(_from, _to, _value);
		return true;
	}
	
	 
	function issue(address _to, uint256 _amount) public onlyOwner validAddress(_to) notThis(_to) {
		_totalSupply = (_totalSupply - _amount);
		balanceOf[_to] = (balanceOf[_to] + _amount);
		Issuance(_amount);
		Transfer(this, _to, _amount);
	}
	
	 
	function burn(uint256 _value) public returns (bool success) {
		destroy(msg.sender, _value);
		Burn(msg.sender, _value);
		return true;
	}
	
	 
	function destroy(address _from, uint256 _amount) public {
	    require(msg.sender == _from);
	    require(balanceOf[_from] >= _amount);
		balanceOf[_from] =(balanceOf[_from] - _amount);
		_totalSupply = (_totalSupply - _amount);
		Transfer(_from, this, _amount);
		Destruction(_amount);
	}
	
	 
	function killBalance() onlyOwner public {
		require(!enablePreSale && !enableIco);
		if(this.balance > 0) {
			owner.transfer(this.balance);
		}
	}
	
	 
	function enabledMintTokens(bool value) onlyOwner public returns(bool result) {
		enableMintTokens = value;
		return enableMintTokens;
	}
	
	 
	function contractBalance() constant public returns (uint256 balance) {
		return balanceOf[this];
	}
	
	 
	function startPreSale() onlyOwner public returns(bool result){
	    enablePreSale=true;
	    return enablePreSale;
	}
	
	 
	function endPreSale() onlyOwner public returns(bool result){
	     enablePreSale=false;
	    return enablePreSale;
	}
	
	 
	function startIco() onlyOwner public returns(bool result){
	    enableIco=true;
	    return enableIco;
	}
	
	 
	function endIco() onlyOwner public returns(bool result){
	     enableIco=false;
	     return enableIco;
	}
	
	 
    function isIco() constant public returns (bool closed) {
		 bool result=((icoStart+(35*24*60*60)) >= now);
		 if(enableIco){
		     return true;
		 }
		 else{
		     return result;
		 }
	}
    
     
    function isPreSale() constant public returns (bool closed) {
		bool result=(preSaleEnd >= now);
		if(enablePreSale){
		    return true;
		}
		else{
		    return result;
		}
	}
}