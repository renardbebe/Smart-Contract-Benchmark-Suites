 

pragma solidity ^0.4.23;

 

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public contractOwner;

    event TransferredOwnership(address indexed _previousOwner, address indexed _newOwner);

    constructor() public {        
        contractOwner = msg.sender;
    }

    modifier ownerOnly() {
        require(msg.sender == contractOwner);
        _;
    }

    function transferOwnership(address _newOwner) internal ownerOnly {
        require(_newOwner != address(0));
        contractOwner = _newOwner;

        emit TransferredOwnership(contractOwner, _newOwner);
    }

}

 
contract LucreVesting is Ownable {
    struct Vesting {        
        uint256 amount;
        uint256 endTime;
    }
    mapping(address => Vesting) internal vestings;

    function addVesting(address _user, uint256 _amount, uint256 _endTime) public ;
    function getVestedAmount(address _user) public view returns (uint256 _amount);
    function getVestingEndTime(address _user) public view returns (uint256 _endTime);
    function vestingEnded(address _user) public view returns (bool) ;
    function endVesting(address _user) public ;
}

 
contract ERC20Standard {
    function balanceOf(address _user) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract ERC223Standard {
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes _data);
}

 
contract ERC223ReceivingContract { 
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

contract BurnToken is Ownable {
    using SafeMath for uint256;
    
    function burn(uint256 _value) public;
    function _burn(address _user, uint256 _value) internal;
    event Burn(address indexed _user, uint256 _value);
}

 
contract LucreToken is ERC20Standard, ERC223Standard, Ownable, LucreVesting, BurnToken {
    using SafeMath for uint256;

    string _name = "LUCRE TOKEN";
    string _symbol = "LCRT";
    string _standard = "ERC20 / ERC223";
    uint256 _decimals = 18;  
    uint256 _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(uint256 _supply) public {
        require(_supply != 0);
        _totalSupply = _supply * (10 ** 18);
        balances[contractOwner] = _totalSupply;
    }

     
    function name() public view returns (string) {
        return _name;        
    }

     
    function symbol() public view returns (string) {
        return _symbol;
    }

     
    function standard() public view returns (string) {
        return _standard;
    }

     
    function decimals() public view returns (uint256) {
        return _decimals;
    }

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address _user) public view returns (uint256 balance){
        return balances[_user];
    }   

     
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_to != 0x0);
        bytes memory _empty;
        if(isContract(_to)){
            return transferToContract(_to, _value, _empty);
        }else{
            return transferToAddress(_to, _value, _empty);
        }
    }

     
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
        require(_to != 0x0);
        if(isContract(_to)){
            return transferToContract(_to, _value, _data);
        }else{
            return transferToAddress(_to, _value, _data);
        }
    }

     
     
    function isContract(address _to) internal view returns (bool) {
        uint256 _codeLength;

        assembly {
            _codeLength := extcodesize(_to)
        }

        return _codeLength > 0;
    }

     
    function transferToContract(address _to, uint256 _value, bytes _data) internal returns (bool) {
        require(balances[msg.sender] >= _value);
        require(validateTransferAmount(msg.sender,_value));
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        ERC223ReceivingContract _tokenReceiver = ERC223ReceivingContract(_to);
        _tokenReceiver.tokenFallback(msg.sender, _value, _data);

        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transferToAddress(address _to, uint256 _value, bytes _data) internal returns (bool) {
        require(balances[msg.sender] >= _value);
        require(validateTransferAmount(msg.sender,_value));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_to != 0x0);
        require(_value <= allowed[_from][msg.sender]);
        require(_value <= balances[_from]);
        require(validateTransferAmount(_from,_value));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = 0;
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

     
    function () public {
        revert();
    }

     
    function burn(uint256 _value) public ownerOnly {
        _burn(msg.sender, _value);
    }

     
    function _burn(address _user, uint256 _value) internal ownerOnly {
        require(balances[_user] >= _value);

        balances[_user] = balances[_user].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        
        emit Burn(_user, _value);
        emit Transfer(_user, address(0), _value);

        bytes memory _empty;
        emit Transfer(_user, address(0), _value, _empty);
    }

     
    function addVesting(address _user, uint256 _amount, uint256 _endTime) public ownerOnly {
        vestings[_user].amount = _amount;
        vestings[_user].endTime = _endTime;
    }

     
    function getVestedAmount(address _user) public view returns (uint256 _amount) {
        _amount = vestings[_user].amount;
        return _amount;
    }

     
    function getVestingEndTime(address _user) public view returns (uint256 _endTime) {
        _endTime = vestings[_user].endTime;
        return _endTime;
    }

     
    function vestingEnded(address _user) public view returns (bool) {
        if(vestings[_user].endTime <= now) {
            return true;
        }
        else {
            return false;
        }
    }

     
     
    function validateTransferAmount(address _user, uint256 _amount) internal view returns (bool) {
        if(vestingEnded(_user)){
            return true;
        }else{
            uint256 _vestedAmount = getVestedAmount(_user);
            uint256 _currentBalance = balanceOf(_user);
            uint256 _availableBalance = _currentBalance.sub(_vestedAmount);

            if(_amount <= _availableBalance) {
                return true;
            }else{
                return false;
            }
        }
    }

     
    function endVesting(address _user) public ownerOnly {
        vestings[_user].endTime = now;
    }
}