 

pragma solidity 0.4.17;

contract Token {

     
    uint256 public totalSupply;

     
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

     

     
     
     
     
    function transfer(address to, uint value) public returns (bool);

     
     
     
     
     
    function transferFrom(address from, address to, uint value) public returns (bool);

     
     
     
     
    function approve(address spender, uint value) public returns (bool);

     
     
    function balanceOf(address owner) public constant returns (uint);

     
     
     
    function allowance(address owner, address spender) public constant returns (uint);
}

contract StandardToken is Token {
     
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;

     

    function transfer(address to, uint value) public returns (bool) {
         
        require((to != 0x0) && (to != address(this)));
        if (balances[msg.sender] < value)
            revert();   
        balances[msg.sender] -= value;
        balances[to] += value;
        Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
         
        require((to != 0x0) && (to != address(this)));
        if (balances[from] < value || allowances[from][msg.sender] < value)
            revert();  
        balances[to] += value;
        balances[from] -= value;
        allowances[from][msg.sender] -= value;
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        allowances[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public constant returns (uint) {
        return allowances[owner][spender];
    }

    function balanceOf(address owner) public constant returns (uint) {
        return balances[owner];
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
       
      uint256 c = a / b;
       
      return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

contract GMToken is StandardToken {

    using SafeMath for uint256;

     
    string public constant name = "Global Messaging Token";
    string public constant symbol = "GMT";
    uint8 public constant decimals = 18;
    uint256 public constant tokenUnit = 10 ** uint256(decimals);

     
    address public owner;

     
    address public ethFundAddress;   
    address public gmtFundAddress;   

     
    mapping (address => bool) public registered;

     
    mapping (address => uint) public purchases;

     
    bool public isFinalized;
    bool public isStopped;
    uint256 public startBlock;   
    uint256 public endBlock;   
    uint256 public firstCapEndingBlock;   
    uint256 public secondCapEndingBlock;   
    uint256 public assignedSupply;   
    uint256 public tokenExchangeRate;   
    uint256 public baseTokenCapPerAddress;   
    uint256 public constant baseEthCapPerAddress = 7 ether;   
    uint256 public constant blocksInFirstCapPeriod = 2105;   
    uint256 public constant blocksInSecondCapPeriod = 1052;   
    uint256 public constant gasLimitInWei = 51000000000 wei;  
    uint256 public constant gmtFund = 500 * (10**6) * tokenUnit;   
    uint256 public constant minCap = 100 * (10**6) * tokenUnit;   

     
    event RefundSent(address indexed _to, uint256 _value);
    event ClaimGMT(address indexed _to, uint256 _value);

    modifier onlyBy(address _account){
        require(msg.sender == _account);  
        _;
    }

    function changeOwner(address _newOwner) onlyBy(owner) external {
        owner = _newOwner;
    }

    modifier registeredUser() {
        require(registered[msg.sender] == true);  
        _;
    }

    modifier minCapReached() {
        require(assignedSupply >= minCap);
        _;
    }

    modifier minCapNotReached() {
        require(assignedSupply < minCap);
        _;
    }

    modifier respectTimeFrame() {
        require(block.number >= startBlock && block.number < endBlock);
        _;
    }

    modifier salePeriodCompleted() {
        require(block.number >= endBlock || assignedSupply.add(gmtFund) == totalSupply);
        _;
    }

    modifier isValidState() {
        require(!isFinalized && !isStopped);
        _;
    }

     
    function GMToken(
        address _ethFundAddress,
        address _gmtFundAddress,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _tokenExchangeRate) 
        public 
    {
        require(_gmtFundAddress != 0x0);
        require(_ethFundAddress != 0x0);
        require(_startBlock < _endBlock && _startBlock > block.number);

        owner = msg.sender;  
        isFinalized = false;  
        isStopped = false;   
        ethFundAddress = _ethFundAddress;
        gmtFundAddress = _gmtFundAddress;
        startBlock = _startBlock;
        endBlock = _endBlock;
        tokenExchangeRate = _tokenExchangeRate;
        baseTokenCapPerAddress = baseEthCapPerAddress.mul(tokenExchangeRate);
        firstCapEndingBlock = startBlock.add(blocksInFirstCapPeriod);
        secondCapEndingBlock = firstCapEndingBlock.add(blocksInSecondCapPeriod);
        totalSupply = 1000 * (10**6) * tokenUnit;   
        assignedSupply = 0;   
    }

     
     
    function stopSale() onlyBy(owner) external {
        isStopped = true;
    }

     
     
    function restartSale() onlyBy(owner) external {
        isStopped = false;
    }

     
    function () payable public {
        claimTokens();
    }

     
     
    function claimTokens() respectTimeFrame registeredUser isValidState payable public {
        require(msg.value > 0);

        uint256 tokens = msg.value.mul(tokenExchangeRate);

        require(isWithinCap(tokens));

         
        uint256 checkedSupply = assignedSupply.add(tokens);

         
        require(checkedSupply.add(gmtFund) <= totalSupply); 

        balances[msg.sender] = balances[msg.sender].add(tokens);
        purchases[msg.sender] = purchases[msg.sender].add(tokens);

        assignedSupply = checkedSupply;
        ClaimGMT(msg.sender, tokens);   
         
         
        Transfer(0x0, msg.sender, tokens);
    }

     
    function isWithinCap(uint256 tokens) internal view returns (bool) {
         
        if (block.number >= secondCapEndingBlock) {
            return true;
        }

         
        require(tx.gasprice <= gasLimitInWei);
        
         
        if (block.number < firstCapEndingBlock) {
            return purchases[msg.sender].add(tokens) <= baseTokenCapPerAddress;
        } else {
            return purchases[msg.sender].add(tokens) <= baseTokenCapPerAddress.mul(4);
        }
    }


     
     
     
    function changeRegistrationStatus(address target, bool isRegistered) public onlyBy(owner) {
        registered[target] = isRegistered;
    }

     
     
     
    function changeRegistrationStatuses(address[] targets, bool isRegistered) public onlyBy(owner) {
        for (uint i = 0; i < targets.length; i++) {
            changeRegistrationStatus(targets[i], isRegistered);
        }
    }

     
    function finalize() minCapReached salePeriodCompleted isValidState onlyBy(owner) external {
         
        balances[gmtFundAddress] = balances[gmtFundAddress].add(gmtFund);
        assignedSupply = assignedSupply.add(gmtFund);
        ClaimGMT(gmtFundAddress, gmtFund);    
        Transfer(0x0, gmtFundAddress, gmtFund);
        
         
         
         
        if (assignedSupply < totalSupply) {
            uint256 unassignedSupply = totalSupply.sub(assignedSupply);
            balances[gmtFundAddress] = balances[gmtFundAddress].add(unassignedSupply);
            assignedSupply = assignedSupply.add(unassignedSupply);

            ClaimGMT(gmtFundAddress, unassignedSupply);   
            Transfer(0x0, gmtFundAddress, unassignedSupply);
        }

        ethFundAddress.transfer(this.balance);

        isFinalized = true;  
    }

     
     
     
    function refund() minCapNotReached salePeriodCompleted registeredUser isValidState external {
        require(msg.sender != gmtFundAddress);   

        uint256 gmtVal = balances[msg.sender];
        require(gmtVal > 0);  

        balances[msg.sender] = balances[msg.sender].sub(gmtVal);
        assignedSupply = assignedSupply.sub(gmtVal);  
        
        uint256 ethVal = gmtVal.div(tokenExchangeRate);  

        msg.sender.transfer(ethVal);
        
        RefundSent(msg.sender, ethVal);   
    }

     
}