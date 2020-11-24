 

pragma solidity >=0.4.18;

contract Token {

     
    function totalSupply() public constant returns (uint supply) {}

     
     
    function balanceOf(address _owner) public constant returns (uint balance) {}

     
     
     
     
    function transfer(address _to, uint _value) public returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value)  public returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract RegularToken is Token {
    mapping (address => uint256) balances;
     
    mapping (address => uint256) lockedBalances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
     
    function transfer(address _to, uint _value)  public returns (bool) {
         
        if (balances[msg.sender] >= _value  && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner)  public constant returns (uint) {
        return balances[_owner] + lockedBalances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)  public constant returns (uint) {
        return allowed[_owner][_spender];
    }


}


contract A5DToken is RegularToken {
    uint256 private keyprice = 30;  
    uint256 public totalSupply = 1000000000*10**18;
    uint8 constant public decimals = 18;
    string constant public name = "5D Bid Coins";
    string constant public symbol = "5D";
    mapping (address => uint) allowedContract;
    address public owner;
    address public communityWallet;
    
    function A5DToken()  public {
        communityWallet = 0x03706722CA31e7d4Ba29F5cB5887E27710Fa013C;
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        Transfer(address(0), msg.sender, totalSupply);
    }
     
    event SellLockedBalance(address indexed _owner, uint256 _amount);
    event FreeLockedBalance(address indexed _owner, address _to,uint256 _amount);
    event UnlockBalance(address indexed _owner, uint256 _amount);
    event SpendLockedBalance(address indexed _owner,address indexed spender, uint256 _amount);

    uint constant MAX_UINT = 2**256 - 1;
    
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
    modifier onlyAllowedContract {
        require (allowedContract[msg.sender] == 1 || msg.sender == owner);
        _;
    }
    
    
    function transferCommunityWallet(address newCommunityWallet)
        public  
        {
        require (msg.sender == communityWallet);
        communityWallet = newCommunityWallet;
    }
     
     
     
     
     
    
    
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        uint allowance = allowed[_from][msg.sender];
        if (balances[_from] >= _value
            && allowance >= _value
            && balances[_to] + _value >= balances[_to]
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            if (allowance < MAX_UINT) {
                allowed[_from][msg.sender] -= _value;
            }
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function unlockBalance(address _owner, uint256 _value)
        public
        onlyOwner()
        returns (bool)
        {
        uint256 shouldUnlockedBalance = 0;
        shouldUnlockedBalance = _value;
        if(shouldUnlockedBalance > lockedBalances[_owner]){
            shouldUnlockedBalance = lockedBalances[_owner];
        }
        balances[_owner] += shouldUnlockedBalance;
        lockedBalances[_owner] -= shouldUnlockedBalance;
        UnlockBalance(_owner, shouldUnlockedBalance);
        return true;
    }
    
    function withdrawAmount()
        public  
        {
        require (msg.sender == communityWallet);
        communityWallet.transfer(this.balance);
    }
    
    function updateKeyPrice(uint256 updatePrice)
        onlyOwner()
        public  {
        keyprice = updatePrice;
    }
    
    function lockedBalanceOf(address _owner)
        constant
        public
        returns (uint256 balance) {
        return lockedBalances[_owner];
    }
    function UnlockedBalanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }
     
    function freeGameLockedToken(address _to, uint256 _value)
    onlyOwner()
    public
    {
         
        if (balances[msg.sender] >= _value  && lockedBalances[_to] + _value >= lockedBalances[_to]) {
            balances[msg.sender] -= _value;
            lockedBalances[_to] += _value;
            FreeLockedBalance(msg.sender, _to, _value);

        }
    }
    
    function getConsideration(uint256 keyquantity) view public returns(uint256){
        uint256 consideration = keyprice * keyquantity /1000;
        return consideration;
    }
    
    function sellGameLockedToken(uint256 keyquantity)
    public
    payable
    returns (bool) 
    {
        uint256 amount = msg.value;
        uint256 consideration = keyprice * keyquantity /1000;
        require(amount >= consideration);
        uint256 _value = keyquantity;
         
        if (balances[owner] >= _value  && lockedBalances[msg.sender] + _value >= lockedBalances[msg.sender]) {
            balances[owner] -= _value;
            lockedBalances[msg.sender] += _value;
            SellLockedBalance(msg.sender, _value);
            return true;
        } else { return false; }
    }
    
    function approveContractReceiveGameLockedToken(address _from)
    onlyOwner()
    public
    returns (bool)
    {
        allowedContract[_from] = 1;
        return true;
    }
    
    function spendGameLockedToken(address _from, uint256 _value)
    public
    onlyAllowedContract()
    returns (bool) {
        
         
        if (lockedBalances[_from] >= _value  && balances[owner] + _value >= balances[owner]) {
            lockedBalances[_from] -= _value;
            balances[owner] += _value;
            SpendLockedBalance(owner, _from, _value);
            return true;
        } else { return false; }
    }
    
    function jackPotGameLockedToken(address _to, uint256 _value)
    onlyAllowedContract()
    public
    {
         
        if (balances[owner] >= _value  && lockedBalances[_to] + _value >= lockedBalances[_to]) {
            balances[owner] -= _value;
            lockedBalances[_to] += _value;
            }
    }
}