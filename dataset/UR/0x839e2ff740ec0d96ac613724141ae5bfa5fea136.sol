 

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


 
 
 
 
contract DIPToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public startDate;
    uint public bonusEnds50;
    uint public bonusEnds20;
    uint public bonusEnds15;
    uint public bonusEnds10;
    uint public bonusEnds5;
    uint public endDate;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    function DIPToken() public {
        symbol = "DIP";
        name = "DIP Token";
        decimals = 18;
        _totalSupply = 180000000000000000000000000;
        balances[0xce8f00911386b2bE473012468e54dCaA82C09F7e] = _totalSupply;
        Transfer(address(0), 0xce8f00911386b2bE473012468e54dCaA82C09F7e, _totalSupply);
        bonusEnds50 = now + 6 weeks;
        bonusEnds20 = now + 7 weeks;
        bonusEnds15 = now + 8 weeks;
        bonusEnds10 = now + 9 weeks;
        bonusEnds5 = now + 10 weeks;
        endDate = now + 11 weeks;

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
        uint tokens;
        if (now <= bonusEnds50) {
            if (msg.value < 10000000000000000000) {
            tokens = msg.value * 16500;
            } else {
            tokens = msg.value * 17490;
            }
        }
        if (now > bonusEnds50 && now <= bonusEnds20) {
            if (msg.value < 10000000000000000000) {
            tokens = msg.value * 13200;
            } else {
            tokens = msg.value * 13992;
            }
        }
        if (now > bonusEnds20 && now <= bonusEnds15) {
            if (msg.value < 10000000000000000000) {
            tokens = msg.value * 12650;
            } else {
            tokens = msg.value * 13409;
            }
        }
        if (now > bonusEnds15 && now <= bonusEnds10) {
            if (msg.value < 10000000000000000000) {
            tokens = msg.value * 12100;
            } else {
            tokens = msg.value * 12826;
            }
        }
        if (now > bonusEnds10 && now <= bonusEnds5) {
            if (msg.value < 10000000000000000000) {
            tokens = msg.value * 11550;
            } else {
            tokens = msg.value * 12243;
            }
        }
        if (bonusEnds5 < now) {
            if (msg.value < 10000000000000000000) {
            tokens = msg.value * 11000;
            } else {
            tokens = msg.value * 11660;
            }
        }
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value);
    }



     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}