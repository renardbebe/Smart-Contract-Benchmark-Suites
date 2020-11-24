 

pragma solidity ^0.5.10;

interface ERC20 {
    function totalSupply()  external returns (uint supply);
    function balanceOf(address _owner) external returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract EmpowCreateEosAccount {
    
    event CreateEosAccountEvent(string _name, string _activePublicKey, string _ownerPublicKey);
    
    struct AccountHistory {
        uint32 payment_type;
        string name;
        string activePublicKey;
        string ownerPublicKey;
        uint256 amount;
    }
    
    mapping (address => uint256) public countAccount;
    mapping (address => mapping (uint256 => AccountHistory)) public accountHistories;
    
    ERC20 USDT_CONTRACT = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    uint256 public PRICE = 144000000;
    uint256 public USDT_PRICE = 3000000;
    uint256 public NAME_LENGTH_LIMIT = 12;
    uint256 public PUBLIC_KEY_LENGTH_LIMIT = 53;
    address payable owner;
    
    modifier onlyOwner () {
        require(msg.sender == owner, "owner require");
        _;
    }
    
    constructor ()
        public
    {
        owner = msg.sender;
    }
    
    function createEosAccount(string memory _name, string memory _activePublicKey, string memory _ownerPublicKey)
        public
        payable
        returns (bool)
    {
         
        require(getStringLength(_name) == NAME_LENGTH_LIMIT, "Name must be 12 characters");
         
        require(getStringLength(_activePublicKey) == PUBLIC_KEY_LENGTH_LIMIT, "Active Public Key not correct");
        require(getStringLength(_ownerPublicKey) == PUBLIC_KEY_LENGTH_LIMIT, "Owner Public Key not correct");
         
        require(msg.value >= PRICE, "Amount send is not enough");
        
         
        accountHistories[msg.sender][countAccount[msg.sender]].payment_type = 0;  
        accountHistories[msg.sender][countAccount[msg.sender]].name = _name;
        accountHistories[msg.sender][countAccount[msg.sender]].activePublicKey = _activePublicKey;
        accountHistories[msg.sender][countAccount[msg.sender]].ownerPublicKey = _ownerPublicKey;
        accountHistories[msg.sender][countAccount[msg.sender]].amount = msg.value;
        countAccount[msg.sender]++;
        
         
        emit CreateEosAccountEvent(_name, _activePublicKey, _ownerPublicKey);
        return true;
    }
    
    function createEosAccountWithUSDT(string memory _name, string memory _activePublicKey, string memory _ownerPublicKey)
        public
        returns (bool)
    {
          
        require(getStringLength(_name) == NAME_LENGTH_LIMIT, "Name must be 12 characters");
         
        require(getStringLength(_activePublicKey) == PUBLIC_KEY_LENGTH_LIMIT, "Active Public Key not correct");
        require(getStringLength(_ownerPublicKey) == PUBLIC_KEY_LENGTH_LIMIT, "Owner Public Key not correct");
         
        require(USDT_CONTRACT.transferFrom(msg.sender, address(this), USDT_PRICE));
         
        accountHistories[msg.sender][countAccount[msg.sender]].payment_type = 1;  
        accountHistories[msg.sender][countAccount[msg.sender]].name = _name;
        accountHistories[msg.sender][countAccount[msg.sender]].activePublicKey = _activePublicKey;
        accountHistories[msg.sender][countAccount[msg.sender]].ownerPublicKey = _ownerPublicKey;
        accountHistories[msg.sender][countAccount[msg.sender]].amount = USDT_PRICE;
        countAccount[msg.sender]++;
        
         
        emit CreateEosAccountEvent(_name, _activePublicKey, _ownerPublicKey);
        return true;
    }
    
     
    
    function updateUSDTAddress (ERC20 _address) 
        public
        onlyOwner
        returns (bool)
    {
        USDT_CONTRACT = _address;
        return true;
    }
    
    function setPrice (uint256 _price, uint256 _usdtPrice)
        public
        onlyOwner
        returns (bool)
    {
        PRICE = _price;
        USDT_PRICE = _usdtPrice;
        return true;
    }
    
    function ownerWithdraw (uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        owner.transfer(_amount);
        return true;
    }

    function ownerWithdrawUSDT ()
        public
        onlyOwner
        returns(bool)
    {
        USDT_CONTRACT.transfer(owner, USDT_CONTRACT.balanceOf(address(this)));
        return true;
    }
    
     
    function getStringLength (string memory _string)
        private
        pure
        returns (uint256)
    {
        bytes memory stringBytes = bytes(_string);
        return stringBytes.length;
    }
}