 

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
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract CrowdsaleInterface {

    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    mapping(address => bool) whitelist;
    mapping(uint256 => address) holders;
    uint256 _totalHolders;  

    function enableWhitelist(address[] _addresses) public returns (bool success);

    modifier onlyWhitelist() {
        require(whitelist[msg.sender] == true);
        _;
    }




}

 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
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

contract TokenTemplate is ERC20Interface, CrowdsaleInterface, Owned {
    using SafeMath for uint;

    bytes32 public symbol;
    uint public price;
    bytes32 public  name;
    uint8 public decimals;
    uint _totalSupply;
    uint amountRaised;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    constructor(bytes32 _name, bytes32 _symbol, uint _total, uint _gweiCostOfEachToken) public {
        symbol = _symbol;
        name = _name;
        decimals = 18;
        price= _gweiCostOfEachToken * 1e9;
        _totalSupply = _total * 10**uint(decimals);

        _totalHolders = 0;
        balances[owner] = _totalSupply;
        holders[_totalHolders] = owner;
        _totalHolders++;

        emit Transfer(address(0), owner, _totalSupply);


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


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }


   function enableWhitelist(address[] _addresses) public onlyOwner returns (bool success) {
        for (uint i = 0; i < _addresses.length; i++) {
            if (whitelist[_addresses[i]] == true) {

            } else {
                whitelist[_addresses[i]] = true;
                holders[_totalHolders] = _addresses[i];
                _totalHolders++;
            }
        }
        return true;
    }

    function getWhitelist() public view returns (address[] addresses) {

        address[] memory wlist = new address[](_totalHolders);

        for (uint256 j=0; j<_totalHolders; j++) {
            wlist[j] = holders[j];
        }
        return wlist;
    }

    function getBalances() public view returns (address[] _addresses, uint256[] _balances) {
        address[] memory wlist1 = new address[](_totalHolders);
        uint256[] memory wlist2 = new uint256[](_totalHolders);

        for (uint256 j=0; j<_totalHolders; j++) {
            wlist1[j] = holders[j];
            wlist2[j] = balances[holders[j]];
        }
        return (wlist1,wlist2);
    }

    function closeCrowdsale() public onlyOwner  {

        crowdsaleClosed = true;
    }

    function safeWithdrawal() public onlyOwner {
        require(crowdsaleClosed);
        require(!fundingGoalReached);

        if (msg.sender.send(amountRaised)) {
            fundingGoalReached = true;
        } else {
            fundingGoalReached = false;
        }

    }



    function () payable onlyWhitelist public {

        require(!crowdsaleClosed);
        uint amount = msg.value;
        uint token_amount = amount.div(price);

        amountRaised = amountRaised.add(amount);


        balances[owner] = balances[owner].sub(token_amount);
        balances[msg.sender] = balances[msg.sender].add(token_amount);
        emit Transfer(owner, msg.sender, token_amount);


         
    }


}