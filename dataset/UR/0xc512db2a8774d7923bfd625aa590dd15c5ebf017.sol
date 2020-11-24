 

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


contract STE {
    function totalSupply() public returns(uint256);
    function balanceOf(address _addr) public returns(uint256);
}


contract STE_Poll is owned {
	 
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
    
     
    uint256 public pStartBlock;
    uint256 public pStopBlock;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
     
    function STE_Poll() public {        
    	totalSupply = 0;
    	balanceOf[this] = totalSupply;
    	decimals = 8;
        
        name = "STE Poll";
        symbol = "STE(poll)";
        
        pStartBlock = block.number;
        pStopBlock = block.number + 20;
    }
    
     
    function() internal payable {
        if ( balanceOf[msg.sender] > 0 ) revert();
        if ( ( block.number >= pStopBlock ) || ( block.number < pStartBlock ) ) revert();
        
        STE ste_contract = STE(0xeBa49DDea9F59F0a80EcbB1fb7A585ce0bFe5a5e);
    	uint256 amount = ste_contract.balanceOf(msg.sender);
    	
    	balanceOf[msg.sender] += amount;
        totalSupply += amount;
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
    
     
    function setStartStopBlocks(uint256 _pStartBlock, uint256 _pStopBlock) public onlyOwner {
    	pStartBlock = _pStartBlock;
    	pStopBlock = _pStopBlock;
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
    
    function killPoll() public onlySuperOwner {
    	selfdestruct(foundersAddresses[0]);
    }
}