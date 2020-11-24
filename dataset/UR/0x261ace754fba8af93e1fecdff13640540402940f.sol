 

pragma solidity ^0.4.24;

 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
 
 
 
contract Phila_Token is ERC20Interface, Owned {
    string public constant symbol = "φιλα";
    string public constant name = "φιλανθρωπία";
    uint8 public constant decimals = 0;
    uint private constant _totalSupply = 10000000;

    address public vaultAddress;
    bool public fundingEnabled;
    uint public totalCollected;          
    uint public tokenPrice;          

    mapping(address => uint) balances;

     
     
     
    constructor() public {
        balances[this] = _totalSupply;
        emit Transfer(address(0), this, _totalSupply);
    }

    function setVaultAddress(address _vaultAddress) public onlyOwner {
        vaultAddress = _vaultAddress;
        return;
    }

    function setFundingEnabled(bool _fundingEnabled) public onlyOwner {
        fundingEnabled = _fundingEnabled;
        return;
    }

    function updateTokenPrice(uint _newTokenPrice) public onlyOwner {
        require(_newTokenPrice > 0);
        tokenPrice = _newTokenPrice;
        return;
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint) {
        return balances[tokenOwner];
    }


     
     
     
     
     
     
     
     
     
     
     
    function approve(address, uint) public returns (bool) {
        revert();
        return false;
    }


     
     
     
     
     
     
     
    function allowance(address, address) public constant returns (uint) {
        return 0;
    }


     
     
     
     
     
     
     
    function transfer(address _to, uint _amount) public returns (bool) {
       if (_amount == 0) {
           emit Transfer(msg.sender, _to, _amount);     
           return true;
       }
        revert();
        return false;
    }


     
     
     
     
     
     
    function transferFrom(address, address, uint) public returns (bool) {
        revert();
        return false;
    }


    function () public payable {
        require (fundingEnabled && (tokenPrice > 0) && (msg.value >= tokenPrice));
        
        totalCollected += msg.value;

         
        vaultAddress.transfer(msg.value);

        uint tokens = msg.value / tokenPrice;

            
           require((msg.sender != 0) && (msg.sender != address(this)));

            
            
           uint previousBalanceFrom = balances[this];

           require(previousBalanceFrom >= tokens);

            
            
           balances[this] = previousBalanceFrom - tokens;

            
            
           uint previousBalanceTo = balances[msg.sender];
           require(previousBalanceTo + tokens >= previousBalanceTo);  
           balances[msg.sender] = previousBalanceTo + tokens;

            
           emit Transfer(this, msg.sender, tokens);

        return;
    }


     
     
     
     
     
     
     
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(this));
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20Interface token = ERC20Interface(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }
    
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}