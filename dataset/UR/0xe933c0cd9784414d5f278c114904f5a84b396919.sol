 

pragma solidity 0.4.20;


contract WhoVote {

    mapping (address => bytes32) public voteHash;
    address public parentContract;
    uint public deadline;

    modifier isActive {
        require(now < deadline);
        _;
    }

    modifier isParent {
        require(msg.sender == parentContract);
        _;
    }

    function WhoVote(address _parentContract, uint timespan) public {
        parentContract = _parentContract;
        deadline = now + timespan;
    }

     
    function recieveVote(address _sender, bytes32 _hash) public isActive isParent returns (bool) {
        require(voteHash[_sender] == 0);
        voteHash[_sender] = _hash;
        return true;
    }


}


 
library SafeMath {

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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
 
contract ERC20Interface {
    function circulatingSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    event TransferEvent(address indexed from, address indexed to, uint value);
}


 
contract StandardToken is ERC20Interface {
    using SafeMath for uint;

    uint public maxSupply;
    uint public totalSupply;
    uint public timestampMint;
    uint public timestampRelease;
    uint8 public decimals;

    string public symbol;
    string public  name;

    address public owner;

    bool public stopped;

    mapping(address => uint) public balanceOf;
    mapping (address => uint) public permissonedAccounts;

     
    modifier onlyAfter() {
        require(now >= timestampMint + 3 weeks);
        _;
    }

     
    modifier isActive() {
        require(!stopped);
        _;
    }

     
    modifier hasPermission(uint _level) {
        require(permissonedAccounts[msg.sender] > 0);
        require(permissonedAccounts[msg.sender] <= _level);
        _;
    }

     
    function circulatingSupply() public view returns (uint) {
        return totalSupply;
    }

     
    function balanceOf(address _owner) public view returns (uint balance) {
        return balanceOf[_owner];
    }

     
    function transfer(address _to, uint _value) public isActive returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf[msg.sender]);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        TransferEvent(msg.sender, _to, _value);
        return true;
    }
}


 
contract Who is StandardToken {

    mapping (address => uint) public votings_;
    mapping (address => uint8) public icoAccounts;
    address public prizePool;
    uint public icoPool;
    uint public raisedIcoValue;
    uint public maxMint;


    event WinningEvent(address[] winner, address contest, uint payoutValue);
    event VotingStarted(address _voting, uint _duration, uint _costPerVote);
    event ParticipatedInVoting(address _sender, address _votingContract, bytes32 _hash, uint _voteAmount);

    modifier icoPhase() {
        require(now >= timestampRelease);
        require(now <= 3 weeks + timestampRelease);
        require(msg.value >= 2*(10**16));
        _;

    }

    function Who() public {
        owner = 0x4c556b28A7D62D3b7A84481521308fbb9687f38F;

        name = "WhoHas";
        symbol = "WHO";
        decimals = 18;

        permissonedAccounts[owner] = 1;
        permissonedAccounts[0x3090Ee894719222DCE4d231d735741B2d44f30ba] = 1;
        timestampRelease = now + 6 hours + 40 minutes;

        balanceOf[owner] = 150000000*(10**18);  
        icoPool = 100000000*(10**18);  
        maxSupply = 1500000000*(10**18);  
        maxMint = 150000*(10**18);  
        totalSupply = totalSupply.add(balanceOf[owner]);  

        stopped = false;
    }

     
    function icoBuy() public icoPhase() payable isActive {
        prizePool.transfer(msg.value);
        raisedIcoValue = raisedIcoValue.add(msg.value);
        uint256 tokenAmount = calculateTokenAmountICO(msg.value);

        require(icoPool >= tokenAmount);

        icoPool = icoPool.sub(tokenAmount);
        balanceOf[msg.sender] += tokenAmount;
        TransferEvent(prizePool, msg.sender, tokenAmount);
        totalSupply = totalSupply.add(tokenAmount);
    }

     
    function calculateTokenAmountICO(uint256 _etherAmount) public icoPhase constant returns(uint256) {
           
           
        if (now <= 10 days + timestampRelease) {
            require(icoAccounts[msg.sender] == 1);
            return _etherAmount.mul(4420);
        } else {
            require(icoAccounts[msg.sender] == 2);
            return _etherAmount.mul(3315);
        }
    }

     
    function killToken() public isActive hasPermission(1) {
        stopped = true;
    }

     
    function updatePermissions(address _account, uint _level) public isActive hasPermission(1) {
        require(_level != 1 && msg.sender != _account);
        permissonedAccounts[_account] = _level;
    }

     
    function updatePrizePool(address _account) public isActive hasPermission(1) {
        prizePool = _account;
    }

     
    function mint(uint _mintAmount) public onlyAfter isActive hasPermission(2) {
        require(_mintAmount <= maxMint);
        require(totalSupply + _mintAmount <= maxSupply);
        balanceOf[owner] = balanceOf[owner].add(_mintAmount);
        totalSupply = totalSupply.add(_mintAmount);
        timestampMint = now;
    }

    function registerForICO(address[] _icoAddresses, uint8 _level) public isActive hasPermission(3) {
        for (uint i = 0; i < _icoAddresses.length; i++) {
            icoAccounts[_icoAddresses[i]] = _level;
        }
    }

     
    function gernerateVoting(uint _timespan, uint _votePrice) public isActive hasPermission(3) {
        require(_votePrice > 0 && _timespan > 0);
        address generatedVoting = new WhoVote(this, _timespan);
        votings_[generatedVoting] = _votePrice;
        VotingStarted(generatedVoting, _timespan, _votePrice);
    }

     
    function addVoting(address _votingContract, uint _votePrice) public isActive hasPermission(3) {
        votings_[_votingContract] = _votePrice;
    }

     
    function finalizeVoting(address _votingContract) public isActive hasPermission(3) {
        votings_[_votingContract] = 0;
    }

     
    function payout(address[] _winner, uint _payoutValue, address _votingAddress) public isActive hasPermission(3) {
        for (uint i = 0; i < _winner.length; i++) {
            transfer(_winner[i], _payoutValue);
        }
        WinningEvent(_winner, _votingAddress, _payoutValue);
    }

     
    function payForVote(address _votingContract, bytes32 _hash, uint _quantity) public isActive {
        require(_quantity >= 1 && _quantity <= 5);
        uint votePrice = votings_[_votingContract];
        require(votePrice > 0);
        transfer(prizePool, _quantity.mul(votePrice));
        sendVote(_votingContract, msg.sender, _hash);
        ParticipatedInVoting(msg.sender, _votingContract, _hash, _quantity);
    }

     
    function sendVote(address _contract, address _sender, bytes32 _hash) private returns (bool) {
        return WhoVote(_contract).recieveVote(_sender, _hash);
    }

}