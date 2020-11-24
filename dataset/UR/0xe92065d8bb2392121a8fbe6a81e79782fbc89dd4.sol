 

pragma solidity ^0.4.21;

 

 

pragma solidity ^0.4.21;

contract AuthorizedList {

    bytes32 constant APHRODITE = keccak256("Goddess of Love!");
    bytes32 constant CUPID = keccak256("Aphrodite's Little Helper.");
    bytes32 constant BULKTRANSFER = keccak256("Bulk Transfer User.");
    mapping (address => mapping(bytes32 => bool)) internal authorized;
    mapping (bytes32 => bool) internal contractPermissions;

}

 

 

pragma solidity ^0.4.21;


contract Authorized is AuthorizedList {

    function Authorized() public {
         
        authorized[msg.sender][APHRODITE] = true;
    }

     
    modifier ifAuthorized(address _address, bytes32 _authorization) {
        require(authorized[_address][_authorization] || authorized[_address][APHRODITE]);
        _;
    }

     
    function isAuthorized(address _address, bytes32 _authorization) public view returns (bool) {
        return authorized[_address][_authorization];
    }

     
     
     
    function toggleAuthorization(address _address, bytes32 _authorization) public ifAuthorized(msg.sender, APHRODITE) {

         
        require(_address != msg.sender);

         
        if (_authorization == APHRODITE && !authorized[_address][APHRODITE]) {
            authorized[_address][CUPID] = false;
        }

        authorized[_address][_authorization] = !authorized[_address][_authorization];
    }
}

 

 

pragma solidity ^0.4.21;


contract Pausable is AuthorizedList, Authorized {

    event Pause();
    event Unpause();


     
    bool public paused = false;

     
    function Pausable() public AuthorizedList() Authorized() { }


     
    modifier whenNotPaused {
        require(!paused);
        _;
    }


     
    modifier whenPaused {
        require(paused);
        _;
    }


     
     
    function pause() public whenNotPaused ifAuthorized(msg.sender, CUPID) returns (bool) {
        emit Pause();
        paused = true;

        return true;
    }


     
     
    function unpause() public whenPaused ifAuthorized(msg.sender, CUPID) returns (bool) {
        emit Unpause();
        paused = false;
    
        return true;
    }
}

 

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

     

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

 

 

pragma solidity ^0.4.21;

contract IERC20Basic {

    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

}

 

 

pragma solidity ^0.4.21;


contract IERC20 is IERC20Basic {

    function allowance(address _tokenholder, address _tokenspender) view public returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _tokenspender, uint256 _value) public returns (bool);
    event Approval(address indexed _tokenholder, address indexed _tokenspender, uint256 _value);

}

 

 

pragma solidity ^0.4.21;



 
contract RecoverCurrency is AuthorizedList, Authorized {

    event EtherRecovered(address indexed _to, uint256 _value);

    function recoverEther() external ifAuthorized(msg.sender, APHRODITE) {
        msg.sender.transfer(address(this).balance);
        emit EtherRecovered(msg.sender, address(this).balance);
    }

     
     
    function recoverToken(address _address) external ifAuthorized(msg.sender, APHRODITE) {
        require(_address != address(0));
        IERC20Basic token = IERC20Basic(_address);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}

 

 

pragma solidity ^0.4.21;


 
contract Freezable is AuthorizedList, Authorized {

    event Frozen(address indexed _account);
    event Unfrozen(address indexed _account);
    
    mapping (address => bool) public frozenAccounts;

     
    function Freezable() public AuthorizedList() Authorized() { }

     
    modifier notFrozen {
        require(!frozenAccounts[msg.sender]);
        _;
    }

     
    function isFrozen(address account) public view returns (bool) {
        return frozenAccounts[account];
    }

     
    function freezeAccount(address account) public ifAuthorized(msg.sender, APHRODITE) returns (bool success) {
        if (!frozenAccounts[account]) {
            frozenAccounts[account] = true;
            emit Frozen(account);
            success = true; 
        }
    }

     
    function unfreezeAccount(address account) public ifAuthorized(msg.sender, APHRODITE) returns (bool success) {
        if (frozenAccounts[account]) {
            frozenAccounts[account] = false;
            emit Unfrozen(account);
            success = true;
        }
    }
}

 

 

pragma solidity ^0.4.21;

contract AllowancesLedger {

    mapping (address => mapping (address => uint256)) public allowances;

}

 

 

pragma solidity ^0.4.21;


contract TokenLedger is AuthorizedList, Authorized {

    mapping(address => uint256) public balances;
    uint256 public totalsupply;

    struct SeenAddressRecord {
        bool seen;
        uint256 accountArrayIndex;
    }

     
    address[] internal accounts;
    mapping(address => SeenAddressRecord) internal seenBefore;

     
     
    function numberAccounts() public view ifAuthorized(msg.sender, APHRODITE) returns (uint256) {
        return accounts.length;
    }

     
    function returnAccounts() public view ifAuthorized(msg.sender, APHRODITE) returns (address[] holders) {
        return accounts;
    }

    function balanceOf(uint256 _id) public view ifAuthorized(msg.sender, CUPID) returns (uint256 balance) {
        require (_id < accounts.length);
        return balances[accounts[_id]];
    }
}

 

 

pragma solidity ^0.4.21;


contract TokenSettings is AuthorizedList, Authorized {

     
     
     

    string public name = "intimate";
    string public symbol = "ITM";

    uint256 public INITIAL_SUPPLY = 100000000 * 10**18;   
    uint8 public constant decimals = 18;


     
     
    function setName(string _name) public ifAuthorized(msg.sender, APHRODITE) {
        name = _name;
    }

     
     
    function setSymbol(string _symbol) public ifAuthorized(msg.sender, APHRODITE) {
        symbol = _symbol;
    }
}

 

 

pragma solidity ^0.4.21;





 
contract BasicTokenStorage is AuthorizedList, Authorized, TokenSettings, AllowancesLedger, TokenLedger {

     
    function BasicTokenStorage() public Authorized() TokenSettings() AllowancesLedger() TokenLedger() { }

     
     
    function trackAddresses(address _tokenholder) internal {
        if (!seenBefore[_tokenholder].seen) {
            seenBefore[_tokenholder].seen = true;
            accounts.push(_tokenholder);
            seenBefore[_tokenholder].accountArrayIndex = accounts.length - 1;
        }
    }

     
     
    function removeSeenAddress(address _tokenholder) internal {
        uint index = seenBefore[_tokenholder].accountArrayIndex;
        require(index < accounts.length);

        if (index != accounts.length - 1) {
            accounts[index] = accounts[accounts.length - 1];
        } 
        accounts.length--;
        delete seenBefore[_tokenholder];
    }
}

 

 

pragma solidity ^0.4.21;







contract BasicToken is IERC20Basic, BasicTokenStorage, Pausable, Freezable {

    using SafeMath for uint256;

    event Transfer(address indexed _tokenholder, address indexed _tokenrecipient, uint256 _value);
    event BulkTransfer(address indexed _tokenholder, uint256 _howmany);

     
    function totalSupply() public view whenNotPaused returns (uint256) {
        return totalsupply;
    }

     
     
     
    function transfer(address _to, uint256 _value) public whenNotPaused notFrozen returns (bool) {

         
        require(_to != address(0));

         
        require(msg.sender != _to);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);

        if (balances[msg.sender] == 0) {
            removeSeenAddress(msg.sender);
        }

         
        trackAddresses(_to);

         
        balances[_to] = balances[_to].add(_value);

         
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

     
     
     
    function bulkTransfer(address[] _tos, uint256[] _values) public whenNotPaused notFrozen ifAuthorized(msg.sender, BULKTRANSFER) returns (bool) {

        require (_tos.length == _values.length);

        uint256 sourceBalance = balances[msg.sender];

         
        balances[msg.sender] = 0;

        for (uint256 i = 0; i < _tos.length; i++) {
            uint256 currentValue = _values[i];
            address _to = _tos[i];
            require(_to != address(0));
            require(currentValue <= sourceBalance);
            require(msg.sender != _to);

            sourceBalance = sourceBalance.sub(currentValue);
            balances[_to] = balances[_to].add(currentValue);

            trackAddresses(_to);

            emit Transfer(msg.sender, _tos[i], currentValue);
        }

         
        balances[msg.sender] = sourceBalance;

        emit BulkTransfer(msg.sender, _tos.length);

        if (balances[msg.sender] == 0) {
            removeSeenAddress(msg.sender);
        }

        return true;
    }


     
     
     
    function balanceOf(address _tokenholder) public view whenNotPaused returns (uint256 balance) {
        require(!isFrozen(_tokenholder));
        return balances[_tokenholder];
    }
}

 

 

pragma solidity ^0.4.21;








contract StandardToken is IERC20Basic, BasicToken, IERC20 {

    using SafeMath for uint256;

    event Approval(address indexed _tokenholder, address indexed _tokenspender, uint256 _value);

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused notFrozen returns (bool) {

         
         
        require(_to != address(0) && _from != _to);

        require(!isFrozen(_from) && !isFrozen(_to));

         
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);

        balances[_from] = balances[_from].sub(_value);

         
        trackAddresses(_to);

        balances[_to] = balances[_to].add(_value);

         
        emit Transfer(_from, _to, _value);

        return true;
    }


     
     
     
    function approve(address _tokenspender, uint256 _value) public whenNotPaused notFrozen returns (bool) {

        require(_tokenspender != address(0) && msg.sender != _tokenspender);

        require(!isFrozen(_tokenspender));

         
         
         
        require((_value == 0) || (allowances[msg.sender][_tokenspender] == 0));

         
        allowances[msg.sender][_tokenspender] = _value;

         
        emit Approval(msg.sender, _tokenspender, _value);

        return true;
    }


     
     
     
     
    function allowance(address _tokenholder, address _tokenspender) public view whenNotPaused returns (uint256) {
        require(!isFrozen(_tokenholder) && !isFrozen(_tokenspender));
        return allowances[_tokenholder][_tokenspender];
    }
}

 

 

pragma solidity ^0.4.21;









contract IntimateShoppe is Pausable, RecoverCurrency {

    using SafeMath for uint256;

     
    address[] internal contributors;

     
    mapping (address => uint256[]) internal contributions;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
     
     
     
     
    event ITMTokenPurchase(address indexed _seller_wallet_address, address indexed _buyer_address, uint256 _value, uint256 _amount);

     
    event SetPeriod(uint256 _startTime, uint256 _endTime);


     
    StandardToken public token;

     
    address public token_address;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet_address;

     
    uint256 public rate = 600;

     
     
     
    uint256 public capTokens;

     
    uint256 public maxValue = 100 ether;

     
    uint256 public minValue = uint256(1 ether)/600;

     
    uint256 public weiRaised = 0;
    uint256 public tokensSold = 0;

     
    uint256 internal highWater = 1 ether;

     
    uint8 public round = 0;

     
     
     
    function IntimateShoppe(
        uint256 _startTime, 
        uint256 _duration, 
        uint256 _rate, 
        address _wallet_address, 
        address _token_address, 
        uint256 _cap,
        uint8 _round) public Authorized() {

        require(_startTime >= 0 && _duration > 0);
        require(_rate > 0);
        require(_wallet_address != address(0x0));
        require(_token_address != address(0x0));
        require(_cap > 0);

        round = _round;

        startTime = _startTime;
        endTime = startTime + _duration;

        rate = _rate;
        minValue = uint256(1 ether)/_rate;
        capTokens = _cap;
        wallet_address = _wallet_address;
        token_address = _token_address;
        token = StandardToken(token_address);
    }

     
     
     
    function trackContributions(address _sender, uint256 _value) internal {
        if (contributions[_sender].length == 0) {
            contributors.push(_sender);
        }
        contributions[_sender].push(_value);
    }

     
     
    function getContributors() external view ifAuthorized(msg.sender, APHRODITE) returns (address[]) {
        return contributors;
    }

     
     
     
     
     
    function getContributionsForAddress(address _contributor) external view ifAuthorized(msg.sender, APHRODITE) returns (uint256[]) {
        return contributions[_contributor];
    }

     
     
     
    function setRound(uint8 _round) public ifAuthorized(msg.sender, APHRODITE) {
        round = _round;
    }

     
     
    function setMaxValue(uint256 _maxValue) public ifAuthorized(msg.sender, APHRODITE) {
         
        require(now < startTime || now > endTime);
        maxValue = _maxValue;
    }

     
     
    function setMinValue(uint256 _minValue) public ifAuthorized(msg.sender, APHRODITE) {
         
        require(now < startTime || now > endTime);
        minValue = _minValue;
    }


     
     
     
    function setTimes(uint256 _startTime, uint256 _duration) public ifAuthorized(msg.sender, APHRODITE) {
         
        require(now < startTime || now > endTime);

        require(_startTime >= 0 && _duration > 0);
        startTime = _startTime;
        endTime = startTime + _duration;
        emit SetPeriod(startTime, endTime);
    }


     
     
    function setCap(uint256 _capTokens) public ifAuthorized(msg.sender, APHRODITE) {
         
        require(now < startTime || now > endTime);
        require(_capTokens > 0);
        capTokens = _capTokens;
    }

     
     
    function setRate(uint256 _rate) public ifAuthorized(msg.sender, APHRODITE) {
        require(_rate > 0);
        rate = _rate;
    }

     
     
    function changeCompanyWallet(address _wallet_address) public ifAuthorized(msg.sender, APHRODITE) {
        wallet_address = _wallet_address;
    }

     
     
    function getHighWater() public view ifAuthorized(msg.sender, APHRODITE) returns (uint256) {
        return highWater;
    }

     
     
    function setHighWater(uint256 _highWater) public ifAuthorized(msg.sender, APHRODITE) {
        highWater = _highWater;
    }


     
    function () payable public {
         
        require(msg.value >= minValue && msg.value <= maxValue);
        backTokenOwner();
    }

     
    function backTokenOwner() whenNotPaused internal {

         
        require(now >= startTime && now <= endTime);

         

        if (address(this).balance >= highWater) {
             
            wallet_address.transfer(address(this).balance);
            emit Transfer(this, wallet_address, address(this).balance);
        }

         
         
        trackContributions(msg.sender, msg.value);

        uint256 tokens = msg.value.mul(rate);

         

         
         
   
        if (token.transferFrom(wallet_address, msg.sender, tokens)) {

            token.freezeAccount(msg.sender);

            weiRaised = weiRaised.add(msg.value);
            tokensSold = tokensSold.add(tokens);
            emit ITMTokenPurchase(wallet_address, msg.sender, msg.value, tokens);

             
            require(tokensSold <= capTokens);
        }
    }
}