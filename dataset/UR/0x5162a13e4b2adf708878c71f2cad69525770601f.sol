 

pragma solidity ^0.4.18;

 
 
 
 
 

contract ERC20Interface {
    function totalSupply() public constant returns (uint256 _totalSupply);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract AcuteAngleCoin is ERC20Interface {
    uint256 public constant decimals = 5;

    string public constant symbol = "AAC";
    string public constant name = "AcuteAngleCoin";

    bool public _selling = true; 
    uint256 public _totalSupply = 10 ** 14;  
    uint256 public _originalBuyPrice = 39 * 10**7;  

     
    address public owner;
 
     
    mapping(address => uint256) private balances;
    
     
    mapping(address => mapping (address => uint256)) private allowed;

     
    mapping(address => bool) private approvedInvestorList;
    
     
    mapping(address => uint256) private deposit;
       

     
    uint256 public totalTokenSold = 0;
    
     
    bool public tradable = false;
    
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onSale() {
        require(_selling);
        _;
    }
    
     
    modifier validInvestor() {
        require(approvedInvestorList[msg.sender]);
        _;
    }
    

    
     
    modifier isTradable(){
        require(tradable == true || msg.sender == owner);
        _;
    }

     
    function()
        public
        payable {
        buyAAC();
    }
    
     
    function buyAAC()
        public
        payable
        onSale
        validInvestor {
        uint256 requestedUnits = (msg.value * _originalBuyPrice) / 10**18;
        require(balances[owner] >= requestedUnits);
         
        balances[owner] -= requestedUnits;
        balances[msg.sender] += requestedUnits;
        
         
        deposit[msg.sender] += msg.value;
        
         
        totalTokenSold += requestedUnits;
        
         
        Transfer(owner, msg.sender, requestedUnits);
        owner.transfer(msg.value);
    }

     
    function AAC() 
        public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
        Transfer(0x0, owner, _totalSupply);
    }
    
     
     
    function totalSupply()
        public 
        constant 
        returns (uint256) {
        return _totalSupply;
    }
    
     
    function turnOnSale() onlyOwner 
        public {
        _selling = true;
    }

     
    function turnOffSale() onlyOwner 
        public {
        _selling = false;
    }
    
    function turnOnTradable() 
        public
        onlyOwner{
        tradable = true;
    }
        
     
     
     
    function balanceOf(address _addr) 
        public
        constant 
        returns (uint256) {
        return balances[_addr];
    }
    
     
     
    function isApprovedInvestor(address _addr)
        public
        constant
        returns (bool) {
        return approvedInvestorList[_addr];
    }
    
     
     
     
    function getDeposit(address _addr)
        public
        constant
        returns(uint256){
        return deposit[_addr];
}
    
     
     
    function addInvestorList(address[] newInvestorList)
        onlyOwner
        public {
        for (uint256 i = 0; i < newInvestorList.length; i++){
            approvedInvestorList[newInvestorList[i]] = true;
        }
    }

     
     
    function removeInvestorList(address[] investorList)
        onlyOwner
        public {
        for (uint256 i = 0; i < investorList.length; i++){
            approvedInvestorList[investorList[i]] = false;
        }
    }
 
     
     
     
     
    function transfer(address _to, uint256 _amount)
        public 
        isTradable
        returns (bool) {
         
         
         
        if ( (balances[msg.sender] >= _amount) &&
             (_amount >= 0) && 
             (balances[_to] + _amount > balances[_to]) ) {  

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
    public
    isTradable
    returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
    
     
     
    function approve(address _spender, uint256 _amount) 
        public
        isTradable
        returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    
     
    function allowance(address _owner, address _spender) 
        public
        constant 
        returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
     
     
    function withdraw() onlyOwner 
        public 
        returns (bool) {
        return owner.send(this.balance);
    }
}