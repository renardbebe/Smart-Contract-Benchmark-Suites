 

pragma solidity ^0.4.15;

 

 

contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Doneth is Ownable {
    using SafeMath for uint256;  

     
    string public name;

     
    uint256 public totalShares;

     
    uint256 public totalWithdrawn;

     
    uint256 public genesisBlockNumber;

     
    uint256 constant public PRECISION = 18;

     
    uint256 public sharedExpense;
    uint256 public sharedExpenseWithdrawn;

     
    mapping(address => Member) public members;
    address[] public memberKeys;
    struct Member {
        bool exists;
        bool admin;
        uint256 shares;
        uint256 withdrawn;
        string memberName;
        mapping(address => uint256) tokensWithdrawn;
    }

     
    mapping(address => Token) public tokens;
    address[] public tokenKeys;
    struct Token {
        bool exists;
        uint256 totalWithdrawn;
    }

    function Doneth(string _contractName, string _founderName) {
        if (bytes(_contractName).length > 21) revert();
        if (bytes(_founderName).length > 21) revert();
        name = _contractName;
        genesisBlockNumber = block.number;
        addMember(msg.sender, 1, true, _founderName);
    }

    event Deposit(address from, uint value);
    event Withdraw(address from, uint value, uint256 newTotalWithdrawn);
    event TokenWithdraw(address from, uint value, address token, uint amount);
    event AddShare(address who, uint256 addedShares, uint256 newTotalShares);
    event RemoveShare(address who, uint256 removedShares, uint256 newTotalShares);
    event ChangePrivilege(address who, bool oldValue, bool newValue);
    event ChangeContractName(string oldValue, string newValue);
    event ChangeMemberName(address who, string oldValue, string newValue);
    event ChangeSharedExpense(uint256 contractBalance, uint256 oldValue, uint256 newValue);
    event WithdrawSharedExpense(address from, address to, uint value, uint256 newSharedExpenseWithdrawn);

     
    function () public payable {
        Deposit(msg.sender, msg.value);
    }

    modifier onlyAdmin() { 
        if (msg.sender != owner && !members[msg.sender].admin) revert();   
        _;
    }

    modifier onlyExisting(address who) { 
        if (!members[who].exists) revert(); 
        _;
    }

     
    function getMemberCount() public constant returns(uint) {
        return memberKeys.length;
    }
    
    function getMemberAtKey(uint key) public constant returns(address) {
        return memberKeys[key];
    }
    
    function getBalance() public constant returns(uint256 balance) {
        return this.balance;
    }
    
    function getContractInfo() public constant returns(string, address, uint256, uint256, uint256) {
        return (string(name), owner, genesisBlockNumber, totalShares, totalWithdrawn);
    }
    
    function returnMember(address _address) public constant onlyExisting(_address) returns(bool admin, uint256 shares, uint256 withdrawn, string memberName) {
      Member memory m = members[_address];
      return (m.admin, m.shares, m.withdrawn, m.memberName);
    }

    function checkERC20Balance(address token) public constant returns(uint256) {
        uint256 balance = ERC20(token).balanceOf(address(this));
        if (!tokens[token].exists && balance > 0) {
            tokens[token].exists = true;
        }
        return balance;
    }

     
    function addMember(address who, uint256 shares, bool admin, string memberName) public onlyAdmin() {
         
        if (members[who].exists) revert();
        if (bytes(memberName).length > 21) revert();

        Member memory newMember;
        newMember.exists = true;
        newMember.admin = admin;
        newMember.memberName = memberName;

        members[who] = newMember;
        memberKeys.push(who);
        addShare(who, shares);
    }

    function updateMember(address who, uint256 shares, bool isAdmin, string name) public onlyAdmin() {
        if (sha3(members[who].memberName) != sha3(name)) changeMemberName(who, name);
        if (members[who].admin != isAdmin) changeAdminPrivilege(who, isAdmin);
        if (members[who].shares != shares) allocateShares(who, shares);
    }

     
    function changeMemberName(address who, string newName) public onlyExisting(who) {
        if (msg.sender != who && msg.sender != owner && !members[msg.sender].admin) revert();
        if (bytes(newName).length > 21) revert();
        ChangeMemberName(who, members[who].memberName, newName);
        members[who].memberName = newName;
    }

    function changeAdminPrivilege(address who, bool newValue) public onlyAdmin() {
        ChangePrivilege(who, members[who].admin, newValue);
        members[who].admin = newValue; 
    }

     
    function changeContractName(string newName) public onlyAdmin() {
        if (bytes(newName).length > 21) revert();
        ChangeContractName(name, newName);
        name = newName;
    }

     
     
     
    function changeSharedExpenseAllocation(uint256 newAllocation) public onlyOwner() {
        if (newAllocation < sharedExpenseWithdrawn) revert();
        if (newAllocation.sub(sharedExpenseWithdrawn) > this.balance) revert();

        ChangeSharedExpense(this.balance, sharedExpense, newAllocation);
        sharedExpense = newAllocation;
    }

     
    function allocateShares(address who, uint256 amount) public onlyAdmin() onlyExisting(who) {
        uint256 currentShares = members[who].shares;
        if (amount == currentShares) revert();
        if (amount > currentShares) {
            addShare(who, amount.sub(currentShares));
        } else {
            removeShare(who, currentShares.sub(amount));
        }
    }

     
    function addShare(address who, uint256 amount) public onlyAdmin() onlyExisting(who) {
        totalShares = totalShares.add(amount);
        members[who].shares = members[who].shares.add(amount);
        AddShare(who, amount, members[who].shares);
    }

     
    function removeShare(address who, uint256 amount) public onlyAdmin() onlyExisting(who) {
        totalShares = totalShares.sub(amount);
        members[who].shares = members[who].shares.sub(amount);
        RemoveShare(who, amount, members[who].shares);
    }

     
     
     
     
     
    function withdraw(uint256 amount) public onlyExisting(msg.sender) {
        uint256 newTotal = calculateTotalWithdrawableAmount(msg.sender);
        if (amount > newTotal.sub(members[msg.sender].withdrawn)) revert();
        
        members[msg.sender].withdrawn = members[msg.sender].withdrawn.add(amount);
        totalWithdrawn = totalWithdrawn.add(amount);
        msg.sender.transfer(amount);
        Withdraw(msg.sender, amount, totalWithdrawn);
    }

     
    function withdrawToken(uint256 amount, address token) public onlyExisting(msg.sender) {
        uint256 newTotal = calculateTotalWithdrawableTokenAmount(msg.sender, token);
        if (amount > newTotal.sub(members[msg.sender].tokensWithdrawn[token])) revert();

        members[msg.sender].tokensWithdrawn[token] = members[msg.sender].tokensWithdrawn[token].add(amount);
        tokens[token].totalWithdrawn = tokens[token].totalWithdrawn.add(amount);
        ERC20(token).transfer(msg.sender, amount);
        TokenWithdraw(msg.sender, amount, token, tokens[token].totalWithdrawn);
    }

     
     
    function withdrawSharedExpense(uint256 amount, address to) public onlyAdmin() {
        if (amount > calculateTotalExpenseWithdrawableAmount()) revert();
        
        sharedExpenseWithdrawn = sharedExpenseWithdrawn.add(amount);
        to.transfer(amount);
        WithdrawSharedExpense(msg.sender, to, amount, sharedExpenseWithdrawn);
    }

     
     
     
    function calculateTotalWithdrawableAmount(address who) public constant onlyExisting(who) returns (uint256) {
         
         
        uint256 balanceSum = this.balance.add(totalWithdrawn);
        balanceSum = balanceSum.sub(sharedExpense);
        balanceSum = balanceSum.add(sharedExpenseWithdrawn);
        
         
        uint256 ethPerSharePPN = balanceSum.percent(totalShares, PRECISION); 
        uint256 ethPPN = ethPerSharePPN.mul(members[who].shares);
        uint256 ethVal = ethPPN.div(10**PRECISION); 
        return ethVal;
    }


    function calculateTotalWithdrawableTokenAmount(address who, address token) public constant returns(uint256) {
        uint256 balanceSum = checkERC20Balance(token).add(tokens[token].totalWithdrawn);

         
        uint256 tokPerSharePPN = balanceSum.percent(totalShares, PRECISION); 
        uint256 tokPPN = tokPerSharePPN.mul(members[who].shares);
        uint256 tokVal = tokPPN.div(10**PRECISION); 
        return tokVal;
    }

    function calculateTotalExpenseWithdrawableAmount() public constant returns(uint256) {
        return sharedExpense.sub(sharedExpenseWithdrawn);
    }

     
    function delegatePercent(uint256 a, uint256 b, uint256 c) public constant returns (uint256) {
        return a.percent(b, c);
    }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

     
     
    function percent(uint256 numerator, uint256 denominator, uint256 precision) internal constant returns(uint256 quotient) {
         
        uint256 _numerator = mul(numerator, 10 ** (precision+1));
         
        uint256 _quotient = (div(_numerator, denominator) + 5) / 10;
        return (_quotient);
    }
}