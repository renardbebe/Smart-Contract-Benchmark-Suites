 

 
contract Token {
	function balanceOf(address user) constant returns (uint256 balance);
	function transfer(address receiver, uint amount) returns(bool);
}

 
 
 
 
contract AltCrowdfunding {
	
	Crowdfunding mainCf ;                                        
	
	function AltCrowdfunding(address cf){						 
		mainCf = Crowdfunding(cf);
	}
	
	function(){
		mainCf.giveFor.value(msg.value)(msg.sender);			 
	}
	
}

contract Crowdfunding {

	struct Backer {
		uint weiGiven;										 
		uint ungivenNxc ;                                 	 
	}
	
	struct Sponsor {
	    uint nxcDirected;                                    
	    uint earnedNexium;                                   
	    address sponsorAddress;                              
	    uint sponsorBonus;
	    uint backerBonus;
	}
	
     
	
	Token 	public nexium;                                   
	address public owner;					               	 
	address public beyond;					            	 
	address public bitCrystalEscrow;   						 
	uint 	public startingEtherValue;						 
	uint 	public stepEtherValue;					         
	uint    public collectedEth;                             
	uint 	public nxcSold;                                  
	uint 	public perStageNxc;                              
	uint 	public nxcPerBcy;                         		 
    uint 	public collectedBcy;                             
	uint 	public minInvest;				            	 
	uint 	public startDate;    							 
	uint 	public endDate;									 
	bool 	public isLimitReached;                           
	
	address[] public backerList;							 
	address[] public altList;					     		 
	mapping(address => Sponsor) public sponsorList;	         
	mapping(address => Backer) public backers;            	 

	modifier onlyBy(address a){
		if (msg.sender != a) throw;                          
		_
	}
	
	event Gave(address);									 
	
 
	
	function Crowdfunding() {
		
		 
		
		nexium = Token(0x45e42d659d9f9466cd5df622506033145a9b89bc); 	 
		beyond = 0x89E7a245d5267ECd5Bf4cA4C1d9D4D5A14bbd130 ;
		owner = msg.sender;
		minInvest = 10 finney;
		startingEtherValue = 700*1000;
		stepEtherValue = 25*1000;
		nxcPerBcy = 14;
		perStageNxc = 5000000 * 1000;
		startDate = 1478012400 ;
		endDate = 1480604400 ;
		bitCrystalEscrow = 0x72037bf2a3fc312cde40c7f7cd7d2cef3ad8c193;
	} 

 
	
	 
	function giveFor(address beneficiary){
		if (msg.value < minInvest) throw;                                       
		if (endDate < now || (now < startDate && now > startDate - 3 hours )) throw;         
		
		 
		uint currentEtherValue = getCurrEthValue();
		
		 
		 
		if(now < startDate) currentEtherValue /= 10;
		
		 
		uint givenNxc = (msg.value * currentEtherValue)/(1 ether);
		nxcSold += givenNxc;                                                    
		if (nxcSold >= perStageNxc) isLimitReached = true ; 
		
		Sponsor sp = sponsorList[msg.sender];
		
		 
		if (sp.sponsorAddress != 0x0000000000000000000000000000000000000000) {
		    sp.nxcDirected += givenNxc;                                         
		    
		     
		    uint bonusRate = sp.nxcDirected / 80000000;
		    if (bonusRate > sp.sponsorBonus) bonusRate = sp.sponsorBonus;
		    
		     
		    uint sponsorNxc = (sp.nxcDirected * bonusRate)/100 - sp.earnedNexium;
			if (!giveNxc(sp.sponsorAddress, sponsorNxc))throw;
			
			
			sp.earnedNexium += sponsorNxc;                                      
			givenNxc = (givenNxc*(100 + sp.backerBonus))/100;                   
		}
		
		if (!giveNxc(beneficiary, givenNxc))throw;                              
		
		 
		Backer backer = backers[beneficiary];
		if (backer.weiGiven == 0){
			backerList[backerList.length++] = beneficiary;
		}
		backer.weiGiven += msg.value;                                           
		collectedEth += msg.value;                                              
		Gave(beneficiary);                                                      
	}
	
	
	 
	 
	 
	function claimNxc(){
	    if (!isLimitReached) throw;
	    address to = msg.sender;
	    nexium.transfer(to, backers[to].ungivenNxc);
	    backers[to].ungivenNxc = 0;
	}
	
	 
	 
	function getBackEther(){
	    getBackEtherFor(msg.sender);
	}
	
	function getBackEtherFor(address account){
	    if (now > endDate && !isLimitReached){
	        uint sentBack = backers[account].weiGiven;
	        backers[account].weiGiven = 0;                                      
	        if(!account.send(sentBack))throw;
	    } else throw ;
	}
	
	 
	function(){
		giveFor(msg.sender);
	}
	
 

     
	function addAlt(address sponsor, uint _sponsorBonus, uint _backerBonus)
	onlyBy(owner){
	    if (_sponsorBonus > 10 || _backerBonus > 10 || _sponsorBonus + _backerBonus > 15) throw;
		altList[altList.length++] = address(new AltCrowdfunding(this));
		sponsorList[altList[altList.length -1]] = Sponsor(0, 0, sponsor, _sponsorBonus, _backerBonus);
	}
	
	 
    function setBCY(uint newValue)
    onlyBy(bitCrystalEscrow){
        if (now < startDate || now > endDate) throw;
        if (newValue != 0 && newValue < 714285714) collectedBcy = newValue;  
        else throw;
    }
    
     
    function withdrawEther(address to, uint amount)
    onlyBy(owner){
        if (!isLimitReached) throw;
        var r = to.send(amount);
    }
    
    function withdrawNxc(address to, uint amount)
    onlyBy(owner){
        nexium.transfer(to, amount);
    }
    
     
     
    function blackBox(){
        if (now < endDate + 100 days)throw;
        nexium.transfer(beyond, nexium.balanceOf(this));
        var r = beyond.send(this.balance);
    }
	
	 
	 
	function giveNxc(address to, uint amount) internal returns (bool){
	    bool res;
	    if (isLimitReached){
	        if (nexium.transfer(to, amount)){
	             
	            if (backers[to].ungivenNxc != 0){
	                 res = nexium.transfer(to, backers[to].ungivenNxc); 
	                 backers[to].ungivenNxc = 0;
	            } else {
	                res = true;
	            }
	        } else {
	            res = false;
	        }
		 
		 
	    } else {
	        backers[to].ungivenNxc += amount;
	        res = true;
	    }
	    return res;
	}
	
	 
	
	function getCurrEthValue() returns(uint){
	    return  startingEtherValue - stepEtherValue * ((nxcSold + collectedBcy * nxcPerBcy)/perStageNxc);
	}
	
}