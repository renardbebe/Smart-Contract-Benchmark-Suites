 

pragma solidity ^0.4.24;

contract Owned {
    
     
     
    address public owner;
    address internal newOwner;
    
     
    constructor() public {
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

contract SafeMath {
    function safeMul(uint a, uint b) pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function safeSub(uint a, uint b) pure internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
    function safeAdd(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
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

contract CUSE is ERC20Token {
    
    string public name = "USE Call Option";
    string public symbol = "CUSE12";
    uint public decimals = 0;
    
    uint256 public totalSupply = 75000000;
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
     
     
     
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
     
        if (balances[_from] >= _value && allowances[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
          balances[_to] += _value;
          balances[_from] -= _value;
          allowances[_from][msg.sender] -= _value;
          emit Transfer(_from, _to, _value);
          return true;
        } else { return false; }
    }
    
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
    
    mapping(address => uint256) public balances;
    
    mapping (address => mapping (address => uint256)) allowances;
}

contract ExchangeCUSE is SafeMath, Owned, CUSE {
    
     
    uint public ExerciseEndTime = 1546272000;
    uint public exchangeRate = 13333 * 10**9 wei;  
    
     
    
     
    address public USEaddress = address(0xd9485499499d66B175Cf5ED54c0a19f1a6Bcb61A);
    
     
    address public officialAddress = address(0x89Ead717c9DC15a222926221897c68F9486E7229);

    function execCUSEOption() public payable returns (bool) {
        require (now < ExerciseEndTime);
        
         
        uint _ether = msg.value;
        (uint _use, uint _refoundETH) = calcUSE(balances[msg.sender], _ether);
        
         
        balances[msg.sender] = safeSub(balances[msg.sender], _use/(10**18));
        balances[officialAddress] = safeAdd(balances[officialAddress], _use/(10**18));
        require (CUSE(USEaddress).transferFrom(officialAddress, msg.sender, _use) == true);

        emit Transfer(msg.sender, officialAddress, _use/(10**18)); 
        
         
        needRefoundETH(_refoundETH);
        officialAddress.transfer(safeSub(_ether, _refoundETH));
    }
    
     
    function calcUSE(uint _cuse, uint _ether) internal view returns (uint _use, uint _refoundETH) {
        uint _amount = _ether / exchangeRate;
        require (safeMul(_amount, exchangeRate) <= _ether);
        
         
        if (_amount <= _cuse) {
            _use = safeMul(_amount, 10**18);
            _refoundETH = 0;
            
        } else {
            _use = safeMul(_cuse, 10**18);
            _refoundETH = safeMul(safeSub(_amount, _cuse), exchangeRate);
        }
        
    }
    
    function needRefoundETH(uint _refoundETH) internal {
        if (_refoundETH > 0) {
            msg.sender.transfer(_refoundETH);
        }
    }
    
    function changeOfficialAddress(address _newAddress) public onlyOwner {
         officialAddress = _newAddress;
    }
}

contract USECallOption is ExchangeCUSE {

    function () payable public {
        revert();
    }

     
    function allocateCandyToken(address[] _owners, uint256[] _values) public onlyOwner {
       for(uint i = 0; i < _owners.length; i++){
		   balances[_owners[i]] = safeAdd(balances[_owners[i]], _values[i]); 
		   emit Transfer(address(this), _owners[i], _values[i]);  		  
        }
    }

     
    function WithdrawETH() payable public onlyOwner {
        officialAddress.transfer(address(this).balance);
    } 
    
}