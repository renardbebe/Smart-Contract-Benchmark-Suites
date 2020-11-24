 

pragma solidity ^0.4.15;

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
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
         
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract EtherSport is StandardToken {
    using SafeMath for uint256;

     
    string public constant name = "Ether Sport";
    string public constant symbol = "ESC";
    uint8 public constant decimals = 18;
    uint256 public constant tokenUnit = 10 ** uint256(decimals);

     
    address public owner;

     
    address public ethFundAddress;   
    address public escFundAddress;   

     
    mapping (address => uint256) public purchases;
    mapping (uint => address) public allocationsIndex;
    mapping (address => uint256) public allocations;
    uint public allocationsLength;
    mapping (string => mapping (string => uint256)) cd;  

     
    bool public isFinalized;
    bool public isStopped;
    uint256 public startBlock;   
    uint256 public endBlock;   
    uint256 public assignedSupply;   
    uint256 public constant minimumPayment = 5 * (10**14);  
    uint256 public constant escFund = 40 * (10**6) * tokenUnit;   

     
    event ClaimESC(address indexed _to, uint256 _value);

    modifier onlyBy(address _account){
        require(msg.sender == _account);
        _;
    }

    function changeOwner(address _newOwner) onlyBy(owner) external {
        owner = _newOwner;
    }

    modifier respectTimeFrame() {
        require(block.number >= startBlock);
        require(block.number < endBlock);
        _;
    }

    modifier salePeriodCompleted() {
        require(block.number >= endBlock || assignedSupply.add(escFund).add(minimumPayment) > totalSupply);
        _;
    }

    modifier isValidState() {
        require(!isFinalized && !isStopped);
        _;
    }

    function allocate(address _escAddress, uint token) internal {
        allocationsIndex[allocationsLength] = _escAddress;
        allocations[_escAddress] = token;
        allocationsLength = allocationsLength + 1;
    }
     
    function EtherSport(
    address _ethFundAddress,
    uint256 _startBlock,
    uint256 _preIcoHeight,
    uint256 _stage1Height,
    uint256 _stage2Height,
    uint256 _stage3Height,
    uint256 _stage4Height,
    uint256 _endBlockHeight
    )
    public
    {
        require(_ethFundAddress != 0x0);
        require(_startBlock > block.number);

        owner = msg.sender;  
        isFinalized = false;  
        isStopped   = false;  
        ethFundAddress = _ethFundAddress;
        totalSupply    = 100 * (10**6) * tokenUnit;   
        assignedSupply = 0;   
         
         
         
         
         
         
         
         
         
         
        cd['preIco']['startBlock'] = _startBlock;                 cd['preIco']['endBlock'] = _startBlock + _preIcoHeight;     cd['preIco']['cap'] = 10 * 10**6 * 10**18; cd['preIco']['exRate'] = 200000;
        cd['stage1']['startBlock'] = _startBlock + _stage1Height; cd['stage1']['endBlock'] = _startBlock + _stage2Height - 1; cd['stage1']['cap'] = 10 * 10**6 * 10**18; cd['stage1']['exRate'] = 100000;
        cd['stage2']['startBlock'] = _startBlock + _stage2Height; cd['stage2']['endBlock'] = _startBlock + _stage3Height - 1; cd['stage2']['cap'] = 15 * 10**6 * 10**18; cd['stage2']['exRate'] = 76923;
        cd['stage3']['startBlock'] = _startBlock + _stage3Height; cd['stage3']['endBlock'] = _startBlock + _stage4Height - 1; cd['stage3']['cap'] = 15 * 10**6 * 10**18; cd['stage3']['exRate'] = 58824;
        cd['stage4']['startBlock'] = _startBlock + _stage4Height; cd['stage4']['endBlock'] = _startBlock + _endBlockHeight;   cd['stage4']['cap'] = 20 * 10**6 * 10**18; cd['stage4']['exRate'] = 50000;
        startBlock = _startBlock;
        endBlock   = _startBlock +_endBlockHeight;

        escFundAddress = 0xfA29D004fD4139B04bda5fa2633bd7324d6f6c76;
        allocationsLength = 0;
         
        allocate(escFundAddress, 0);  
        allocate(0x610a20536e7b7A361D6c919529DBc1E037E1BEcB, 5 * 10**6 * 10**18);  
        allocate(0x198bd6be0D747111BEBd5bD053a594FD63F3e87d, 4 * 10**6 * 10**18);  
        allocate(0x02401E5B98202a579F0067781d66FBd4F2700Cb6, 4 * 10**6 * 10**18);  
         
        allocate(0x778ACEcf52520266675b09b8F5272098D8679f43, 3 * 10**6 * 10**18);  
        allocate(0xdE96fdaFf4f865A1E27085426956748c5D4b8e24, 2 * 10**6 * 10**18);  
         
        allocate(0x4E10125fc934FCADB7a30b97F9b4b642d4804e3d, 2 * 10**6 * 10**18);  
        allocate(0xF391B5b62Fd43401751c65aF5D1D02D850Ab6b7c, 2 * 10**6 * 10**18);  
        allocate(0x08474BcC5F8BB9EEe6cAc7CBA9b6fb1d20eF5AA4, 1 * 10**6 * 10**18);  
         
        allocate(0x9F5818196E45ceC2d57DFc0fc0e3D7388e5de48d, 2 * 10**6 * 10**18);  
        allocate(0x9e43667D1e3Fb460f1f2432D0FF3203364a3d284, 2 * 10**6 * 10**18);  
        allocate(0x809040D6226FE73f245a0a16Dd685b5641540B74,  500 * 10**3 * 10**18);  
        allocate(0xaE2542d16cc3D6d487fe87Fc0C03ad0D41e46AFf,  500 * 10**3 * 10**18);  
         
        allocate(0xbC82DE22610c51ACe45d3BCf03b9b3cd179731b2, 1 * 10**6 * 10**18);  
         
        allocate(0x302Cd6D41866ec03edF421a0CD4f4cbDFB0B67b0,  800 * 10**3 * 10**18);  
        allocate(0xe190CCb2f92A0dCAc30bb4a4a92863879e5ff751,   50 * 10**3 * 10**18);  
        allocate(0xfC7cf20f29f5690dF508Dd0FB99bFCB4a7d23073,  100 * 10**3 * 10**18);  
        allocate(0x1DC97D37eCbf7D255BF4d461075936df2BdFd742,   50 * 10**3 * 10**18);  
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

     
    function calculateTokenExchangeRate() internal returns (uint256) {
        if (cd['preIco']['startBlock'] <= block.number && block.number <= cd['preIco']['endBlock']) { return cd['preIco']['exRate']; }
        if (cd['stage1']['startBlock'] <= block.number && block.number <= cd['stage1']['endBlock']) { return cd['stage1']['exRate']; }
        if (cd['stage2']['startBlock'] <= block.number && block.number <= cd['stage2']['endBlock']) { return cd['stage2']['exRate']; }
        if (cd['stage3']['startBlock'] <= block.number && block.number <= cd['stage3']['endBlock']) { return cd['stage3']['exRate']; }
        if (cd['stage4']['startBlock'] <= block.number && block.number <= cd['stage4']['endBlock']) { return cd['stage4']['exRate']; }
         
        return 0;
    }

    function maximumTokensToBuy() constant internal returns (uint256) {
        uint256 maximum = 0;
        if (cd['preIco']['startBlock'] <= block.number) { maximum = maximum.add(cd['preIco']['cap']); }
        if (cd['stage1']['startBlock'] <= block.number) { maximum = maximum.add(cd['stage1']['cap']); }
        if (cd['stage2']['startBlock'] <= block.number) { maximum = maximum.add(cd['stage2']['cap']); }
        if (cd['stage3']['startBlock'] <= block.number) { maximum = maximum.add(cd['stage3']['cap']); }
        if (cd['stage4']['startBlock'] <= block.number) { maximum = maximum.add(cd['stage4']['cap']); }
        return maximum.sub(assignedSupply);
    }

     
     
    function claimTokens() respectTimeFrame isValidState payable public {
        require(msg.value >= minimumPayment);

        uint256 tokenExchangeRate = calculateTokenExchangeRate();
         
        require(tokenExchangeRate > 0);

        uint256 tokens = msg.value.mul(tokenExchangeRate).div(100);

         
        require(tokens <= maximumTokensToBuy());

         
        uint256 checkedSupply = assignedSupply.add(tokens);

         
        require(checkedSupply.add(escFund) <= totalSupply);

        balances[msg.sender] = balances[msg.sender].add(tokens);
        purchases[msg.sender] = purchases[msg.sender].add(tokens);

        assignedSupply = checkedSupply;
        ClaimESC(msg.sender, tokens);   
         
         
        Transfer(0x0, msg.sender, tokens);
    }

     
    function finalize() salePeriodCompleted isValidState onlyBy(owner) external {
         
        balances[escFundAddress] = balances[escFundAddress].add(escFund);
        assignedSupply = assignedSupply.add(escFund);
        ClaimESC(escFundAddress, escFund);    
        Transfer(0x0, escFundAddress, escFund);


        for(uint i=0;i<allocationsLength;i++)
        {
            balances[allocationsIndex[i]] = balances[allocationsIndex[i]].add(allocations[allocationsIndex[i]]);
            ClaimESC(allocationsIndex[i], allocations[allocationsIndex[i]]);   
            Transfer(0x0, allocationsIndex[i], allocations[allocationsIndex[i]]);
        }

         
         
         
        if (assignedSupply < totalSupply) {
            uint256 unassignedSupply = totalSupply.sub(assignedSupply);
            balances[escFundAddress] = balances[escFundAddress].add(unassignedSupply);
            assignedSupply = assignedSupply.add(unassignedSupply);

            ClaimESC(escFundAddress, unassignedSupply);   
            Transfer(0x0, escFundAddress, unassignedSupply);
        }

        ethFundAddress.transfer(this.balance);

        isFinalized = true;  
    }
}