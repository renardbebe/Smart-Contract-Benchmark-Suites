 

pragma solidity ^0.4.24;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0 || b == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "Mul overflow!");
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Sub overflow!");
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "Add overflow!");
        return c;
    }
}

 
 
 
 
contract ERC20Interface {

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns(bool);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

 
 
 
contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner, "Only Owner can do that!");
        _;
    }

    function transferOwnership(address _newOwner)
    external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership()
    external {
        require(msg.sender == newOwner, "You are not new Owner!");
        owner = newOwner;
        newOwner = address(0);
        emit OwnershipTransferred(owner, newOwner);
    }
}

contract Permissioned {

    function approve(address _spender, uint256 _value) public returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool);
    function allowance(address _owner, address _spender) external view returns (uint256);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Burnable {

    function burn(uint256 _value) external returns(bool);
    function burnFrom(address _from, uint256 _value) external returns(bool);

     
    event Burn(address indexed _from, uint256 _value);
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract Aligato is ERC20Interface, Owned, Permissioned, Burnable {

    using SafeMath for uint256;  

     
    mapping(address => uint256) internal _balanceOf;

     
    mapping(address => mapping(address => uint256)) internal _allowance;

    bool public isLocked = true;  

    uint256 icoSupply = 0;

     
    function setICO(address user, uint256 amt) internal{
        uint256 amt2 = amt * (10 ** uint256(decimals));
        _balanceOf[user] = amt2;
        emit Transfer(0x0, user, amt2);
        icoSupply += amt2;
    }

     
   

     
    constructor(string _symbol, string _name, uint256 _supply, uint8 _decimals)
    public {
        require(_supply != 0, "Supply required!");  
        owner = msg.sender;
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        
        totalSupply = _supply.mul(10 ** uint256(decimals));  
        _balanceOf[msg.sender] = totalSupply - icoSupply;
        emit Transfer(address(0), msg.sender, totalSupply - icoSupply);
    }

     
    function unlock() external onlyOwner returns (bool success)
    {
        require (isLocked == true, "It is unlocked already!");  
        isLocked = false;
        return true;
    }

     
    function balanceOf(address _owner)
    external view
    returns(uint256 balance) {
        return _balanceOf[_owner];
    }

     
    function _transfer(address _from, address _to, uint256 _value)
    internal {
         
        require (isLocked == false || _from == owner, "Contract is locked!");
         
        require(_to != address(0), "Can`t send to 0x0, use burn()");
         
        require(_balanceOf[_from] >= _value, "Not enough balance!");
         
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
         
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value)
    external
    returns(bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
    external
    returns(bool success) {
         
        require(_value <= _allowance[_from][msg.sender], "Not enough allowance!");
         
        require(_value <= _balanceOf[_from], "Not enough balance!");
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        emit Approval(_from, _to, _allowance[_from][_to]);
        return true;
    }

     
    function approve(address _spender, uint256 _value)
    public
    returns(bool success) {
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    external
    returns(bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function allowance(address _owner, address _spender)
    external view
    returns(uint256 value) {
        return _allowance[_owner][_spender];
    }

     
    function burn(uint256 _value)
    external
    returns(bool success) {
        _burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value)
    external
    returns(bool success) {
          
        require(_value <= _allowance[_from][msg.sender], "Not enough allowance!");
         
        require(_value <= _balanceOf[_from], "Insuffient balance!");
         
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        _burn(_from, _value);
        emit Approval(_from, msg.sender, _allowance[_from][msg.sender]);
        return true;
    }

    function _burn(address _from, uint256 _value)
    internal {
         
        require(_balanceOf[_from] >= _value, "Insuffient balance!");
         
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
         
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(_from, address(0), _value);
    }

     
     
     
    function () external payable {
        revert("This contract is not accepting ETH.");
    }

     
    function withdraw(uint256 _amount)
    external onlyOwner
    returns (bool){
        require(_amount <= address(this).balance, "Not enough balance!");
        owner.transfer(_amount);
        return true;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint256 _value)
    external onlyOwner
    returns(bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, _value);
    }
}