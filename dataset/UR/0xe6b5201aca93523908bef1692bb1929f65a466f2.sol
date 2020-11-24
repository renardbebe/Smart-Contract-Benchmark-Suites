 

pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

}

 
 
 
 
 
 
contract IscToken {

     
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint value);
	event Owner(address indexed from, address indexed to);
    event TransferEdrIn(address indexed from, uint value);
    event TransferEdrOut(address indexed from, uint value);

     
    using SafeMath for uint;

     
    address public owner;
    bool public frozen = false;  

     
    uint8 constant public decimals = 5;
    uint public totalSupply = 1000 * 10 ** (8+uint256(decimals));   
    string constant public name = "ISChain Token";
    string constant public symbol = "ISC";

    mapping(address => uint) ownerance;  
    mapping(address => mapping(address => uint)) public allowance;  

     
    address private EDRADDR  = 0x245580fc423Bd82Ab531d325De0Ba5ff8Ec79402;

    uint public edrBalance;  
    uint public totalCirculating;  


     
     
    modifier onlyPayloadSize(uint size) {
      assert(msg.data.length == size + 4);
      _;
    }

     
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isNotFrozen() {
        require(!frozen);
        _;
    }

     
    modifier hasEnoughBalance(uint _amount) {
        require(ownerance[msg.sender] >= _amount);
        _;
    }

    modifier overflowDetected(address _owner, uint _amount) {
        require(ownerance[_owner] + _amount >= ownerance[_owner]);
        _;
    }

    modifier hasAllowBalance(address _owner, address _allower, uint _amount) {
        require(allowance[_owner][_allower] >= _amount);
        _;
    }

    modifier isNotEmpty(address _addr, uint _value) {
        require(_addr != address(0));
        require(_value != 0);
        _;
    }

    modifier isValidAddress {
        assert(0x0 != msg.sender);
        _;
    }

     
    constructor() public {
        owner = msg.sender;
        ownerance[EDRADDR] = totalSupply;
        edrBalance = totalSupply;
        totalCirculating = 0;
        emit Transfer(address(0), EDRADDR, totalSupply);
    }


     
    function approve(address _spender, uint _value)
        isNotFrozen
        isValidAddress
        public returns (bool success)
    {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);  
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value)
        isNotFrozen
        isValidAddress
        overflowDetected(_to, _value)
        public returns (bool success)
    {
        require(ownerance[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);

        ownerance[_to] = ownerance[_to].add(_value);
        ownerance[_from] = ownerance[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public
        constant returns (uint balance)
    {
        return ownerance[_owner];
    }

    function transfer(address _to, uint _value) public
        isNotFrozen
        isValidAddress
        isNotEmpty(_to, _value)
        hasEnoughBalance(_value)
        overflowDetected(_to, _value)
        onlyPayloadSize(2 * 32)
        returns (bool success)
    {
        ownerance[msg.sender] = ownerance[msg.sender].sub(_value);
        ownerance[_to] = ownerance[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        if (msg.sender == EDRADDR) {
            totalCirculating = totalCirculating.add(_value);
            edrBalance = totalSupply - totalCirculating;
            emit TransferEdrOut(_to, _value);
        }
        if (_to == EDRADDR) {
            totalCirculating = totalCirculating.sub(_value);
            edrBalance = totalSupply - totalCirculating;
            emit TransferEdrIn(_to, _value);
        }
        return true;
    }

     
    function transferOwner(address _newOwner)
        isOwner
        public returns (bool success)
    {
        if (_newOwner != address(0)) {
            owner = _newOwner;
            emit Owner(msg.sender, owner);
        }
        return true;
    }

    function freeze()
        isOwner
        public returns (bool success)
    {
        frozen = true;
        return true;
    }

    function unfreeze()
        isOwner
        public returns (bool success)
    {
        frozen = false;
        return true;
    }

    function burn(uint _value)
        isNotFrozen
        isValidAddress
        hasEnoughBalance(_value)
        public returns (bool success)
    {
        ownerance[msg.sender] = ownerance[msg.sender].sub(_value);
        ownerance[0x0] = ownerance[0x0].add(_value);
        totalSupply = totalSupply.sub(_value);
        totalCirculating = totalCirculating.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function transferMultiple(address[] _dests, uint[] _values)
        isNotFrozen
        isValidAddress
        public returns (uint)
    {
        uint i = 0;
        if (msg.sender == EDRADDR) {
            while (i < _dests.length) {
                require(ownerance[msg.sender] >= _values[i]);
                ownerance[msg.sender] = ownerance[msg.sender].sub(_values[i]);
                ownerance[_dests[i]] = ownerance[_dests[i]].add(_values[i]);
                totalCirculating = totalCirculating.add(_values[i]);
                emit Transfer(msg.sender, _dests[i], _values[i]);
                emit TransferEdrOut(_dests[i], _values[i]);
                i += 1;
            }
            edrBalance = totalSupply - totalCirculating;
        } else {
            while (i < _dests.length) {
                require(ownerance[msg.sender] >= _values[i]);
                ownerance[msg.sender] = ownerance[msg.sender].sub(_values[i]);
                ownerance[_dests[i]] = ownerance[_dests[i]].add(_values[i]);
                emit Transfer(msg.sender, _dests[i], _values[i]);
                i += 1;
            }
        }
        return(i);
    }

     
    function transferEdrAddr(address _newEddr)
        isOwner
        isValidAddress
        onlyPayloadSize(32)
        public returns (bool success)
    {
        if (_newEddr != address(0)) {
            address _oldaddr = EDRADDR;
            ownerance[_newEddr] = ownerance[EDRADDR];
            ownerance[EDRADDR] = 0;
            EDRADDR = _newEddr;
            emit Transfer(_oldaddr, EDRADDR, ownerance[_newEddr]);
        }
        return true;
    }


}