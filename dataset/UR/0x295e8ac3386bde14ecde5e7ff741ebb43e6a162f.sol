 

 

pragma solidity 0.5.9;

 

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

contract ScribeRole is Context {
    using Roles for Roles.Role;

    event ScribeAdded(address indexed account);
    event ScribeRemoved(address indexed account);

    Roles.Role private _Scribes;

    constructor () internal {
        _addScribe(_msgSender());
    }

    modifier onlyScribe() {
        require(isScribe(_msgSender()), "ScribeRole: caller does not have the Scribe role");
        _;
    }

    function isScribe(address account) public view returns (bool) {
        return _Scribes.has(account);
    }

    function addScribe(address account) public onlyScribe {
        _addScribe(account);
    }

    function renounceScribe() public {
        _removeScribe(_msgSender());
    }

    function _addScribe(address account) internal {
        _Scribes.add(account);
        emit ScribeAdded(account);
    }

    function _removeScribe(address account) internal {
        _Scribes.remove(account);
        emit ScribeRemoved(account);
    }
}

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

contract lexDAORegistry is ScribeRole {  
    using SafeMath for uint256;
    
     
	address payable public lexAgonDAO = 0xBBE222Ef97076b786f661246232E41BE0DFf6cc4;
	
	 
	uint256 public LSW = 1;  
	uint256 public RDDR;  
	
	 
	uint256 private lexRate;  
	address private lexAddress;  
    
    mapping(address => uint256) public reputation;  
    mapping(address => uint256) public lastActionTimestamp;  
    
    mapping (uint256 => lexScriptWrapper) public lexScript;  
	mapping (uint256 => DDR) public rddr;  
	
    struct lexScriptWrapper {  
            address lexScribe;  
            address lexAddress;  
            string templateTerms;  
            uint256 lexID;  
            uint256 lexRate;  
        } 

	struct DDR {  
        	address client;  
        	address provider;  
        	IERC20 ddrToken;  
        	string deliverable;  
        	string governingLawForum;  
        	uint256 ddrNumber;  
        	uint256 timeStamp;  
        	uint256 retainerDuration;  
        	uint256 retainerTermination;  
        	uint256 deliverableRate;  
        	uint256 paid;  
        	uint256 payCap;  
        	uint256 lexID;  
    	}

	constructor() public {  
	        address LEXScribe = msg.sender;  
	         
	        string memory ddrTerms = "|| Establishing a digital retainer hereby as [[ddrNumber]] and acknowledging mutual consideration and agreement, Client, identified by ethereum address 0x[[client]], commits to perform under this digital payment transactional script capped at $[[payCap]] digital dollar value denominated in 0x[[ddrToken]] for benefit of Provider, identified by ethereum address 0x[[provider]], in exchange for prompt satisfaction of the following, [[deliverable]], to Client by Provider upon scripted payments set at the rate of $[[deliverableRate]] per deliverable, with such retainer relationship not to exceed [[retainerDuration]] seconds and to be governed by choice of [[governingLawForum]] law and 'either/or' arbitration rules in [[governingLawForum]]. ||";
	        uint256 lexID = 0;  
	        uint256 LEXRate = 100;  
	        address LEXAddress = 0xBBE222Ef97076b786f661246232E41BE0DFf6cc4;  
	        lexScript[lexID] = lexScriptWrapper(  
                	LEXScribe,
                	LEXAddress,
                	ddrTerms,
                	lexID,
                	LEXRate);
        }

     
    event Enscribed(uint256 indexed lexID, address indexed lexScribe);  
	event Registered(uint256 indexed ddrNumber, uint256 indexed lexID, address client, address provider);  
	event Paid(uint256 indexed ddrNumber, uint256 indexed lexID, uint256 ratePaid, uint256 totalPaid, address client);  

     
     
    function stakeReputation() payable public onlyScribe {
            require(msg.value == 0.1 ether);
            reputation[msg.sender] = 10;
            address(lexAgonDAO).transfer(msg.value);
        }
     
    function isReputable(address x) public view returns (bool) {
            return reputation[x] > 0;
        }
     
    modifier cooldown() {
            require(now.sub(lastActionTimestamp[msg.sender]) > 1 days);
            _;
            lastActionTimestamp[msg.sender] = now;
        }
     
    function reduceScribeRep(address reducedLexScribe) cooldown public {
            require(isReputable(msg.sender));
            reputation[reducedLexScribe] = reputation[reducedLexScribe].sub(1); 
        }
     
    function repairScribeRep(address repairedLexScribe) cooldown public {
            require(isReputable(msg.sender));
            require(reputation[repairedLexScribe] < 10);
            reputation[repairedLexScribe] = reputation[repairedLexScribe].add(1); 
            lastActionTimestamp[msg.sender] = now;
        }

     
     
	function writeLEXScriptWrapper(string memory templateTerms, uint256 LEXRate, address LEXAddress) public onlyScribe {
	        require(isReputable(msg.sender));
	        address lexScribe = msg.sender;
	        uint256 lexID = LSW.add(1);  
	        LSW = LSW.add(1);  
	    
	        lexScript[lexID] = lexScriptWrapper(  
                	lexScribe,
                	LEXAddress,
                	templateTerms,
                	lexID,
                	LEXRate);
                	
            emit Enscribed(lexID, lexScribe); 
	    }
	 
	function editLEXScriptWrapper(uint256 lexID, string memory newTemplateTerms, address newLEXAddress) public {
	        lexScriptWrapper storage lS = lexScript[lexID];
	        require(address(msg.sender) == lS.lexScribe);  
	    
	        lexScript[lexID] = lexScriptWrapper(  
                	msg.sender,
                	newLEXAddress,
                	newTemplateTerms,
                	lexID,
                	lS.lexRate);
            emit Enscribed(lexID, msg.sender);
    	}
    	
     
	 
	function registerDDR(
    	    address client,
    	    address provider,
    	    IERC20 ddrToken,
    	    string memory deliverable,
    	    string memory governingLawForum,
    	    uint256 retainerDuration,
    	    uint256 deliverableRate,
    	    uint256 payCap,
    	    uint256 lexID) public {
            require(deliverableRate <= payCap, "registerDDR: deliverableRate cannot exceed payCap");  
            uint256 ddrNumber = RDDR.add(1);  
            uint256 paid = 0;  
            uint256 timeStamp = now;  
            uint256 retainerTermination = timeStamp + retainerDuration;  
    
        	RDDR = RDDR.add(1);  
    
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
                	payCap,
                	lexID);
        	 
            emit Registered(ddrNumber, lexID, client, provider); 
        }

     
	function payDDR(uint256 ddrNumber) public {  
    	    DDR storage ddr = rddr[ddrNumber];  
    	    lexScriptWrapper storage lS = lexScript[ddr.lexID];
    	    require (now <= ddr.retainerTermination);  
    	    require(address(msg.sender) == ddr.client);  
    	    require(ddr.paid.add(ddr.deliverableRate) <= ddr.payCap, "payDAI: payCap exceeded");  
    	    uint256 lexFee = ddr.deliverableRate.div(lS.lexRate);
    	    ddr.ddrToken.transferFrom(msg.sender, ddr.provider, ddr.deliverableRate);  
    	    ddr.ddrToken.transferFrom(msg.sender, lS.lexAddress, lexFee);
    	    ddr.paid = ddr.paid.add(ddr.deliverableRate);  
        	emit Paid(ddr.ddrNumber, ddr.lexID, ddr.deliverableRate, ddr.paid, msg.sender); 
    	}
}