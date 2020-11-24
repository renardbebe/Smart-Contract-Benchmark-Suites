 
contract OZPImplementation is usingOraclize {
     
    using SafeMath for uint256;




     




     
    bool private initialized = false;




     
    mapping(address => uint256) internal balances;
    uint256 internal totalSupply_;
    string public constant name = "OZAPHYRE";  
    string public constant symbol = "OZP";  
    uint8 public constant decimals = 18;  
    uint256 public constant ozpDecimal = 6;
    uint256 public counter = 1;
    
    uint256 public Price_OZP_Euro;
    uint256 public newPrice;
    string public supplyRegulator;
   event LogConstructorInitiated(string nextStep);
   event LogPriceUpdated(string price);
   event LogNewOraclizeQuery(string description);




    




    
    




     
    mapping (address => mapping (address => uint256)) internal allowed;




     
    address public owner;




     
    bool public paused = false;




     
    address public lawEnforcementRole;
    mapping(address => bool) internal frozen;




     
    address public supplyController;




     




     
    event Transfer(address indexed from, address indexed to, uint256 value);




     
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );




     
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );




     
    event Pause();
    event Unpause();




     
    event AddressFrozen(address indexed addr);
    event AddressUnfrozen(address indexed addr);
    event FrozenAddressWiped(address indexed addr);
    event LawEnforcementRoleSet (
        address indexed oldLawEnforcementRole,
        address indexed newLawEnforcementRole
    );




     
    event SupplyIncreased(address indexed to, uint256 value);
    event SupplyDecreased(address indexed from, uint256 value);
    event SupplyControllerSet(
        address indexed oldSupplyController,
        address indexed newSupplyController
    );




     




     




     
    function initialize() public {
        require(!initialized, "already initialized");
        owner = msg.sender;
        lawEnforcementRole = address(0);
        totalSupply_ = 0;
        supplyController = msg.sender;
        initialized = true;
    }




     
    constructor() payable public {
        initialize();
        increaseSupply(1068809780000000000000000000);
        transfer(0xFD68F55C242f54478dFaB29BAE8111401288177E,68809780000000000000000000);
        decreaseSupply(68809780000000000000000000);

         
    }




     
    
    function () external payable {}




   function __callback(bytes32 myid, string result) public {
      if (msg.sender != oraclize_cbAddress()) revert();
          Price_OZP_Euro =1000000/(parseInt(result));
       emit LogPriceUpdated(result);
       updatePrice();
     emit LogNewOraclizeQuery("callback call hua ");

   }


   function updatePrice()  payable public {
           emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
           oraclize_query(1800,"URL", "json(https://api.pro.coinbase.com/products/ETH-EUR/ticker).price");
            emit LogNewOraclizeQuery("orcalize quey executed ");
          
   }
    
    
    
    

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }




     
    function transfer(address _to, uint256 _value)  public whenNotPaused returns (bool) {
        require(_to != address(0), "cannot transfer to address zero");
   	require(!frozen[_to] && !frozen[msg.sender], "address frozen");
        require(_value <= balances[msg.sender], "insufficient funds");




        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }




function sendCoin(address receiver, uint amount) public returns(bool sufficient) {
		if (balances[msg.sender] < amount) return false;
		balances[msg.sender] -= amount;
		balances[receiver] += amount;
		emit Transfer(msg.sender, receiver, amount);
		return true;
	}




     
    function balanceOf(address _addr) public view returns (uint256) {
        return balances[_addr];
    }




     




     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        require(_to != address(0), "cannot transfer to address zero");
        require(!frozen[_to] && !frozen[_from] && !frozen[msg.sender], "address frozen");
        require(_value <= balances[_from], "insufficient funds");
        require(_value <= allowed[_from][msg.sender], "insufficient allowance");




        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }




     
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozen[_spender] && !frozen[msg.sender], "address frozen");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }




     
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }
    








  
    




     




     
    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }




     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "cannot transfer ownership to address zero");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }




     




     
    modifier whenNotPaused() {
        require(!paused, "whenNotPaused");
        _;
    }




     
    function pause() public onlyOwner {
        require(!paused, "already paused");
        paused = true;
        emit Pause();
    }




     
    function unpause() public onlyOwner {
        require(paused, "already unpaused");
        paused = false;
        emit Unpause();
    }




     




     
    function setLawEnforcementRole(address _newLawEnforcementRole) public {
        require(msg.sender == lawEnforcementRole || msg.sender == owner, "only lawEnforcementRole or Owner");
        emit LawEnforcementRoleSet(lawEnforcementRole, _newLawEnforcementRole);
        lawEnforcementRole = _newLawEnforcementRole;
    }




    modifier onlyLawEnforcementRole() {
        require(msg.sender == lawEnforcementRole, "onlyLawEnforcementRole");
        _;
    }




     
    function freeze(address _addr) public onlyLawEnforcementRole {
        require(!frozen[_addr], "address already frozen");
        frozen[_addr] = true;
        emit AddressFrozen(_addr);
    }




     
    function unfreeze(address _addr) public onlyLawEnforcementRole {
        require(frozen[_addr], "address already unfrozen");
        frozen[_addr] = false;
        emit AddressUnfrozen(_addr);
    }




     
    function wipeFrozenAddress(address _addr) public onlyLawEnforcementRole {
        require(frozen[_addr], "address is not frozen");
        uint256 _balance = balances[_addr];
        balances[_addr] = 0;
        totalSupply_ = totalSupply_.sub(_balance);
        emit FrozenAddressWiped(_addr);
        emit SupplyDecreased(_addr, _balance);
        emit Transfer(_addr, address(0), _balance);
    }




     
    function isFrozen(address _addr) public view returns (bool) {
        return frozen[_addr];
    }




     




     
    function setSupplyController(address _newSupplyController) public {
        require(msg.sender == supplyController || msg.sender == owner, "only SupplyController or Owner");
        require(_newSupplyController != address(0), "cannot set supply controller to address zero");
        emit SupplyControllerSet(supplyController, _newSupplyController);
        supplyController = _newSupplyController;
    }




    modifier onlySupplyController() {
        require(msg.sender == supplyController, "onlySupplyController");
        _;
    }




     
    function increaseSupply(uint256 _value) public onlySupplyController returns (bool success) {
        totalSupply_ = totalSupply_.add(_value);
        balances[supplyController] = balances[supplyController].add(_value);
        emit SupplyIncreased(supplyController, _value);
        emit Transfer(address(0), supplyController, _value);
        return true;
    }




     
    function decreaseSupply(uint256 _value)  public onlySupplyController returns (bool success) {
        require(_value <= balances[supplyController], "not enough supply");
        balances[supplyController] = balances[supplyController].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit SupplyDecreased(supplyController, _value);
        emit Transfer(supplyController, address(0), _value);
        return true;
    }
}




