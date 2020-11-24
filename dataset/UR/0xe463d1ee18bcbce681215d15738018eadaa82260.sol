 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
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

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract FIICToken is Ownable {
    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint8 public decimals = 0;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    struct LockFund {
        uint256 amount;
        uint256 startTime;
        uint256 lockUnit;
        uint256 times;
        bool recyclable;
    }
    mapping (address => LockFund) public lockFunds;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    event LockTransfer(address indexed acc, uint256 amount, uint256 startTime, uint256 lockUnit, uint256 times);
    
     
    event recycleToke(address indexed acc, uint256 amount, uint256 startTime);

     
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                     
        name = tokenName;                                        
        symbol = tokenSymbol;                                    
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != address(0x0),"目的地址不能为空");
        
        require(_from != _to,"自己不能给自己转账");
        
         
        require(balanceOf[_from] - getLockedAmount(_from) >= _value,"转账的数量不能超过可用的数量");
         
        require(balanceOf[_to] + _value > balanceOf[_to],"转账的数量有问题");
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances); 
        
        
    }

    function getLockedAmount(address _from) public view returns (uint256 lockAmount) {
        LockFund memory lockFund = lockFunds[_from];
        if(lockFund.amount > 0) {
            if(block.timestamp <= lockFund.startTime) {
                return lockFund.amount;
            }
            uint256 ap = lockFund.amount.div(lockFund.times);
             
             
            uint256 t = (block.timestamp.sub(lockFund.startTime)).div(lockFund.lockUnit);
 
            if(t < lockFund.times) {
                return lockFund.amount.sub(ap.mul(t));
            }
        }
        return 0;
    }
    
    function getReleaseAmount(address _from) public view returns (uint256 releaseAmount) {
       LockFund memory lockFund = lockFunds[_from];
        if(lockFund.amount > 0) {
            if(block.timestamp <= lockFund.startTime) {
                return 0;
            }
            uint256 ap = lockFund.amount / lockFund.times;
            uint256 t = (block.timestamp - lockFund.startTime) / lockFund.lockUnit;
            if(t>= lockFund.times){
                return lockFund.amount;
            }
            return ap * t;
        }
        return balanceOf[_from];
        
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
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
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
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

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }

     
    function lockTransfer(address _lockAddress, uint256 _lockAmount, uint256 _startReleaseTime, uint256 _releaseInterval, uint256 _releaseTimes,bool _recyclable) onlyOwner public {
         
        _transfer(msg.sender, _lockAddress, _lockAmount);
         
        LockFund storage lockFund = lockFunds[_lockAddress];
        lockFund.amount = _lockAmount;
        lockFund.startTime = _startReleaseTime;
        lockFund.lockUnit = _releaseInterval;
        lockFund.times = _releaseTimes;
        lockFund.recyclable = _recyclable;

        emit LockTransfer(_lockAddress, _lockAmount, _startReleaseTime, _releaseInterval, _releaseTimes);
    }
    
     
    function recycleRemainingToken(address _lockAddress) onlyOwner public{
         
        LockFund storage lockFund = lockFunds[_lockAddress];
        require(lockFund.recyclable == true,"该地址不支持撤销操作");
        
        uint256 remaingCount = getLockedAmount(_lockAddress);
        
         
        require(balanceOf[owner()] + remaingCount > balanceOf[owner()],"转账的数量有问题");
         
        uint previousBalances = balanceOf[owner()] + balanceOf[_lockAddress];
         
        balanceOf[_lockAddress] -= remaingCount;
         
        balanceOf[owner()] += remaingCount;
            
        lockFund.amount = 0;
        
        emit recycleToke(_lockAddress,remaingCount,block.timestamp);
        emit Transfer(_lockAddress, owner(), remaingCount);
         
        assert(balanceOf[owner()] + balanceOf[_lockAddress] == previousBalances); 
        
    }
}