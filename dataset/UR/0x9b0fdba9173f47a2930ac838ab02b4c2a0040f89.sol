 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 


 
 
 
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


 
 
 
 
contract WTToken is ERC20Interface {
    using SafeMath for uint;

    struct UnlockRule {
        uint time;
        uint balance;
    }

    string constant public symbol  = "WTT";
    string constant public name    = "WinTech Token";
    uint8 constant public decimals = 18;
    uint _totalSupply              = 100000000e18;

    address crowdSale              = 0x6F76f25ac0D1fCc611dC605E85e57C5516480BD9;
    address founder                = 0x316461dC8aFBFd31c4a11B7e0f1C7D26b8f8160f;
    address team                   = 0xF204b3934d972DfcA1a5Bf990A9650d71008E28d;
    address platform               = 0x66111e6338A5C06568325F845f4030e673f5aF88;

    uint constant crowdSaleTokens  = 48000000e18;  
    uint constant founderTokens    = 22000000e18;  
    uint constant teamTokens       = 18000000e18;  
    uint constant platformTokens   = 12000000e18;  

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

     
     
     
     
    mapping(uint    => UnlockRule) public unlockRule;


     
     
     
    constructor(uint time1, uint time2, uint time3, uint time4, uint bal1, uint bal2, uint bal3, uint bal4) public {

        unlockRule[1] = UnlockRule(time1, bal1);
        unlockRule[2] = UnlockRule(time2, bal2);
        unlockRule[3] = UnlockRule(time3, bal3);
        unlockRule[4] = UnlockRule(time4, bal4);

        preSale(crowdSale, crowdSaleTokens);
        preSale(founder,   founderTokens);
        preSale(team,      teamTokens);
        preSale(platform,  platformTokens);
    }


    function preSale(address _address, uint _amount) internal returns (bool) {
        balances[_address] = _amount;
        emit Transfer(address(0x0), _address, _amount);
    }


    function transferPermissions(address spender, uint tokens) internal constant returns (bool) {

        if (spender == team) {
            uint bal = balances[team].sub(tokens);
            if (bal < minimumBalance()) {
                return false;
            }
        }

        return true;
    }


    function minimumBalance() public view returns (uint) {
        for (uint i = 1; i <= 4; ++i) {
            if (now < unlockRule[i].time) {
                return unlockRule[i].balance;
            }
        }

        return 0;
    }


     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        require(transferPermissions(msg.sender, tokens), "Lock Rule");
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to]         = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(transferPermissions(from, tokens), "Lock Rule");
        balances[from]            = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to]              = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
    function () public payable {
        revert();
    }
}