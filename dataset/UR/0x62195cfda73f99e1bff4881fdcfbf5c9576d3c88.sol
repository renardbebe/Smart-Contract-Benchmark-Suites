 

 

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

 
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

     
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

 
contract lexDAOregistry is ScribeRole, ERC20 {  
    using SafeMath for uint256;
    
     
    address payable public lexDAO;
	
     
    address public lexContractAddress = address(this);
    ERC20 lexContract = ERC20(lexContractAddress); 
    
    string public name = "lexDAO";
    string public symbol = "LEX";
    uint8 public decimals = 18;
	
     
    uint256 public LSW = 1;  
    uint256 public RDC;  
    uint256 public RDDR;  
	
     
    mapping(address => uint256) public reputation;  
    mapping(address => uint256) public lastActionTimestamp;  
    mapping(address => uint256) public lastSuperActionTimestamp;  
    
     
    mapping (uint256 => lexScriptWrapper) public lexScript;  
    mapping (uint256 => DC) public rdc;  
    mapping (uint256 => DDR) public rddr;  
	
    struct lexScriptWrapper {  
        address lexScribe;  
        address lexAddress;  
        string templateTerms;  
        uint256 lexID;  
        uint256 lexVersion;  
        uint256 lexRate;  
    }
        
    struct DC {  
        address signatory;  
        string templateTerms;  
        string signatureDetails;  
        uint256 lexID;  
        uint256 dcNumber;  
        uint256 timeStamp;  
        bool revoked;  
    }
    	
    struct DDR {  
        address client;  
        address provider;  
        ERC20 ddrToken;  
        string deliverable;  
        string governingLawForum;  
        uint256 lexID;  
        uint256 ddrNumber;  
        uint256 timeStamp;  
        uint256 retainerTermination;  
        uint256 deliverableRate;  
        uint256 paid;  
        uint256 payCap;  
        bool disputed;  
    }
    	
    constructor(string memory tldrTerms, uint256 tldrLexRate, address tldrLexAddress, address payable tldrLexDAO) public {  
	    address lexScribe = msg.sender;  
	    reputation[msg.sender] = 3;  
	    lexDAO = tldrLexDAO;  
	    uint256 lexID = 1;  
	    uint256 lexVersion = 0;  
	    
	        lexScript[lexID] = lexScriptWrapper(  
                lexScribe,
                tldrLexAddress,
                tldrTerms,
                lexID,
                lexVersion,
                tldrLexRate);
    }
        
     
    event Enscribed(uint256 indexed lexID, uint256 indexed lexVersion, address indexed lexScribe);  
    event Signed(uint256 indexed lexID, uint256 indexed dcNumber, address indexed signatory);  
    event Registered(uint256 indexed ddrNumber, uint256 indexed lexID);  
    event Paid(uint256 indexed ddrNumber, uint256 indexed lexID);  
    
        
     
    modifier cooldown() {
        require(now.sub(lastActionTimestamp[msg.sender]) > 1 days);  
        _;
        
	    lastActionTimestamp[msg.sender] = now;  
    }
        
     
    modifier icedown() {
        require(now.sub(lastSuperActionTimestamp[msg.sender]) > 90 days);  
        _;
        
	    lastSuperActionTimestamp[msg.sender] = now;  
    }
    
     
    function addScribe(address account) public {
        require(msg.sender == lexDAO);
        _addScribe(account);
	    reputation[account] = 1;
    }
    
     
    function removeScribe(address account) public {
        require(msg.sender == lexDAO);
        _removeScribe(account);
	    reputation[account] = 0;
    }
    
     
    function updateLexDAO(address payable newLexDAO) public {
    	require(msg.sender == lexDAO);
        require(newLexDAO != address(0));  
        
	    lexDAO = newLexDAO;  
    }
        
     
    function stakeETHreputation() payable public onlyScribe icedown {
        require(msg.value == 0.1 ether);  
        
	    reputation[msg.sender] = 3;  
        
	    address(lexDAO).transfer(msg.value);  
    }
    
     
    function stakeLEXreputation() public onlyScribe icedown { 
	    _burn(_msgSender(), 10000000000000000000);  
        
	    reputation[msg.sender] = 3;  
    }
         
     
    function isReputable(address x) public view returns (bool) {  
        return reputation[x] > 0;
    }
        
     
    function reduceScribeRep(address reducedLexScribe) cooldown public {
        require(isReputable(msg.sender));  
        require(msg.sender != reducedLexScribe);  
        
	    reputation[reducedLexScribe] = reputation[reducedLexScribe].sub(1);  
    }
        
     
    function repairScribeRep(address repairedLexScribe) cooldown public {
        require(isReputable(msg.sender));  
        require(msg.sender != repairedLexScribe);  
        require(reputation[repairedLexScribe] < 3);  
        require(reputation[repairedLexScribe] > 0);  
        
	    reputation[repairedLexScribe] = reputation[repairedLexScribe].add(1);  
    }
       
     
     
    function writeLexScript(string memory templateTerms, uint256 lexRate, address lexAddress) public {
        require(isReputable(msg.sender));  
	
	    uint256 lexID = LSW.add(1);  
	    uint256 lexVersion = 0;  
	    LSW = LSW.add(1);  
	    
	        lexScript[lexID] = lexScriptWrapper(  
                msg.sender,
                lexAddress,
                templateTerms,
                lexID,
                lexVersion,
                lexRate);
                
        _mint(msg.sender, 1000000000000000000);  
	
        emit Enscribed(lexID, lexVersion, msg.sender); 
    }
	    
     
    function editLexScript(uint256 lexID, string memory templateTerms, address lexAddress) public {
	    lexScriptWrapper storage lS = lexScript[lexID];  
	
	    require(address(msg.sender) == lS.lexScribe);  
	
	    uint256 lexVersion = lS.lexVersion.add(1);  
	    
	        lexScript[lexID] = lexScriptWrapper(  
                msg.sender,
                lexAddress,
                templateTerms,
                lexID,
                lexVersion,
                lS.lexRate);
                	
        emit Enscribed(lexID, lexVersion, msg.sender);
    }

     
     
    function signDC(uint256 lexID, string memory signatureDetails) public {  
	    lexScriptWrapper storage lS = lexScript[lexID];  
	
	    uint256 dcNumber = RDC.add(1);  
	    bool revoked = false;  
	    RDC = RDC.add(1);  
	        
	        rdc[dcNumber] = DC(  
                msg.sender,
                lS.templateTerms,
                signatureDetails,
                lexID,
                dcNumber,
                now,
                revoked);
                	
        emit Signed(lexID, dcNumber, msg.sender);
    }
    	
     
    function revokeDC(uint256 dcNumber) public {  
	    DC storage dc = rdc[dcNumber];  
	
	    require(address(msg.sender) == dc.signatory);  
	    
	        rdc[dcNumber] = DC( 
                msg.sender,
                "Signature Revoked",  
                dc.signatureDetails,
                dc.lexID,
                dc.dcNumber,
                now,
                true);
                	
        emit Signed(dc.lexID, dcNumber, msg.sender);
    }
    
     
    function registerDDR(  
    	address client,
    	address provider,
    	ERC20 ddrToken,
    	string memory deliverable,
    	string memory governingLawForum,
        uint256 retainerDuration,
    	uint256 deliverableRate,
    	uint256 payCap,
    	uint256 lexID) public {
    	require(lexID != (0));  
        require(deliverableRate <= payCap);  
	    require(msg.sender == provider);  
        
	    uint256 ddrNumber = RDDR.add(1);  
        uint256 retainerTermination = now.add(retainerDuration);  
        
	    ddrToken.transferFrom(client, address(this), payCap);  
        
	    RDDR = RDDR.add(1);  
    
            rddr[ddrNumber] = DDR(  
                client,
                provider,
                ddrToken,
                deliverable,
                governingLawForum,
                lexID,
                ddrNumber,
                now,  
                retainerTermination,
                deliverableRate,
                0,
                payCap,
                false);
        	 
        emit Registered(lexID, ddrNumber); 
    }
         
     
    function delegateDDRclient(uint256 ddrNumber, address clientDelegate) public {
        DDR storage ddr = rddr[ddrNumber];  
        
        require(ddr.disputed == false);  
        require (now <= ddr.retainerTermination);  
        require(msg.sender == ddr.client);  
        require(ddr.paid < ddr.payCap);  
        
        ddr.client = clientDelegate;  
    }
    
     
    function disputeDDR(uint256 ddrNumber) public {
        DDR storage ddr = rddr[ddrNumber];  
        
	    require(ddr.disputed == false);  
        require (now <= ddr.retainerTermination);  
        require(msg.sender == ddr.client || msg.sender == ddr.provider);  
	    require(ddr.paid < ddr.payCap);  
        
	    ddr.disputed = true;  
    }
    
     
    function resolveDDR(uint256 ddrNumber, uint256 clientAward, uint256 providerAward) public {
        DDR storage ddr = rddr[ddrNumber];  
	
	    uint256 ddRemainder = ddr.payCap.sub(ddr.paid);  
	
	    require(clientAward.add(providerAward) == ddRemainder);  
        require(msg.sender != ddr.client);  
        require(msg.sender != ddr.provider);  
        require(isReputable(msg.sender));  
	    require(balanceOf(msg.sender) >= 5000000000000000000);  
	
        uint256 resolutionFee = ddRemainder.div(20);  
	    uint256 resolutionFeeSplit = resolutionFee.div(2);  
	
        ddr.ddrToken.transfer(ddr.client, clientAward.sub(resolutionFeeSplit));  
        ddr.ddrToken.transfer(ddr.provider, providerAward.sub(resolutionFeeSplit));  
    	ddr.ddrToken.transfer(msg.sender, resolutionFee);  
    	
    	_mint(msg.sender, 1000000000000000000);  
	
	    ddr.paid = ddr.paid.add(ddRemainder);  
    }
    
     
    function payDDR(uint256 ddrNumber) public {  
    	DDR storage ddr = rddr[ddrNumber];  
    	lexScriptWrapper storage lS = lexScript[ddr.lexID];  
	
	    require(ddr.disputed == false);  
    	require(now <= ddr.retainerTermination);  
    	require(address(msg.sender) == ddr.client);  
    	require(ddr.paid.add(ddr.deliverableRate) <= ddr.payCap);  
	
    	uint256 lexFee = ddr.deliverableRate.div(lS.lexRate);  
	
    	ddr.ddrToken.transfer(ddr.provider, ddr.deliverableRate.sub(lexFee));  
    	ddr.ddrToken.transfer(lS.lexAddress, lexFee);  
    	ddr.paid = ddr.paid.add(ddr.deliverableRate);  
        
	    emit Paid(ddr.ddrNumber, ddr.lexID); 
    }
    
     
    function withdrawDDR(uint256 ddrNumber) public {  
    	DDR storage ddr = rddr[ddrNumber];  
	
    	require(now >= ddr.retainerTermination);  
    	require(address(msg.sender) == ddr.client);  
    	
    	uint256 remainder = ddr.payCap.sub(ddr.paid);  
    	
    	require(remainder > 0);  
	
    	ddr.ddrToken.transfer(ddr.client, remainder);  
    	
    	ddr.paid = ddr.paid.add(remainder);  
    }
}