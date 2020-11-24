 

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

    mapping(address => uint8) whitelist;
    mapping(uint256 => address) holders;
    uint256 _totalHolders;  

    function enableWhitelist(address[] _addresses) public returns (bool success);

    modifier onlyWhitelist() {
        require(whitelist[msg.sender] == 2);
        _;
    }




}

 
 
 
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
     
     
     

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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
        price= _gweiCostOfEachToken * 10**9;
        _totalSupply = _total * 10**uint(decimals);

        _totalHolders = 0;

        balances[owner] = _totalSupply;
        holders[_totalHolders] = owner;
        whitelist[owner] = 2;
        _totalHolders++;


        emit Transfer(address(0), owner, _totalSupply);


    }


     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) onlyWhitelist public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) onlyWhitelist public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) onlyWhitelist public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function enableWhitelist(address[] _addresses) public onlyOwner returns (bool success) {
        for (uint i = 0; i < _addresses.length; i++) {
            _addWalletToWhitelist(_addresses[i]);
        }
        return true;
    }

    function _addWalletToWhitelist(address addr) internal {
        if (whitelist[addr] == 2) {
        } else if (whitelist[addr] == 1) {
            whitelist[addr] = 2;
        } else {
            whitelist[addr] = 2;
            holders[_totalHolders] = addr;
            _totalHolders++;
        }
    }

    function disableWhitelist(address[] _addresses) public onlyOwner returns (bool success) {
        for (uint i = 0; i < _addresses.length; i++) {
            _disableWhitelist(_addresses[i]);
        }
        return true;
    }

    function _disableWhitelist(address addr) internal {
        if (whitelist[addr] == 2) {
            whitelist[addr] = 1;
        } else {
        }
    }

    function getWhitelist() public view returns (address[] addresses) {

        uint256 j;
        uint256 count = 0;

        for (j=0; j<_totalHolders; j++) {
            if (whitelist[holders[j]] == 2) {
                count = count+1;
            } else {
            }
        }
        address[] memory wlist = new address[](count);

        for (j=0; j<count; j++) {
            if (whitelist[holders[j]] == 2) {
                wlist[j] = holders[j];
            } else {
            }
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

     
    function immediateWithdrawal() public onlyOwner {
        if (msg.sender.send(amountRaised)) {
             
            amountRaised = 0;
        } else {
             
        }
    }

    function burnTokens(uint token_amount) public onlyOwner {

        require(!crowdsaleClosed);
        balances[owner] = balances[owner].sub(token_amount);
        _totalSupply = _totalSupply.sub(token_amount);
        emit Transfer(owner, address(0), token_amount);
    }

    function mintTokens(uint token_amount) public onlyOwner {
        require(!crowdsaleClosed);
        _totalSupply = _totalSupply.add(token_amount);
        balances[owner] = balances[owner].add(token_amount);
        emit Transfer(address(0), owner, token_amount);
    }

    function transferOwnership(address newOwner) public onlyOwner {

        require(!crowdsaleClosed);

         
        _addWalletToWhitelist(newOwner);

         
        uint token_amount = balances[owner];
        balances[owner] = 0;
        balances[newOwner] = balances[newOwner].add(token_amount);
        emit Transfer(owner, newOwner, token_amount);

         
        _transferOwnership(newOwner);

    }


    function () payable onlyWhitelist public {

        require(!crowdsaleClosed);
        uint amount = msg.value;
        require(amount.div(price) > 0);
        uint token_amount = (amount.div(price))*10**18;

        amountRaised = amountRaised.add(amount);

        balances[owner] = balances[owner].sub(token_amount);
        balances[msg.sender] = balances[msg.sender].add(token_amount);
        emit Transfer(owner, msg.sender, token_amount);

    }


}