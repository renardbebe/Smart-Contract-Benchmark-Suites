 

 

pragma solidity ^0.4.16;

 
contract owned {
    address public owner;

    function owned() public {
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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

 
 
contract TokenERC20 {
    uint256 public totalSupply;
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
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

     
    function burn(uint256 _value) public returns (bool success) {
         
        require(balanceOf[msg.sender] >= _value);
         
        balanceOf[msg.sender] -= _value;
         
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
         
        require(balanceOf[_from] >= _value);
         
        require(_value <= allowance[_from][msg.sender]);
         
        balanceOf[_from] -= _value;
         
        allowance[_from][msg.sender] -= _value;
         
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}

 
 
 

 
contract TosToken is owned, TokenERC20 {

     
    string public constant name = "ThingsOpreatingSystem";
     
    string public constant symbol = "TOS";
     
    uint8 public constant decimals = 18;


    uint256 public totalSupply = 1000000000 * 10 ** uint256(decimals);
     
    uint256 public MAX_FUNDING_SUPPLY = totalSupply * 500 / 1000;

     
     
    address public lockJackpots;
     
     
     
    uint256 public remainingReward;

     
    uint256 public lockStartTime = 1521043200;
     
    uint256 public lockDeadline = 1524931200;
     
    uint256 public unLockTime = 1544803200;

     
    uint public constant NUM_OF_PHASE = 3;
    uint[3] public lockRewardsPercentages = [
        1000,    
        500,     
        300     
    ];

     
    mapping (address => uint256) public lockBalanceOf;

     
     
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

     
    function TosToken() public {
         
        balanceOf[msg.sender] = totalSupply;
    }

     
    function transfer(address _to, uint256 _value) public {
         
        require(!(lockJackpots != 0x0 && msg.sender == lockJackpots));

         
        if (lockJackpots != 0x0 && _to == lockJackpots) {
            _lockToken(_value);
        }
        else {
             
            if (unLockTime <= now && lockBalanceOf[msg.sender] > 0) {
                lockBalanceOf[msg.sender] = 0;
            }

            _transfer(msg.sender, _to, _value);
        }
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(lockBalanceOf[_from] + _value > lockBalanceOf[_from]);
         
        require(balanceOf[_from] >= lockBalanceOf[_from] + _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        require(!frozenAccount[_from]);
         
        require(!frozenAccount[_to]);
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }

     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
    function increaseLockReward(uint256 _value) public{
        require(_value > 0);
        _transfer(msg.sender, lockJackpots, _value * 10 ** uint256(decimals));
        _calcRemainReward();
    }

     
    function _lockToken(uint256 _lockValue) internal {
         
        require(lockJackpots != 0x0);
        require(now >= lockStartTime);
        require(now <= lockDeadline);
        require(lockBalanceOf[msg.sender] + _lockValue > lockBalanceOf[msg.sender]);
         
        require(balanceOf[msg.sender] >= lockBalanceOf[msg.sender] + _lockValue);

        uint256 _reward =  _lockValue * _calcLockRewardPercentage() / 1000;
         
        _transfer(lockJackpots, msg.sender, _reward);

         
        lockBalanceOf[msg.sender] += _lockValue + _reward;
        _calcRemainReward();
    }

    uint256 lockRewardFactor;
     
    function _calcLockRewardPercentage() internal returns (uint factor){

        uint phase = NUM_OF_PHASE * (now - lockStartTime)/( lockDeadline - lockStartTime);
        if (phase  >= NUM_OF_PHASE) {
            phase = NUM_OF_PHASE - 1;
        }
    
        lockRewardFactor = lockRewardsPercentages[phase];
        return lockRewardFactor;
    }

     
    function rewardActivityEnd() onlyOwner public {
         
        require(unLockTime < now);
         
        _transfer(lockJackpots, owner, balanceOf[lockJackpots]);
        _calcRemainReward();
    }

    function() payable public {}

     
    function setLockJackpots(address newLockJackpots) onlyOwner public {
        require(lockJackpots == 0x0 && newLockJackpots != 0x0 && newLockJackpots != owner);
        lockJackpots = newLockJackpots;
        _calcRemainReward();
    }

     
    function _calcRemainReward() internal {
        remainingReward = balanceOf[lockJackpots];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(_from != lockJackpots);
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        require(msg.sender != lockJackpots);
        return super.approve(_spender, _value);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        require(msg.sender != lockJackpots);
        return super.approveAndCall(_spender, _value, _extraData);
    }

    function burn(uint256 _value) public returns (bool success) {
        require(msg.sender != lockJackpots);
        return super.burn(_value);
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_from != lockJackpots);
        return super.burnFrom(_from, _value);
    }
}