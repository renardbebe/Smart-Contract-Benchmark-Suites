 

pragma solidity ^0.4.21;

contract Owned {
    
     
     
    address public owner;
    address internal newOwner;
    
     
    function Owned() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    event updateOwner(address _oldOwner, address _newOwner);
    
     
    function changeOwner(address _newOwner) public onlyOwner returns(bool) {
        require(owner != _newOwner);
        newOwner = _newOwner;
        return true;
    }
    
     
    function acceptNewOwner() public returns(bool) {
        require(msg.sender == newOwner);
        emit updateOwner(owner, newOwner);
        owner = newOwner;
        return true;
    }
    
}

 
library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
        return c;
    }
    
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Token {
     
     
    uint256 public totalSupply;
    
     
    mapping (address => uint256) public balances;
    
     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);
    
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Controlled is Owned, ERC20Token {
    using SafeMath for uint;
    uint256 public releaseStartTime;
    uint256 oneMonth = 3600 * 24 * 30;
    
     
    bool  public emergencyStop = false;
    
    struct userToken {
        uint256 UST;
        uint256 addrLockType;
    }
    mapping (address => userToken) public userReleaseToken;
    
    modifier canTransfer {
        require(emergencyStop == false);
        _;
    }
    
    modifier releaseTokenValid(address _user, uint256 _time, uint256 _value) {
		uint256 _lockTypeIndex = userReleaseToken[_user].addrLockType;
		if(_lockTypeIndex != 0) {
			require (balances[_user].sub(_value) >= userReleaseToken[_user].UST.sub(calcReleaseToken(_user, _time, _lockTypeIndex)));
        }
        
		_;
    }
    
    
    function canTransferUST(bool _bool) public onlyOwner{
        emergencyStop = _bool;
    }
    
     
     
     
     
     
    function calcReleaseToken(address _user, uint256 _time, uint256 _lockTypeIndex) internal view returns (uint256) {
        uint256 _timeDifference = _time.sub(releaseStartTime);
        uint256 _whichPeriod = getPeriod(_lockTypeIndex, _timeDifference);
        
        if(_lockTypeIndex == 1) {
            
            return (percent(userReleaseToken[_user].UST, 25) + percent(userReleaseToken[_user].UST, _whichPeriod.mul(25)));
        }
        
        if(_lockTypeIndex == 2) {
            return (percent(userReleaseToken[_user].UST, 25) + percent(userReleaseToken[_user].UST, _whichPeriod.mul(25)));
        }
        
        if(_lockTypeIndex == 3) {
            return (percent(userReleaseToken[_user].UST, 10) + percent(userReleaseToken[_user].UST, _whichPeriod.mul(15)));
        }
		
		revert();
    
    }
    
     
     
     
     
    function getPeriod(uint256 _lockTypeIndex, uint256 _timeDifference) internal view returns (uint256) {
        if(_lockTypeIndex == 1) {            
            uint256 _period1 = (_timeDifference.div(oneMonth)).div(12);
            if(_period1 >= 3){
                _period1 = 3;
            }
            return _period1;
        }
        if(_lockTypeIndex == 2) {            
            uint256 _period2 = _timeDifference.div(oneMonth);
            if(_period2 >= 3){
                _period2 = 3;
            }
            return _period2;
        }
        if(_lockTypeIndex == 3) {            
            uint256 _period3 = _timeDifference.div(oneMonth);
            if(_period3 >= 6){
                _period3 = 6;
            }
            return _period3;
        }
		
		revert();
    }
    
    function percent(uint _token, uint _percentage) internal pure returns (uint) {
        return _percentage.mul(_token).div(100);
    }
    
}

contract standardToken is ERC20Token, Controlled {
    
    mapping (address => mapping (address => uint256)) public allowances;
    
     
     
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

     
     
     
     
    
	function transfer(
        address _to,
        uint256 _value) 
        public 
        canTransfer
        releaseTokenValid(msg.sender, now, _value)
        returns (bool) 
    {
        require (balances[msg.sender] >= _value);            
        require (balances[_to] + _value >= balances[_to]);   
        balances[msg.sender] -= _value;                      
        balances[_to] += _value;                             
        emit Transfer(msg.sender, _to, _value);              
        return true;
    }
    
     
     
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;           
        emit Approval(msg.sender, _spender, _value);              
        return true;
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        approve(_spender, _value);                           
         
         
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { 
            revert(); 
        }
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public canTransfer releaseTokenValid(msg.sender, now, _value) returns (bool success) {
        require (balances[_from] >= _value);                 
        require (balances[_to] + _value >= balances[_to]);   
        require (_value <= allowances[_from][msg.sender]);   
        balances[_from] -= _value;                           
        balances[_to] += _value;                             
        allowances[_from][msg.sender] -= _value;             
        emit Transfer(_from, _to, _value);                        
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowances[_owner][_spender];
    }

}

contract UST is Owned, standardToken {
        
    string constant public name   = "UseChainToken";
    string constant public symbol = "UST";
    uint constant public decimals = 18;

    uint256 public totalSupply = 0;
    uint256 constant public topTotalSupply = 2 * 10**10 * 10**decimals;
    uint public forSaleSupply        = percent(topTotalSupply, 45);
    uint public marketingPartnerSupply = percent(topTotalSupply, 5);
    uint public coreTeamSupply   = percent(topTotalSupply, 15);
    uint public technicalCommunitySupply       = percent(topTotalSupply, 15);
    uint public communitySupply          = percent(topTotalSupply, 20);
    uint public softCap                = percent(topTotalSupply, 30);
    
    function () public {
        revert();
    }
    
     
     
    function setRealseTime(uint256 _time) public onlyOwner {
        releaseStartTime = _time;
    }
    
     
     
     
     
    function allocateToken(address[] _owners, uint256[] _values, uint256[] _addrLockType) public onlyOwner {
        require ((_owners.length == _values.length) && ( _values.length == _addrLockType.length));
        for(uint i = 0; i < _owners.length ; i++){
            uint256 value = _values[i] * 10 ** decimals;
            
            totalSupply = totalSupply.add(value);
            balances[_owners[i]] = balances[_owners[i]].add(value);              
            emit Transfer(0x0, _owners[i], value);    
            
            userReleaseToken[_owners[i]].UST = userReleaseToken[_owners[i]].UST.add(value);
            userReleaseToken[_owners[i]].addrLockType = _addrLockType[i];
        }
    }
    
     
     
     
	function allocateCandyToken(address[] _owners, uint256[] _values) public onlyOwner {
       for(uint i = 0; i < _owners.length ; i++){
           uint256 value = _values[i] * 10 ** decimals;
           totalSupply = totalSupply.add(value);
		   balances[_owners[i]] = balances[_owners[i]].add(value); 
		   emit Transfer(0x0, _owners[i], value);  		  
        }
    }
    
}