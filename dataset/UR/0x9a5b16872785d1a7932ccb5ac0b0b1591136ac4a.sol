 

 

pragma solidity 0.5.9;

 

contract DigitalDollarRetainerRegistry {
    
	mapping (uint256 => DDR) public rddr;  

	struct DDR {
        	address client;  
        	address provider;  
        	ERC20 ddrToken;  
        	string deliverable;  
        	string governingLawForum;  
        	uint256 ddrNumber;  
        	uint256 timeStamp;  
        	uint256 retainerDuration;  
        	uint256 retainerTermination;  
        	uint256 deliverableRate;  
        	uint256 paid;  
        	uint256 payCap;  
    	}

	 
	string public ddrTerms = "|| Establishing a digital retainer hereby as [[ddrNumber]] and acknowledging mutual consideration and agreement, Client, identified by ethereum address 0x[[client]], commits to perform under this digital payment transactional script capped at $[[payCap]] digital dollar value denominated in 0x[[ddrToken]] for benefit of Provider, identified by ethereum address 0x[[provider]], in exchange for prompt satisfaction of the following, [[deliverable]], to Client by Provider upon scripted payments set at the rate of $[[deliverableRate]] per deliverable, with such retainer relationship not to exceed [[retainerDuration]] seconds and to be governed by choice of [[governingLawForum]] law and 'either/or' arbitration rules in [[governingLawForum]]. ||";
	uint256 public RDDR;  

	event Registered(address indexed client, address indexed provider);  
	event Paid(uint256 ratePaid, uint256 totalPaid, address indexed client);  

	function registerDDR(
    	address client,
    	address provider,
    	ERC20 ddrToken,
    	string memory deliverable,
    	string memory governingLawForum,
    	uint256 retainerDuration,
    	uint256 deliverableRate,
    	uint256 payCap) public {
        	require(deliverableRate <= payCap, "constructor: deliverableRate cannot exceed payCap");  
        	uint256 ddrNumber = RDDR + 1;  
        	uint256 paid = 0;  
        	uint256 timeStamp = now;  
        	uint256 retainerTermination = timeStamp + retainerDuration;  
    
        	RDDR = RDDR + 1;  
    
        	rddr[ddrNumber] = DDR(  
                	client,
                	provider,
                	ddrToken,
                	deliverable,
                	governingLawForum,
                	ddrNumber,
                	timeStamp,
                	retainerDuration,
                	retainerTermination,
                	deliverableRate,
                	paid,
                	payCap);
        	 
            	emit Registered(client, provider); 
        	}

	function payDDR(uint256 ddrNumber) public {  
    	DDR storage ddr = rddr[ddrNumber];  
    	require (now <= ddr.retainerTermination);  
    	require(address(msg.sender) == ddr.client);  
    	require(ddr.paid + ddr.deliverableRate <= ddr.payCap, "payDAI: payCap exceeded");  
    	ddr.ddrToken.transferFrom(msg.sender, ddr.provider, ddr.deliverableRate);  
    	ddr.paid = ddr.paid + ddr.deliverableRate;  
        	emit Paid(ddr.deliverableRate, ddr.paid, msg.sender); 
    	}
   	 
	function tipOpenESQ() public payable {  
    	0xBBE222Ef97076b786f661246232E41BE0DFf6cc4.transfer(msg.value);  
    	}
}

 

 
contract ERC20 {
	uint256 public totalSupply;

	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);

	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);
}