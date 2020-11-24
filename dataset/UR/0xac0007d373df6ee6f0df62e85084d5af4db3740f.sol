 

pragma solidity ^0.4.18;

 

contract upToken{
	 
    string public name;
    string public symbol;
    uint8 public decimals;
    string public standard = 'Token 0.1';
    uint256 public totalSupply;
    
     
    uint256 public tokenPrice;

	 
    uint256 public redeemPrice;
    
	 
    uint256 public lastTxBlockNum;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

     
    function upToken() public {        
        name = "upToken";
        symbol = "UPT";
        decimals = 15;
        totalSupply = 0;

		 
        tokenPrice = 100000000;
    }
    
	 
    function transfer(address _to, uint256 _value) public {
    	if (balanceOf[msg.sender] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        
        uint256 avp = 0;
        uint256 amount = 0;
        
         
        if ( _to == address(this) ) {
        	 
        	if ( lastTxBlockNum < (block.number-5000) ) {
        		avp = this.balance * 1000000000 / totalSupply;
        		amount = ( _value * avp ) / 1000000000;
        	} else {
	        	amount = ( _value * redeemPrice ) / 1000000000;
	        }
        	balanceOf[msg.sender] -= _value;
        	totalSupply -= _value;
        	        	
        	 
	    	if ( totalSupply != 0 ) {
	    		avp = (this.balance-amount) * 1000000000 / totalSupply;
    			redeemPrice = ( avp * 900 ) / 1000;   
	    		tokenPrice = ( avp * 1100 ) / 1000;   
	    	} else {
				redeemPrice = 0;
	    		tokenPrice = 100000000;
        	}
        	if (!msg.sender.send(amount)) revert();
        	Transfer(msg.sender, 0x0, _value);
        } else {
        	balanceOf[msg.sender] -= _value;
	        balanceOf[_to] += _value;
        	Transfer(msg.sender, _to, _value);
        }        
    }

    function approve(address _spender, uint256 _value) public returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        if (balanceOf[_from] < _value) revert();
        if ((balanceOf[_to] + _value) < balanceOf[_to]) revert();
        if (_value > allowance[_from][msg.sender]) revert();

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);
        return true;
    }
    
     
    function() internal payable {
    	 
    	if ( msg.value < 10000000000 ) revert();
    	
    	lastTxBlockNum = block.number;
    	
    	uint256 amount = ( msg.value / tokenPrice ) * 1000000000;
    	balanceOf[msg.sender] += amount;
    	totalSupply += amount;
    	
    	 
    	uint256 avp = this.balance * 1000000000 / totalSupply;
    	redeemPrice = avp * 900 / 1000;   
    	tokenPrice = avp * 1100 / 1000;   
    	
        Transfer(0x0, msg.sender, amount);
    }
}