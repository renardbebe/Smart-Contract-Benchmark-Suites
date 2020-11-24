 

pragma solidity >=0.4.10;

contract Token {
    function transferFrom(address from, address to, uint amount) returns(bool);
    function transfer(address to, uint amount) returns(bool);
    function balanceOf(address addr) constant returns(uint);
}

contract Owned {
    address public owner;
    address public newOwner;

     
    event ChangedOwner(address indexed new_owner);

     

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _newOwner) onlyOwner external {
        newOwner = _newOwner;
    }

    function acceptOwnership() external {
        if (msg.sender == newOwner) {
            owner = newOwner;
            newOwner = 0x0;
            ChangedOwner(owner);
        }
    }
}

 
contract Savings is Owned {
     
    uint public periods;

     
    uint public t0special;

    uint constant public intervalSecs = 30 days;
    uint constant public precision = 10 ** 18;


     
    event Withdraws(address indexed who, uint amount);
    event Deposit(address indexed who, uint amount);

    bool public inited;
    bool public locked;
    uint public startBlockTimestamp = 0;

    Token public token;

     
    mapping (address => uint) public deposited;

     
    uint public totalfv;

     
    uint public remainder;

     
    uint public total;

     
    mapping (address => uint256) public withdrawn;

    bool public nullified;

    modifier notNullified() { require(!nullified); _; }

    modifier preLock() { require(!locked && startBlockTimestamp == 0); _; }

     
    modifier postLock() { require(locked); _; }

     
    modifier preStart() { require(locked && startBlockTimestamp == 0); _; }

     
    modifier postStart() { require(locked && startBlockTimestamp != 0); _; }

     
    modifier notInitialized() { require(!inited); _; }

     
    modifier initialized() { require(inited); _; }

     
    function() {
        revert();
    }

     
    function nullify() onlyOwner {
        nullified = true;
    }

     
    function init(uint _periods, uint _t0special) onlyOwner notInitialized {
        require(_periods != 0);
        periods = _periods;
        t0special = _t0special;
    }

    function finalizeInit() onlyOwner notInitialized {
        inited = true;
    }

    function setToken(address tok) onlyOwner {
        token = Token(tok);
    }

     
    function lock() onlyOwner {
        locked = true;
    }

     
    function start(uint _startBlockTimestamp) onlyOwner initialized preStart {
        startBlockTimestamp = _startBlockTimestamp;
        uint256 tokenBalance = token.balanceOf(this);
        total = tokenBalance;
        remainder = tokenBalance;
    }

     
    function isStarted() constant returns(bool) {
        return locked && startBlockTimestamp != 0;
    }

     
     

     
    function refundTokens(address addr, uint amount) onlyOwner preLock {
        token.transfer(addr, amount);
    }


     
    function updateTotal() onlyOwner postLock {
        uint current = token.balanceOf(this);
        require(current >= remainder);  

        uint difference = (current - remainder);
        total += difference;
        remainder = current;
    }

     
    function periodAt(uint _blockTimestamp) constant returns(uint) {
         
        if (startBlockTimestamp > _blockTimestamp)
            return 0;

         
        uint p = ((_blockTimestamp - startBlockTimestamp) / intervalSecs) + 1;
        if (p > periods)
            p = periods;
        return p;
    }

     
     
    function period() constant returns(uint) {
        return periodAt(block.timestamp);
    }

     
     
     
     
    function deposit(uint tokens) notNullified {
        depositTo(msg.sender, tokens);
    }


    function depositTo(address beneficiary, uint tokens) preLock notNullified {
        require(token.transferFrom(msg.sender, this, tokens));
        deposited[beneficiary] += tokens;
        totalfv += tokens;
        Deposit(beneficiary, tokens);
    }

     
    function bulkDepositTo(uint256[] bits) onlyOwner {
        uint256 lomask = (1 << 96) - 1;
        for (uint i=0; i<bits.length; i++) {
            address a = address(bits[i]>>96);
            uint val = bits[i]&lomask;
            depositTo(a, val);
        }
    }

     
     
    function withdraw() notNullified returns(bool) {
        return withdrawTo(msg.sender);
    }

     
    function availableForWithdrawalAt(uint256 blockTimestamp) constant returns (uint256) {
         
        return ((t0special + periodAt(blockTimestamp)) * precision) / (t0special + periods);
    }

     
    function _withdrawTo(uint _deposit, uint _withdrawn, uint _blockTimestamp, uint _total) constant returns (uint) {
        uint256 fraction = availableForWithdrawalAt(_blockTimestamp);

         
        uint256 withdrawable = ((_deposit * fraction * _total) / totalfv) / precision;

         
        if (withdrawable > _withdrawn) {
            return withdrawable - _withdrawn;
        }
        return 0;
    }

     
    function withdrawTo(address addr) postStart notNullified returns (bool) {
        uint _d = deposited[addr];
        uint _w = withdrawn[addr];

        uint diff = _withdrawTo(_d, _w, block.timestamp, total);

         
        if (diff == 0) {
            return false;
        }

         
        require((diff + _w) <= ((_d * total) / totalfv));

         
        require(token.transfer(addr, diff));

        withdrawn[addr] += diff;
        remainder -= diff;
        Withdraws(addr, diff);
        return true;
    }

     
    function bulkWithdraw(address[] addrs) notNullified {
        for (uint i=0; i<addrs.length; i++)
            withdrawTo(addrs[i]);
    }

     
     
     
     
     
    uint public mintingNonce;
    function multiMint(uint nonce, uint256[] bits) onlyOwner preLock {

        if (nonce != mintingNonce) return;
        mintingNonce += 1;
        uint256 lomask = (1 << 96) - 1;
        uint sum = 0;
        for (uint i=0; i<bits.length; i++) {
            address a = address(bits[i]>>96);
            uint value = bits[i]&lomask;
            deposited[a] += value;
            sum += value;
            Deposit(a, value);
        }
        totalfv += sum;
    }
}