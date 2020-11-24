 

pragma solidity ^0.4.21;


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

     
    function rescueTokens(ERC20Basic _token) external onlyOwner {
        uint256 balance = _token.balanceOf(this);
        assert(_token.transfer(owner, balance));
    }

     
    function withdrawEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    uint256 totalSupply_;

    mapping(address => uint256) balances;
    mapping(address => uint256) lockedBalanceMap;     
    mapping(address => uint256) releaseTimeMap;       

    event BalanceLocked(address indexed _addr, uint256 _amount);


     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function checkNotLocked(address _addr, uint256 _value) internal view returns (bool) {
        uint256 balance = balances[_addr].sub(_value);
        if (releaseTimeMap[_addr] > block.timestamp && balance < lockedBalanceMap[_addr]) {
            revert();
        }
        return true;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        checkNotLocked(msg.sender, _value);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function lockedBalanceOf(address _owner) public view returns (uint256) {
        return lockedBalanceMap[_owner];
    }

     
    function releaseTimeOf(address _owner) public view returns (uint256) {
        return releaseTimeMap[_owner];
    }
}


 
contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        checkNotLocked(_from, _value);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}


 
contract AbstractToken is Ownable, StandardToken {
    string public name;
    string public symbol;
    uint256 public decimals;

    string public value;         
    string public description;   
    string public website;       
    string public email;         
    string public news;          
    uint256 public cap;          


    mapping (address => bool) public mintAgents;   

    event Mint(address indexed _to, uint256 _amount);
    event MintAgentChanged(address _addr, bool _state);
    event NewsPublished(string _news);


     
    function setInfo(string _description, string _website, string _email) external onlyOwner returns (bool) {
        description = _description;
        website = _website;
        email = _email;
        return true;
    }

     
    function setNews(string _news) external onlyOwner returns (bool) {
        news = _news;
        emit NewsPublished(_news);
        return true;
    }

     
    function setMintAgent(address _addr, bool _state) onlyOwner public returns (bool) {
        mintAgents[_addr] = _state;
        emit MintAgentChanged(_addr, _state);
        return true;
    }

     
    constructor() public {
        setMintAgent(msg.sender, true);
    }
}


 
contract VNETToken is Ownable, AbstractToken {
    event Donate(address indexed _from, uint256 _amount);


     
    constructor() public {
        name = "VNET Token";
        symbol = "VNET";
        decimals = 6;
        value = "1 Token = 100 GByte client newtwork traffic flow";

         
        cap = 35000000000 * (10 ** decimals);
    }

     
    function () public payable {
        emit Donate(msg.sender, msg.value);
    }

     
    function mint(address _to, uint256 _amount) external returns (bool) {
        require(mintAgents[msg.sender] && totalSupply_.add(_amount) <= cap);

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function mintWithLock(address _to, uint256 _amount, uint256 _lockedAmount, uint256 _releaseTime) external returns (bool) {
        require(mintAgents[msg.sender] && totalSupply_.add(_amount) <= cap);
        require(_amount >= _lockedAmount);

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        lockedBalanceMap[_to] = lockedBalanceMap[_to] > 0 ? lockedBalanceMap[_to].add(_lockedAmount) : _lockedAmount;
        releaseTimeMap[_to] = releaseTimeMap[_to] > 0 ? releaseTimeMap[_to] : _releaseTime;
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        emit BalanceLocked(_to, _lockedAmount);
        return true;
    }
}