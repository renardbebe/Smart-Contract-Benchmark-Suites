 

pragma solidity ^0.4.15;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract IRntToken {
    uint256 public decimals = 18;

    uint256 public totalSupply = 1000000000 * (10 ** 18);

    string public name = "RNT Token";

    string public code = "RNT";


    function balanceOf() public constant returns (uint256 balance);

    function transfer(address _to, uint _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
}

contract RntToken is IRntToken {
    using SafeMath for uint256;

    address public owner;

     
    address public releaseAgent;

     
    bool public released = false;

     
    mapping (address => bool) public transferAgents;

    mapping (address => mapping (address => uint256)) public allowed;

    mapping (address => uint256) public balances;

    bool public paused = false;

    event Pause();

    event Unpause();

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Transfer(address indexed _from, address indexed _to, uint _value);

    function RntToken() payable {
        require(msg.value == 0);
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    modifier canTransfer(address _sender) {
        require(released || transferAgents[_sender]);
        _;
    }

     
    modifier inReleaseState(bool releaseState) {
        require(releaseState == released);
        _;
    }

     
    modifier onlyReleaseAgent() {
        require(msg.sender == releaseAgent);
        _;
    }

     
    function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

         
        releaseAgent = addr;
    }

     
    function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
        transferAgents[addr] = state;
    }

     
    function releaseTokenTransfer() public onlyReleaseAgent {
        released = true;
    }

    function transfer(address _to, uint _value) public canTransfer(msg.sender) whenNotPaused returns (bool success) {
        require(_to != address(0));

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public canTransfer(_from) whenNotPaused returns (bool success) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function balanceOf() public constant returns (uint256 balance) {
        return balances[msg.sender];
    }


     


     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }

     
     

     
    function() external {
    }
}