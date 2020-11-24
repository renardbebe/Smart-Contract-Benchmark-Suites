 

pragma solidity ^0.4.18;

     
    library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    }


    contract Owned {

         
         
        modifier onlyOwner() {
            require(msg.sender == owner);
            _;
        }

        address public owner;
         
        function Owned() public {
            owner = msg.sender;
        }

        address public newOwner;

         
         
         
        function changeOwner(address _newOwner) onlyOwner public {
            newOwner = _newOwner;
        }


        function acceptOwnership() public {
            if (msg.sender == newOwner) {
                owner = newOwner;
            }
        }
    }


    contract ERC20Protocol {
         
         
        uint public totalSupply;

         
         
        function balanceOf(address _owner) constant public returns (uint balance);

         
         
         
         
        function transfer(address _to, uint _value) public returns (bool success);

         
         
         
         
         
        function transferFrom(address _from, address _to, uint _value) public returns (bool success);

         
         
         
         
        function approve(address _spender, uint _value) public returns (bool success);

         
         
         
        function allowance(address _owner, address _spender) constant public returns (uint remaining);

        event Transfer(address indexed _from, address indexed _to, uint _value);
        event Approval(address indexed _owner, address indexed _spender, uint _value);
    }

    contract StandardToken is ERC20Protocol {
        using SafeMath for uint;

         
        modifier onlyPayloadSize(uint size) {
            require(msg.data.length >= size + 4);
            _;
        }

        function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public returns (bool success) {
             
             
             
             
            if (balances[msg.sender] >= _value) {
                balances[msg.sender] -= _value;
                balances[_to] += _value;
                Transfer(msg.sender, _to, _value);
                return true;
            } else { return false; }
        }

        function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) public returns (bool success) {
             
             
            if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
                balances[_to] += _value;
                balances[_from] -= _value;
                allowed[_from][msg.sender] -= _value;
                Transfer(_from, _to, _value);
                return true;
            } else { return false; }
        }

        function balanceOf(address _owner) constant public returns (uint balance) {
            return balances[_owner];
        }

        function approve(address _spender, uint _value) onlyPayloadSize(2 * 32) public returns (bool success) {
             
             
             
             
            assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        }

        function allowance(address _owner, address _spender) constant public returns (uint remaining) {
        return allowed[_owner][_spender];
        }

        mapping (address => uint) balances;
        mapping (address => mapping (address => uint)) allowed;
    }

    contract SharesChainToken is StandardToken {
         
        string public constant name = "SharesChainToken";
        string public constant symbol = "SCTK";
        uint public constant decimals = 18;

         
        uint public constant MAX_TOTAL_TOKEN_AMOUNT = 20000000000 ether;

         
         
        address public minter;

         

        modifier onlyMinter {
            assert(msg.sender == minter);
            _;
        }

        modifier maxTokenAmountNotReached (uint amount){
            assert(totalSupply.add(amount) <= MAX_TOTAL_TOKEN_AMOUNT);
            _;
        }

         
        function SharesChainToken(address _minter) public {
            minter = _minter;
        }


         
        function mintToken(address recipient, uint _amount)
            public
            onlyMinter
            maxTokenAmountNotReached(_amount)
            returns (bool)
        {
            totalSupply = totalSupply.add(_amount);
            balances[recipient] = balances[recipient].add(_amount);
            return true;
        }
    }

    contract SharesChainTokenCrowdFunding is Owned {
    using SafeMath for uint;

      
     
    uint public constant MAX_TOTAL_TOKEN_AMOUNT = 20000000000 ether;

     
    uint public constant MAX_CROWD_FUNDING_ETH = 30000 ether;

     
    uint public constant TEAM_INCENTIVES_AMOUNT = 2000000000 ether;  
    uint public constant OPERATION_AMOUNT = 2000000000 ether;        
    uint public constant MINING_POOL_AMOUNT = 8000000000 ether;      
    uint public constant MAX_PRE_SALE_AMOUNT = 8000000000 ether;     

     
    address public TEAM_HOLDER;
    address public MINING_POOL_HOLDER;
    address public OPERATION_HOLDER;

     
    uint public constant EXCHANGE_RATE = 205128;
    uint8 public constant MAX_UN_LOCK_TIMES = 10;

     
     
    address public walletOwnerAddress;
     
    uint public startTime;


    SharesChainToken public sharesChainToken;

     
    uint16 public numFunders;
    uint public preSoldTokens;
    uint public crowdEther;

     
    mapping (address => bool) public whiteList;

     
    address[] private investors;

     
    mapping (address => uint8) leftReleaseTimes;

     
    mapping (address => uint) lockedTokens;

     
    bool public halted;

     
    bool public close;

     

    event NewSale(address indexed destAddress, uint ethCost, uint gotTokens);

     
    modifier notHalted() {
        require(!halted);
        _;
    }

    modifier isHalted() {
        require(halted);
        _;
    }

    modifier isOpen() {
        require(!close);
        _;
    }

    modifier isClose() {
        require(close);
        _;
    }

    modifier onlyWalletOwner {
        require(msg.sender == walletOwnerAddress);
        _;
    }

    modifier initialized() {
        require(address(walletOwnerAddress) != 0x0);
        _;
    }

    modifier ceilingEtherNotReached(uint x) {
        require(crowdEther.add(x) <= MAX_CROWD_FUNDING_ETH);
        _;
    }

    modifier earlierThan(uint x) {
        require(now < x);
        _;
    }

    modifier notEarlierThan(uint x) {
        require(now >= x);
        _;
    }

    modifier inWhiteList(address user) {
        require(whiteList[user]);
        _;
    }

     
    function SharesChainTokenCrowdFunding(address _owner, address _walletOwnerAddress, uint _startTime, address _teamHolder, address _miningPoolHolder, address _operationHolder) public {
        require(_walletOwnerAddress != 0x0);
        owner = _owner;
        halted = false;
        close = false;
        walletOwnerAddress = _walletOwnerAddress;
        startTime = _startTime;
        preSoldTokens = 0;
        crowdEther = 0;
        TEAM_HOLDER = _teamHolder;
        MINING_POOL_HOLDER = _miningPoolHolder;
        OPERATION_HOLDER = _operationHolder;
        sharesChainToken = new SharesChainToken(this);
        sharesChainToken.mintToken(_teamHolder, TEAM_INCENTIVES_AMOUNT);
        sharesChainToken.mintToken(_miningPoolHolder, MINING_POOL_AMOUNT);
        sharesChainToken.mintToken(_operationHolder, OPERATION_AMOUNT);
    }

     
    function () public payable {
        buySCTK(msg.sender, msg.value);
    }


     
     
    function buySCTK(address receiver, uint costEth)
        private
        notHalted
        isOpen
        initialized
        inWhiteList(receiver)
        ceilingEtherNotReached(costEth)
        notEarlierThan(startTime)
        returns (bool)
    {
        require(receiver != 0x0);
        require(costEth >= 1 ether);

         
        require(!isContract(receiver));

        if (lockedTokens[receiver] == 0) {
            numFunders++;
            investors.push(receiver);
            leftReleaseTimes[receiver] = MAX_UN_LOCK_TIMES;  
        }

         
        uint gotTokens = calculateGotTokens(costEth);

         
        require(preSoldTokens.add(gotTokens) <= MAX_PRE_SALE_AMOUNT);
        lockedTokens[receiver] = lockedTokens[receiver].add(gotTokens);
        preSoldTokens = preSoldTokens.add(gotTokens);
        crowdEther = crowdEther.add(costEth);
        walletOwnerAddress.transfer(costEth);
        NewSale(receiver, costEth, gotTokens);
        return true;
    }


     
    function setWhiteListInBatch(address[] users)
        public
        onlyOwner
    {
        for (uint i = 0; i < users.length; i++) {
            whiteList[users[i]] = true;
        }
    }

     
    function addOneUserIntoWhiteList(address user)
        public
        onlyOwner
    {
        whiteList[user] = true;
    }

     
    function queryLockedTokens(address user) public view returns(uint) {
        return lockedTokens[user];
    }


     
    function calculateGotTokens(uint costEther) pure internal returns (uint gotTokens) {
        gotTokens = costEther * EXCHANGE_RATE;
        if (costEther > 0 && costEther < 100 ether) {
            gotTokens = gotTokens.mul(1);
        }else if (costEther >= 100 ether && costEther < 500 ether) {
            gotTokens = gotTokens.mul(115).div(100);
        }else {
            gotTokens = gotTokens.mul(130).div(100);
        }
        return gotTokens;
    }

     
     
    function halt() public onlyOwner {
        halted = true;
    }

     
     
    function unHalt() public onlyOwner {
        halted = false;
    }

     
    function stopCrowding() public onlyOwner {
        close = true;
    }

     
    function changeWalletOwnerAddress(address newWalletAddress) public onlyWalletOwner {
        walletOwnerAddress = newWalletAddress;
    }


     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) {
            return false;
        }
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }


    function releaseRestPreSaleTokens()
        public
        onlyOwner
        isClose
    {
        uint unSoldTokens = MAX_PRE_SALE_AMOUNT - preSoldTokens;
        sharesChainToken.mintToken(OPERATION_HOLDER, unSoldTokens);
    }

     

     
    function unlock10PercentTokensInBatch()
        public
        onlyOwner
        isClose
        returns (bool)
    {
        for (uint8 i = 0; i < investors.length; i++) {
            if (leftReleaseTimes[investors[i]] > 0) {
                uint releasedTokens = lockedTokens[investors[i]] / leftReleaseTimes[investors[i]];
                sharesChainToken.mintToken(investors[i], releasedTokens);
                lockedTokens[investors[i]] = lockedTokens[investors[i]] - releasedTokens;
                leftReleaseTimes[investors[i]] = leftReleaseTimes[investors[i]] - 1;
            }
        }
        return true;
    }
}