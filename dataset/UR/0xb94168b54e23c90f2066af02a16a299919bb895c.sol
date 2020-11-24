 

pragma solidity ^0.4.25;


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
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


 
contract Ownable {
    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


 
contract Haltable is Ownable {
    bool public halted;

    modifier inNormalState {
        require(!halted);
        _;
    }

    modifier inEmergencyState {
        require(halted);
        _;
    }

     
    function halt() external onlyOwner inNormalState {
        halted = true;
    }

     
    function resume() external onlyOwner inEmergencyState {
        halted = false;
    }

}


 
contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}


 
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) public allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 _allowance;
        _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


 
contract Burnable is StandardToken {
    using SafeMath for uint;

     
    event Burn(address indexed from, uint256 value);

    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
         
        balances[msg.sender] = balances[msg.sender].sub(_value);
         
        totalSupply = totalSupply.sub(_value);
         
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
         
        require(_value <= allowed[_from][msg.sender]);
         
        balances[_from] = balances[_from].sub(_value);
         
        totalSupply = totalSupply.sub(_value);
         
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(_to != 0x0);
         

        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_to != 0x0);
         

        return super.transferFrom(_from, _to, _value);
    }
}


 
contract Centive is Burnable, Ownable {

    string public name;
    string public symbol;
    uint8 public decimals = 18;

     
    address public releaseAgent;

     
    bool public released = false;

     
    mapping(address => bool) public transferAgents;

     
    modifier canTransfer(address _sender) {
        require(transferAgents[_sender] || released);
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

     
    constructor(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
         
        balances[msg.sender] = totalSupply;
         
        name = tokenName;
         
        symbol = tokenSymbol;
         
    }

     
    function setReleaseAgent(address addr) external onlyOwner inReleaseState(false) {

         
        releaseAgent = addr;
    }

    function release() external onlyReleaseAgent inReleaseState(false) {
        released = true;
    }

     
    function setTransferAgent(address addr, bool state) external onlyOwner inReleaseState(false) {
        transferAgents[addr] = state;
    }

    function transfer(address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
         
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public canTransfer(_from) returns (bool success) {
         
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value) public onlyOwner returns (bool success) {
        return super.burn(_value);
    }

    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
        return super.burnFrom(_from, _value);
    }
}