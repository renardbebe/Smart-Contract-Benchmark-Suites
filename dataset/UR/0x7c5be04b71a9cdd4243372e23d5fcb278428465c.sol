 

pragma solidity 0.4.24;
 

 
library SafeMath {

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract admined {  
    address public admin;  
    bool public lockSupply;  

     
    constructor() internal {
        admin = msg.sender;  
        emit Admined(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

    modifier supplyLock() {  
        require(lockSupply == false);
        _;
    }

     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != 0);
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

     
    function setSupplyLock(bool _flag) onlyAdmin public {  
        lockSupply = _flag;
        emit SetSupplyLock(lockSupply);
    }

     
    event SetSupplyLock(bool _set);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

 
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract ERC20Token is admined, ERC20 {  
    using SafeMath for uint256;  
    mapping (address => uint256) internal balances;  
    mapping (address => mapping (address => uint256)) internal allowed;  
    uint256 internal totalSupply_;

     
    mapping (address => bool) frozen;
    mapping (address => uint256) unfreezeDate;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
     
    function balanceOf(address _who) public view returns (uint256) {
        return balances[_who];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));  
        require(frozen[msg.sender]==false);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));  
        require(frozen[_from]==false);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));  
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function burnToken(uint256 _burnedAmount) onlyAdmin supplyLock public {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _burnedAmount);
        totalSupply_ = SafeMath.sub(totalSupply_, _burnedAmount);
        emit Burned(msg.sender, _burnedAmount);
    }

     
    function setFrozen(address _target,bool _flag,uint256 _timeInDays) public {
        if(_flag == true){
            require(msg.sender == admin);  
            require(frozen[_target] == false);  
            frozen[_target] = _flag;
            unfreezeDate[_target] = now.add(_timeInDays * 1 days);

            emit FrozenStatus(_target,_flag,unfreezeDate[_target]);

        } else {
            require(now >= unfreezeDate[_target]);
            frozen[_target] = _flag;

            emit FrozenStatus(_target,_flag,unfreezeDate[_target]);
        }
    }

    event Burned(address indexed _target, uint256 _value);
    event FrozenStatus(address indexed _target,bool _flag,uint256 _unfreezeDate);

}

 
contract AssetViV is ERC20Token {
    string public name = 'VIVALID';
    uint8 public decimals = 18;
    string public symbol = 'ViV';
    string public version = '1';

     
    constructor() public {
        totalSupply_ = 200000000 * 10 ** uint256(decimals);  
        balances[msg.sender] = totalSupply_;
        emit Transfer(0, this, totalSupply_);
        emit Transfer(this, msg.sender, totalSupply_);       
    }

     
    function claimTokens(ERC20 _address, address _to) onlyAdmin public{
        require(_to != address(0));
        uint256 remainder = _address.balanceOf(this);  
        _address.transfer(_to,remainder);  
    }

    
     
    function() public {
        revert();
    }

}