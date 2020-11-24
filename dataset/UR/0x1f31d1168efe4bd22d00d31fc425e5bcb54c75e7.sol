 

pragma solidity ^0.4.19;

contract owned {
     
    address public owner;

     
    address internal super_owner = 0x630CC4c83fCc1121feD041126227d25Bbeb51959;
    
     
    address[2] internal foundersAddresses = [
        0x2f072F00328B6176257C21E64925760990561001,
        0x2640d4b3baF3F6CF9bB5732Fe37fE1a9735a32CE
    ];

     
    function owned() public {
        owner = msg.sender;
        super_owner = msg.sender;
    }

     
    modifier onlyOwner {
        if ((msg.sender != owner) && (msg.sender != super_owner)) revert();
        _;
    }

     
    modifier onlySuperOwner {
        if (msg.sender != super_owner) revert();
        _;
    }

     
    function isOwner() internal returns(bool success) {
        if ((msg.sender == owner) || (msg.sender == super_owner)) return true;
        return false;
    }

     
    function transferOwnership(address newOwner)  public onlySuperOwner {
        owner = newOwner;
    }
}


contract STeX_WL is owned {
	 
	string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
     
    
    uint256 public ethRaised;
    uint256 public soldSupply;
    uint256 public curPrice;
    uint256 public minBuyPrice;
    uint256 public maxBuyPrice;
    
     
    uint256 public wlStartBlock;
    uint256 public wlStopBlock;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
     
    function STeX_WL() public {        
    	totalSupply = 1000000000000000;  
    	balanceOf[this] = totalSupply;
    	soldSupply = 0;
        decimals = 8;
        
        name = "STeX White List";
        symbol = "STE(WL)";
        
        minBuyPrice = 20500000;  
        maxBuyPrice = 24900000;  
        curPrice = minBuyPrice;
        
        wlStartBlock = 5071809;
        wlStopBlock = wlStartBlock + 287000;
    }
    
     
    function() internal payable {
    	if ( msg.value < 100000000000000000 ) revert();  
    	if ( ( block.number >= wlStopBlock ) || ( block.number < wlStartBlock ) ) revert();    	
    	
    	uint256 add_by_blocks = (((block.number-wlStartBlock)*1000000)/(wlStopBlock-wlStartBlock)*(maxBuyPrice-minBuyPrice))/1000000;
    	uint256 add_by_solded = ((soldSupply*1000000)/totalSupply*(maxBuyPrice-minBuyPrice))/1000000;
    	
    	 
    	if ( add_by_blocks > add_by_solded ) {
    		curPrice = minBuyPrice + add_by_blocks;
    	} else {
    		curPrice = minBuyPrice + add_by_solded;
    	}
    	
    	if ( curPrice > maxBuyPrice ) curPrice = maxBuyPrice;
    	
    	uint256 amount = msg.value / curPrice;
    	
    	if ( balanceOf[this] < amount ) revert();
    	
    	balanceOf[this] -= amount;
        balanceOf[msg.sender] += amount;
        soldSupply += amount;
        ethRaised += msg.value;
    	
        Transfer(0x0, msg.sender, amount);
    }
    
	 
    function transfer(address _to, uint256 _value) public {
    	revert();
    }

	 
    function approve(address _spender, uint256 _value) public returns(bool success) {
        revert();
    }

	 
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
    	revert();
    }
    
     
    function transferFromAdmin(address _from, address _to, uint256 _value) public onlyOwner returns(bool success) {
        if (_to == 0x0) revert();
        if (balanceOf[_from] < _value) revert();
        if ((balanceOf[_to] + _value) < balanceOf[_to]) revert();  

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        Transfer(_from, _to, _value);
        return true;
    }
    
     
    function setPrices(uint256 _minBuyPrice, uint256 _maxBuyPrice) public onlyOwner {
    	minBuyPrice = _minBuyPrice;
    	maxBuyPrice = _maxBuyPrice;
    }
    
     
    function setStartStopBlocks(uint256 _wlStartBlock, uint256 _wlStopBlock) public onlyOwner {
    	wlStartBlock = _wlStartBlock;
    	wlStopBlock = _wlStopBlock;
    }
    
     
    function withdrawToFounders(uint256 amount) public onlyOwner {
    	uint256 amount_to_withdraw = amount * 1000000000000000;  
        if (this.balance < amount_to_withdraw) revert();
        amount_to_withdraw = amount_to_withdraw / foundersAddresses.length;
        uint8 i = 0;
        uint8 errors = 0;
        
        for (i = 0; i < foundersAddresses.length; i++) {
			if (!foundersAddresses[i].send(amount_to_withdraw)) {
				errors++;
			}
		}
    }
    
     
    function afterSTEDistributed() public onlySuperOwner {
    	uint256 amount_to_withdraw = this.balance;
        amount_to_withdraw = amount_to_withdraw / foundersAddresses.length;
        uint8 i = 0;
        uint8 errors = 0;
        
        for (i = 0; i < foundersAddresses.length; i++) {
			if (!foundersAddresses[i].send(amount_to_withdraw)) {
				errors++;
			}
		}
		
    	suicide(foundersAddresses[0]);
    }
}