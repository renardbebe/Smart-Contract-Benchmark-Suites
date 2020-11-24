 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 


 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
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


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
 
 
 
contract iotpowerToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public remaining;
    uint public _totalSupply;
    uint public startDate;
    uint public stageOneBegin;
    uint public stageOneEnd;
    uint public stageTwoBegin;
    uint public stageTwoEnd;
    uint public stageThreeBegin;
    uint public stageThreeEnd;
    uint public stageFourBegin;
    uint public stageFourEnd;
    uint public stageFiveBegin;
    uint public stageFiveEnd;
    uint public endDate;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    function iotpowerToken() public {
        symbol = "IP";
        name = "IOTPOWER Token";
        decimals = 0;
        _totalSupply = 900000000;
        stageOneBegin = 1537747200; 
        stageOneEnd = 1539561599;
        stageTwoBegin = 1539561600;
        stageTwoEnd = 1541375999;
        stageThreeBegin = 1541376000;
        stageThreeEnd = 1543190399;
        stageFourBegin = 1543190400;
        stageFourEnd = 1545004799;
        stageFiveBegin = 1545004800;
        stageFiveEnd = 1546819199;
        endDate = 1548633599;
        balances[0x7cf186Cad802cB992c4F14a634C7E81c9e8957b8] = _totalSupply;
        Transfer(address(0), 0x7cf186Cad802cB992c4F14a634C7E81c9e8957b8, _totalSupply);
    }


     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
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
        
        require(now >= startDate && now <= endDate);
        require(msg.value > 0);                      
        require(msg.value <= msg.sender.balance);    

        uint tokens;
        uint weiAmount = msg.value;

        assert(remaining <= _totalSupply);

        if (now >= stageOneBegin && now <= stageOneEnd) {
            tokens = 7185 * weiAmount / 1 ether;
        } else if (now >= stageTwoBegin && now <= stageTwoEnd) {
            tokens = 6789 * weiAmount / 1 ether;
        } else if (now >= stageThreeBegin && now <= stageThreeEnd) {
            tokens = 6392 * weiAmount / 1 ether;
        } else if (now >= stageFourBegin && now <= stageFourEnd) {
            tokens = 5996 * weiAmount / 1 ether;
        }  else if (now >= stageFiveBegin && now <= stageFiveEnd) {
            tokens = 5600 * weiAmount / 1 ether;
        } else {
            tokens = 4955 * weiAmount / 1 ether;
        }

        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        Transfer(address(0), msg.sender, tokens);
        owner.transfer(weiAmount);
        remaining = safeAdd(remaining,tokens);
  
    }



     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}