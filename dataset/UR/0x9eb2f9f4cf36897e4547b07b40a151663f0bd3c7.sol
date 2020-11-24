 

 

contract ConfigInterface {
        address public owner;
        mapping(address => bool) admins;
        mapping(bytes32 => address) addressMap;
        mapping(bytes32 => bool) boolMap;
        mapping(bytes32 => bytes32) bytesMap;
        mapping(bytes32 => uint256) uintMap;

         
         
         
         
        function setConfigAddress(bytes32 _key, address _val) returns(bool success);

         
         
         
         
        function setConfigBool(bytes32 _key, bool _val) returns(bool success);

         
         
         
         
        function setConfigBytes(bytes32 _key, bytes32 _val) returns(bool success);

         
         
         
         
        function setConfigUint(bytes32 _key, uint256 _val) returns(bool success);

         
         
         
        function getConfigAddress(bytes32 _key) returns(address val);

         
         
         
        function getConfigBool(bytes32 _key) returns(bool val);

         
         
         
        function getConfigBytes(bytes32 _key) returns(bytes32 val);

         
         
         
        function getConfigUint(bytes32 _key) returns(uint256 val);

         
         
        function addAdmin(address _admin) returns(bool success);

         
         
         
        function removeAdmin(address _admin) returns(bool success);

}

contract TokenInterface {

        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowed;
        mapping(address => bool) seller;

        address config;
        address owner;
        address dao;
        address public badgeLedger;
        bool locked;

         
        uint256 public totalSupply;

         
         
        function balanceOf(address _owner) constant returns(uint256 balance);

         
         
         
         
        function transfer(address _to, uint256 _value) returns(bool success);

         
         
         
         
         
        function transferFrom(address _from, address _to, uint256 _value) returns(bool success);

         
         
         
         
        function approve(address _spender, uint256 _value) returns(bool success);

         
         
         
        function allowance(address _owner, address _spender) constant returns(uint256 remaining);

         
         
         
         
        function mint(address _owner, uint256 _amount) returns(bool success);

         
         
         
         
        function mintBadge(address _owner, uint256 _amount) returns(bool success);

        function registerDao(address _dao) returns(bool success);

        function registerSeller(address _tokensales) returns(bool success);

        event Transfer(address indexed _from, address indexed _to, uint256 indexed _value);
        event Mint(address indexed _recipient, uint256 indexed _amount);
        event Approval(address indexed _owner, address indexed _spender, uint256 indexed _value);
}

contract TokenSalesInterface {

        struct SaleProxy {
                address payout;
                bool isProxy;
        }

        struct SaleStatus {
                bool founderClaim;
                uint256 releasedTokens;
                uint256 releasedBadges;
                uint256 claimers;
        }

        struct Info {
                uint256 totalWei;
                uint256 totalCents;
                uint256 realCents;
                uint256 amount;
        }

        struct SaleConfig {
                uint256 startDate;
                uint256 periodTwo;
                uint256 periodThree;
                uint256 endDate;
                uint256 goal;
                uint256 cap;
                uint256 badgeCost;
                uint256 founderAmount;
                address founderWallet;
        }

        struct Buyer {
                uint256 centsTotal;
                uint256 weiTotal;
                bool claimed;
        }

        Info saleInfo;
        SaleConfig saleConfig;
        SaleStatus saleStatus;

        address config;
        address owner;
        bool locked;

        uint256 public ethToCents;

        mapping(address => Buyer) buyers;
        mapping(address => SaleProxy) proxies;

         
         
         
         
        function ppb(uint256 _a, uint256 _c) public constant returns(uint256 b);


         
         
         
         
        function calcShare(uint256 _contrib, uint256 _total) public constant returns(uint256 share);

         
         
         
        function weiToCents(uint256 _wei) public constant returns(uint256 centsvalue);

        function proxyPurchase(address _user) returns(bool success);

         
         
         
        function purchase(address _user, uint256 _amount) private returns(bool success);

         
         
         
         
         
         
         
        function userInfo(address _user) public constant returns(uint256 centstotal, uint256 weitotal, uint256 share, uint badges, bool claimed);

         
        function myInfo() public constant returns(uint256 centstotal, uint256 weitotal, uint256 share, uint badges, bool claimed);

         
         
        function totalWei() public constant returns(uint);

         
         
        function totalCents() public constant returns(uint);

         
         
         
         
         
         
         
         
         
         
         
         

        function claimFor(address _user) returns(bool success);

         
        function claim() returns(bool success);

        function claimFounders() returns(bool success);

         
        function goalReached() public constant returns(bool reached);

         
         
        function getPeriod() public constant returns(uint saleperiod);

         
         
        function startDate() public constant returns(uint date);

         
         
        function periodTwo() public constant returns(uint date);

         
         
        function periodThree() public constant returns(uint date);

         
         
        function endDate() public constant returns(uint date);

         
         

        function isEnded() public constant returns(bool ended);

         
         
        function sendFunds() public returns(bool success);

         
        function regProxy(address _payout) returns(bool success);

        function getProxy(address _payout) public returns(address proxy);

        function getPayout(address _proxy) public returns(address payout, bool isproxy);

        function unlock() public returns(bool success);

        function getSaleStatus() public constant returns(bool fclaim, uint256 reltokens, uint256 relbadges, uint256 claimers);

        function getSaleInfo() public constant returns(uint256 weiamount, uint256 cents, uint256 realcents, uint256 amount);

        function getSaleConfig() public constant returns(uint256 start, uint256 two, uint256 three, uint256 end, uint256 goal, uint256 cap, uint256 badgecost, uint256 famount, address fwallet);

        event Purchase(uint256 indexed _exchange, uint256 indexed _rate, uint256 indexed _cents);
        event Claim(address indexed _user, uint256 indexed _amount, uint256 indexed _badges);

}

contract Badge {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowed;

        address public owner;
        bool public locked;

         
        uint256 public totalSupply;

        modifier ifOwner() {
                if (msg.sender != owner) {
                        throw;
                } else {
                        _
                }
        }


        event Transfer(address indexed _from, address indexed _to, uint256 _value);
        event Mint(address indexed _recipient, uint256 indexed _amount);
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);

        function Badge() {
                owner = msg.sender;
        }

        function safeToAdd(uint a, uint b) returns(bool) {
                return (a + b >= a);
        }

        function addSafely(uint a, uint b) returns(uint result) {
                if (!safeToAdd(a, b)) {
                        throw;
                } else {
                        result = a + b;
                        return result;
                }
        }

        function safeToSubtract(uint a, uint b) returns(bool) {
                return (b <= a);
        }

        function subtractSafely(uint a, uint b) returns(uint) {
                if (!safeToSubtract(a, b)) throw;
                return a - b;
        }

        function balanceOf(address _owner) constant returns(uint256 balance) {
                return balances[_owner];
        }

        function transfer(address _to, uint256 _value) returns(bool success) {
                if (balances[msg.sender] >= _value && _value > 0) {
                        balances[msg.sender] = subtractSafely(balances[msg.sender], _value);
                        balances[_to] = addSafely(_value, balances[_to]);
                        Transfer(msg.sender, _to, _value);
                        success = true;
                } else {
                        success = false;
                }
                return success;
        }

        function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
                if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
                        balances[_to] = addSafely(balances[_to], _value);
                        balances[_from] = subtractSafely(balances[_from], _value);
                        allowed[_from][msg.sender] = subtractSafely(allowed[_from][msg.sender], _value);
                        Transfer(_from, _to, _value);
                        return true;
                } else {
                        return false;
                }
        }

        function approve(address _spender, uint256 _value) returns(bool success) {
                allowed[msg.sender][_spender] = _value;
                Approval(msg.sender, _spender, _value);
                success = true;
                return success;
        }

        function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
                remaining = allowed[_owner][_spender];
                return remaining;
        }

        function mint(address _owner, uint256 _amount) ifOwner returns(bool success) {
                totalSupply = addSafely(totalSupply, _amount);
                balances[_owner] = addSafely(balances[_owner], _amount);
                Mint(_owner, _amount);
                return true;
        }

        function setOwner(address _owner) ifOwner returns(bool success) {
                owner = _owner;
                return true;
        }

}

contract Token {

        address public owner;
        address public config;
        bool public locked;
        address public dao;
        address public badgeLedger;
        uint256 public totalSupply;

        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowed;
        mapping(address => bool) seller;

         

        modifier ifSales() {
                if (!seller[msg.sender]) throw;
                _
        }

        modifier ifOwner() {
                if (msg.sender != owner) throw;
                _
        }

        modifier ifDao() {
                if (msg.sender != dao) throw;
                _
        }

        event Transfer(address indexed _from, address indexed _to, uint256 _value);
        event Mint(address indexed _recipient, uint256 _amount);
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);

        function Token(address _config) {
                config = _config;
                owner = msg.sender;
                address _initseller = ConfigInterface(_config).getConfigAddress("sale1:address");
                seller[_initseller] = true;
                badgeLedger = new Badge();
                locked = false;
        }

        function safeToAdd(uint a, uint b) returns(bool) {
                return (a + b >= a);
        }

        function addSafely(uint a, uint b) returns(uint result) {
                if (!safeToAdd(a, b)) {
                        throw;
                } else {
                        result = a + b;
                        return result;
                }
        }

        function safeToSubtract(uint a, uint b) returns(bool) {
                return (b <= a);
        }

        function subtractSafely(uint a, uint b) returns(uint) {
                if (!safeToSubtract(a, b)) throw;
                return a - b;
        }

        function balanceOf(address _owner) constant returns(uint256 balance) {
                return balances[_owner];
        }

        function transfer(address _to, uint256 _value) returns(bool success) {
                if (balances[msg.sender] >= _value && _value > 0) {
                        balances[msg.sender] = subtractSafely(balances[msg.sender], _value);
                        balances[_to] = addSafely(balances[_to], _value);
                        Transfer(msg.sender, _to, _value);
                        success = true;
                } else {
                        success = false;
                }
                return success;
        }

        function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
                if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
                        balances[_to] = addSafely(balances[_to], _value);
                        balances[_from] = subtractSafely(balances[_from], _value);
                        allowed[_from][msg.sender] = subtractSafely(allowed[_from][msg.sender], _value);
                        Transfer(_from, _to, _value);
                        return true;
                } else {
                        return false;
                }
        }

        function approve(address _spender, uint256 _value) returns(bool success) {
                allowed[msg.sender][_spender] = _value;
                Approval(msg.sender, _spender, _value);
                success = true;
                return success;
        }

        function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
                remaining = allowed[_owner][_spender];
                return remaining;
        }

        function mint(address _owner, uint256 _amount) ifSales returns(bool success) {
                totalSupply = addSafely(_amount, totalSupply);
                balances[_owner] = addSafely(balances[_owner], _amount);
                return true;
        }

        function mintBadge(address _owner, uint256 _amount) ifSales returns(bool success) {
                if (!Badge(badgeLedger).mint(_owner, _amount)) return false;
                return true;
        }

        function registerDao(address _dao) ifOwner returns(bool success) {
                if (locked == true) return false;
                dao = _dao;
                locked = true;
                return true;
        }

        function setDao(address _newdao) ifDao returns(bool success) {
                dao = _newdao;
                return true;
        }

        function isSeller(address _query) returns(bool isseller) {
                return seller[_query];
        }

        function registerSeller(address _tokensales) ifDao returns(bool success) {
                seller[_tokensales] = true;
                return true;
        }

        function unregisterSeller(address _tokensales) ifDao returns(bool success) {
                seller[_tokensales] = false;
                return true;
        }

        function setOwner(address _newowner) ifDao returns(bool success) {
                if (Badge(badgeLedger).setOwner(_newowner)) {
                        owner = _newowner;
                        success = true;
                } else {
                        success = false;
                }
                return success;
        }

}