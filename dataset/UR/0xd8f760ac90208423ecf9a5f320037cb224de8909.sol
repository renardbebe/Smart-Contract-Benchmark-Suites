 

 
pragma solidity ^0.4.15;

contract NYX {	
     
     
     
     
     
	bytes32 emergencyHash;
	 
    address authority;
     
    address public owner;
     
    bytes32 resqueHash;
     
    bytes32 keywordHash;
     
     
     
     
    bytes32[10] photoHashes;
     
     
     
    uint resqueRequestTime;
     
     
     
    uint authorityRequestTime;
     
	uint lastExpenseTime;
	 
	bool public lastChanceEnabled = false;
	 
	bool lastChanceUseResqueAccountAddress = true;
	 
    event NYXDecentralizedIdentificationRequest(string swarmLinkPhoto, string swarmLinkVideo);
	
     
    enum Stages {
        Normal,  
        ResqueRequested,  
        AuthorityRequested  
    }
     
    Stages stage = Stages.Normal;

     
    function NYX(bytes32 resqueAccountHash, address authorityAccount, bytes32 kwHash, bytes32[10] photoHshs) {
        owner = msg.sender;
        resqueHash = resqueAccountHash;
        authority = authorityAccount;
        keywordHash = kwHash;
         
        uint8 x = 0;
        while(x < photoHshs.length)
        {
            photoHashes[x] = photoHshs[x];
            x++;
        }
    }
     
    modifier onlyByResque()
    {
        require(keccak256(msg.sender) == resqueHash);
        _;
    }
    modifier onlyByAuthority()
    {
        require(msg.sender == authority);
        _;
    }
    modifier onlyByOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyByEmergency(string keywordPhrase) {
        require(keccak256(keywordPhrase, msg.sender) == emergencyHash);
        _;
    }

     
	function toggleLastChance(bool useResqueAccountAddress) onlyByOwner()
	{
	     
	    require(stage == Stages.Normal);
	     
		lastChanceEnabled = !lastChanceEnabled;
		 
		lastChanceUseResqueAccountAddress = useResqueAccountAddress;
	}
	
	 
    function transferByOwner(address recipient, uint amount) onlyByOwner() payable {
         
        require(stage == Stages.Normal);
         
        require(amount <= this.balance);
		 
		require(recipient != address(0x0));
		
        recipient.transfer(amount);
         
		lastExpenseTime = now;
    }

     
    function withdrawByResque() onlyByResque() {
         
        if(stage != Stages.ResqueRequested)
        {
             
            resqueRequestTime = now;
             
            stage = Stages.ResqueRequested;
            return;
        }
         
        else if(now <= resqueRequestTime + 1 days)
        {
            return;
        }
         
        require(stage == Stages.ResqueRequested);
        msg.sender.transfer(this.balance);
    }

     
    function setEmergencyAccount(bytes32 emergencyAccountHash, bytes32 photoHash) onlyByAuthority() {
        require(photoHash != 0x0 && emergencyAccountHash != 0x0);
         
        uint8 x = 0;
        bool authorized = false;
        while(x < photoHashes.length)
        {
            if(photoHashes[x] == keccak256(photoHash))
            {
                 
                authorized = true;
                break;
            }
            x++;
        }
        require(authorized);
         
        authorityRequestTime = now;
         
        stage = Stages.AuthorityRequested;
         
		emergencyHash = emergencyAccountHash;
    }
   
     
	function withdrawByEmergency(string keyword) onlyByEmergency(keyword)
	{
		require(now > authorityRequestTime + 1 days);
		require(keccak256(keyword) == keywordHash);
		require(stage == Stages.AuthorityRequested);
		
		msg.sender.transfer(this.balance);
	}

     
	function lastChance(address recipient, address resqueAccount)
	{
	     
		if(!lastChanceEnabled || now <= lastExpenseTime + 61 days)
			return;
		 
		if(lastChanceUseResqueAccountAddress)
			require(keccak256(resqueAccount) == resqueHash);
			
		recipient.transfer(this.balance);			
	}	
	
     
    function() payable
    {
         
        require(stage == Stages.Normal);
    }
}