 

pragma solidity ^0.4.16;


 
 
 
contract WhiteListAccess {
    
    function WhiteListAccess() public {
        owner = msg.sender;
        whitelist[owner] = true;
        whitelist[address(this)] = true;
    }
    
    address public owner;
    mapping (address => bool) whitelist;

    modifier onlyOwner {require(msg.sender == owner); _;}
    modifier onlyWhitelisted {require(whitelist[msg.sender]); _;}

    function addToWhiteList(address trusted) public onlyOwner() {
        whitelist[trusted] = true;
    }

    function removeFromWhiteList(address untrusted) public onlyOwner() {
        whitelist[untrusted] = false;
    }

}
 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
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


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}



 
 
 
contract CNT_Common is WhiteListAccess {
    string  public name;
    
    function CNT_Common() public {  }

     
    address public SALE_address;    
}


 
 
 
 
contract Token is ERC20Interface, CNT_Common {
    using SafeMath for uint;

    bool    public   freezed;
    bool    public   initialized;
    uint8   public   decimals;
    uint    public   totSupply;
    string  public   symbol;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

    address public ICO_PRE_SALE = address(0x1);
    address public ICO_TEAM = address(0x2);
    address public ICO_PROMO_REWARDS = address(0x3);
    address public ICO_EOS_AIRDROP = address(0x4);

     
     
     
    
    function Token(uint8 _decimals, uint _thousands, string _name, string _sym) public {
        owner = msg.sender;
        symbol = _sym;
        name = _name;
        decimals = _decimals;
        totSupply = _thousands * 10**3 * 10**uint(decimals);
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return totSupply;
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        require(!freezed);
        require(initialized);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function desapprove(address spender) public returns (bool success) {
        allowed[msg.sender][spender] = 0;
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(!freezed);
        require(initialized);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


     
     
     
    function () public payable {
        revert();
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }


     
     
    function init(address _sale) public {
        require(!initialized);
         
        SALE_address = _sale;
        whitelist[SALE_address] = true;
        initialized = true;
        freezed = true;
    }

    function ico_distribution(address to, uint tokens) public onlyWhitelisted() {
        require(initialized);
        balances[ICO_PRE_SALE] = balances[ICO_PRE_SALE].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(ICO_PRE_SALE, to, tokens);
    }

    function ico_promo_reward(address to, uint tokens) public onlyWhitelisted() {
        require(initialized);
        balances[ICO_PROMO_REWARDS] = balances[ICO_PROMO_REWARDS].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(ICO_PROMO_REWARDS, to, tokens);
    }

    function balanceOfMine() constant public returns (uint) {
        return balances[msg.sender];
    }

    function rename(string _name) public onlyOwner() {
        name = _name;
    }    

    function unfreeze() public onlyOwner() {
        freezed = false;
    }

    function refreeze() public onlyOwner() {
        freezed = true;
    }
    
}

contract CNT_Token is Token(18, 500000, "Chip", "CNT") {
    function CNT_Token() public {
        uint _millons = 10**6 * 10**18;
        balances[ICO_PRE_SALE]       = 300 * _millons;  
        balances[ICO_TEAM]           =  90 * _millons;  
        balances[ICO_PROMO_REWARDS]  =  10 * _millons;  
        balances[ICO_EOS_AIRDROP]    = 100 * _millons;  
        balances[address(this)]      = 0;
        Transfer(address(this), ICO_PRE_SALE, balances[ICO_PRE_SALE]);
        Transfer(address(this), ICO_TEAM, balances[ICO_TEAM]);
        Transfer(address(this), ICO_PROMO_REWARDS, balances[ICO_PROMO_REWARDS]);
        Transfer(address(this), ICO_EOS_AIRDROP, balances[ICO_EOS_AIRDROP]);
    }
}

contract BGB_Token is Token(18, 500000, "BG-Coin", "BGB") {
    function BGB_Token() public {
        uint _millons = 10**6 * 10**18;
        balances[ICO_PRE_SALE]      = 250 * _millons;  
        balances[ICO_TEAM]          = 200 * _millons;  
        balances[ICO_PROMO_REWARDS] =  50 * _millons;  
        balances[address(this)] =   0;
        Transfer(address(this), ICO_PRE_SALE, balances[ICO_PRE_SALE]);
        Transfer(address(this), ICO_TEAM, balances[ICO_TEAM]);
        Transfer(address(this), ICO_PROMO_REWARDS, balances[ICO_PROMO_REWARDS]);
    }
}

contract VPE_Token is Token(18, 1000, "Vapaee", "VPE") {
    function VPE_Token() public {
        uint _thousands = 10**3 * 10**18;
        balances[ICO_PRE_SALE]  = 500 * _thousands;  
        balances[ICO_TEAM]      = 500 * _thousands;  
        balances[address(this)] =   0;
        Transfer(address(this), ICO_PRE_SALE, balances[ICO_PRE_SALE]);
        Transfer(address(this), ICO_TEAM, balances[ICO_TEAM]);
    }
}

contract GVPE_Token is Token(18, 100, "Golden Vapaee", "GVPE") {
    function GVPE_Token() public {
        uint _thousands = 10**3 * 10**18;
        balances[ICO_PRE_SALE]  = 100 * _thousands;  
        balances[address(this)] = 0;
        Transfer(address(this), ICO_PRE_SALE, balances[ICO_PRE_SALE]);
    }
}