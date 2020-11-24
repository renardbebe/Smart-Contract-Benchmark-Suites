 

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
    event TokensClaimed(address indexed to, uint tokens);
}

contract EthVerifyCore{
    mapping (address => bool) public verifiedUsers;
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

 
 
 
contract VerifyToken is ERC20Interface {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public dailyDistribution;
    uint public timestep;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    mapping(address => uint) public lastClaimed;
    uint public claimedYesterday;
    uint public claimedToday;
    uint public dayStartTime;
    bool public activated=false;
    address public creator;

    EthVerifyCore public ethVerify=EthVerifyCore(0x1Ea6fAd76886fE0C0BF8eBb3F51678B33D24186c); 

     
     
     
    constructor() public {
        timestep=24 hours; 
        symbol = "VRF";
        name = "0xVerify";
        decimals = 18;
        dailyDistribution=10000000 * 10**uint(decimals);
        claimedYesterday=20;
        claimedToday=0;
        dayStartTime=now;
        _totalSupply=14 * dailyDistribution;
        balances[msg.sender] = _totalSupply;
        creator=msg.sender;
    }
    function activate(){
      require(!activated);
      require(msg.sender==creator);
      dayStartTime=now-1 minutes;
      activated=true;
    }
     
     
     
    function claimTokens() public{
        require(activated);
         
        if(dayStartTime<now.sub(timestep)){
            uint daysPassed=(now.sub(dayStartTime)).div(timestep);
            dayStartTime=dayStartTime.add(daysPassed.mul(timestep));
            claimedYesterday=claimedToday > 1 ? claimedToday : 1;  
            claimedToday=0;
        }

         
        require(ethVerify.verifiedUsers(msg.sender));

         
        require(lastClaimed[msg.sender] <= dayStartTime);
        lastClaimed[msg.sender]=now;

         
        claimedToday=claimedToday.add(1);
        balances[msg.sender]=balances[msg.sender].add(dailyDistribution.div(claimedYesterday));
        _totalSupply=_totalSupply.add(dailyDistribution.div(claimedYesterday));
        emit TokensClaimed(msg.sender,dailyDistribution.div(claimedYesterday));
    }

     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
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