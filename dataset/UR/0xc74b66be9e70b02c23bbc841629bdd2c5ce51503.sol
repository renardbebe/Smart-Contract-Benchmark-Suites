 

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

contract TokenERC20 is owned {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    struct freezeAccountInfo{
        uint256 freezeStartTime;
        uint256 freezePeriod;
        uint256 freezeAmount;
    }

    mapping (address => freezeAccountInfo) public freezeAccount;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

    function issueAndFreeze(address _to, uint _value, uint _freezePeriod) onlyOwner public {
        _transfer(msg.sender, _to, _value);

        freezeAccount[_to] = freezeAccountInfo({
            freezeStartTime : now,
            freezePeriod : _freezePeriod,
            freezeAmount : _value
        });
    }

    function getFreezeInfo(address _target) view 
        public returns(
            uint _freezeStartTime,
            uint _freezePeriod, 
            uint _freezeAmount, 
            uint _freezeDeadline) {
        freezeAccountInfo storage targetFreezeInfo = freezeAccount[_target];
        return (targetFreezeInfo.freezeStartTime, 
        targetFreezeInfo.freezePeriod,
        targetFreezeInfo.freezeAmount,
        targetFreezeInfo.freezeStartTime + targetFreezeInfo.freezePeriod * 1 minutes);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);

         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);

         
        uint256 freezeStartTime;
        uint256 freezePeriod;
        uint256 freezeAmount;
        uint256 freezeDeadline;

        (freezeStartTime,freezePeriod,freezeAmount,freezeDeadline) = getFreezeInfo(_from);
         
        uint256 freeAmountFrom = balanceOf[_from] - freezeAmount;

        require(freezeStartTime == 0 ||  
        freezeDeadline < now ||  
        (freeAmountFrom >= _value));  

         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
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
}