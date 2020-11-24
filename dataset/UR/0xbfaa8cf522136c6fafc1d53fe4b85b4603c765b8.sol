 

contract ERC20Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

library SafeMathLib {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0 && a > 0);
         
        uint256 c = a / b;
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract StandardToken is ERC20Token {
    using SafeMathLib for uint;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value > 0 && balances[msg.sender] >= _value);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value > 0 && balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Winchain is StandardToken, Ownable {
    using SafeMathLib for uint256;

    uint256 INTERVAL_TIME = 63072000; 
    uint256 public deadlineToFreedTeamPool; 
    string public name = "Winchain";
    string public symbol = "WIN";
    uint256 public decimals = 18;
    uint256 public INITIAL_SUPPLY = (210) * (10 ** 8) * (10 ** 18); 

     
    uint256 winPoolForSecondStage;
     
    uint256 winPoolForThirdStage;
     
    uint256 winPoolToTeam;
     
    uint256 winPoolToWinSystem;

    event Freed(address indexed owner, uint256 value);

    function Winchain(){
        totalSupply = INITIAL_SUPPLY;
        deadlineToFreedTeamPool = INTERVAL_TIME.add(block.timestamp);

        uint256 peerSupply = totalSupply.div(100);
         
        balances[msg.sender] = peerSupply.mul(30);
         
        winPoolForSecondStage = peerSupply.mul(15);
         
        winPoolForThirdStage = peerSupply.mul(20);
         
        winPoolToTeam = peerSupply.mul(15);
         
        winPoolToWinSystem = peerSupply.mul(20);

    }

     
     
    function balanceWinPoolForSecondStage() public constant returns (uint256 remaining) {
        return winPoolForSecondStage;
    }

    function freedWinPoolForSecondStage() onlyOwner returns (bool success) {
        require(winPoolForSecondStage > 0);
        require(balances[msg.sender].add(winPoolForSecondStage) >= balances[msg.sender]
        && balances[msg.sender].add(winPoolForSecondStage) >= winPoolForSecondStage);

        balances[msg.sender] = balances[msg.sender].add(winPoolForSecondStage);
        Freed(msg.sender, winPoolForSecondStage);
        winPoolForSecondStage = 0;
        return true;
    }
     
    function balanceWinPoolForThirdStage() public constant returns (uint256 remaining) {
        return winPoolForThirdStage;
    }

    function freedWinPoolForThirdStage() onlyOwner returns (bool success) {
        require(winPoolForThirdStage > 0);
        require(balances[msg.sender].add(winPoolForThirdStage) >= balances[msg.sender]
        && balances[msg.sender].add(winPoolForThirdStage) >= winPoolForThirdStage);

        balances[msg.sender] = balances[msg.sender].add(winPoolForThirdStage);
        Freed(msg.sender, winPoolForThirdStage);
        winPoolForThirdStage = 0;
        return true;
    }
     
    function balanceWinPoolToTeam() public constant returns (uint256 remaining) {
        return winPoolToTeam;
    }

    function freedWinPoolToTeam() onlyOwner returns (bool success) {
        require(winPoolToTeam > 0);
        require(balances[msg.sender].add(winPoolToTeam) >= balances[msg.sender]
        && balances[msg.sender].add(winPoolToTeam) >= winPoolToTeam);

        require(block.timestamp >= deadlineToFreedTeamPool);

        balances[msg.sender] = balances[msg.sender].add(winPoolToTeam);
        Freed(msg.sender, winPoolToTeam);
        winPoolToTeam = 0;
        return true;
    }
     
    function balanceWinPoolToWinSystem() public constant returns (uint256 remaining) {
        return winPoolToWinSystem;
    }

    function freedWinPoolToWinSystem() onlyOwner returns (bool success) {
        require(winPoolToWinSystem > 0);
        require(balances[msg.sender].add(winPoolToWinSystem) >= balances[msg.sender]
        && balances[msg.sender].add(winPoolToWinSystem) >= winPoolToWinSystem);

        balances[msg.sender] = balances[msg.sender].add(winPoolToWinSystem);
        Freed(msg.sender, winPoolToWinSystem);
        winPoolToWinSystem = 0;
        return true;
    }

    function() public payable {
        revert();
    }

}