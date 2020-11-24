 

 

pragma solidity 0.4.18;

 

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

 

 
contract ERC20 {
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

contract COINPIGGY is ERC20 {
    using SafeMath for uint256;
    
    address public admin;
    string public constant name = "COINPIGGY";
    string public constant symbol = "CPGY";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;


    mapping(address => bool) internal blacklist;
    event Burn(address indexed from, uint256 value);

     
     
     
    bool public checkTokenLock = false;

     
    modifier adminOnly {
        require(msg.sender == admin);
        _;
    }

    modifier transferable {
        require(msg.sender == admin || !checkTokenLock);
        _;
    }

    function COINPIGGY(uint256 _initialSupply) public {
        balances[msg.sender] = _initialSupply.mul(1e18);
        totalSupply = _initialSupply.mul(1e18);
        admin = msg.sender;
    }

    
     
     
     
    function blockTransfer(bool _block) external adminOnly {
        checkTokenLock = _block;
    }


     
     
     
    function updateBlackList(address _addr, bool _inBlackList) external adminOnly{
        blacklist[_addr] = _inBlackList;
    }
    

    function isInBlackList(address _addr) public view returns(bool){
        return blacklist[_addr];
    }
    
    function balanceOf(address _who) public view returns(uint256) {
        return balances[_who];
    }

    function transfer(address _to, uint256 _amount) public transferable returns(bool) {
        require(_to != address(0));
        require(_to != address(this));
        require(_amount > 0);
        require(_amount <= balances[msg.sender]);
        require(blacklist[msg.sender] == false);
        require(blacklist[_to] == false);

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public transferable returns(bool) {
        require(_to != address(0));
        require(_to != address(this));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        require(blacklist[_from] == false);
        require(blacklist[_to] == false);

        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns(bool) {
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }
    
    function burn(uint256 _amount) public transferable returns (bool) {
        require(_amount > 0);
        require(balances[msg.sender] >= _amount);
        
        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        Burn(msg.sender, _amount);
        return true;
    }

    function burnFrom(address _from, uint256 _amount)public transferable returns (bool) {
        require(_amount > 0);
        require(balances[_from] >= _amount);
        require(allowed[_from][msg.sender]  >= _amount);
        
        totalSupply = totalSupply.sub(_amount);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        Burn(_from, _amount);
        return true;
    }

}