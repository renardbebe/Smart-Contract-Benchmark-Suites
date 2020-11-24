 

pragma solidity 0.4.25;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Owned {

    address public owner;  

    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner)
            revert();
        _;  
    }

    function transferOwnership(address _newOwner) public onlyOwner returns (bool success) {
        if (msg.sender != owner)
            revert();
        owner = _newOwner;
        return true;

    }
}

contract CommunityBankCoin is Owned {
    using SafeMath for uint256;

    uint256     public  totalSupply;
    uint8       public  decimals;
    string      public  name;
    string      public  symbol;
    bool        public  tokenIsFrozen;
    bool        public  tokenMintingEnabled;
    bool        public  contractLaunched;
    bool		public	stakingStatus;

    mapping (address => mapping (address => uint256))   public allowance;
    mapping (address => uint256)                        public balances;
    event Transfer(address indexed _sender, address indexed _recipient, uint256 _amount);
    event Approve(address indexed _owner, address indexed _spender, uint256 _amount);
    event LaunchContract(address indexed _launcher, bool _launched);
    event FreezeTransfers(address indexed _invoker, bool _frozen);
    event UnFreezeTransfers(address indexed _invoker, bool _thawed);
    event MintTokens(address indexed _minter, uint256 _amount, bool indexed _minted);
    event TokenMintingDisabled(address indexed _invoker, bool indexed _disabled);
    event TokenMintingEnabled(address indexed _invoker, bool indexed _enabled);


    constructor() public {
        name = "Community Decentralized Banking";
        symbol = "CMD";
        decimals = 6;

        totalSupply = 100000000000000;
        balances[msg.sender] = totalSupply;
        tokenIsFrozen = false;
        tokenMintingEnabled = false;
        contractLaunched = false;
    }



     
    function launchContract() public onlyOwner {
        require(!contractLaunched);
        tokenIsFrozen = false;
        tokenMintingEnabled = true;
        contractLaunched = true;
        emit LaunchContract(msg.sender, true);
    }

    
     
     
     
    function transfer(address _receiver, uint256 _amount)
    public
    returns (bool success)
    {
        require(transferCheck(msg.sender, _receiver, _amount));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        emit Transfer(msg.sender, _receiver, _amount);
        return true;
    }


     
     
    function tokenBurner(uint256 _amount) public
    onlyOwner
    returns (bool burned)
    {
        require(_amount > 0);
        require(totalSupply.sub(_amount) > 0);
        require(balances[msg.sender] > _amount);
        require(balances[msg.sender].sub(_amount) > 0);
        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        emit Transfer(msg.sender, 0, _amount);
        return true;
    }

     
     

    function tokenMinter(uint256 _amount)
    internal
    view
    returns (bool valid)
    {
        require(tokenMintingEnabled);
        require(_amount > 0);
        require(totalSupply.add(_amount) > 0);
        require(totalSupply.add(_amount) > totalSupply);
        return true;
    }


     
     
    function tokenFactory(uint256 _amount) public
    onlyOwner
    returns (bool success)
    {
        require(tokenMinter(_amount));
        totalSupply = totalSupply.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        emit Transfer(0, msg.sender, _amount);
        return true;
    }


     
    function transferCheck(address _sender, address _receiver, uint256 _amount)
    private
    constant
    returns (bool success)
    {
        require(!tokenIsFrozen);
        require(_amount > 0);
        require(_receiver != address(0));
        require(balances[_sender].sub(_amount) >= 0);
        require(balances[_receiver].add(_amount) > 0);
        require(balances[_receiver].add(_amount) > balances[_receiver]);
        return true;
    }


     
    function totalSupply()
    public
    constant
    returns (uint256 _totalSupply)
    {
        return totalSupply;
    }

     
    function balanceOf(address _person)
    public
    constant
    returns (uint256 _balance)
    {
        return balances[_person];
    }

    
     
    function allowance(address _owner, address _spender)
    public
    constant
    returns (uint256 _amount)
    {
        return allowance[_owner][_spender];
    }
    
    function withdrawAll() public onlyOwner {
        uint bal = address(this).balance;
        address(owner).transfer(bal);
    }
    
    uint256 public sellPrice;
    uint256 public buyPrice;

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
    function buy() public payable returns (uint amount) {
        amount = SafeMath.div(msg.value, buyPrice);                     
        balances[msg.sender]=SafeMath.add(balances[msg.sender],amount);
        balances[owner]=SafeMath.sub(balances[owner],amount);
       
        emit Transfer(owner,msg.sender,amount);
        return amount;
    }

    function sell(uint amount) public returns (uint revenue) {
        require(balances[msg.sender] >= amount);          
        balances[owner] = SafeMath.add(balances[owner],amount);                
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], amount);                   
        revenue = SafeMath.mul(amount, sellPrice);
        msg.sender.transfer(revenue);                      
        emit Transfer(msg.sender, owner, amount);  
        return revenue;                                    
    }
    
}