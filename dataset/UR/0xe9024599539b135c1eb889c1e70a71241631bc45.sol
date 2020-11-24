 

pragma solidity ^0.4.16;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }



contract ITUTokenERC20 is owned {
     
    string public name = "iTrue";
    string public symbol = "ITU";
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

    string public version = "0.1";

    bool public canTransfer = false;

    struct HoldBalance{
        uint256 amount;
        uint256 timeEnd;
    }

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => HoldBalance) public holdBalances;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= 32 * size + 4) ;
        _;
    }

     
    constructor() public {
        uint128 initialSupply = 8000000000;
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = "iTrue";                                    
        symbol = "ITU";                                
    }

    function tstart() onlyOwner public {
        canTransfer = true;
    }

    function tstop() onlyOwner public {
        canTransfer = false;
    }

    function availableBalance(address _owner) internal constant returns(uint256) {
        if (holdBalances[_owner].timeEnd <= now) {
            return balanceOf[_owner];
        } else {
            assert(balanceOf[_owner] >= holdBalances[_owner].amount);
            return balanceOf[_owner] - holdBalances[_owner].amount;
        }
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(canTransfer);
         
        require(_to != 0x0);

        require(availableBalance(_from) >= _value);

         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transferF(address _from, address _to, uint256 _value) onlyOwner onlyPayloadSize(3) public returns (bool success) {
        _transfer(_from, _to, _value);
        return true;
    }

    function transferHold(address _from, address _to, uint256 _value, uint256 _hold, uint256 _expire) onlyOwner onlyPayloadSize(5) public returns (bool success) {
        require(_hold <= _value);
         
        _transfer(_from, _to, _value);
         
        holdBalances[_to] = HoldBalance(_hold, _expire);
        return true;
    }

    function setHold(address _owner, uint256 _hold, uint256 _expire) onlyOwner onlyPayloadSize(3) public returns (bool success) {
        holdBalances[_owner] = HoldBalance(_hold, _expire);
        return true;
    }

     
    function getB(address _owner) onlyOwner onlyPayloadSize(1) public constant returns (uint256 balance) {
        return availableBalance(_owner);
    }

    function getHold(address _owner) onlyOwner onlyPayloadSize(1) public constant returns (uint256 hold, uint256 holdt, uint256 n) {
        return (holdBalances[_owner].amount, holdBalances[_owner].timeEnd, now);
    }
     

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) onlyPayloadSize(2) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}