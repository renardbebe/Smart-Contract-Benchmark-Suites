 

pragma solidity ^0.4.24;

contract pyramidMKII {
    address owner;
	
	struct blockinfo {
        uint256 outstanding;                                                     
        uint256 dividend;                                                      	 
		uint256 value;															 
		uint256 index;                                                           
	}
	struct debtinfo {
		uint256 idx;															 
		uint256 pending;														 
		uint256 initial;														 
	}
    struct account {
        uint256 ebalance;                                                        
		mapping(uint256=>debtinfo) owed;										 
    }
	
	uint256 public blksze;														 
	uint256 public surplus;
	uint256 public IDX;														     
	mapping(uint256=>blockinfo) public blockData;								 
	mapping(address=>account) public balances;
	
	bytes32 public consul_nme;
	uint256 public consul_price;
	address public consul;
	address patrician;
	
    string public standard = 'PYRAMIDMKII';
    string public name = 'PYRAMIDMKII';
    string public symbol = 'PM2';
    uint8 public decimals = 0 ;
	
	constructor() public {                                                     
        owner = msg.sender;  
        blksze = 1 ether; 
        consul= owner;                                                           
        patrician = owner;                                                       
	}
	
	function addSurplus() public payable { surplus += msg.value; }               
	
	function callSurplus() public {                                              
	    require(surplus >= blksze, "not enough surplus");                        
	    blockData[IDX].value += blksze;                                          
	    surplus -= blksze;
	    nextBlock();
	}
	    
	function owedAt(uint256 blk) public view returns(uint256, uint256, uint256)
		{ return (	balances[msg.sender].owed[blk].idx, 
					balances[msg.sender].owed[blk].pending, 
					balances[msg.sender].owed[blk].initial); }
	
	function setBlockSze(uint256 _sze) public {
		require(msg.sender == owner && _sze >= 1 ether, "error blksze");
		blksze = _sze;
	}
	
	function withdraw() public {
		require(balances[msg.sender].ebalance > 0, "not enough divs claimed");
        uint256 sval = balances[msg.sender].ebalance;
        balances[msg.sender].ebalance = 0;
        msg.sender.transfer(sval);
        emit event_withdraw(msg.sender, sval);
	}
	
	function chkConsul(address addr, uint256 val, bytes32 usrmsg) internal returns(uint256) {
	    if(val <= consul_price) return val;
	    balances[owner].ebalance += val/4;                                       
	    balances[consul].ebalance += val/4;                                      
	    consul = addr;
	    consul_price = val;
	    consul_nme = usrmsg;
	    balances[addr].owed[IDX].pending += (val/2) + (val/4);                   
	    balances[addr].owed[IDX].initial += (val/2) + (val/4);
	    blockData[IDX].outstanding += (val/2) + (val/4);
	    emit event_consul(val, usrmsg);
	    return val/2;
	}
	
	function nextBlock() internal {
	    if(blockData[IDX].value>= blksze) { 
			surplus += blockData[IDX].value - blksze;
			blockData[IDX].value = blksze;
			if(IDX > 0) 
			    blockData[IDX].outstanding -= 
			        (blockData[IDX-1].outstanding * blockData[IDX-1].dividend)/100 ether;
			blockData[IDX].dividend = 
				(blksze * 100 ether) / blockData[IDX].outstanding;				 
			IDX += 1;															 
			blockData[IDX].index = IDX;                                          
			blockData[IDX].outstanding = blockData[IDX-1].outstanding;			 
			if(IDX % 200 == 0 && IDX != 0) blksze += 1 ether;                    
			emit event_divblk(IDX);
		}
	}
	
	function pyramid(address addr, uint256 val, bytes32 usrmsg) internal {
	    val = chkConsul(addr, val, usrmsg);
		uint256 mval = val - (val/10);                                           
		uint256 tval = val + (val/2);
		balances[owner].ebalance += (val/100);                                   
		balances[consul].ebalance += (val*7)/100 ;                               
		balances[patrician].ebalance+= (val/50);                                 
		patrician = addr;                                                        
		uint256 nsurp = (mval < blksze)? blksze-mval : (surplus < blksze)? surplus : 0;
		nsurp = (surplus >= nsurp)? nsurp : 0;
		mval += nsurp;                                                           
		surplus-= nsurp;                                                        
		blockData[IDX].value += mval;
        blockData[IDX].outstanding += tval;                                      
		balances[addr].owed[IDX].idx = IDX;							             
		balances[addr].owed[IDX].pending += tval;                                
		balances[addr].owed[IDX].initial += tval;
		nextBlock();
		emit event_deposit(val, usrmsg);
	}
	
	function deposit(bytes32 usrmsg) public payable {
		require(msg.value >= 0.001 ether, "not enough ether");
		pyramid(msg.sender, msg.value, usrmsg);
	}
	
	function reinvest(uint256 val, bytes32 usrmsg) public {
		require(val <= balances[msg.sender].ebalance && 
				val > 0.001 ether, "no funds");
		balances[msg.sender].ebalance -= val;
		pyramid(msg.sender, val, usrmsg);
	}	
	
	function mine1000(uint256 blk) public {
		require(balances[msg.sender].owed[blk].idx < IDX && blk < IDX, "current block");
		require(balances[msg.sender].owed[blk].pending > 0.001 ether, "no more divs");
		uint256 cdiv = 0;
		for(uint256 i = 0; i < 1000; i++) {
			cdiv = (balances[msg.sender].owed[blk].pending *
                    blockData[balances[msg.sender].owed[blk].idx].dividend ) / 100 ether;  
			cdiv = (cdiv > balances[msg.sender].owed[blk].pending)?     
						balances[msg.sender].owed[blk].pending : cdiv;           
			balances[msg.sender].owed[blk].idx += 1;                             
			balances[msg.sender].owed[blk].pending -= cdiv;
			balances[msg.sender].ebalance += cdiv;
			if( balances[msg.sender].owed[blk].pending == 0 || 
			    balances[msg.sender].owed[blk].idx >= IDX ) 
				return;
		}
	}

     
    event event_withdraw(address addr, uint256 val);
    event event_deposit(uint256 val, bytes32 umsg);
    event event_consul(uint256 val, bytes32 umsg);
    event event_divblk(uint256 idx);
}