 

 

pragma solidity ^0.4.18;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract SaleCallbackInterface {
    function handleSaleCompletionCallback(uint256 _tokens) external payable returns (bool);
    function handleSaleClaimCallback(address _recipient, uint256 _tokens) external returns (bool);  
}

contract Sale is SafeMath {
    
    address public creator;		     
    address public delegate;		 
    
    address public marketplace;	     
    
    uint256 public start;			 
    uint256 public finish;			 
    uint256 public release;			 
    
    uint256 public pricer;			 
    uint256 public size;			 
    
    bool public restricted;		     

    bool public active;			     
    								 
    								 
    								
    
    int8 public progress;			 
    
    uint256 public tokens;			 
    uint256 public value;			 
    
    uint256 public withdrawls;		 
    uint256 public reserves;		 
    
    mapping(address => bool) public participants;			 
    address[] public participantIndex;						 
    
    mapping(address => uint256) public participantTokens;	 
    mapping(address => uint256) public participantValues;	 
    
    mapping(address => bool) public participantRefunds;	     
    mapping(address => bool) public participantClaims;		 
    
    mapping(address => bool) public whitelist;				 
    
    uint256[] public bonuses;								 
    
    bool public mutable;									 
    
    modifier ifCreator { require(msg.sender == creator); _; }		 
    modifier ifDelegate { require(msg.sender == delegate); _; }		 
    modifier ifMutable { require(mutable); _; }						 
    
    event Created();																						 
    event Bought(address indexed _buyer, address indexed _recipient, uint256 _tokens, uint256 _value);		 
    event Claimed(address indexed _recipient, uint256 _tokens);												 
    event Refunded(address indexed _recipient, uint256 _value);												 
    event Reversed(address indexed _recipient, uint256 _tokens, uint256 _value);							 
    event Granted(address indexed _recipient, uint256 _tokens);												 
    event Withdrew(address _recipient, uint256 _value);														 
    event Completed(uint256 _tokens, uint256 _value, uint256 _reserves);									 
    event Certified(uint256 _tokens, uint256 _value);														 
    event Cancelled(uint256 _tokens, uint256 _value);														 
    event Listed(address _participant);																		 
    event Delisted(address _participant);																	 
    event Paused();																							 
    event Activated();    																					 

    function Sale() {
        
        creator = msg.sender;
        delegate = msg.sender;
        
        start = 1;					             
        finish = 1535760000;				     
        release = 1536969600;				     
        
        pricer = 100000;					     
        
        size = 10 ** 18 * pricer * 2000 * 2;	 

        restricted = false;                      
                                                 
    
        bonuses = [1, 20];                       
        
        mutable = true;                          
        active = true;                           
        
        Created();
        Activated();
    }
    
     
    
    function getMyTokenBalance() external constant returns (uint256) {
        return participantTokens[msg.sender];
    }
    
     
     
    
    function buy(address _recipient) public payable {
        
         
        
        require(_recipient != address(0x0));

		 
		
        require(msg.value >= 10 ** 17);

		 
		
        require(active);

		 

        require(progress == 0 || progress == 1);

		 
		
        require(block.timestamp >= start);

		 
		
        require(block.timestamp < finish);
		
		 

        require((! restricted) || whitelist[msg.sender]);
        
         

        require((! restricted) || whitelist[_recipient]);
        
         

        uint256 baseTokens = safeMul(msg.value, pricer);
        
         
        
        uint256 totalTokens = safeAdd(baseTokens, safeDiv(safeMul(baseTokens, getBonusPercentage()), 100));

		 
		
        require(safeAdd(tokens, totalTokens) <= size);
        
         

        if (! participants[_recipient]) {
            participants[_recipient] = true;
            participantIndex.push(_recipient);
        }
        
         

        participantTokens[_recipient] = safeAdd(participantTokens[_recipient], totalTokens);
        participantValues[_recipient] = safeAdd(participantValues[_recipient], msg.value);

		 

        tokens = safeAdd(tokens, totalTokens);
        value = safeAdd(value, msg.value);
        
         

        Bought(msg.sender, _recipient, totalTokens, msg.value);
    }
    
     
    
    function claim() external {
	    
	     
        
        require(progress == 2);
        
         
        
        require(block.timestamp >= release);
        
         
        
        require(participantTokens[msg.sender] > 0);
        
         
        
        require(! participantClaims[msg.sender]);
        
		 

        participantClaims[msg.sender] = true;
        
         
        
        Claimed(msg.sender, participantTokens[msg.sender]);
        
         
        
        SaleCallbackInterface(marketplace).handleSaleClaimCallback(msg.sender, participantTokens[msg.sender]);
    }
    
     
    
    function refund() external {
        
         
        
        require(progress == -1);
        
         
        
        require(participantValues[msg.sender] > 0);
        
         
        
        require(! participantRefunds[msg.sender]);
        
		 
        
        participantRefunds[msg.sender] = true;
        
         
        
        Refunded(msg.sender, participantValues[msg.sender]);
        
         
    
        address(msg.sender).transfer(participantValues[msg.sender]);
    }    
    
     
    
    function withdraw(uint256 _sanity, address _recipient, uint256 _value) ifCreator external {
        
         
        
        require(_sanity == 100010001);
        
         
        
        require(_recipient != address(0x0));
        
         
        
        require(progress == 1 || progress == 2);
        
         
        
        require(this.balance >= _value);
        
         
        
        withdrawls = safeAdd(withdrawls, _value);
        
         
        
        Withdrew(_recipient, _value);
        
         
        
        address(_recipient).transfer(_value);
    } 
    
     
    
    function complete(uint256 _sanity, uint256 _value) ifCreator external {
        
         
        
        require(_sanity == 101010101);
	    
	     
        
        require(progress == 0 || progress == 1);
        
         
        
        require(block.timestamp >= finish);
        
         
        
        require(this.balance >= _value);
        
         
        
        progress = 2;
        
         
        
        reserves = safeAdd(reserves, _value);
        
         
        
        Completed(tokens, value, _value);
        
         
        
        SaleCallbackInterface(marketplace).handleSaleCompletionCallback.value(_value)(tokens);
    }    
    
     
    
    function certify(uint256 _sanity) ifCreator external {
        
         
        
        require(_sanity == 101011111);
	    
	     
	    
        require(progress == 0);
        
         
        
        require(block.timestamp >= start);
        
         
        
        progress = 1;
        
         
        
        Certified(tokens, value);
    }
    
     
    
    function cancel(uint256 _sanity) ifCreator external {
        
         
        
        require(_sanity == 111110101);
	    
	     
	    
        require(progress == 0);
        
         
        
        progress = -1;
        
         
        
        Cancelled(tokens, value);
    }    
    
     
    
    function reverse(address _recipient) ifDelegate external {
        
         
        
        require(_recipient != address(0x0));
        
         
        
        require(progress == 0 || progress == 1);
        
         
        
        require(participantTokens[_recipient] > 0 || participantValues[_recipient] > 0);
        
        uint256 initialParticipantTokens = participantTokens[_recipient];
        uint256 initialParticipantValue = participantValues[_recipient];
        
         
        
        tokens = safeSub(tokens, initialParticipantTokens);
        value = safeSub(value, initialParticipantValue);
        
         
        
        participantTokens[_recipient] = 0;
        participantValues[_recipient] = 0;
        
         
        
        Reversed(_recipient, initialParticipantTokens, initialParticipantValue);
        
         
        
        if (initialParticipantValue > 0) {
            address(_recipient).transfer(initialParticipantValue);
        }
    }
    
     
    
    function grant(address _recipient, uint256 _tokens) ifDelegate external {
        
       	 
       
        require(_recipient != address(0x0));
		
		 
		
        require(progress == 0 || progress == 1);
        
         
        
        if (! participants[_recipient]) {
            participants[_recipient] = true;
            participantIndex.push(_recipient);
        }
        
         
        
        participantTokens[_recipient] = safeAdd(participantTokens[_recipient], _tokens);
        
         
        
        tokens = safeAdd(tokens, _tokens);
        
         
        
        Granted(_recipient, _tokens);
    }    
    
     
    
    function list(address[] _addresses) ifDelegate external {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
            Listed(_addresses[i]);
        }
    }
    
     
    
    function delist(address[] _addresses) ifDelegate external {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
            Delisted(_addresses[i]);
        }
    }  
    
	 
    
    function pause() ifDelegate external {
        active = false;
        Paused();
    }
    
     

    function activate() ifDelegate external {
        active = true;
        Activated();
    }

    function setDelegate(address _delegate) ifCreator external {
        delegate = _delegate;
    }
    
    function setRestricted(bool _restricted) ifDelegate external {
        restricted = _restricted;
    }
    
    function setMarketplace(address _marketplace) ifCreator ifMutable external {
        marketplace = _marketplace;
    }
    
    function setBonuses(uint256[] _bonuses) ifDelegate ifMutable external {
        bonuses = _bonuses;
    }
    
    function setFinish(uint256 _finish) ifDelegate ifMutable external {
        finish = _finish;
    }

    function setRelease(uint256 _release) ifDelegate ifMutable external {
        release = _release;
    }     
    
     
    
    function getBonusPercentage() public constant returns (uint256) {
        
        uint256 finalBonus;
        
        uint256 iterativeTimestamp;
        uint256 iterativeBonus;
        
         
         
         
         
        
        for (uint256 i = 0; i < bonuses.length; i++) {
            if (i % 2 == 0) {
                iterativeTimestamp = bonuses[i];
            } else {
                iterativeBonus = bonuses[i];
                if (block.timestamp >= iterativeTimestamp) {
                    finalBonus = iterativeBonus;
                }
            }
        } 
        
        return finalBonus;
    }    
    
    function() public payable {
        buy(msg.sender);
    }
    
}