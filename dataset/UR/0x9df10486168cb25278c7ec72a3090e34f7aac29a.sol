 

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

 
contract GPowerToken is owned{
    
     
	string public standard = 'Token 1';

	string public name = 'GPower';

	string public symbol = 'GRP';

	uint8 public decimals = 18;

	uint256 public totalSupply =0;
	
	 
    uint preSaleStart=1513771200;
    uint preSaleEnd=1515585600;
    uint256 preSaleTotalTokens=30000000;
    uint256 preSaleTokenCost=6000;
    address preSaleAddress;
    bool public enablePreSale=false;
    
     
    uint icoStart;
    uint256 icoSaleTotalTokens=400000000;
    address icoAddress;
    bool public enableIco=false;
    
     
    uint256 advisersConsultantTokens=15000000;
    address advisersConsultantsAddress;
    
     
    uint256 bountyTokens=15000000;
    address bountyAddress;
    
     
    uint256 founderTokens=40000000;
    address founderAddress;
    
     
    address public wallet;
    
     
    bool public transfersEnabled = false;
    bool public stopSale=false;
    uint256 newCourceSale=0;
    
      
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public balanceOfPreSale;
    
     
    mapping (address => mapping (address => uint256)) allowed;
    
     
    event Transfer(address from, address to, uint256 value);
    
	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	 
	event Destruction(uint256 _amount);
	
	 
	event Burn(address indexed from, uint256 value);
	
	 
	event Issuance(uint256 _amount);
	
	function GPowerToken() public{
        preSaleAddress=0xC07850969A0EC345A84289f9C5bb5F979f27110f;
        icoAddress=0x1C21Cf57BF4e2dd28883eE68C03a9725056D29F1;
        advisersConsultantsAddress=0xe8B6dA1B801b7F57e3061C1c53a011b31C9315C7;
        bountyAddress=0xD53E82Aea770feED8e57433D3D61674caEC1D1Be;
        founderAddress=0xDA0D3Dad39165EA2d7386f18F96664Ee2e9FD8db;
        totalSupply =(500000000*1000000000000000000);
	}
	
	 
    function() payable public {
        require(msg.value>0);
        require(msg.sender != 0x0);
        
        if(!stopSale){
            uint256 weiAmount;
            uint256 tokens;
            wallet=owner;
        
             if(newCourceSale>0){
                    weiAmount=newCourceSale;
                }
                    
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
                        weiAmount=4000;
            }
        
        tokens=msg.value*weiAmount/1000000000000000000;
        Transfer(this, msg.sender, tokens*1000000000000000000);
        balanceOf[msg.sender]+=tokens*1000000000000000000;
        totalSupply-=tokens*1000000000000000000;
        wallet.transfer(msg.value);
        }
        else{
                require(0>1);
             }
	}
	
	 
	function transfer(address _to, uint256 _value) public returns (bool success) {
	    if(transfersEnabled || msg.sender==owner){
		    require(balanceOf[msg.sender] >= _value*1000000000000000000);
		     
		    balanceOf[msg.sender]-= _value*1000000000000000000;
	        balanceOf[_to] += _value*1000000000000000000;
		    Transfer(msg.sender, _to, _value*1000000000000000000);
		    return true;
	    }
	    else{
	        return false;
	    }
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	    if(transfersEnabled || msg.sender==owner){
	         
		    require(balanceOf[_from] >= _value*1000000000000000000);
		     

		     
		    balanceOf[_from] -= _value*1000000000000000000;
		     
		    balanceOf[_to] +=  _value*1000000000000000000;

		    Transfer(_from, _to, _value*1000000000000000000);
		    return true;
	    }
	    else{
	        return false;
	    }
	}
	
	 
	function transferOwner(address _to,uint256 _value) public onlyOwner returns(bool success){
	     
	    totalSupply-=_value*1000000000000000000;
		 
		balanceOf[_to] = (balanceOf[_to] + _value*1000000000000000000);
		Transfer(this, _to, _value*1000000000000000000);
		return true;
	}
	
	function transferArrayBalanceForPreSale(address[] addrs,uint256[] values) public onlyOwner returns(bool result){
	    for(uint i=0;i<addrs.length;i++){
	        transfer(addrs[i],values[i]*1000000000000000000);
	    }
	    return true;
	}
	
	function transferBalanceForPreSale(address addrs,uint256 value) public onlyOwner returns(bool result){
	        transfer(addrs,value*1000000000000000000);
	        return true;
	}
	
	 
	function burnOwner(uint256 _value) public onlyOwner returns (bool success) {
		destroyOwner(msg.sender, _value*1000000000000000000);
		Burn(msg.sender, _value*1000000000000000000);
		return true;
	}
	
	 
	function destroyOwner(address _from, uint256 _amount) public onlyOwner{
	    balanceOf[_from] =(balanceOf[_from] - _amount*1000000000000000000);
		totalSupply = (totalSupply - _amount*1000000000000000000);
		Transfer(_from, this, _amount*1000000000000000000);
		Destruction(_amount*1000000000000000000);
	}
	
	 
	function killTotalSupply() onlyOwner public {
	    totalSupply=0;
	}
	
	  
    function GetBalanceOwnerForTransfer(uint256 value) onlyOwner public{
        require(msg.sender==owner);
        if(totalSupply>=value*1000000000000000000){
            balanceOf[this]-= value*1000000000000000000;
	        balanceOf[owner] += value*1000000000000000000;
	        totalSupply-=value*1000000000000000000;
            Transfer(this,owner,value*1000000000000000000);
        }
    }
    
	
	 
	function killTokensForGPower() onlyOwner public{
	    if(bountyTokens>0){
	        Transfer(this,bountyAddress,bountyTokens*1000000000000000000);
            Transfer(this,founderAddress,founderTokens*1000000000000000000);
            Transfer(this,advisersConsultantsAddress,advisersConsultantTokens*1000000000000000000);
            
            balanceOf[bountyAddress]+=(bountyTokens*1000000000000000000);
	        balanceOf[founderAddress]+=(founderTokens*1000000000000000000);
	        balanceOf[advisersConsultantsAddress]+=advisersConsultantTokens*1000000000000000000;
	        totalSupply-=((bountyTokens+founderTokens+advisersConsultantTokens)*1000000000000000000);
	        
	        bountyTokens=0;
	        founderTokens=0;
	        advisersConsultantTokens=0; 
	    }
	}
	
	 
	function contractBalance() constant public returns (uint256 balance) {
		return balanceOf[this];
	}
	
	 
	function setParamsStopSale(bool _value) public onlyOwner{
	    stopSale=_value;
	}
	
	 
	function setParamsTransfer(bool _value) public onlyOwner{
	    transfersEnabled=_value;
	}
	
	 
    function setParamsIco(bool _value) public onlyOwner returns(bool result){
        enableIco=_value;
        return true;
    }
    
	 
    function setParamsPreSale(bool _value) public onlyOwner returns(bool result){
        enablePreSale=_value;
        return true;
    }
    
     
    function setCourceSale(uint256 value) public onlyOwner{
        newCourceSale=value;
    }
	
	 
    function isIco() constant public returns (bool ico) {
		 bool result=((icoStart+(35*24*60*60)) >= now);
		 if(enableIco){
		     return true;
		 }
		 else{
		     return result;
		 }
	}
    
     
    function isPreSale() constant public returns (bool preSale) {
		bool result=(preSaleEnd >= now);
		if(enablePreSale){
		    return true;
		}
		else{
		    return result;
		}
	}
}