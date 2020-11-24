 

pragma solidity 0.4.23;


contract SafeMath {

    function safeAdd(uint a, uint b) public pure returns(uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns(uint c) {
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

 
 
 
 
contract BYSToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;
    address public tokenOwner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping (address => uint256) public frozenAccountByOwner;

    uint256 public freeCrawDeadline;
    event FrozenAccount(address target, uint256 deadline);
     
     
     
    constructor() public {
        symbol = "BYS";
        name = "Bayesin";
        decimals = 18;
        totalSupply = 2000000000 * 10 ** 18;   
        tokenOwner = 0xC92221388BA9418777454e142d4dA4513bdb81A1;
        freeCrawDeadline =  1536681600;
         
         
         
         
        balances[tokenOwner] = totalSupply;
        emit Transfer(address(0), tokenOwner, totalSupply);
    }

    modifier isOwner
    {
        require(msg.sender == tokenOwner);
        _;
    }

    modifier afterFrozenDeadline() { 
        if (now >= freeCrawDeadline) 
        _; 
    }

    function managerAccount(address target, uint256 deadline) public isOwner
    {
        frozenAccountByOwner[target] = deadline;
        emit FrozenAccount(target, deadline);
    }

     
     
     
    function totalSupply() public view returns (uint) {
        return totalSupply;
    }


     
     
     
    function balanceOf(address _tokenOwner) public view returns (uint balance) {
        return balances[_tokenOwner];
    }


     
     
     
     
     
    function transfer(address _to, uint _tokens) public afterFrozenDeadline returns (bool success) {

        require(now > frozenAccountByOwner[msg.sender]);
        balances[msg.sender] = safeSub(balances[msg.sender], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address _spender, uint _tokens) public returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _tokens) public afterFrozenDeadline returns (bool success) {

        require(_tokens > 0);
        require(block.timestamp > frozenAccountByOwner[_from]);

        balances[_from] = safeSub(balances[_from], _tokens);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        emit Transfer(_from, _to, _tokens);
        return true;
    }


     
     
     
     
    function allowance(address _tokenOwner, address _spender) public view returns (uint remaining) {
        return allowed[_tokenOwner][_spender];
    }


     
     
     
     
     
    function approveAndCall(address _spender, uint _tokens) public returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
         
        return true;
    }

    function fundTransfer(address _to, uint256 _amount) internal {
        require(_amount > 0);
        require(balances[tokenOwner] - _amount > 0);
        balances[tokenOwner] = safeSub(balances[tokenOwner], _amount);
        balances[_to] = safeAdd(balances[_to], _amount);
        emit Transfer(tokenOwner, _to, _amount);
    }
}


contract CrowSale is BYSToken {

    address public beneficiary; 
    uint public minGoal = 0;  
    uint public maxGoal = 0;  
    uint public price = 0; 

    uint public perPrice = 0;            
    uint public perDeadLine = 0;         
    uint public perAmountRaised = 0;     
    uint public perTokenAmount = 0;
    uint public perTokenAmountMax = 0;

    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    uint256 public totalRaised = 0;
    uint256 public amountRaised = 0;  
    uint256 public tokenAmountRasied = 0;

    uint256 public bonus01 = 0;  
    uint public bonus01Start = 0;  
    uint public bonus01End = 0;  
    uint256 public bonus02 = 0;  
    uint public bonus02Start = 0;  
    uint public bonus02End = 0;  
    uint public bonus = 0;

    mapping(address => uint256) public fundBalance;

     

     

    event GoalReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);
     
     
     
     
     
     
     
     
     
     
     
     
     
    constructor() public {
        
        beneficiary = 0xC92221388BA9418777454e142d4dA4513bdb81A1;  
        minGoal = 3000 * 1 ether;  
        maxGoal = 20000 * 1 ether;   
         
        price = 7000;
        fundingGoalReached = false;
        crowdsaleClosed = false;
        amountRaised = 0;  
        tokenAmountRasied = 0;

        bonus01 = 40;
        bonus01Start = safeMul(0, 1 ether);  
        bonus01End = safeMul(2000, 1 ether);  
        bonus02 = 20;
        bonus02Start = safeMul(2000, 1 ether);  
        bonus02End = safeMul(10000, 1 ether);    

        bonus = 0;


        perPrice = 13000;            
        perDeadLine = 1532620800;
         
         
        perAmountRaised = 0;     
        perTokenAmount = 0;
        perTokenAmountMax = 26000000 * 10 ** 18;     
    }

    function () public payable {
        require(!crowdsaleClosed);
        require(msg.sender != tokenOwner);

        if (block.timestamp > freeCrawDeadline) {
            crowdsaleClosed = true;
            revert();
        }

        uint amount = msg.value;        

        uint256 returnTokenAmount = 0;
        if (block.timestamp < perDeadLine) {
             
            if (perTokenAmount >= perTokenAmountMax) {
                revert();                
            }
            perAmountRaised = safeAdd(perAmountRaised, amount);
            returnTokenAmount = safeMul(amount, perPrice);
            perTokenAmount = safeAdd(perTokenAmount, returnTokenAmount);
            
        } else {
            fundBalance[msg.sender] = safeAdd(fundBalance[msg.sender], amount);
            if ((amountRaised >= bonus01Start) && (amountRaised < bonus01End)) {
                bonus = bonus01;
            }else if ((amountRaised >= bonus02Start) && (amountRaised < bonus02End)) {
                bonus = bonus02;
            }else {
                bonus = 0;
            }

            amountRaised = safeAdd(amountRaised, amount);
            returnTokenAmount = safeMul(amount, price);
            returnTokenAmount = safeAdd(returnTokenAmount,
            safeDiv( safeMul(returnTokenAmount, bonus), 100) );
        }

        totalRaised = safeAdd(totalRaised, amount);
        tokenAmountRasied = safeAdd(tokenAmountRasied, returnTokenAmount);  

        fundTransfer(msg.sender, returnTokenAmount);
        emit FundTransfer(msg.sender, amount, true);

        if (amountRaised >= minGoal) {
            fundingGoalReached = true;
        }

        if (amountRaised >= maxGoal) {
            fundingGoalReached = true;
            crowdsaleClosed = true;
        }
    }

    modifier afterDeadline() { if ((now >= freeCrawDeadline) || (amountRaised >= maxGoal)) _; }

    function checkGoalReached() public afterDeadline {
        if (amountRaised >= minGoal) {
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    function safeWithdrawal() public afterDeadline {

        if (!fundingGoalReached && beneficiary != msg.sender) {
                
            uint amount = fundBalance[msg.sender];
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false);
                fundBalance[msg.sender] = 0;
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            
            if (address(this).balance > 0) {
                msg.sender.transfer(address(this).balance);
                emit FundTransfer(beneficiary, address(this).balance, false);
                perAmountRaised = 0;
            } 
        }
    }

    function perSaleWithDrawal() public {

        require(beneficiary == msg.sender);
        if(perAmountRaised > 0) {
            msg.sender.transfer(perAmountRaised);
            emit FundTransfer(beneficiary, perAmountRaised, false);
            perAmountRaised = 0;
        }

    }
}